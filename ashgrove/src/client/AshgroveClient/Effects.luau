--[[
	Effects: what the server announces, drawn locally. Lightning, the
	keen's cold grade, rain around you when you're outdoors, and the
	spectator camera for a player the Banshee has taken.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Net = require(Shared:WaitForChild("Net"))

local player = Players.LocalPlayer

local Effects = {}

local grade: ColorCorrectionEffect
local rain: ParticleEmitter
local keening = false
local flashing = false
local spectating = false
local spectateIndex = 0

local function lightning()
	if flashing then
		return
	end
	flashing = true
	local savedAmbient = Lighting.Ambient
	local savedOutdoor = Lighting.OutdoorAmbient
	local savedBrightness = Lighting.Brightness
	local function on()
		Lighting.Ambient = Color3.fromRGB(150, 160, 180)
		Lighting.OutdoorAmbient = Color3.fromRGB(190, 200, 220)
		Lighting.Brightness = 3
	end
	local function off()
		Lighting.Ambient = savedAmbient
		Lighting.OutdoorAmbient = savedOutdoor
		Lighting.Brightness = savedBrightness
	end
	on()
	task.wait(0.06)
	off()
	task.wait(0.09)
	on()
	task.wait(0.05)
	off()
	flashing = false
end

-- Rain falls around the camera when there's open sky above it. It stops
-- while she keens, with the storm.
local function startRain()
	local cloud = Instance.new("Part")
	cloud.Name = "AshgroveRain"
	cloud.Anchored = true
	cloud.CanCollide = false
	cloud.CanQuery = false
	cloud.CanTouch = false
	cloud.Transparency = 1
	cloud.Size = Vector3.new(70, 1, 70)
	rain = Instance.new("ParticleEmitter")
	rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Rate = 700
	rain.Lifetime = NumberRange.new(0.5, 0.7)
	rain.Speed = NumberRange.new(90, 110)
	rain.Size = NumberSequence.new(0.12)
	rain.Squash = NumberSequence.new(3)
	rain.Transparency = NumberSequence.new(0.45)
	rain.Color = ColorSequence.new(Color3.fromRGB(170, 185, 200))
	rain.LightInfluence = 1
	rain.Parent = cloud
	cloud.Parent = workspace.CurrentCamera

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	task.spawn(function()
		while true do
			task.wait(0.3)
			local camera = workspace.CurrentCamera
			if cloud.Parent ~= camera then
				cloud.Parent = camera
			end
			local at = camera.CFrame.Position
			cloud.CFrame = CFrame.new(at + Vector3.new(0, 35, 0))
			local character = player.Character
			params.FilterDescendantsInstances = if character then { character, cloud } else { cloud }
			local roof = workspace:Raycast(at, Vector3.new(0, 120, 0), params)
			rain.Enabled = roof == nil and not keening
		end
	end)
end

local function keen(state: string)
	keening = state == "start"
	local goal = if state == "start"
		then { TintColor = Color3.fromRGB(196, 214, 214), Saturation = -0.55, Brightness = -0.06, Contrast = 0.12 }
		else { TintColor = Color3.new(1, 1, 1), Saturation = 0, Brightness = 0, Contrast = 0 }
	TweenService:Create(grade, TweenInfo.new(if state == "start" then 1.5 else 3), goal):Play()
end

local function others(): { Player }
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and other.Character and not other:GetAttribute("Taken") then
			table.insert(list, other)
		end
	end
	return list
end

local function watchNext()
	local list = others()
	if #list == 0 then
		return
	end
	spectateIndex = spectateIndex % #list + 1
	local character = list[spectateIndex].Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		workspace.CurrentCamera.CameraSubject = humanoid
	end
end

local function spectate(on: boolean)
	spectating = on
	if on then
		watchNext()
	else
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			workspace.CurrentCamera.CameraSubject = humanoid
		end
	end
end

function Effects.start(hud)
	grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "AshgroveKeenGrade"
	grade.Parent = Lighting
	startRain()

	Net.event("Lightning").OnClientEvent:Connect(function()
		task.spawn(lightning)
	end)
	Net.event("Keen").OnClientEvent:Connect(function(state: string, info)
		keen(state)
		hud.keen(state, info or {})
	end)
	Net.event("Spectate").OnClientEvent:Connect(spectate)

	UserInputService.InputBegan:Connect(function(input, processed)
		if spectating and not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
			watchNext()
		end
	end)
end

return Effects
