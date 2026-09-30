--[[
	Plays cutscenes the server asks for, and shows other players' finds.

	Studio only: preview any scene without catching anything.
	  Left Alt + 1..7          full scene
	  Left Alt + Shift + 1..7  3-second replay
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local Cutscenes = ReplicatedStorage:WaitForChild("Cutscenes")
local Config = require(Cutscenes:WaitForChild("Config"))
local Director = require(Cutscenes:WaitForChild("Director"))

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("CutsceneRemotes")
	remotes:WaitForChild("Play").OnClientEvent:Connect(function(itemId: string, opts)
		Director.play(itemId, opts)
	end)

	remotes:WaitForChild("Announce").OnClientEvent:Connect(function(finderName: string, itemName: string, oneIn: number?)
		local channels = TextChatService:FindFirstChild("TextChannels")
		local general = channels and channels:FindFirstChild("RBXGeneral")
		if general and general:IsA("TextChannel") then
			local odds = if oneIn then ` ({Director.formatOneIn(oneIn)})` else ""
			general:DisplaySystemMessage(`{finderName} just caught the {itemName}!{odds}`)
		end
	end)
end)

if RunService:IsStudio() then
	local order = { "PirateDoubloon", "KoiSpirit", "SirensLyre", "FallenStar", "Mothership", "FrostWyrm", "CrystalGolem" }
	local keys = {
		[Enum.KeyCode.One] = 1,
		[Enum.KeyCode.Two] = 2,
		[Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4,
		[Enum.KeyCode.Five] = 5,
		[Enum.KeyCode.Six] = 6,
		[Enum.KeyCode.Seven] = 7,
	}

	-- Lands the preview on the water (or ground) about 25 studs ahead.
	local function previewLanding(): Vector3
		local camera = workspace.CurrentCamera
		local flat = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
		flat = if flat.Magnitude > 1e-3 then flat.Unit else -Vector3.zAxis
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local base = if root then (root :: BasePart).Position else camera.CFrame.Position
		local ahead = base + flat * 25
		local params = RaycastParams.new()
		params.IgnoreWater = false
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character :: Instance }
		local hit = workspace:Raycast(ahead + Vector3.yAxis * 60, Vector3.yAxis * -200, params)
		return if hit then hit.Position else ahead - Vector3.yAxis * 3
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
			return
		end
		local index = keys[input.KeyCode]
		if not index or Director.isPlaying() then
			return
		end
		local itemId = order[index]
		if not Config.items[itemId] then
			return
		end
		task.spawn(Director.play, itemId, {
			full = not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift),
			landing = previewLanding(),
			oneIn = if itemId == "CrystalGolem" then 756000000 else nil,
		})
	end)
end
