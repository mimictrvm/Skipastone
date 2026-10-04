--[[
	Controls: keyboard input. Movement modes go to the server, which sets
	speed (and the noise you make). PC keyboard and mouse only for now.

	  Shift sprint   C crouch   F torch   R reload   G gold   Q close note
	  H help         E interact (Roblox prompts)
	  Studio only: F6 next chapter, F7 keen here, F8 refill
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local player = Players.LocalPlayer

local Controls = {}

local sprintHeld = false
local crouched = false
local sentMode = "walk"

local function sendMode()
	local mode = if sprintHeld then "sprint" elseif crouched then "crouch" else "walk"
	if mode ~= sentMode then
		sentMode = mode
		Net.event("Move"):FireServer(mode)
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local offset = if mode == "crouch" then Vector3.new(0, -1.6, 0) else Vector3.zero
		TweenService:Create(humanoid, TweenInfo.new(0.25), { CameraOffset = offset }):Play()
	end
end

function Controls.start(hud)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.RightShift then
			sprintHeld = true
			crouched = false
			sendMode()
		elseif key == Enum.KeyCode.C or key == Enum.KeyCode.LeftControl then
			crouched = not crouched
			sendMode()
		elseif key == Enum.KeyCode.F then
			Net.event("Flashlight"):FireServer(not player:GetAttribute("Flashlight"))
		elseif key == Enum.KeyCode.R then
			Net.event("Reload"):FireServer()
		elseif key == Enum.KeyCode.G then
			Net.event("Ward"):FireServer()
		elseif key == Enum.KeyCode.Q then
			hud.closeNote()
		elseif key == Enum.KeyCode.H then
			hud.toggleHelp()
		elseif RunService:IsStudio() and Config.debug.studioKeys then
			if key == Enum.KeyCode.F6 then
				Net.event("Debug"):FireServer("next")
			elseif key == Enum.KeyCode.F7 then
				Net.event("Debug"):FireServer("keen")
			elseif key == Enum.KeyCode.F8 then
				Net.event("Debug"):FireServer("refill")
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			sprintHeld = false
			sendMode()
		end
	end)

	local function onCharacter(character: Model)
		sprintHeld = false
		crouched = false
		sentMode = ""
		task.defer(sendMode)
		-- Your own "Revive" prompt is for your crewmates; hide it from you.
		local root = character:WaitForChild("HumanoidRootPart", 10)
		local revive = root and root:WaitForChild("Revive", 10)
		if revive and revive:IsA("ProximityPrompt") then
			revive.MaxActivationDistance = 0
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return Controls
