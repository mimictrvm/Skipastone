--[[
	The Banshee. Unkillable, and never a chaser.

	CORE RULE: when she keens, someone nearby will die soon. If nothing
	else dies, one of you will.

	States
	  Hidden    not in the world. Distant keening may be heard.
	  Mourning  kneeling at a site of death. Safe, unless disturbed: getting
	            within Config.banshee.disturbRadius, a torch on her face, or
	            a gunshot nearby turns her grief into a keen.
	  Keening   the storm goes silent and a doom window opens. Resolved by:
	              fulfil  an entity dies in the wing
	              leave   every player gets out of the wing (the wing is
	                      then shut for a while: Doors.lockout)
	              rite    the wing's wake custom is kept (Rites)
	            Otherwise, when the window closes:
	  Taking    she is in front of the one she faced, and takes them.

	Guarantees (direction doc, section 9): she never chases or patrols;
	she's always heard before she's seen; no more than one keen per wing
	visit, none in sanctuaries, none within minGapBetweenKeens of the last.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Signal = require(Shared:WaitForChild("Signal"))

local Crew = require(script.Parent.Crew)
local Doors = require(script.Parent.Doors)
local Light = require(script.Parent.Light)
local Map = require(script.Parent.Map)
local Noise = require(script.Parent.Noise)
local Reading = require(script.Parent.Reading)
local Registry = require(script.Parent.Entities.Registry)
local Rigs = require(script.Parent.Entities.Rigs)
local Rites = require(script.Parent.Rites)
local Say = require(script.Parent.Say)
local Storm = require(script.Parent.Storm)

local cfg = Config.banshee

local KEEN_WINGS = { "Gallery", "ServantsWing", "Vault" }

local Banshee = {}

Banshee.keenStarted = Signal.new() -- (wing, target)
Banshee.keenEnded = Signal.new() -- (wing, outcome, victim?)
Banshee.mourningEnded = Signal.new() -- (key?, disturbed)

type Keen = {
	wing: string,
	target: Player,
	startedAt: number,
	endsAt: number,
	forced: boolean,
	lastAgitate: number,
}

type Mourning = {
	position: Vector3,
	wing: string,
	endsAt: number,
	graceUntil: number,
	key: string?,
}

local model: Model
local state = "Hidden"
local keen: Keen? = nil
local mourning: Mourning? = nil
local keenSound: Sound? = nil

local distantEnabled = false
local nextDistantAt = math.huge
local naturalEnabled = false
local nextNaturalAt = math.huge
local lastKeenEnd = -math.huge
local taughtKeen = false
local taughtMourning = false

local visits: { [string]: { occupied: boolean, keened: boolean } } = {}
local mournedWings: { [string]: boolean } = {}

for _, wing in KEEN_WINGS do
	visits[wing] = { occupied = false, keened = false }
end

------------------------------------------------------------------ presence

local function eachPart(fn: (BasePart) -> ())
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "Root" then
			fn(p)
		end
	end
end

local function show(cf: CFrame, pose: string)
	local placed = if pose == "kneel" then cf * CFrame.new(0, -2.4, 0) * CFrame.Angles(math.rad(-14), 0, 0) else cf
	model:PivotTo(placed)
	eachPart(function(p)
		p.Transparency = 1
	end)
	model.Parent = Map.root()
	eachPart(function(p)
		TweenService:Create(p, TweenInfo.new(1.2), { Transparency = p:GetAttribute("BaseTransparency") or 0 }):Play()
	end)
end

local function hide(seconds: number?)
	local t = seconds or 1
	eachPart(function(p)
		TweenService:Create(p, TweenInfo.new(t), { Transparency = 1 }):Play()
	end)
	local token = model:GetAttribute("HideToken") or 0
	model:SetAttribute("HideToken", token + 1)
	task.delay(t, function()
		if model:GetAttribute("HideToken") == token + 1 and state == "Hidden" then
			model.Parent = ServerStorage
		end
	end)
end

local function floorBelow(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { model, Map.interact("Glows") }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	local entities = Map.root():FindFirstChild("Entities")
	if entities then
		table.insert(ignore, entities)
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -24, 0), params)
	return if hit then hit.Position else position
end

local function faceTowards(at: Vector3, towards: Vector3): CFrame
	local flatTarget = Vector3.new(towards.X, at.Y, towards.Z)
	if (flatTarget - at).Magnitude < 0.1 then
		return CFrame.new(at)
	end
	return CFrame.lookAt(at, flatTarget)
end

-- Where she stands to keen at a target: a marker in the wing at a
-- readable distance, preferring one with a clear line to them.
local function keenSpot(wing: string, target: Player): CFrame
	local markers = Map.markers("BansheeKeen_" .. wing .. "_")
	local root = Crew.root(target)
	if #markers == 0 or not root then
		local at = if root then root.Position + root.CFrame.LookVector * 20 else Vector3.zero
		return faceTowards(floorBelow(at), if root then root.Position else at)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, Map.interact("Glows") }
	local best, bestScore = markers[1], -math.huge
	for _, m in markers do
		local offset = root.Position - m.Position
		local distance = offset.Magnitude
		local score = -math.abs(distance - 28)
		local hit = workspace:Raycast(m.Position + Vector3.new(0, 8, 0), root.Position - (m.Position + Vector3.new(0, 8, 0)), params)
		local character = target.Character
		if hit == nil or (character and hit.Instance:IsDescendantOf(character)) then
			score += 40
		end
		if score > bestScore then
			best, bestScore = m, score
		end
	end
	return faceTowards(best.Position, root.Position)
