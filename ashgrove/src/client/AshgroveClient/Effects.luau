--[[
	Effects: what the server announces, drawn locally. Gunshot tracers and
	muzzle flashes, lightning, the keen's cold grade, and the spectator
	camera for a player the Banshee has taken.
]]

local Debris = game:GetService("Debris")
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
local flashing = false
local spectating = false
local spectateIndex = 0

local function muzzleOf(shooter: Player): Attachment?
	local character = shooter.Character
	local tool = character and character:FindFirstChild("Pistol")
	local handle = tool and tool:FindFirstChild("Handle")
	local muzzle = handle and handle:FindFirstChild("Muzzle")
	return if muzzle and muzzle:IsA("Attachment") then muzzle else nil
end

local function shotFx(shooter: Player, origin: Vector3, hit: Vector3, kind: string)
	local muzzle = muzzleOf(shooter)
	local from = if muzzle then muzzle.WorldPosition else origin
	if shooter == player then
		-- Our own camera is the origin; start the tracer just ahead of it.
		from = origin + (hit - origin).Unit * 1.5 + Vector3.new(0, -0.3, 0)
	end
	local length = (hit - from).Magnitude
	if length > 0.5 then
		local tracer = Instance.new("Part")
		tracer.Anchored = true
		tracer.CanCollide = false
		tracer.CanQuery = false
		tracer.CanTouch = false
		tracer.Material = Enum.Material.Neon
		tracer.Color = Color3.fromRGB(255, 220, 170)
		tracer.Size = Vector3.new(0.05, 0.05, length)
		tracer.CFrame = CFrame.lookAt(from, hit) * CFrame.new(0, 0, -length / 2)
		tracer.Transparency = 0.3
		tracer.Parent = workspace.CurrentCamera
		TweenService:Create(tracer, TweenInfo.new(0.08), { Transparency = 1 }):Play()
		Debris:AddItem(tracer, 0.1)
	end
	if muzzle then
		local light = muzzle:FindFirstChild("MuzzleFlash")
		if light and light:IsA("PointLight") then
			light.Enabled = true
			task.delay(0.05, function()
				light.Enabled = false
			end)
		end
	end
	if kind ~= "none" then
		local spark = Instance.new("Part")
		spark.Anchored = true
		spark.CanCollide = false
		spark.CanQuery = false
		spark.CanTouch = false
		spark.Material = Enum.Material.Neon
		spark.Color = if kind == "entity" then Color3.fromRGB(200, 60, 50) else Color3.fromRGB(255, 210, 150)
		spark.Shape = Enum.PartType.Ball
		spark.Size = Vector3.one * 0.3
		spark.Position = hit
		spark.Parent = workspace.CurrentCamera
		TweenService:Create(spark, TweenInfo.new(0.15), { Transparency = 1, Size = Vector3.one * 0.05 }):Play()
		Debris:AddItem(spark, 0.2)
	end
end

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

local function keen(state: string)
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

	Net.event("ShotFx").OnClientEvent:Connect(shotFx)
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
