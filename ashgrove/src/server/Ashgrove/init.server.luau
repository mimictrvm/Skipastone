--[[
	Ashgrove House (server entry). Builds the greybox if the place has no
	"AshgroveHouse" model yet, sets up first-person play, and starts Story 1.

	Everything this script needs is its children. See ashgrove/README.md
	for where each piece goes in Studio.
]]

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Config"))

StarterPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
StarterPlayer.CameraMaxZoomDistance = 0.5
StarterPlayer.EnableMouseLockOption = false
StarterPlayer.CharacterWalkSpeed = Config.player.walkSpeed
StarterPlayer.CharacterUseJumpPower = true
StarterPlayer.CharacterJumpPower = Config.player.jumpPower
Players.RespawnTime = 3

-- The Baseplate template's floor (y -16..0) would fill the cellar vault,
-- and its spawn would drop players into the courtyard.
for _, name in { "Baseplate", "SpawnLocation" } do
	local leftover = workspace:FindFirstChild(name)
	if leftover and leftover:IsA("BasePart") then
		leftover:Destroy()
	end
end

if not workspace:FindFirstChild("AshgroveHouse") then
	require(script.Greybox).build()
end

require(script.Director).start()