end

------------------------------------------------------------------ rules

function Banshee.canKeen(wing: string, forced: boolean?): boolean
	if state == "Keening" or state == "Taking" or state == "Ending" then
		return false
	end
	if forced then
		return true
	end
	if not visits[wing] then
		return false -- the hall, the van and the grounds are never keened
	end
	if os.clock() - lastKeenEnd < cfg.minGapBetweenKeens then
		return false
	end
	if visits[wing].keened then
		return false
	end
	return #Crew.playersInWing(wing) > 0
end

local function scheduleNatural()
	nextNaturalAt = os.clock() + cfg.naturalKeenMin + math.random() * (cfg.naturalKeenMax - cfg.naturalKeenMin)
end

local function stopKeenSound()
	if keenSound then
		local s = keenSound
		keenSound = nil
		TweenService:Create(s, TweenInfo.new(1.5), { Volume = 0 }):Play()
		task.delay(1.6, function()
			s:Destroy()
		end)
	end
end

local function endMourning(disturbed: boolean)
	local m = mourning
	mourning = nil
	if state == "Mourning" then
		state = "Hidden"
		if not disturbed then
			hide(2)
		end
	end
	if m then
		Banshee.mourningEnded:Fire(m.key, disturbed)
	end
end

local function resolve(outcome: string, victim: Player?)
	local k = keen
	if not k then
		return
	end
	keen = nil
	state = "Hidden"
	Rites.setActive(k.wing, false)
	Storm.silence(false)
	stopKeenSound()
	lastKeenEnd = os.clock()
	Net.event("Keen"):FireAllClients("end", { outcome = outcome })
	if outcome == "fulfilled" then
		Say.all("[The keening stops.] Something died. She turns away.", 5, "story")
	elseif outcome == "left" then
		Say.all("[The keening fades behind you.] You got out. That wing won't let you back in for a while.", 6, "story")
		Doors.lockout(k.wing)
	elseif outcome == "rite" then
		Say.all("[The keening breaks off.] The custom is kept. She takes no one from that room.", 6, "story")
	end
	hide(1.5)
	if naturalEnabled then
		scheduleNatural()
	end
	Banshee.keenEnded:Fire(k.wing, outcome, victim)
end

