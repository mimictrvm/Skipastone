--[[
	Offline check of the greybox, run with Lune (https://lune-org.github.io):

	    lune run tools/check_greybox.luau

	Builds the house with Greybox.luau outside Studio, then checks what the
	gameplay relies on: every marker the code looks up exists and sits in
	the right wing, nothing important is buried inside solid geometry, and
	the main walking routes and the gallery sight line are clear.

	It can't test physics, pathfinding or play; that needs Studio.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local game = roblox.Instance.new("DataModel")
local workspace = game:GetService("Workspace")

local env: { [string]: any } = {
	workspace = workspace,
	game = game,
	math = math,
	table = table,
	string = string,
	typeof = typeof,
	type = type,
	pairs = pairs,
	ipairs = ipairs,
	next = next,
	print = print,
	warn = print,
	error = error,
	assert = assert,
	tostring = tostring,
	tonumber = tonumber,
	setmetatable = setmetatable,
	getmetatable = getmetatable,
	select = select,
}
for key, value in roblox :: any do
	env[key] = value
end

local source = fs.readFile("src/server/Ashgrove/Greybox.luau")
local Greybox = luau.load(source, { debugName = "Greybox", environment = env })()
local house = Greybox.build()

local Vector3 = roblox.Vector3
local failures = 0
local function fail(message: string)
	failures += 1
	print("FAIL  " .. message)
end

------------------------------------------------------------------ helpers

local function inside(p, position, epsilon: number?): boolean
	local e = epsilon or 0
	local rel = p.CFrame:PointToObjectSpace(position)
	local half = p.Size / 2
	return math.abs(rel.X) < half.X - e and math.abs(rel.Y) < half.Y - e and math.abs(rel.Z) < half.Z - e
end

local solids = {}
for _, p in house.Geometry:GetDescendants() do
	if p:IsA("BasePart") and p.CanCollide then
		table.insert(solids, p)
	end
end
-- Locked doors count as solid only when we say so.
local function solidAt(position, epsilon: number?, extra: { any }?): any
	for _, p in solids do
		if inside(p, position, epsilon) then
			return p
		end
	end
	for _, p in extra or {} do
		if inside(p, position, epsilon) then
			return p
		end
	end
	return nil
end

local zones = {}
for _, z in house.Zones:GetChildren() do
	table.insert(zones, z)
end
table.sort(zones, function(a, b)
	return (a:GetAttribute("Priority") or 0) > (b:GetAttribute("Priority") or 0)
end)
local function wingAt(position): string?
	for _, z in zones do
		if inside(z, position) then
			return z:GetAttribute("Wing")
		end
	end
	return nil
end

local function marker(name: string)
	local m = house.Markers:FindFirstChild(name)
	if not m then
		fail("missing marker " .. name)
	end
	return m
end

local function markers(prefix: string)
	local out = {}
	for _, m in house.Markers:GetChildren() do
		if string.sub(m.Name, 1, #prefix) == prefix then
			table.insert(out, m)
		end
	end
	return out
end

-- A standing player's body: feet to head above a floor point.
local function bodyClear(position, label: string)
	for _, dy in { 0.6, 2.5, 4.8 } do
		local hit = solidAt(position + Vector3.new(0, dy, 0), 0.05)
		if hit then
			fail(`{label}: body at {position} overlaps {hit.Name}`)
			return
		end
	end
end

local function segmentClear(a, b, label: string, step: number?)
	local offset = b - a
	local n = math.max(1, math.ceil(offset.Magnitude / (step or 0.5)))
	for i = 0, n do
		local point = a + offset * (i / n)
		local hit = solidAt(point, 0.05)
		if hit then
			fail(`{label}: blocked at {point} by {hit.Name}`)
			return
		end
	end
end

------------------------------------------------------------------ checks

-- Every marker the code asks for by name, and the wing it must be in.
local expected = {
	Spawn_Van = "Van",
	Spawn_HallCamp = "Hall",
	Spawn_Stairwell = "ServantsWing",
	Dullahan_Spawn = "Gallery",
	Lampshy_Spawn = "ServantsWing",
	Body_Gallery = "Gallery",
	Body_Kitchen = "ServantsWing",
}
for name, wing in expected do
	local m = marker(name)
	if m and wingAt(m.CFrame.Position) ~= wing then
		fail(`{name} is in {wingAt(m.CFrame.Position)}, expected {wing}`)
	end
end
for prefix, wing in { Dullahan_Route_ = "Gallery", Lampshy_Route_ = "ServantsWing" } do
	local list = markers(prefix)
	if #list < 2 then
		fail("too few " .. prefix .. " markers")
	end
	for _, m in list do
		if wingAt(m.CFrame.Position) ~= wing then
			fail(`{m.Name} is in {wingAt(m.CFrame.Position)}, expected {wing}`)
		end
	end
end
for _, wing in { "Gallery", "ServantsWing", "Vault" } do
	local list = markers("BansheeKeen_" .. wing .. "_")
	if #list == 0 then
		fail("no BansheeKeen markers for " .. wing)
	end
	for _, m in list do
		if wingAt(m.CFrame.Position + Vector3.new(0, 1, 0)) ~= wing then
			fail(`{m.Name} is in {wingAt(m.CFrame.Position)}, expected {wing}`)
		end
		bodyClear(m.CFrame.Position, m.Name)
	end
end

-- Spawns: a player has to fit.
for _, name in { "Spawn_Van", "Spawn_HallCamp", "Spawn_Stairwell" } do
	local m = marker(name)
	if m then
		bodyClear(m.CFrame.Position - Vector3.new(0, 3, 0), name)
	end
end
-- Entity spawns: centre of the body clear.
for _, name in { "Dullahan_Spawn", "Lampshy_Spawn" } do
	local m = marker(name)
	if m and solidAt(m.CFrame.Position, 0.05) then
		fail(name .. " is inside geometry")
	end
end

-- Interactives must not be buried.
for _, folderName in { "Notes", "Pickups", "Objects" } do
	for _, p in house.Interact[folderName]:GetChildren() do
		local hit = solidAt(p.CFrame.Position, 0.02)
		if hit then
			fail(`{folderName}/{p.Name} at {p.CFrame.Position} is inside {hit.Name}`)
		end
	end
end

-- The rooms the story names exist as zones.
for _, room in { "Hall", "Gallery", "Corridor", "Kitchen", "Scullery", "Housekeeper", "ServantsHall", "Vault", "Van" } do
	if not house.Zones:FindFirstChild(room) then
		fail("missing zone " .. room)
	end
end

-- Walking routes, at waist height (doors open).
local routes = {
	{ "drive to front door", Vector3.new(-124, 2.5, 0), Vector3.new(-50, 2.5, 0) },
	{ "hall to gallery", Vector3.new(-20, 2.5, -19), Vector3.new(5, 2.5, -19) },
	{ "hall to servants' corridor", Vector3.new(-20, 2.5, 11), Vector3.new(5, 2.5, 11) },
	{ "corridor length", Vector3.new(-8, 2.5, 11), Vector3.new(108, 2.5, 11) },
	{ "corridor to kitchen", Vector3.new(10, 2.5, 11), Vector3.new(10, 2.5, 17) },
	{ "corridor to scullery", Vector3.new(45, 2.5, 11), Vector3.new(45, 2.5, 18) },
	{ "corridor to housekeeper", Vector3.new(72, 2.5, 11), Vector3.new(72, 2.5, 20) },
	{ "corridor to servants' hall", Vector3.new(97, 2.5, 11), Vector3.new(97, 2.5, 20) },
	{ "scullery to stair head", Vector3.new(33, 2.5, 18), Vector3.new(33, 2.5, 27) },
	{ "vault floor, stair foot to box", Vector3.new(60, -13.5, 27), Vector3.new(60, -13.5, -4) },
}
for _, r in routes do
	segmentClear(r[2], r[3], r[1])
end

-- The cellar stairs: a body standing on the ramp the whole way down.
for i = 0, 20 do
	local t = i / 20
	local floorPoint = Vector3.new(36.5 + 21 * t, -16 * (0.5 / 22 + 21 * t / 22) + 0.05, 27)
	for _, dy in { 1, 3, 5 } do
		local hit = solidAt(floorPoint + Vector3.new(0, dy, 0), 0.05)
		if hit and hit.Name ~= "CellarStairs" then
			fail(`cellar stairs: head room blocked at {floorPoint} by {hit.Name}`)
			break
		end
	end
end

-- The gallery's long sight line, at eye height.
segmentClear(Vector3.new(-8, 5, -19), Vector3.new(99, 5, -19), "gallery sight line")

-- Rite sites each have three steps.
for _, site in house.Interact.Rites:GetChildren() do
	local steps = 0
	for _, p in site:GetChildren() do
		if p:GetAttribute("RiteStep") then
			steps += 1
		end
	end
	if steps ~= 3 then
		fail(`{site.Name} has {steps} rite steps`)
	end
end

local count = #house:GetDescendants()
print(`greybox: {count} instances, {#solids} solid parts, {#zones} zones`)
if failures > 0 then
	print(`{failures} problem(s)`)
	error("greybox check failed")
end
print("greybox check passed")
