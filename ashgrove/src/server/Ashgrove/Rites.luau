--[[
	Rites: the wake custom that answers a keen.

	A rite site is a Model under Interact/Rites with a Wing attribute and
	three step parts (RiteStep = "clock" | "mirror" | "window"). Its prompts
	only work while the Banshee is keening in that wing. Each step is a
	short committed action; when all three are done, Rites.completed fires
	and the Banshee is answered.

	Each site keeps the custom once. The room stays changed afterwards
	(the clock stopped, the mirror covered, the window open).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local Signal = require(Shared:WaitForChild("Signal"))

local Crew = require(script.Parent.Crew)
local Map = require(script.Parent.Map)
local Say = require(script.Parent.Say)

local Rites = {}

Rites.completed = Signal.new() -- (siteName, wing, player)

local STEP_TEXT = {
	clock = { action = "Stop the clock", done = "The clock stops." },
	mirror = { action = "Cover the mirror", done = "The glass is covered." },
	window = { action = "Open the window", done = "The window is open." },
}

type Site = {
	model: Model,
	wing: string,
	used: boolean,
	steps: { [BasePart]: boolean },
}

local sites: { Site } = {}

local function applyStep(part: BasePart, step: string)
	if step == "mirror" then
		local cloth = part:FindFirstChild("Cloth")
		if cloth and cloth:IsA("BasePart") then
			cloth.Transparency = 0
		end
	elseif step == "window" then
		part.Transparency = 0.95
		part.CanCollide = false
	elseif step == "clock" then
		part:SetAttribute("Stopped", true)
	end
end

local function siteDone(site: Site): boolean
	for _, isDone in site.steps do
		if not isDone then
			return false
		end
	end
	return true
end

function Rites.hasUnusedSite(wing: string): boolean
	for _, site in sites do
		if site.wing == wing and not site.used then
			return true
		end
	end
	return false
end

-- Turns the prompts on (during a keen in that wing) or off.
function Rites.setActive(wing: string, on: boolean)
	for _, site in sites do
		if site.wing == wing then
			for part, isDone in site.steps do
				local prompt = part:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Enabled = on and not site.used and not isDone
				end
			end
		end
	end
end

function Rites.setup()
	for _, model in Map.interact("Rites"):GetChildren() do
		if model:IsA("Model") then
			local site: Site = {
				model = model,
				wing = model:GetAttribute("Wing") or "",
				used = false,
				steps = {},
			}
			table.insert(sites, site)
			for _, part in model:GetChildren() do
				local step = part:GetAttribute("RiteStep")
				if part:IsA("BasePart") and step and STEP_TEXT[step] then
					site.steps[part] = false
					local prompt = Instance.new("ProximityPrompt")
					prompt.ActionText = STEP_TEXT[step].action
					prompt.ObjectText = "The wake custom"
					prompt.HoldDuration = 0.2
					prompt.MaxActivationDistance = 8
					prompt.RequiresLineOfSight = false
					prompt.Enabled = false
					prompt.Parent = part
					prompt.Triggered:Connect(function(player)
						if site.used or site.steps[part] then
							return
						end
						Crew.commit(player, Config.commit.rite, STEP_TEXT[step].action, function()
							if site.used or site.steps[part] then
								return
							end
							site.steps[part] = true
							prompt.Enabled = false
							applyStep(part, step)
							Audio.play("riteStep", part, 0.6)
							Say.near(part.Position, 40, STEP_TEXT[step].done, 3, "story")
							if siteDone(site) then
								site.used = true
								Rites.completed:Fire(model.Name, site.wing, player)
							end
						end)
					end)
				end
			end
		end
	end
end

return Rites
