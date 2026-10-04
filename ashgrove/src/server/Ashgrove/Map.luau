--[[
	Map: what the gameplay knows about the house. Everything is looked up
	from workspace.AshgroveHouse by folder, name and attribute, so the
	greybox can be swapped for art without touching any system.

	Wings are the unit the Banshee and the entities care about:
	  Grounds, Van, Hall, Gallery, ServantsWing, Vault
	Rooms are finer, for the bell board and story triggers.
]]

local Debris = game:GetService("Debris")

local Map = {}

export type Zone = {
	name: string,
	wing: string,
	room: string,
	priority: number,
	part: BasePart,
}

local root: Model? = nil
local zones: { Zone } = {}

function Map.root(): Model
	if not root then
		local found = workspace:WaitForChild("AshgroveHouse") :: Model
		root = found
		for _, p in found:WaitForChild("Zones"):GetChildren() do
			if p:IsA("BasePart") then
				table.insert(zones, {
					name = p.Name,
					wing = p:GetAttribute("Wing") or p.Name,
					room = p:GetAttribute("Room") or p.Name,
					priority = p:GetAttribute("Priority") or 0,
					part = p,
				})
			end
		end
		table.sort(zones, function(a, b)
			return a.priority > b.priority
		end)
	end
	return root :: any
end

local function inside(p: BasePart, position: Vector3): boolean
	local rel = p.CFrame:PointToObjectSpace(position)
	local half = p.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y and math.abs(rel.Z) <= half.Z
end

function Map.zoneAt(position: Vector3): Zone?
	Map.root()
	for _, z in zones do
		if inside(z.part, position) then
			return z
		end
	end
	return nil
end

function Map.wingAt(position: Vector3): string?
	local z = Map.zoneAt(position)
	return z and z.wing
end

function Map.roomAt(position: Vector3): string?
	local z = Map.zoneAt(position)
	return z and z.room
end

-- Sanctuary is read live: the hall stops being one when its lamp fails.
function Map.isSanctuary(position: Vector3): boolean
	local z = Map.zoneAt(position)
	return z ~= nil and z.part:GetAttribute("Sanctuary") == true
end

function Map.isExterior(position: Vector3): boolean
	local z = Map.zoneAt(position)
	return z ~= nil and z.part:GetAttribute("Exterior") == true
end

-- Across a threshold: somewhere the Banshee's keen can't follow.
function Map.isThreshold(position: Vector3): boolean
	return Map.isSanctuary(position) or Map.isExterior(position)
end

function Map.zonesWithAttribute(name: string, value: any): { BasePart }
	Map.root()
	local out = {}
	for _, z in zones do
		if z.part:GetAttribute(name) == value then
			table.insert(out, z.part)
		end
	end
	return out
end

function Map.marker(name: string): BasePart
	local m = Map.root():WaitForChild("Markers"):FindFirstChild(name)
	assert(m and m:IsA("BasePart"), `AshgroveHouse is missing marker "{name}"`)
	return m
end

function Map.markers(prefix: string): { BasePart }
	local out = {}
	for _, m in Map.root():WaitForChild("Markers"):GetChildren() do
		if m:IsA("BasePart") and string.sub(m.Name, 1, #prefix) == prefix then
			table.insert(out, m)
		end
	end
	table.sort(out, function(a, b)
		return a.Name < b.Name
	end)
	return out
end

function Map.interact(name: string): Instance
	return Map.root():WaitForChild("Interact"):WaitForChild(name)
end

-- Everything that counts as "light" for entities that care: powered lamps
-- and temporary glows (a dropped head, a dead Lamp-shy).
function Map.lightSources(): { BasePart }
	local out = {}
	for _, folderName in { "Lamps", "Glows" } do
		for _, p in Map.interact(folderName):GetChildren() do
			if p:IsA("BasePart") and (p:GetAttribute("LightRadius") or 0) > 0 and p:GetAttribute("Powered") ~= false then
				table.insert(out, p)
			end
		end
	end
	return out
end

-- A temporary light source. `follow` keeps it on a moving part.
function Map.addGlow(position: Vector3, radius: number, seconds: number, colour: Color3, follow: BasePart?): BasePart
	local p = Instance.new("Part")
	p.Name = "Glow"
	p.Anchored = follow == nil
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one * 0.5
	p.Position = position
	p:SetAttribute("LightRadius", radius)
	local light = Instance.new("PointLight")
	light.Range = radius * 1.4
	light.Brightness = 1.2
	light.Color = colour
	light.Parent = p
	if follow then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = follow
		weld.Part1 = p
		p.Position = follow.Position
		weld.Parent = p
		p.Massless = true
	end
	p.Parent = Map.interact("Glows")
	Debris:AddItem(p, seconds)
	return p
end

-- Random point on the floor of a zone part (top of the floor at its bottom).
function Map.randomPointIn(zonePart: BasePart, height: number?): Vector3
	local half = zonePart.Size / 2
	local local_ = Vector3.new((math.random() * 2 - 1) * (half.X - 3), -half.Y + 1 + (height or 0), (math.random() * 2 - 1) * (half.Z - 3))
	return zonePart.CFrame:PointToWorldSpace(local_)
end

return Map