local function take()
	local k = keen
	if not k then
		return
	end
	-- The one she faced, if still in the wing; otherwise whoever's closest.
	local victim: Player? = nil
	local inWing = Crew.playersInWing(k.wing, true)
	if table.find(inWing, k.target) then
		victim = k.target
	else
		local herPos = model:GetPivot().Position
		local best = math.huge
		for _, player in inWing do
			local root = Crew.root(player)
			local d = if root then (root.Position - herPos).Magnitude else math.huge
			if d < best then
				victim, best = player, d
			end
		end
	end
	if not victim then
		resolve("left")
		return
	end
	state = "Taking"
	local root = Crew.root(victim)
	if root then
		local at = floorBelow(root.Position + root.CFrame.LookVector * 4)
		model:PivotTo(faceTowards(at, root.Position))
	end
	Say.to(victim, "[She is right in front of you]", cfg.takeRevealTime, "sound")
	task.wait(cfg.takeRevealTime)
	if keen ~= k then
		return
	end
	Audio.play("bansheeTake", model:FindFirstChild("Chest") or model.PrimaryPart, 1, 300)
	Crew.take(victim)
	Say.all("[A scream, and then nothing]", 4, "sound")
	resolve("taken", victim)
end

-- Starts a keen in a wing. opts.target picks who she faces; opts.forced
-- skips the frequency rules (story beats); opts.at keeps her where she is.
function Banshee.keen(wing: string, opts: { target: Player?, forced: boolean?, at: CFrame?, duration: number? }?): boolean
	local o = opts or {}
	if not Banshee.canKeen(wing, o.forced) then
		return false
	end
	local target = o.target
	if not target or not table.find(Crew.playersInWing(wing, true), target) then
		local candidates = Crew.playersInWing(wing)
		if #candidates == 0 then
			candidates = Crew.playersInWing(wing, true)
		end
		if #candidates == 0 then
			return false
		end
		target = candidates[math.random(1, #candidates)]
	end
	local victimTarget = target :: Player
	if mourning then
		endMourning(true)
	end
	local now = os.clock()
	local duration = o.duration or (cfg.doomWindowMin + math.random() * (cfg.doomWindowMax - cfg.doomWindowMin))
	keen = {
		wing = wing,
		target = victimTarget,
		startedAt = now,
		endsAt = now + duration,
		forced = o.forced == true,
		lastAgitate = now,
	}
	state = "Keening"
	if visits[wing] then
		visits[wing].keened = true
	end

	show(o.at or keenSpot(wing, victimTarget), "stand")
	Storm.silence(true)
	stopKeenSound()
	local chest = model:FindFirstChild("Chest")
	if chest then
		keenSound = Audio.loop("keen", chest, 1)
		if keenSound then
			keenSound.RollOffMaxDistance = 400
		end
	end
	Say.all("[A keening rises. The storm goes quiet.]", 5, "sound")
	Say.to(victimTarget, "She is facing you.", 6, "story")
	Say.except(victimTarget, `She is facing {victimTarget.DisplayName}.`, 6, "story")
	if not taughtKeen then
		taughtKeen = true
		task.delay(3, function()
			Say.all("Something here has to die, or you have to get out. Or keep the old custom, if the room has one.", 8, "hint")
		end)
	end
	Net.event("Keen"):FireAllClients("start", {
		wing = wing,
		target = victimTarget.UserId,
		targetName = victimTarget.DisplayName,
		endsAt = workspace:GetServerTimeNow() + duration,
		length = duration,
	})
	Rites.setActive(wing, true)
	local root = Crew.root(victimTarget)
	for _, e in Registry.activeInWing(wing) do
		e:agitate(if root then root.Position else e:position())
	end
	Banshee.keenStarted:Fire(wing, victimTarget)
	return true
end

-- Kneels at a site of death. opts.noteId reveals a note there; opts.grace
-- is how long she ignores people already close (an aftermath).
function Banshee.mourn(position: Vector3, opts: { noteId: string?, key: string?, duration: number?, grace: number? }?): boolean
	local o = opts or {}
	if state ~= "Hidden" then
		return false
	end
	local wing = Map.wingAt(position)
	if not wing or not visits[wing] then
		return false
	end
	state = "Mourning"
	mourning = {
		position = position,
		wing = wing,
		endsAt = os.clock() + (o.duration or cfg.mournTime),
		graceUntil = os.clock() + (o.grace or 0),
		key = o.key,
	}
	mournedWings[wing] = true
	local spot = floorBelow(position + Vector3.new(-2.5, 0, 2.5))
	show(faceTowards(spot, position), "kneel")
	if o.noteId then
		Reading.reveal(o.noteId)
	end
	Say.near(position, 140, "[Soft weeping, somewhere close]", 4, "sound")
	if not taughtMourning then
		taughtMourning = true
		task.delay(3, function()
			Say.all("She hasn't noticed you. Crouch to get close, and keep your torch off her face.", 8, "hint")
		end)
	end
	return true
end

local function disturb(player: Player?)
	local m = mourning
	if not m then
		return
	end
	local at = model:GetPivot()
	endMourning(true)
	local root = player and Crew.root(player)
	if player and root and Banshee.canKeen(m.wing) then
		local standing = faceTowards(floorBelow(at.Position + Vector3.new(0, 2.4, 0)), root.Position)
		Say.to(player, "You disturbed her.", 3, "story")
		Banshee.keen(m.wing, { target = player, at = standing })
	else
		Say.near(m.position, 80, "[A shriek, and she's gone]", 3, "sound")
		hide(0.4)
	end
end

function Banshee.distantNow()
	local quiet: { string } = {}
	for _, wing in KEEN_WINGS do
		if #Crew.playersInWing(wing, true) == 0 then
			table.insert(quiet, wing)
		end
	end
	local wing = if #quiet > 0 then quiet[math.random(1, #quiet)] else KEEN_WINGS[math.random(1, #KEEN_WINGS)]
	local markers = Map.markers("BansheeKeen_" .. wing .. "_")
	if #markers > 0 then
		local emitter = Instance.new("Part")
		emitter.Anchored = true
		emitter.CanCollide = false
		emitter.CanQuery = false
		emitter.Transparency = 1
		emitter.Size = Vector3.one
		emitter.Position = markers[math.random(1, #markers)].Position + Vector3.new(0, 8, 0)
		emitter.Parent = Map.interact("Glows")
		Audio.play("keenDistant", emitter, 0.6, 500)
		task.delay(12, function()
			emitter:Destroy()
		end)
	end
	for _, player in Players:GetPlayers() do
		local root = Crew.root(player)
		if not root or Map.wingAt(root.Position) ~= wing then
			Say.to(player, "[Keening, far off in the house]", 4, "sound")
		end
	end
end

function Banshee.enableDistant()
	if not distantEnabled then
		distantEnabled = true
		nextDistantAt = os.clock() + cfg.distantMin + math.random() * (cfg.distantMax - cfg.distantMin)
	end
end

function Banshee.setNatural(on: boolean)
	naturalEnabled = on
	if on then
		scheduleNatural()
	else
		nextNaturalAt = math.huge
	end
end

function Banshee.isKeening(): boolean
	return state == "Keening" or state == "Taking"
end

function Banshee.isMourning(): boolean
	return state == "Mourning"
end

-- Checkpoint wipe: she goes, the storm comes back, nothing carries over.
function Banshee.reset()
	if keen then
		Rites.setActive(keen.wing, false)
		Net.event("Keen"):FireAllClients("end", { outcome = "reset" })
	end
	keen = nil
	mourning = nil
	stopKeenSound()
	Storm.silence(false)
	state = "Hidden"
	hide(0.1)
	lastKeenEnd = os.clock()
	for _, v in visits do
		v.occupied = false
		v.keened = false
	end
	if naturalEnabled then
		scheduleNatural()
	end
end

-- Story 1's last image: she keeps keening after you've crossed into the
-- rain. It wasn't about you.
function Banshee.ending(at: CFrame)
	keen = nil
	mourning = nil
	state = "Ending"
	naturalEnabled = false
	distantEnabled = false
	show(at, "stand")
	Storm.silence(true)
	stopKeenSound()
	local chest = model:FindFirstChild("Chest")
	if chest then
		keenSound = Audio.loop("keen", chest, 1)
	end
end

------------------------------------------------------------------ loop

function Banshee.setup()
	model = Rigs.banshee()
	model.Parent = ServerStorage

	Registry.died:Connect(function(entity, position: Vector3)
		if state == "Keening" and keen and (entity.wing == keen.wing or Map.wingAt(position) == keen.wing) then
			resolve("fulfilled")
			task.delay(2.5, function()
				Banshee.mourn(position, { key = entity.id, duration = 30, grace = cfg.aftermathGrace })
			end)
		elseif state == "Hidden" and distantEnabled and Config.story.mournDullahanDeaths and not mournedWings[entity.wing] then
			task.delay(3, function()
				Banshee.mourn(position, { key = entity.id, duration = 30, grace = cfg.aftermathGrace })
			end)
		end
	end)

	Rites.completed:Connect(function(_site, wing: string)
		if keen and keen.wing == wing then
			resolve("rite")
		end
	end)

	Noise.emitted:Connect(function(noise)
		if state == "Mourning" and mourning and noise.kind == "gunshot" and os.clock() >= mourning.graceUntil then
			if (noise.position - model:GetPivot().Position).Magnitude <= cfg.disturbShotRadius then
				disturb(noise.source)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		if keen and keen.target == player then
			local others = Crew.playersInWing(keen.wing, true)
			if #others > 0 then
				keen.target = others[1]
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = os.clock()

			for wing, v in visits do
				local occupied = #Crew.playersInWing(wing, true) > 0
				if occupied and not v.occupied then
					v.keened = false
				end
				v.occupied = occupied
			end

			if state == "Mourning" and mourning then
				local face = model:FindFirstChild("Face") :: BasePart?
				local herPos = model:GetPivot().Position
				local disturber: Player? = nil
				local listening = now >= mourning.graceUntil
				for _, player in Crew.activePlayers() do
					local root = Crew.root(player)
					local radius = if player:GetAttribute("MoveMode") == "crouch" then cfg.disturbRadiusCrouched else cfg.disturbRadius
					if listening and root and (root.Position - herPos).Magnitude <= radius then
						disturber = player
						break
					end
				end
				if listening and not disturber and face then
					disturber = Light.beamOn(face.Position, cfg.disturbLightRange, { model })
				end
				if disturber then
					disturb(disturber)
				elseif now >= mourning.endsAt then
					endMourning(false)
				end
			elseif state == "Keening" and keen then
				local k = keen
				if #Crew.playersInWing(k.wing, true) == 0 then
					resolve("left")
				elseif now >= k.endsAt then
					task.spawn(take)
				elseif now - k.lastAgitate >= cfg.agitateEvery then
					k.lastAgitate = now
					local root = Crew.root(k.target)
					for _, e in Registry.activeInWing(k.wing) do
						e:agitate(if root then root.Position else e:position())
					end
				end
			elseif state == "Hidden" then
				if distantEnabled and now >= nextDistantAt then
					nextDistantAt = now + cfg.distantMin + math.random() * (cfg.distantMax - cfg.distantMin)
					Banshee.distantNow()
				end
				if naturalEnabled and now >= nextNaturalAt then
					local bestWing, bestCount = nil, 0
					for _, wing in KEEN_WINGS do
						local count = #Crew.playersInWing(wing)
						if count > bestCount and Banshee.canKeen(wing) then
							bestWing, bestCount = wing, count
						end
					end
					if bestWing and Banshee.keen(bestWing) then
						-- scheduled again when it resolves
						nextNaturalAt = math.huge
					else
						nextNaturalAt = now + 20
					end
				end
			end
		end
	end)
end

return Banshee
