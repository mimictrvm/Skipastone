--[[
	Hooks: the only place the cutscene system touches the rest of the game.

	Every function here has a working default so scenes run in an empty
	place, but each one is meant to be pointed at the game's real system.
	Look for "WIRE UP" to find the ones that matter most.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Hooks = {}

-- WIRE UP: return the Index's 3D model for an item (it gets cloned, never moved).
-- Returning nil makes the scene build its own placeholder.
function Hooks.getItemModel(itemId: string): Model?
	local folder = ReplicatedStorage:FindFirstChild("ItemModels")
	local model = folder and folder:FindFirstChild(itemId)
	if model and model:IsA("Model") then
		return model
	end
	return nil
end

-- WIRE UP: stop the thrown stone at the landing point.
-- Return the stone part if you have it; scenes use it as the focal object.
function Hooks.freezeThrow(landing: Vector3): BasePart?
	return nil
end

-- WIRE UP: let the throw system clean up its stone once the scene has ended.
function Hooks.releaseThrow() end

-- Hides every ScreenGui except ours, remembering what was on.
local hiddenGuis: { ScreenGui } = {}
function Hooks.hideHud()
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		for _, gui in playerGui:GetChildren() do
			if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "CutsceneGui" then
				gui.Enabled = false
				table.insert(hiddenGuis, gui)
			end
		end
	end
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, false)
end

function Hooks.showHud()
	for _, gui in hiddenGuis do
		if gui.Parent then
			gui.Enabled = true
		end
	end
	table.clear(hiddenGuis)
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, true)
end

-- WIRE UP if the game's music isn't in a SoundService SoundGroup called "Music".
local savedMusicVolume: number? = nil
function Hooks.duckMusic(duration: number)
	local group = SoundService:FindFirstChild("Music")
	if group and group:IsA("SoundGroup") then
		savedMusicVolume = savedMusicVolume or group.Volume
		TweenService:Create(group, TweenInfo.new(duration), { Volume = 0 }):Play()
	end
end

function Hooks.restoreMusic(duration: number)
	local group = SoundService:FindFirstChild("Music")
	if group and group:IsA("SoundGroup") and savedMusicVolume then
		TweenService:Create(group, TweenInfo.new(duration), { Volume = savedMusicVolume }):Play()
	end
	savedMusicVolume = nil
end

local function getControls()
	local playerModule = Players.LocalPlayer:FindFirstChild("PlayerScripts")
		and Players.LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
	if not playerModule then
		return nil
	end
	local ok, module = pcall(require, playerModule)
	return ok and module:GetControls() or nil
end

function Hooks.lockControls()
	local controls = getControls()
	if controls then
		controls:Disable()
	end
end

function Hooks.unlockControls()
	local controls = getControls()
	if controls then
		controls:Enable()
	end
end

-- WIRE UP: open the normal loot reveal. Called once the scene has faded out.
function Hooks.showLootReveal(itemId: string) end

return Hooks
