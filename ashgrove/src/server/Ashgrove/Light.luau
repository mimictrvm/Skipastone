--[[
	Light: is this point lit? Used by entities whose rules depend on light
	(the Lamp-shy freezes in it) and by the Banshee (light on her face
	disturbs her mourning).

	Lit means any of: a lightning flash, a powered lamp or temporary glow in
	range, or a flashlight beam pointed at it with nothing in the way.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Config"))

local Crew = require(script.Parent.Crew)
local Map = require(script.Parent.Map)
local Storm = require(script.Parent.Storm)

local Light = {}

local function clearLine(from: Vector3, to: Vector3, ignore: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local offset = to - from
	local hit = workspace:Raycast(from, offset, params)
	-- Hitting something within the last 3 studs means we hit the target
	-- itself (or right next to it).
	return hit == nil or (hit.Position - to).Magnitude < 3
end

local function characters(): { Instance }
	local list = {}
	for _, player in game:GetService("Players"):GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	return list
end

-- Which player's flashlight is on this point, if any.
function Light.beamOn(point: Vector3, maxRange: number?, ignore: { Instance }?): Player?
	local range = maxRange or Config.flashlight.litRange
	local cosHalf = math.cos(math.rad(Config.flashlight.beamHalfAngle))
	for _, beam in Crew.flashlights() do
		local offset = point - beam.origin
		local distance = offset.Magnitude
		if distance <= range and distance > 0.01 and offset.Unit:Dot(beam.direction) >= cosHalf then
			local list = characters()
			if ignore then
				for _, inst in ignore do
					table.insert(list, inst)
				end
			end
			if clearLine(beam.origin, point, list) then
				return beam.player
			end
		end
	end
	return nil
end

function Light.isLit(point: Vector3, ignore: { Instance }?): boolean
	-- Lightning reaches everywhere with a window: not the cellar vault.
	if Storm.isFlashing() and Map.wingAt(point) ~= "Vault" then
		return true
	end
	for _, source in Map.lightSources() do
		if (source.Position - point).Magnitude <= (source:GetAttribute("LightRadius") :: number) then
			return true
		end
	end
	return Light.beamOn(point, nil, ignore) ~= nil
end

return Light
