--[[
	Torch: the player's own torch, drawn locally so it follows the camera
	without lag (the server's copy on your head, which everyone else sees,
	is hidden on your screen). Also reports to the server:
	  - where you're looking, ten times a second (the torch beam that
	    monsters react to)
	  - each left click with a tool out (your gun): monsters hear the shot,
	    and Shots uses the ray to tell which body part you hit.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local player = Players.LocalPlayer

local Torch = {}

function Torch.start()
	local torch = Instance.new("Part")
	torch.Name = "AshLocalTorch"
	torch.Anchored = true
	torch.CanCollide = false
	torch.CanQuery = false
	torch.CanTouch = false
	torch.Transparency = 1
	torch.Size = Vector3.one * 0.2
	local light = Instance.new("SpotLight")
	light.Angle = Config.flashlight.angle
	light.Range = Config.flashlight.range
	light.Brightness = Config.flashlight.brightness
	light.Color = Color3.fromRGB(255, 240, 220)
	light.Shadows = true
	light.Face = Enum.NormalId.Front
	light.Enabled = false
	light.Parent = torch
	torch.Parent = workspace.CurrentCamera

	RunService:BindToRenderStep("AshgroveTorch", Enum.RenderPriority.Camera.Value + 1, function()
		local camera = workspace.CurrentCamera
		if torch.Parent ~= camera then
			torch.Parent = camera
		end
		torch.CFrame = camera.CFrame * CFrame.new(0.4, -0.5, 0)
		light.Enabled = player:GetAttribute("LightOn") == true
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		local attachment = head and head:FindFirstChild("AshFlashlight")
		local serverLight = attachment and attachment:FindFirstChild("AshFlashlight")
		if serverLight and serverLight:IsA("SpotLight") then
			serverLight.Enabled = false
		end
	end)

	local lastClick = 0
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local character = player.Character
		if not character or not character:FindFirstChildOfClass("Tool") then
			return
		end
		local now = os.clock()
		if now - lastClick < 0.1 then
			return
		end
		lastClick = now
		local camera = workspace.CurrentCamera
		Net.event("Shot"):FireServer(camera.CFrame.Position, camera.CFrame.LookVector)
	end)

	task.spawn(function()
		local aimRemote = Net.unreliable("Aim")
		while true do
			task.wait(0.1)
			aimRemote:FireServer(workspace.CurrentCamera.CFrame.LookVector)
		end
	end)
end

return Torch
