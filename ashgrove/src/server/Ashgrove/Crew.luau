--[[
	Crew: the players. Hits, going down, being revived, being taken by the
	Banshee, party wipes, movement modes and their noise, the flashlight,
	the gold ward, and "committed" actions.

	Health is ours, not the Humanoid's: Config.player.hitsToDown hits put a
	player down, a crewmate revives them, and when nobody is left standing
	the party wipes back to the last checkpoint (Director handles that via
	Crew.wiped).

	A committed action (securing an object, a rite step, a revive) roots the
	player and blocks shooting for its length. The player can't cancel it;
	a hit can.

	Player attributes the client reads: Hits, Downed, Taken, MoveMode,
	Flashlight, LightOn, Battery, HasGold, WardRaised, WardReadyAt,
	CommitLabel, CommitEnds, CommitLength.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Signal"))

local Map = require(script.Parent.Map)
local Noise = require(script.Parent.Noise)
local Say = require(script.Parent.Say)

local Crew = {}

Crew.wiped = Signal.new()
Crew.characterReady = Signal.new() -- (player, character)
Crew.goldLost = Signal.new()

-- Director sets this so every (re)spawn lands at the current checkpoint.
Crew.spawnCFrame = function(_player: Player): CFrame?
	return nil
end

type Commit = { label: string, token: {}, onCancel: (() -> ())? }

type State = {
	hits: number,
	downed: boolean,
	taken: boolean,
	mode: string,
	flashlightOn: boolean,
	suppressUntil: number,
	battery: number,
	aim: Vector3,
	hasGold: boolean,
	wardUntil: number,
	wardReadyAt: number,
	commit: Commit?,
	invulnUntil: number,
	lastRegen: number,
	hipHeight: number,
	light: SpotLight?,
	lightAttachment: Attachment?,
	revivePrompt: ProximityPrompt?,
	goldPart: BasePart?,
}

local states: { [Player]: State } = {}
local wiping = false

local function newState(): State
	return {
		hits = 0,
		downed = false,
		taken = false,
		mode = "walk",
		flashlightOn = false,
		suppressUntil = 0,
		battery = Config.flashlight.battery,
		aim = Vector3.new(0, 0, -1),
		hasGold = false,
		wardUntil = 0,
		wardReadyAt = 0,
		commit = nil,
		invulnUntil = 0,
		lastRegen = 0,
		hipHeight = 2,
	}
end

function Crew.state(player: Player): State?
	return states[player]
end

function Crew.root(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Crew.head(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("Head") :: BasePart?
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- Standing, in the game, and able to act.
function Crew.isActive(player: Player): boolean
	local s = states[player]
	if not s or s.downed or s.taken then
		return false
	end
	local humanoid = humanoidOf(player)
	return humanoid ~= nil and humanoid.Health > 0 and Crew.root(player) ~= nil
end

-- What entities may go after: active and not inside a sanctuary.
function Crew.isTargetable(player: Player): boolean
	if not Crew.isActive(player) then
		return false
	end
	local root = Crew.root(player)
	return root ~= nil and not Map.isSanctuary(root.Position)
end

function Crew.activePlayers(): { Player }
	local out = {}
	for player in states do
		if Crew.isActive(player) then
			table.insert(out, player)
		end
	end
	return out
end

-- Active players whose character is inside a wing.
function Crew.playersInWing(wing: string, includeDowned: boolean?): { Player }
	local out = {}
	for player, s in states do
		local root = Crew.root(player)
		if root and not s.taken and (includeDowned or Crew.isActive(player)) and Map.wingAt(root.Position) == wing then
			table.insert(out, player)
		end
	end
	return out
end

function Crew.isCommitting(player: Player): boolean
	local s = states[player]
	return s ~= nil and s.commit ~= nil
end

------------------------------------------------------------------ movement

local function refreshSpeed(player: Player)
	local s = states[player]
	local humanoid = humanoidOf(player)
	if not s or not humanoid then
		return
	end
	local p = Config.player
	local speed
	if s.taken or s.commit then
		speed = 0
	elseif s.downed then
		speed = p.downedSpeed
	elseif s.mode == "sprint" then
		speed = p.sprintSpeed
	elseif s.mode == "crouch" then
		speed = p.crouchSpeed
	else
		speed = p.walkSpeed
	end
	humanoid.WalkSpeed = speed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = if s.downed or s.commit or s.taken then 0 else p.jumpPower
	humanoid.HipHeight = if s.downed then math.max(0.2, s.hipHeight - 1.2) else s.hipHeight
end

------------------------------------------------------------------ flashlight

local function lightOn(s: State): boolean
	return s.flashlightOn and s.battery > 0 and os.clock() >= s.suppressUntil and not s.taken
end

local function updateLight(player: Player)
	local s = states[player]
	if not s then
		return
	end
	local on = lightOn(s)
	if s.light then
		s.light.Enabled = on
	end
	player:SetAttribute("Flashlight", s.flashlightOn)
	player:SetAttribute("LightOn", on)
	player:SetAttribute("Battery", math.floor(s.battery + 0.5))
end

-- Forces the light off for a while (reloading needs both hands).
function Crew.suppressFlashlight(player: Player, seconds: number)
	local s = states[player]
	if not s then
		return
	end
	s.suppressUntil = math.max(s.suppressUntil, os.clock() + seconds)
	updateLight(player)
	task.delay(seconds + 0.05, updateLight, player)
end

function Crew.addBattery(player: Player, amount: number): boolean
	local s = states[player]
	if not s or s.battery >= Config.flashlight.maxBattery - 1 then
		return false
	end
	s.battery = math.min(Config.flashlight.maxBattery, s.battery + amount)
	updateLight(player)
	return true
end

-- Every flashlight currently shining: where from and which way.
function Crew.flashlights(): { { player: Player, origin: Vector3, direction: Vector3 } }
	local out = {}
	for player, s in states do
		if lightOn(s) then
			local head = Crew.head(player)
			if head then
				table.insert(out, { player = player, origin = head.Position, direction = s.aim })
			end
		end
	end
	return out
end

function Crew.aim(player: Player): Vector3
	local s = states[player]
	return if s then s.aim else Vector3.new(0, 0, -1)
end

------------------------------------------------------------------ ward

function Crew.giveGold(player: Player)
	local s = states[player]
	if s then
		s.hasGold = true
		player:SetAttribute("HasGold", true)
		Say.to(player, "Cornelius's gold sovereign. [G] raises it.", 5, "hint")
	end
end

function Crew.isWardRaised(player: Player): boolean
	local s = states[player]
	return s ~= nil and os.clock() < s.wardUntil and Crew.isActive(player)
end

local function raiseWard(player: Player)
	local s = states[player]
	if not s or not s.hasGold or not Crew.isActive(player) then
		return
	end
	local now = os.clock()
	if now < s.wardReadyAt then
		return
	end
	s.wardReadyAt = now + Config.ward.cooldown
	s.wardUntil = now + Config.ward.raiseTime
	player:SetAttribute("WardRaised", true)
	player:SetAttribute("WardReadyAt", workspace:GetServerTimeNow() + Config.ward.cooldown)
	if s.goldPart then
		s.goldPart.Transparency = 0
	end
	task.delay(Config.ward.raiseTime, function()
		player:SetAttribute("WardRaised", false)
		if s.goldPart then
			s.goldPart.Transparency = 1
		end
	end)
end

------------------------------------------------------------------ commit

local function clearCommitAttributes(player: Player)
	player:SetAttribute("CommitLabel", nil)
	player:SetAttribute("CommitEnds", nil)
	player:SetAttribute("CommitLength", nil)
end

-- Starts a committed action. Returns false if the player can't commit
-- right now (already busy, down, taken).
function Crew.commit(player: Player, seconds: number, label: string, onDone: () -> (), onCancel: (() -> ())?): boolean
	local s = states[player]
	if not s or not Crew.isActive(player) or s.commit then
		return false
	end
	local token = {}
	s.commit = { label = label, token = token, onCancel = onCancel }
	player:SetAttribute("CommitLabel", label)
	player:SetAttribute("CommitEnds", workspace:GetServerTimeNow() + seconds)
	player:SetAttribute("CommitLength", seconds)
	refreshSpeed(player)
	task.delay(seconds, function()
		local current = s.commit
		if current and current.token == token then
			s.commit = nil
			clearCommitAttributes(player)
			refreshSpeed(player)
			onDone()
		end
	end)
	return true
end

function Crew.cancelCommit(player: Player)
	local s = states[player]
	local current = s and s.commit
	if not s or not current then
		return
	end
	s.commit = nil
	clearCommitAttributes(player)
	refreshSpeed(player)
	Say.to(player, "Interrupted.", 2, "hint")
	if current.onCancel then
		task.spawn(current.onCancel)
	end
end

------------------------------------------------------------------ hits, down, taken

local function checkWipe()
	if wiping then
		return
	end
	local anyone, anyActive = false, false
	for player in states do
		if player.Parent and player.Character then
			anyone = true
			if Crew.isActive(player) then
				anyActive = true
			end
		end
	end
	if anyone and not anyActive then
		wiping = true
		Crew.wiped:Fire()
	end
end

local function setRevivePrompt(player: Player, enabled: boolean)
	local s = states[player]
	if s and s.revivePrompt then
		s.revivePrompt.Enabled = enabled
	end
end

function Crew.down(player: Player)
	local s = states[player]
	if not s or s.downed or s.taken then
		return
	end
	s.downed = true
	Crew.cancelCommit(player)
	player:SetAttribute("Downed", true)
	refreshSpeed(player)
	setRevivePrompt(player, true)
	Say.to(player, "You're down. A crewmate can get you up.", 6, "story")
	Say.except(player, `{player.DisplayName} is down. Get to them.`, 5, "story")
	checkWipe()
end

function Crew.revive(player: Player)
	local s = states[player]
	if not s or not s.downed or s.taken then
		return
	end
	s.downed = false
	s.hits = Config.player.hitsToDown - 1
	s.invulnUntil = os.clock() + 2
	player:SetAttribute("Downed", false)
	player:SetAttribute("Hits", s.hits)
	setRevivePrompt(player, false)
	refreshSpeed(player)
	Say.all(`{player.DisplayName} is back on their feet.`, 3, "story")
end

function Crew.hit(player: Player, amount: number)
	local s = states[player]
	if not s or not Crew.isActive(player) then
		return
	end
	local now = os.clock()
	if now < s.invulnUntil then
		return
	end
	s.invulnUntil = now + Config.player.hitInvulnerability
	s.hits = math.min(s.hits + amount, Config.player.hitsToDown)
	player:SetAttribute("Hits", s.hits)
	local root = Crew.root(player)
	if root then
		Audio.play("hurt", root, 0.7)
	end
	Crew.cancelCommit(player)
	if s.hits >= Config.player.hitsToDown then
		Crew.down(player)
	end
end

-- Taken by the Banshee: out of the game until the party reaches a
-- sanctuary. Can't be revived in place.
function Crew.take(player: Player)
	local s = states[player]
	if not s or s.taken then
		return
	end
	Crew.cancelCommit(player)
	s.taken = true
	s.downed = false
	player:SetAttribute("Taken", true)
	player:SetAttribute("Downed", false)
	setRevivePrompt(player, false)
	updateLight(player)
	refreshSpeed(player)
	local character = player.Character
	local root = Crew.root(player)
	if character and root then
		root.Anchored = true
		character:PivotTo(CFrame.new(Config.player.takenHoldPosition))
	end
	Net.event("Spectate"):FireClient(player, true)
	Say.except(player, `{player.DisplayName} is gone. Get somewhere safe and they'll come back.`, 6, "story")
	checkWipe()
end

local function placeCharacter(player: Player, cf: CFrame)
	local character = player.Character
	local root = Crew.root(player)
	if character and root then
		root.Anchored = false
		character:PivotTo(cf)
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

function Crew.restoreTaken(at: CFrame)
	local i = 0
	for player, s in states do
		if s.taken then
			i += 1
			s.taken = false
			s.hits = 0
			player:SetAttribute("Taken", false)
			player:SetAttribute("Hits", 0)
			placeCharacter(player, at * CFrame.new(2 * i, 0, 2))
			refreshSpeed(player)
			updateLight(player)
			Net.event("Spectate"):FireClient(player, false)
			Say.all(`{player.DisplayName} stumbles back in out of the dark.`, 4, "story")
		end
	end
end

-- Checkpoint reset after a wipe.
function Crew.resetAll(at: CFrame)
	local i = 0
	for player, s in states do
		s.commit = nil
		clearCommitAttributes(player)
		s.hits = 0
		s.downed = false
		s.taken = false
		s.suppressUntil = 0
		s.invulnUntil = os.clock() + 3
		player:SetAttribute("Hits", 0)
		player:SetAttribute("Downed", false)
		player:SetAttribute("Taken", false)
		setRevivePrompt(player, false)
		placeCharacter(player, at * CFrame.new((i % 4) * 3 - 4.5, 0, math.floor(i / 4) * 3))
		refreshSpeed(player)
		updateLight(player)
		Net.event("Spectate"):FireClient(player, false)
		i += 1
	end
	wiping = false
end

------------------------------------------------------------------ characters

local function onCharacter(player: Player, character: Model)
	local s = states[player]
	if not s then
		return
	end
	s.hits = 0
	s.downed = false
	s.taken = false
	s.commit = nil
	clearCommitAttributes(player)
	player:SetAttribute("Hits", 0)
	player:SetAttribute("Downed", false)
	player:SetAttribute("Taken", false)

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local head = character:WaitForChild("Head") :: BasePart
	s.hipHeight = humanoid.HipHeight
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local attachment = Instance.new("Attachment")
	attachment.Name = "AshFlashlight"
	attachment.Position = Vector3.new(0, 0.2, -0.6)
	attachment.Parent = head
	local light = Instance.new("SpotLight")
	light.Name = "AshFlashlight"
	light.Angle = Config.flashlight.angle
	light.Range = Config.flashlight.range
	light.Brightness = Config.flashlight.brightness
	light.Color = Color3.fromRGB(255, 240, 220)
	light.Shadows = true
	light.Face = Enum.NormalId.Front
	light.Enabled = false
	light.Parent = attachment
	s.light = light
	s.lightAttachment = attachment

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Revive"
	prompt.ActionText = "Revive"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(rescuer: Player)
		if rescuer == player or not s.downed or s.taken then
			return
		end
		Crew.commit(rescuer, Config.commit.revive, `Getting {player.DisplayName} up`, function()
			Crew.revive(player)
		end)
	end)
	s.revivePrompt = prompt

	local gold = Instance.new("Part")
	gold.Name = "RaisedGold"
	gold.Shape = Enum.PartType.Ball
	gold.Size = Vector3.one * 0.6
	gold.Color = Color3.fromRGB(214, 172, 60)
	gold.Material = Enum.Material.Metal
	gold.CanCollide = false
	gold.CanQuery = false
	gold.Massless = true
	gold.Transparency = 1
	local weld = Instance.new("Weld")
	weld.Part0 = head
	weld.Part1 = gold
	weld.C0 = CFrame.new(-0.8, -0.2, -1.6)
	weld.Parent = gold
	gold.Parent = character
	s.goldPart = gold

	refreshSpeed(player)
	updateLight(player)

	task.spawn(function()
		if not character.Parent then
			character.AncestryChanged:Wait()
		end
		task.wait()
		local cf = Crew.spawnCFrame(player)
		if cf then
			character:PivotTo(cf)
		end
	end)
	Crew.characterReady:Fire(player, character)
end

local function onPlayer(player: Player)
	states[player] = newState()
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMaxZoomDistance = 0.5
	player:SetAttribute("MoveMode", "walk")
	player:SetAttribute("HasGold", false)
	player:SetAttribute("Battery", Config.flashlight.battery)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

------------------------------------------------------------------ start

function Crew.start()
	Net.event("Move").OnServerEvent:Connect(function(player, mode)
		local s = states[player]
		if s and (mode == "walk" or mode == "sprint" or mode == "crouch") then
			s.mode = mode
			player:SetAttribute("MoveMode", mode)
			refreshSpeed(player)
		end
	end)

	Net.event("Flashlight").OnServerEvent:Connect(function(player, on)
		local s = states[player]
		if s and typeof(on) == "boolean" then
			s.flashlightOn = on
			updateLight(player)
		end
	end)

	Net.unreliable("Aim").OnServerEvent:Connect(function(player, direction)
		local s = states[player]
		if not s or typeof(direction) ~= "Vector3" or direction.Magnitude < 0.5 or direction.Magnitude ~= direction.Magnitude then
			return
		end
		s.aim = direction.Unit
		local head = Crew.head(player)
		if head and s.lightAttachment then
			local rel = head.CFrame:VectorToObjectSpace(s.aim)
			local origin = Vector3.new(0, 0.2, -0.6)
			s.lightAttachment.CFrame = CFrame.lookAt(origin, origin + rel)
		end
	end)

	Net.event("Ward").OnServerEvent:Connect(raiseWard)

	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		local s = states[player]
		states[player] = nil
		if s and s.hasGold then
			Crew.goldLost:Fire()
		end
		task.defer(checkWipe)
	end)

	-- Footstep noise.
	task.spawn(function()
		local n = Config.player.noise
		while true do
			task.wait(n.sampleEvery)
			for player, s in states do
				local root = Crew.root(player)
				if root and Crew.isActive(player) then
					local v = root.AssemblyLinearVelocity
					local speed = Vector3.new(v.X, 0, v.Z).Magnitude
					if speed > 2 then
						local radius = if s.mode == "sprint" and speed > Config.player.walkSpeed + 2
							then n.sprint
							elseif s.mode == "crouch" then n.crouch
							else n.walk
						Noise.emit(root.Position, radius, "footsteps", player)
					end
				end
			end
		end
	end)

	-- Battery, regeneration in sanctuaries, taken players coming back.
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(0.5)
			local now = os.clock()
			local dt = now - last
			last = now
			local safeRoot: BasePart? = nil
			local anyTaken = false
			for player, s in states do
				if lightOn(s) then
					s.battery = math.max(0, s.battery - dt)
					if s.battery <= 0 then
						s.flashlightOn = false
						Say.to(player, "Your torch is dead. Find batteries.", 4, "hint")
					end
					updateLight(player)
				end
				if s.taken then
					anyTaken = true
				end
				local root = Crew.root(player)
				if root and Crew.isActive(player) and Map.isSanctuary(root.Position) then
					safeRoot = root
					if s.hits > 0 and now - s.lastRegen >= Config.player.sanctuaryRegenEvery then
						s.lastRegen = now
						s.hits -= 1
						player:SetAttribute("Hits", s.hits)
					end
				else
					s.lastRegen = now
				end
			end
			if anyTaken and safeRoot then
				Crew.restoreTaken(safeRoot.CFrame)
			end
			checkWipe()
		end
	end)
end

return Crew
