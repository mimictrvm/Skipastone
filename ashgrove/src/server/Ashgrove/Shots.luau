--[[
	Shots: notices YOUR gun hitting Ashgrove's monsters, without needing to
	know how your gun works.

	Three sources, combined (Config.integration.hitDetection):
	  1. Click reports. Every left click with a tool out sends the camera's
	     ray here. That's the gunshot NOISE (always), and the aim used to
	     work out which body part was hit.
	  2. Damage. Monster Humanoids have huge health; when your gun damages
	     one, that's the confirmed hit. The part is found along the
	     shooter's last click ray (the Dullahan's head matters), and health
	     is topped back up straight away.
	  3. Hooks.reportHit(player, part, position) from your gun's own code.
	     Exact. Once it's been used, 1 and 2 stop counting hits.

	In "auto" mode, if three click rays hit a monster and none of them ever
	came with damage, your gun clearly doesn't damage Humanoids: Shots
	switches to "click" mode by itself and says so in the Output window.

	Click rays don't know about your wobble. For hits that match your
	bullets exactly, wire Hooks.reportHit.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Crew = require(script.Parent.Crew)
local Map = require(script.Parent.Map)
local Noise = require(script.Parent.Noise)
local Registry = require(script.Parent.Entities.Registry)

local cfg = Config.integration

local Shots = {}

type Click = { origin: Vector3, direction: Vector3, at: number }

local mode: string = cfg.hitDetection
local lastClick: { [Player]: Click } = {}
local lastNoise: { [Player]: number } = {}
local damageEverSeen = false
local hooksUsed = false
local undamagedClickHits = 0

local function rayParams(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { Map.interact("Glows") }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	return params
end

-- First thing along a ray; returns the entity if it's one of ours.
local function castFor(origin: Vector3, direction: Vector3): (any, BasePart?, Vector3?)
	local result = workspace:Raycast(origin, direction.Unit * cfg.clickRange, rayParams())
	if not result then
		return nil, nil, nil
	end
	return Registry.fromPart(result.Instance), result.Instance :: BasePart, result.Position
end

local function apply(entity, part: BasePart, shooter: Player, position: Vector3)
	if entity and entity.status == "active" then
		entity:shot(part, shooter, position)
	end
end

------------------------------------------------------------------ for Hooks

function Shots.reportShot(player: Player, origin: Vector3?)
	local now = os.clock()
	if now - (lastNoise[player] or 0) < 0.15 then
		return
	end
	lastNoise[player] = now
	local head = Crew.head(player)
	local at = origin or (if head then head.Position else nil)
	if at then
		Noise.emit(at, cfg.gunshotNoise, "gunshot", player)
	end
end

function Shots.reportHit(player: Player, part: BasePart, position: Vector3?)
	hooksUsed = true
	local entity = Registry.fromPart(part)
	if entity then
		apply(entity, part, player, position or part.Position)
	end
end

function Shots.reportReload(player: Player, seconds: number?)
	local duration = seconds or cfg.reloadTorchOff
	if duration > 0 then
		Crew.suppressFlashlight(player, duration)
	end
end

------------------------------------------------------------------ damage

-- Entity calls this when its Humanoid loses health.
function Shots.onDamaged(entity)
	damageEverSeen = true
	if hooksUsed or mode == "hooks" or mode == "click" then
		return
	end
	-- Who did it: the most recent click whose ray reaches this entity.
	local now = os.clock()
	local bestPlayer, bestPart, bestPos, bestAt = nil, nil, nil, -math.huge
	for player, click in lastClick do
		if now - click.at < 0.8 and click.at > bestAt then
			local hitEntity, part, position = castFor(click.origin, click.direction)
			if hitEntity == entity and part then
				bestPlayer, bestPart, bestPos, bestAt = player, part, position, click.at
			end
		end
	end
	if not bestPlayer then
		-- Shot from an angle the click ray can't explain (your wobble): blame
		-- the nearest player with a tool out, and call it a body hit.
		local root = entity.root
		local nearest, distance = nil, math.huge
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local r = Crew.root(player)
			if character and r and root and character:FindFirstChildOfClass("Tool") then
				local d = (r.Position - root.Position).Magnitude
				if d < distance then
					nearest, distance = player, d
				end
			end
		end
		if nearest and root then
			apply(entity, root, nearest, root.Position)
		end
		return
	end
	apply(entity, bestPart :: BasePart, bestPlayer, bestPos :: Vector3)
end

------------------------------------------------------------------ clicks

local function onClick(player: Player, origin: any, direction: any)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" or direction.Magnitude < 0.5 then
		return
	end
	local head = Crew.head(player)
	if not head or (origin - head.Position).Magnitude > 10 or not Crew.isActive(player) then
		return
	end
	local character = player.Character
	if not character or not character:FindFirstChildOfClass("Tool") then
		return
	end
	local now = os.clock()
	lastClick[player] = { origin = origin, direction = direction.Unit, at = now }
	Shots.reportShot(player, origin)

	if hooksUsed or mode == "hooks" or mode == "damage" then
		return
	end
	local entity, part, position = castFor(origin, direction)
	if not entity or not part then
		return
	end
	if mode == "click" then
		apply(entity, part, player, position :: Vector3)
		return
	end
	-- "auto": wait a moment to see whether the gun's own damage arrives.
	task.delay(0.5, function()
		if damageEverSeen or hooksUsed or mode ~= "auto" then
			return
		end
		undamagedClickHits += 1
		if undamagedClickHits >= 3 then
			mode = "click"
			warn("[Ashgrove] Your gun doesn't seem to damage Humanoids, so hits now come from click rays. For exact hits, call Hooks.reportHit from your gun (see ServerScriptService.Ashgrove.Hooks).")
			apply(entity, part, player, position :: Vector3)
		end
	end)
end

function Shots.start()
	Net.event("Shot").OnServerEvent:Connect(onClick)
	Net.event("Reload").OnServerEvent:Connect(function(player)
		local character = player.Character
		if character and character:FindFirstChildOfClass("Tool") then
			Shots.reportReload(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastClick[player] = nil
		lastNoise[player] = nil
	end)
end

return Shots
