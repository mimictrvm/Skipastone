--[[
	Registry: every killable entity in the game, by id, plus the signals
	other systems listen to.

	  died(entity, position, killer)   a manifestation was killed (banished).
	                                   The Banshee treats this as a death.
	  formed(entity)                   it re-formed at its object.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Signal"))

local Registry = {}

Registry.died = Signal.new()
Registry.formed = Signal.new()

local entities: { [string]: any } = {}
local order: { any } = {}

function Registry.add(entity: any)
	entities[entity.id] = entity
	table.insert(order, entity)
end

function Registry.get(id: string): any
	return entities[id]
end

function Registry.all(): { any }
	return order
end

-- The entity a part belongs to, if any (for bullets).
function Registry.fromPart(part: Instance): any
	local node: Instance? = part
	while node and node ~= workspace do
		local id = node:GetAttribute("EntityId")
		if id and node:IsA("Model") then
			return entities[id]
		end
		node = node.Parent
	end
	return nil
end

function Registry.activeInWing(wing: string): { any }
	local out = {}
	for _, e in order do
		if e.status == "active" and e.wing == wing then
			table.insert(out, e)
		end
	end
	return out
end

return Registry
