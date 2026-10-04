--[[
	Gun (server): the pistol. Ammo, reloads and hits are decided here; the
	client only reports where it aimed (sway included) and draws effects.

	- Small magazine, slow reload (Config.pistol.reloadTime) that can't be
	  cancelled. The flashlight is forced off while reloading.
	- Gunshots are loud: a Noise every entity in range hears.
	- Can't shoot while down, taken, or committed to an action.

	Player attributes: Ammo, Reserve, Reloading, ReloadEnds.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Crew = require(script.Parent.Crew)
local Map = require(script.Parent.Map)
local Noise = require(script.Parent.Noise)
local Registry = require(script.Parent.Entities.Registry)

local cfg = Config.pistol

local Gun = {}

type GunState = {
	mag: number,
	reserve: number,
	reloading: boolean,
	reloadToken: {}?,
	lastShot: number,
	saved: { mag: number, reserve: number }?,
}

local states: { [Player]: GunState } = {}

local function publish(player: Player)
	local s = states[player]
	if s then
		player:SetAttribute("Ammo", s.mag)
		player:SetAttribute("Reserve", s.reserve)
		player:SetAttribute("Reloading", s.reloading)
	end
end

local function makeTool(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Pistol"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Pistol"
	tool.Grip = CFrame.new(0, -0.3, 0.2)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 0.9, 1.5)
	handle.Color = Color3.fromRGB(34, 34, 36)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.Position = Vector3.new(0, 0.25, -0.8)
	muzzle.Parent = handle
	local flash = Instance.new("PointLight")
	flash.Name = "MuzzleFlash"
	flash.Range = 14
	flash.Brightness = 4
	flash.Color = Color3.fromRGB(255, 200, 140)
	flash.Enabled = false
	flash.Parent = muzzle
	return tool
end

local function giveTool(player: Player, character: Model)
	local backpack = player:WaitForChild("Backpack")
	for _, container in { backpack, character } do
		for _, old in container:GetChildren() do
			if old.Name == "Pistol" and old:IsA("Tool") then
				old:Destroy()
			end
		end
	end
	local tool = makeTool()
	tool.Parent = backpack
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	task.defer(function()
		if tool.Parent == backpack then
			humanoid:EquipTool(tool)
		end
	end)
end

local function equipped(player: Player): Tool?
	local character = player.Character
	local tool = character and character:FindFirstChild("Pistol")
	return if tool and tool:IsA("Tool") then tool else nil
end

local function fire(player: Player, origin: any, direction: any)
	local s = states[player]
	if not s or typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end
	if direction.Magnitude < 0.5 or direction.Magnitude ~= direction.Magnitude then
		return
	end
	if not Crew.isActive(player) or Crew.isCommitting(player) or s.reloading then
		return
	end
	local now = os.clock()
	if now - s.lastShot < cfg.fireInterval * 0.9 then
		return
	end
	local tool = equipped(player)
	local head = Crew.head(player)
	if not tool or not head or (origin - head.Position).Magnitude > cfg.maxOriginOffset then
		return
	end
	if s.mag <= 0 then
		local handle = tool:FindFirstChild("Handle")
		if handle then
			Audio.play("dryFire", handle, 0.6)
		end
		return
	end
	s.lastShot = now
	s.mag -= 1
	publish(player)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { Map.interact("Glows") }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local dir = direction.Unit
	local result = workspace:Raycast(origin, dir * cfg.range, params)
	local hitPosition = if result then result.Position else origin + dir * cfg.range
	local kind = if result then "world" else "none"

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	if handle then
		Audio.play("gunshot", handle, 1, 300)
	end
	Noise.emit(origin, cfg.gunshotNoise, "gunshot", player)

	if result then
		local entity = Registry.fromPart(result.Instance)
		if entity then
			kind = "entity"
			entity:shot(result.Instance :: BasePart, player, result.Position)
		end
	end
	Net.event("ShotFx"):FireAllClients(player, origin, hitPosition, kind)
end

local function reload(player: Player)
	local s = states[player]
	if not s or s.reloading or s.mag >= cfg.magazine or s.reserve <= 0 then
		return
	end
	if not Crew.isActive(player) or Crew.isCommitting(player) or not equipped(player) then
		return
	end
	local token = {}
	s.reloading = true
	s.reloadToken = token
	player:SetAttribute("ReloadEnds", workspace:GetServerTimeNow() + cfg.reloadTime)
	publish(player)
	Crew.suppressFlashlight(player, cfg.reloadTime)
	local tool = equipped(player)
	local handle = tool and tool:FindFirstChild("Handle")
	if handle then
		Audio.play("reload", handle, 0.7)
	end
	task.delay(cfg.reloadTime, function()
		if s.reloadToken ~= token then
			return
		end
		local moved = math.min(cfg.magazine - s.mag, s.reserve)
		s.mag += moved
		s.reserve -= moved
		s.reloading = false
		s.reloadToken = nil
		publish(player)
	end)
end

-- Adds reserve ammo. Returns how many rounds were taken (0 if full).
function Gun.addAmmo(player: Player, amount: number): number
	local s = states[player]
	if not s then
		return 0
	end
	local taken = math.min(amount, cfg.maxReserve - s.reserve)
	if taken <= 0 then
		return 0
	end
	s.reserve += taken
	publish(player)
	return taken
end

function Gun.refill(player: Player)
	local s = states[player]
	if s then
		s.mag = cfg.magazine
		s.reserve = cfg.maxReserve
		publish(player)
	end
end

-- Checkpoints: remember ammo now; after a wipe, restore it (never less
-- than one full magazine).
function Gun.saveAll()
	for _, s in states do
		s.saved = { mag = s.mag, reserve = s.reserve }
	end
end

function Gun.restoreAll()
	for player, s in states do
		local saved = s.saved or { mag = cfg.magazine, reserve = cfg.startReserve }
		s.mag = math.max(saved.mag, cfg.magazine)
		s.reserve = saved.reserve
		s.reloading = false
		s.reloadToken = nil
		publish(player)
	end
end

-- Start before Crew, so the first characterReady is heard.
function Gun.start()
	local function onPlayer(player: Player)
		states[player] = {
			mag = cfg.magazine,
			reserve = cfg.startReserve,
			reloading = false,
			reloadToken = nil,
			lastShot = 0,
			saved = nil,
		}
		publish(player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		if not states[player] then
			onPlayer(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	Crew.characterReady:Connect(function(player: Player, character: Model)
		local s = states[player]
		if s then
			s.reloading = false
			s.reloadToken = nil
			publish(player)
		end
		giveTool(player, character)
	end)
	Net.event("Fire").OnServerEvent:Connect(fire)
	Net.event("Reload").OnServerEvent:Connect(reload)
end

return Gun
