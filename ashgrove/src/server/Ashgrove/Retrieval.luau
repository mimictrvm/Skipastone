--[[
	Retrieval: the objective grammar. Each story is a list of collection
	objects to secure where they're found.

	An object part has ObjectId, Label, Securable and (optionally)
	EntityId. Securing is a committed action of Config.commit.secure
	seconds, or secureWhileEntityActive if its entity is up and about:
	kill it first and the window opens. Securing removes the entity for
	the rest of the story and closes the object's warded crate.

	Non-securable objects (the sealed box) can only be inspected.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))
local Signal = require(Shared:WaitForChild("Signal"))

local Crew = require(script.Parent.Crew)
local Map = require(script.Parent.Map)
local Registry = require(script.Parent.Entities.Registry)
local Say = require(script.Parent.Say)

local Retrieval = {}

Retrieval.secured = Signal.new() -- (objectId, player)
Retrieval.inspected = Signal.new() -- (objectId, player)

local objects: { [string]: BasePart } = {}
local done: { [string]: boolean } = {}
local enabled: { [string]: boolean } = {}

function Retrieval.isDone(objectId: string): boolean
	return done[objectId] == true
end

function Retrieval.setEnabled(objectId: string, on: boolean)
	enabled[objectId] = on
	local p = objects[objectId]
	local prompt = p and p:FindFirstChildOfClass("ProximityPrompt")
	if prompt and not done[objectId] then
		prompt.Enabled = on
	end
end

local function closeCrate(objectId: string)
	for _, crate in Map.interact("Crates"):GetChildren() do
		if crate:GetAttribute("CrateFor") == objectId then
			local lid = crate:FindFirstChild("Lid")
			if lid and lid:IsA("BasePart") then
				lid.Transparency = 0
				lid.CanCollide = true
			end
		end
	end
end

local function secure(objectId: string, player: Player?)
	if done[objectId] then
		return
	end
	done[objectId] = true
	local p = objects[objectId]
	local prompt = p:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end
	TweenService:Create(p, TweenInfo.new(0.6), { Transparency = 1 }):Play()
	p.CanCollide = false
	p.CanQuery = false
	closeCrate(objectId)
	Audio.play("secure", p, 0.7)
	local entityId = p:GetAttribute("EntityId")
	local entity = entityId and Registry.get(entityId)
	if entity then
		entity:secure()
	end
	Say.all(`{p:GetAttribute("Label")} secured.`, 4, "story")
	Retrieval.secured:Fire(objectId, player)
end

-- Studio debug: secure an object as if someone had done it.
function Retrieval.forceSecure(objectId: string)
	if objects[objectId] then
		secure(objectId, nil)
	end
end

function Retrieval.setup()
	for _, p in Map.interact("Objects"):GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("ObjectId") then
			local objectId = p:GetAttribute("ObjectId") :: string
			objects[objectId] = p
			local securable = p:GetAttribute("Securable") == true
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = if securable then "Secure" else "Inspect"
			prompt.ObjectText = p:GetAttribute("Label") or objectId
			prompt.HoldDuration = 0.25
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Enabled = false
			prompt.Parent = p
			prompt.Triggered:Connect(function(player)
				if done[objectId] or not enabled[objectId] then
					return
				end
				if not securable then
					done[objectId] = true
					prompt.Enabled = false
					Retrieval.inspected:Fire(objectId, player)
					return
				end
				local entityId = p:GetAttribute("EntityId")
				local entity = entityId and Registry.get(entityId)
				local busy = entity ~= nil and entity.status == "active"
				local seconds = if busy then Config.commit.secureWhileEntityActive else Config.commit.secure
				if busy then
					Say.to(player, "It's still up. This will take longer.", 3, "hint")
				end
				Crew.commit(player, seconds, `Securing {prompt.ObjectText}`, function()
					secure(objectId, player)
				end)
			end)
		end
	end
end

return Retrieval
