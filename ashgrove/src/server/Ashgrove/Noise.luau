--[[
	Noise: anything an entity could hear. Footsteps, gunshots, a dropped
	head. Entities listen to Noise.emitted and decide for themselves.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Signal"))

export type Noise = {
	position: Vector3,
	radius: number,
	kind: string, -- "footsteps" | "gunshot" | "impact"
	source: Player?,
}

local Noise = {}

Noise.emitted = Signal.new()

function Noise.emit(position: Vector3, radius: number, kind: string, source: Player?)
	if radius <= 0 then
		return
	end
	Noise.emitted:Fire({ position = position, radius = radius, kind = kind, source = source } :: Noise)
end

return Noise
