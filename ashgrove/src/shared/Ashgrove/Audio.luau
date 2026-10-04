--[[
	Plays a sound from Config.sounds by key. Empty ids are skipped, so
	every call is safe before audio has been picked.

	Parent the sound to a part or attachment for 3D sound, or to
	SoundService for a flat one. On the server, a sound played in the
	workspace is heard by everyone.
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Config"))

local Audio = {}

function Audio.id(key: string): string
	return (Config.sounds :: any)[key] or ""
end

function Audio.play(key: string, parent: Instance, volume: number?, maxDistance: number?): Sound?
	local id = Audio.id(key)
	if id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = id
	sound.Volume = volume or 0.6
	sound.RollOffMaxDistance = maxDistance or 120
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 30)
	return sound
end

-- Looping sound that stays until destroyed.
function Audio.loop(key: string, parent: Instance, volume: number?): Sound?
	local id = Audio.id(key)
	if id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = id
	sound.Volume = volume or 0.5
	sound.Looped = true
	sound.Parent = parent
	sound:Play()
	return sound
end

return Audio
