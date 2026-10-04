--[[
	Aim: the pistol on the client. Sway, the crosshair, shooting, and the
	player's own torch.

	"Hard to aim in a hurry": the aim wanders inside a radius that's wide
	while you move, wider when you sprint, and closes in over
	Config.pistol.sway.settleTime once you stand still. Each shot kicks it
	open again; holding your own torch widens it. The dot shows where the
	shot will actually go and the ring shows the radius.

	The server decides ammo and hits; this only reports the swayed aim.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local player = Players.LocalPlayer
local sway = Config.pistol.sway

local Aim = {}

local radius = sway.minDegrees
local kick = 0
local stillTime = 10
local lastShot = 0
local seedA = math.random() * 100
local seedB = math.random() * 100 + 200
local direction = Vector3.new(0, 0, -1)

local torch: Part
local torchLight: SpotLight

local function equipped(): boolean
	local character = player.Character
	local tool = character and character:FindFirstChild("Pistol")
	return tool ~= nil and tool:IsA("Tool")
end

local function canShoot(hud): boolean
	return equipped()
		and not hud.isNoteOpen()
		and not player:GetAttribute("Downed")
		and not player:GetAttribute("Taken")
		and not player:GetAttribute("Reloading")
		and player:GetAttribute("CommitLabel") == nil
end

local function step(hud, dt: number)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?

	local speed = 0
	if root then
		local v = root.AssemblyLinearVelocity
		speed = Vector3.new(v.X, 0, v.Z).Magnitude
	end
	local moving = speed > 1
	local sprinting = moving and player:GetAttribute("MoveMode") == "sprint" and speed > Config.player.walkSpeed + 2
	stillTime = if moving then 0 else stillTime + dt

	local target
	if sprinting then
		target = sway.sprintingDegrees
	elseif moving then
		target = sway.movingDegrees
	else
		local settle = math.clamp(stillTime / sway.settleTime, 0, 1)
		target = sway.movingDegrees + (sway.minDegrees - sway.movingDegrees) * settle
	end
	if player:GetAttribute("LightOn") then
		target *= sway.flashlightMultiplier
	end
	local rate = if target > radius then 8 else 3
	radius += (target - radius) * math.min(1, dt * rate)
	kick = math.max(0, kick - dt * sway.kickDegrees * 1.5)
	local effective = radius + kick

	local t = os.clock() * sway.wanderSpeed
	local yaw = math.rad(math.clamp(math.noise(t, seedA) * 2, -1, 1) * effective)
	local pitch = math.rad(math.clamp(math.noise(t, seedB) * 2, -1, 1) * effective)
	direction = (camera.CFrame * CFrame.Angles(pitch, yaw, 0)).LookVector

	local viewport = camera.ViewportSize
	local screen = camera:WorldToViewportPoint(camera.CFrame.Position + direction * 50)
	local pixelsPerRadian = (viewport.Y / 2) / math.tan(math.rad(camera.FieldOfView / 2))
	hud.setCrosshair(Vector2.new(screen.X, screen.Y), math.tan(math.rad(effective)) * pixelsPerRadian, equipped() and not player:GetAttribute("Taken"))

	-- Own torch: drawn locally so it follows the camera without lag. The
	-- server's copy on our head (which everyone else sees) is hidden here.
	torch.CFrame = camera.CFrame * CFrame.new(0.4, -0.5, 0)
	torchLight.Enabled = player:GetAttribute("LightOn") == true
	local head = character and character:FindFirstChild("Head")
	local attachment = head and head:FindFirstChild("AshFlashlight")
	local serverLight = attachment and attachment:FindFirstChild("AshFlashlight")
	if serverLight and serverLight:IsA("SpotLight") then
		serverLight.Enabled = false
	end
end

local function fire(hud)
	if not canShoot(hud) then
		return
	end
	local now = os.clock()
	if now - lastShot < Config.pistol.fireInterval then
		return
	end
	lastShot = now
	if (player:GetAttribute("Ammo") or 0) > 0 then
		kick += sway.kickDegrees
	end
	-- An empty gun still reports, so the server can play the dry click.
	Net.event("Fire"):FireServer(workspace.CurrentCamera.CFrame.Position, direction)
end

function Aim.start(hud)
	torch = Instance.new("Part")
	torch.Name = "AshLocalTorch"
	torch.Anchored = true
	torch.CanCollide = false
	torch.CanQuery = false
	torch.CanTouch = false
	torch.Transparency = 1
	torch.Size = Vector3.one * 0.2
	torchLight = Instance.new("SpotLight")
	torchLight.Angle = Config.flashlight.angle
	torchLight.Range = Config.flashlight.range
	torchLight.Brightness = Config.flashlight.brightness
	torchLight.Color = Color3.fromRGB(255, 240, 220)
	torchLight.Shadows = true
	torchLight.Face = Enum.NormalId.Front
	torchLight.Enabled = false
	torchLight.Parent = torch
	torch.Parent = workspace.CurrentCamera

	RunService:BindToRenderStep("AshgroveAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
		step(hud, dt)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			fire(hud)
		end
	end)

	-- Where we're looking, for the server's copy of the torch beam.
	task.spawn(function()
		local aimRemote = Net.unreliable("Aim")
		while true do
			task.wait(0.1)
			aimRemote:FireServer(workspace.CurrentCamera.CFrame.LookVector)
		end
	end)
end

return Aim
