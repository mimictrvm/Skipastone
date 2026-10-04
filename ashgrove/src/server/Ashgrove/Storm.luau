--[[
	Storm: the night's lighting, rain and lightning, and how they change.

	- Lightning is gameplay light. Flashes come at irregular intervals and
	  count as "lit" for Storm.flashWindow seconds (the Lamp-shy freezes).
	- The storm builds: each secured object raises the level. At
	  Config.storm.powerCutLevel the hall's work lamp fails and the hall
	  stops being a sanctuary.
	- When the Banshee keens, the storm goes silent: no rain, no lightning.
	  That silence is the warning.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Map = require(script.Parent.Map)
local Say = require(script.Parent.Say)

local Storm = {}

Storm.level = 0

local silenced = false
local flashUntil = 0
local rain: Sound? = nil

local function setupLighting()
	Lighting.ClockTime = 1
	Lighting.Brightness = 0.3
	Lighting.Ambient = Color3.fromRGB(10, 10, 14)
	Lighting.OutdoorAmbient = Color3.fromRGB(26, 30, 38)
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0.2
	Lighting.GlobalShadows = true
	Lighting.ExposureCompensation = -0.2
	Lighting.FogColor = Color3.fromRGB(20, 24, 30)
	Lighting.FogStart = 0
	Lighting.FogEnd = 260

	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") or child:IsA("Atmosphere") then
			child:Destroy()
		end
	end
	local sky = Instance.new("Sky")
	sky.StarCount = 0
	sky.CelestialBodiesShown = false
	sky.Parent = Lighting
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.42
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(40, 46, 56)
	atmosphere.Decay = Color3.fromRGB(20, 22, 28)
	atmosphere.Glare = 0
	atmosphere.Haze = 2
	atmosphere.Parent = Lighting
end

function Storm.isFlashing(): boolean
	return os.clock() < flashUntil
end

function Storm.isSilenced(): boolean
	return silenced
end

local function flash()
	flashUntil = os.clock() + Config.storm.flashWindow
	Net.event("Lightning"):FireAllClients(1)
	task.delay(1 + math.random() * 2.5, function()
		if silenced then
			return
		end
		Audio.play("thunder", SoundService, 0.7)
		Say.all("[Thunder]", 2, "sound")
	end)
end

function Storm.start()
	setupLighting()
	rain = Audio.loop("rain", SoundService, Config.storm.rainVolume[0])
	task.spawn(function()
		while true do
			local range = Config.storm.lightning[math.min(Storm.level, 3)]
			task.wait(range.min + math.random() * (range.max - range.min))
			if not silenced then
				flash()
			end
		end
	end)
end

function Storm.silence(on: boolean)
	silenced = on
	if rain then
		local volume = if on then 0 else Config.storm.rainVolume[math.min(Storm.level, 3)]
		TweenService:Create(rain, TweenInfo.new(if on then 1.5 else 4), { Volume = volume }):Play()
	end
end

-- Turns off every lamp in a power group. Zones powered by that group stop
-- being sanctuaries.
function Storm.cutPower(group: string)
	for _, lamp in Map.interact("Lamps"):GetChildren() do
		if lamp:GetAttribute("PowerGroup") == group then
			lamp:SetAttribute("Powered", false)
			for _, light in lamp:GetDescendants() do
				if light:IsA("Light") then
					light.Enabled = false
				end
			end
			if lamp:IsA("BasePart") then
				lamp.Material = Enum.Material.SmoothPlastic
				lamp.Color = Color3.fromRGB(40, 36, 30)
			end
		end
	end
	for _, zonePart in Map.zonesWithAttribute("PoweredBy", group) do
		zonePart:SetAttribute("Sanctuary", false)
	end
end

function Storm.escalate()
	Storm.level += 1
	if rain and not silenced then
		TweenService:Create(rain, TweenInfo.new(6), { Volume = Config.storm.rainVolume[math.min(Storm.level, 3)] }):Play()
	end
	Say.all("[The storm gets worse]", 3, "sound")
	if Storm.level == Config.storm.powerCutLevel then
		Storm.cutPower("Hall")
		Say.all("The work lamp in the hall gutters out. The hall isn't safe any more.", 6, "story")
	end
end

return Storm
