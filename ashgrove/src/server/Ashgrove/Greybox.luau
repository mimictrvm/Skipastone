--[[
	Greybox: builds Story 1's Ashgrove House out of grey blocks, so the game
	is playable before any art exists. The art brief's assets replace these
	blocks one-for-one; the gameplay never looks at the blocks themselves,
	only at what's in the Zones, Markers and Interact folders.

	Boot builds it at runtime if the workspace has no "AshgroveHouse". To
	see it (and edit it) in Studio before pressing Play, run this in the
	Command Bar:

	    require(game.ServerScriptService.Ashgrove.Greybox).build()

	Once it exists in the place, Boot uses yours and never rebuilds it.

	Layout (studs; 1 stud = 0.28 m; ground-floor top at y = 0; +X is east,
	towards the cliff):

	    Van and drive    x -160..-116   the hub and first sanctuary
	    Entrance hall    x  -60..-10    z -30..30, 24 high, the first crew's camp
	    Portrait gallery x  -10..110    z -30..-8, 20 high, 120-stud sight line
	    (courtyard)      x  -10..110    z  -8..8, closed off
	    Servants' wing   x  -10..110    z   8..30, 12 high
	        corridor z 8..14; kitchen x -10..30; scullery 30..60 (stairs down);
	        housekeeper 60..85; servants' hall 85..110
	    Cellar vault     x   20..80     z -20..30, floor at y = -16
	    Cliff edge       x  130, sea far below

	What the systems read:
	    Zones/*     invisible boxes. Attributes: Wing, Room, Sanctuary,
	                Exterior, Priority, PoweredBy
	    Markers/*   invisible parts named Spawn_*, Dullahan_*, Lampshy_*,
	                Body_*, BansheeKeen_<Wing>_*
	    Interact/   Notes, Objects, Crates, Rites, Doors, Lamps, Pickups,
	                BellBoard, Glows
]]

local Greybox = {}

local C = {
	stone = Color3.fromRGB(88, 86, 82),
	plaster = Color3.fromRGB(118, 112, 100),
	wallpaper = Color3.fromRGB(74, 68, 60),
	oak = Color3.fromRGB(70, 50, 36),
	floor = Color3.fromRGB(56, 43, 33),
	flag = Color3.fromRGB(70, 70, 68),
	ground = Color3.fromRGB(38, 44, 32),
	gravel = Color3.fromRGB(78, 76, 72),
	glass = Color3.fromRGB(110, 128, 146),
	iron = Color3.fromRGB(44, 44, 48),
	brass = Color3.fromRGB(150, 118, 60),
	gold = Color3.fromRGB(214, 172, 60),
	sheet = Color3.fromRGB(194, 188, 174),
	black = Color3.fromRGB(14, 14, 16),
	crate = Color3.fromRGB(108, 84, 56),
	van = Color3.fromRGB(172, 174, 176),
	sea = Color3.fromRGB(14, 28, 38),
	cloth = Color3.fromRGB(58, 62, 72),
	paper = Color3.fromRGB(218, 210, 188),
	bone = Color3.fromRGB(206, 196, 168),
	lamp = Color3.fromRGB(255, 214, 160),
}

type Gap = { at: number, width: number, height: number, sill: number?, glass: boolean? }

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function box(parent: Instance, name: string, x1: number, x2: number, y1: number, y2: number, z1: number, z2: number, colour: Color3, material: Enum.Material?): Part
	local size = Vector3.new(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1))
	local centre = Vector3.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)
	return part(parent, name, size, CFrame.new(centre), colour, material)
end

local function invisible(p: BasePart): BasePart
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

-- A 1-stud-thick wall running along `axis` from `from` to `to`, centred on
-- `fixed` on the other axis, with door and window gaps.
local function wall(parent: Instance, name: string, axis: string, from: number, to: number, fixed: number, y0: number, height: number, gaps: { Gap }, colour: Color3, material: Enum.Material?)
	local function seg(segName: string, a: number, b: number, y1: number, y2: number, thick: number, segColour: Color3, segMaterial: Enum.Material?): Part
		if axis == "X" then
			return box(parent, segName, a, b, y1, y2, fixed - thick, fixed + thick, segColour, segMaterial)
		end
		return box(parent, segName, fixed - thick, fixed + thick, y1, y2, a, b, segColour, segMaterial)
	end

	local sorted = table.clone(gaps)
	table.sort(sorted, function(g1, g2)
		return g1.at < g2.at
	end)
	local cursor = from
	for _, g in sorted do
		local a, b = g.at - g.width / 2, g.at + g.width / 2
		if a > cursor then
			seg(name, cursor, a, y0, y0 + height, 0.5, colour, material)
		end
		local sill = g.sill or 0
		if sill > 0 then
			seg(name .. "Sill", a, b, y0, y0 + sill, 0.5, colour, material)
		end
		local top = sill + g.height
		if top < height then
			seg(name .. "Lintel", a, b, y0 + top, y0 + height, 0.5, colour, material)
		end
		if g.glass then
			local glass = seg(name .. "Glass", a, b, y0 + sill, y0 + top, 0.1, C.glass, Enum.Material.Glass)
			glass.Transparency = 0.55
		end
		cursor = b
	end
	if cursor < to then
		seg(name, cursor, to, y0, y0 + height, 0.5, colour, material)
	end
end

local function slab(parent: Instance, name: string, x1: number, x2: number, z1: number, z2: number, top: number, colour: Color3, material: Enum.Material?): Part
	return box(parent, name, x1, x2, top - 1, top, z1, z2, colour, material)
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function setAttributes(inst: Instance, attrs: { [string]: any }?)
	if attrs then
		for k, v in attrs do
			inst:SetAttribute(k, v)
		end
	end
end

local function label(p: BasePart, text: string, face: Enum.NormalId)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 1
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.Garamond
	t.TextColor3 = C.paper
	t.Parent = gui
	gui.Parent = p
end

function Greybox.build(opts: { replace: boolean? }?): Model
	local existing = workspace:FindFirstChild("AshgroveHouse")
	if existing then
		if opts and opts.replace then
			existing:Destroy()
		else
			return existing :: Model
		end
	end

	local root = Instance.new("Model")
	root.Name = "AshgroveHouse"
	local geo = folder(root, "Geometry")
	local zones = folder(root, "Zones")
	local markers = folder(root, "Markers")
	local interact = folder(root, "Interact")
	local notes = folder(interact, "Notes")
	local objects = folder(interact, "Objects")
	local crates = folder(interact, "Crates")
	local rites = folder(interact, "Rites")
	local doors = folder(interact, "Doors")
	local lamps = folder(interact, "Lamps")
	local pickups = folder(interact, "Pickups")
	folder(interact, "Glows")

	local function zone(name: string, x1: number, x2: number, y1: number, y2: number, z1: number, z2: number, attrs: { [string]: any })
		local z = box(zones, name, x1, x2, y1, y2, z1, z2, C.black)
		invisible(z)
		setAttributes(z, attrs)
	end

	local function marker(name: string, position: Vector3, lookAt: Vector3?, attrs: { [string]: any }?)
		local cf = if lookAt then CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z)) else CFrame.new(position)
		local m = part(markers, name, Vector3.one, cf, C.black)
		invisible(m)
		setAttributes(m, attrs)
	end

	local function note(noteId: string, position: Vector3, kind: string?, attrs: { [string]: any }?): Part
		local p
		if kind == "recorder" then
			p = part(notes, noteId, Vector3.new(0.8, 0.3, 0.5), CFrame.new(position), C.black)
		else
			p = part(notes, noteId, Vector3.new(1, 0.05, 1.4), CFrame.new(position), C.paper)
		end
		p:SetAttribute("NoteId", noteId)
		setAttributes(p, attrs)
		return p
	end

	local function pickup(kind: string, group: string, position: Vector3, always: boolean?)
		local size = if kind == "ammo" then Vector3.new(1.2, 0.8, 0.8) elseif kind == "battery" then Vector3.new(0.5, 0.9, 0.5) else Vector3.new(0.7, 0.7, 0.7)
		local colour = if kind == "ammo" then Color3.fromRGB(78, 84, 52) elseif kind == "battery" then Color3.fromRGB(180, 140, 40) else C.gold
		local p = part(pickups, kind, size, CFrame.new(position + Vector3.new(0, size.Y / 2, 0)), colour, if kind == "gold" then Enum.Material.Metal else nil)
		if kind == "gold" then
			p.Shape = Enum.PartType.Ball
		end
		p.CanCollide = false
		setAttributes(p, { Kind = kind, Group = group, Always = always == true })
	end

	local function crate(objectId: string, x: number, z: number, y: number)
		local base = box(crates, "Crate_" .. objectId, x - 2, x + 2, y, y + 3, z - 1.5, z + 1.5, C.crate, Enum.Material.WoodPlanks)
		base:SetAttribute("CrateFor", objectId)
		local lid = box(base, "Lid", x - 2.1, x + 2.1, y + 3, y + 3.3, z - 1.6, z + 1.6, C.crate, Enum.Material.WoodPlanks)
		lid.Transparency = 1
		lid.CanCollide = false
		label(box(base, "Ward", x - 1.5, x + 1.5, y + 0.5, y + 2.5, z - 1.55, z - 1.5, C.crate), "WARDED", Enum.NormalId.Front)
	end

	local function door(doorId: string, x1: number, x2: number, y1: number, y2: number, z1: number, z2: number, attrs: { [string]: any })
		local d = box(doors, doorId, x1, x2, y1, y2, z1, z2, C.oak, Enum.Material.Wood)
		d:SetAttribute("DoorId", doorId)
		setAttributes(d, attrs)
	end

	local function crewBody(name: string, x: number, y: number, z: number, yaw: number)
		local cf = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
		part(geo, name .. "Torso", Vector3.new(2, 0.9, 2.8), cf * CFrame.new(0, 0.45, 0), C.cloth)
		part(geo, name .. "Legs", Vector3.new(1.8, 0.7, 2.6), cf * CFrame.new(0, 0.35, 2.6), C.cloth)
		part(geo, name .. "Head", Vector3.new(1, 0.9, 1), cf * CFrame.new(0.3, 0.45, -1.9), Color3.fromRGB(150, 120, 100))
		part(geo, name .. "Torch", Vector3.new(0.3, 0.3, 1), cf * CFrame.new(1.8, 0.15, -0.6) * CFrame.Angles(0, math.rad(40), 0), C.black)
	end

	local function dustSheet(x1: number, x2: number, y1: number, y2: number, z1: number, z2: number)
		box(geo, "DustSheet", x1, x2, y1, y2, z1, z2, C.sheet, Enum.Material.Fabric)
	end

	------------------------------------------------------------------ grounds
	slab(geo, "Ground", -300, -60, -300, 300, 0, C.ground, Enum.Material.Grass)
	slab(geo, "Ground", -60, 130, -300, -30, 0, C.ground, Enum.Material.Grass)
	slab(geo, "Ground", -60, 130, 30, 300, 0, C.ground, Enum.Material.Grass)
	slab(geo, "Ground", 110, 130, -30, 30, 0, C.ground, Enum.Material.Grass)
	slab(geo, "Courtyard", -10, 110, -8, 8, 0, C.ground, Enum.Material.Grass)
	box(geo, "Drive", -160, -60, 0, 0.1, -6, 6, C.gravel, Enum.Material.Pebble)

	-- Cliff and sea.
	box(geo, "CliffFace", 130, 131, -120, 0, -300, 300, C.stone, Enum.Material.Rock)
	box(geo, "Sea", 131, 700, -130, -120, -300, 300, C.sea, Enum.Material.Water)
	box(geo, "CliffWall", 127, 128, 0, 3, -300, 300, C.stone, Enum.Material.Cobblestone)
	invisible(box(geo, "CliffBarrier", 128, 129, 0, 80, -300, 300, C.black)).CanCollide = true
	invisible(box(geo, "BoundWest", -301, -300, 0, 80, -300, 300, C.black)).CanCollide = true
	invisible(box(geo, "BoundNorth", -300, 130, 0, 80, -301, -300, C.black)).CanCollide = true
	invisible(box(geo, "BoundSouth", -300, 130, 0, 80, 300, 301, C.black)).CanCollide = true

	-- The van: hub, sanctuary, start and finish.
	box(geo, "VanBody", -148, -134, 1.5, 8.5, -3.5, 3.5, C.van, Enum.Material.Metal)
	box(geo, "VanCab", -134, -131, 1.5, 6.5, -3.5, 3.5, C.van, Enum.Material.Metal)
	box(geo, "VanWindscreen", -131.2, -130.9, 4, 6.2, -3, 3, C.glass, Enum.Material.Glass)
	for _, wx in { -145, -135 } do
		for _, wz in { -3.6, 3.6 } do
			-- Cylinders run along their X axis; turned to run along Z (the axle).
			local wheel = part(geo, "Wheel", Vector3.new(1, 3, 3), CFrame.new(wx, 1.5, wz) * CFrame.Angles(0, math.rad(90), 0), C.black)
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
	local headlights = box(geo, "Headlights", -131, -130.8, 2.5, 3.5, -3, 3, C.lamp, Enum.Material.Neon)
	local beam = Instance.new("SpotLight")
	beam.Face = Enum.NormalId.Right
	beam.Range = 60
	beam.Angle = 50
	beam.Brightness = 2
	beam.Color = C.lamp
	beam.Parent = headlights
	local vanLamp = box(lamps, "VanLantern", -127.5, -126.5, 0, 1.4, 5.5, 6.5, C.lamp, Enum.Material.Neon)
	setAttributes(vanLamp, { PowerGroup = "Van", LightRadius = 18 })
	local vanLight = Instance.new("PointLight")
	vanLight.Range = 24
	vanLight.Brightness = 1.4
	vanLight.Color = C.lamp
	vanLight.Parent = vanLamp

	-- The first crew's van, dead and open.
	box(geo, "CrewOneVan", -128, -114, 1.5, 8.5, -33.5, -26.5, Color3.fromRGB(70, 74, 80), Enum.Material.Metal)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "AshgroveSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 0.2, 6)
	spawn.CFrame = CFrame.new(-124, 0.1, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = geo

	------------------------------------------------------------------ hall
	slab(geo, "HallFloor", -60, -10, -30, 30, 0, C.floor, Enum.Material.WoodPlanks)
	box(geo, "HallCeiling", -60, -10, 24, 25, -30, 30, C.plaster)
	wall(geo, "HallWest", "Z", -30, 30, -60, 0, 24, {
		{ at = 0, width = 8, height = 12 },
		{ at = -18, width = 5, height = 10, sill = 4, glass = true },
		{ at = 18, width = 5, height = 10, sill = 4, glass = true },
	}, C.stone, Enum.Material.Cobblestone)
	wall(geo, "HallNorth", "X", -60, -10, -30, 0, 24, {
		{ at = -45, width = 5, height = 12, sill = 4, glass = true },
		{ at = -25, width = 5, height = 12, sill = 4, glass = true },
	}, C.stone, Enum.Material.Cobblestone)
	wall(geo, "HallSouth", "X", -60, -10, 30, 0, 24, {
		{ at = -45, width = 5, height = 12, sill = 4, glass = true },
		{ at = -25, width = 5, height = 12, sill = 4, glass = true },
	}, C.stone, Enum.Material.Cobblestone)
	wall(geo, "HallEast", "Z", -30, 30, -10, 0, 24, {
		{ at = -19, width = 10, height = 14 },
		{ at = 11, width = 5, height = 9 },
	}, C.wallpaper)

	-- Grand stair: the upper floor is for later stories, so it's blocked.
	for i = 0, 11 do
		box(geo, "Stair", -57 + i * 1.6, -55.4 + i * 1.6, 0, 1 + i, 22, 29, C.oak, Enum.Material.WoodPlanks)
	end
	part(geo, "FallenBeam", Vector3.new(8, 2, 1), CFrame.new(-54, 1, 21) * CFrame.Angles(0, 0, math.rad(8)), C.oak, Enum.Material.Wood)
	invisible(box(geo, "StairBarrier", -60, -36, 0, 24, 21, 22, C.black)).CanCollide = true

	-- The first crew's camp.
	box(geo, "WorkLampPole", -32.2, -31.8, 0, 7, -4.2, -3.8, C.iron, Enum.Material.Metal)
	local hallLamp = box(lamps, "HallWorkLamp", -32.8, -31.2, 7, 8, -4.8, -3.2, C.lamp, Enum.Material.Neon)
	setAttributes(hallLamp, { PowerGroup = "Hall", LightRadius = 28 })
	local hallLight = Instance.new("PointLight")
	hallLight.Range = 45
	hallLight.Brightness = 1.6
	hallLight.Color = C.lamp
	hallLight.Shadows = true
	hallLight.Parent = hallLamp
	box(geo, "Generator", -30, -26, 0, 2.5, -12, -9, Color3.fromRGB(150, 60, 40), Enum.Material.Metal)
	box(geo, "CampTable", -44, -36, 2.8, 3.3, -9, -5, C.oak, Enum.Material.Wood)
	for _, lx in { -43.6, -36.4 } do
		for _, lz in { -8.6, -5.4 } do
			box(geo, "TableLeg", lx - 0.2, lx + 0.2, 0, 2.8, lz - 0.2, lz + 0.2, C.oak, Enum.Material.Wood)
		end
	end
	note("Manifest", Vector3.new(-42, 3.33, -7))
	note("Memo_Hall", Vector3.new(-38.5, 3.45, -7), "recorder")
	pickup("battery", "Hall", Vector3.new(-37, 3.3, -5.8), true)
	pickup("ammo", "Hall", Vector3.new(-28, 2.5, -10.5), true)

	box(geo, "CatalogueDrawers", -54, -50, 0, 4, -14, -10, C.oak, Enum.Material.Wood)
	note("Card_Dullahan", Vector3.new(-53.2, 4.03, -12.5))
	note("Card_Lampshy", Vector3.new(-52, 4.03, -12.5))
	note("Card_Banshee", Vector3.new(-50.8, 4.03, -12.5))

	-- Lot 077's case, found empty.
	box(geo, "CombCase", -22, -18, 0, 3.5, 18, 22, C.oak, Enum.Material.Wood)
	box(geo, "CombCushion", -21, -19, 3.5, 3.8, 19, 21, Color3.fromRGB(90, 30, 34), Enum.Material.Fabric)
	box(geo, "CombGlass", -22, -18, 3.5, 6.5, 18, 22, C.glass, Enum.Material.Glass).Transparency = 0.7

	-- Cornelius's pocket piece: the gold ward.
	box(geo, "GoldCase", -22, -18, 0, 3.5, -26, -22, C.oak, Enum.Material.Wood)
	pickup("gold", "Hall", Vector3.new(-20, 3.5, -24), true)
	note("Card_Gold", Vector3.new(-18.8, 3.53, -22.8))

	for i, c in { { -48, -20 }, { -46, 14 }, { -26, 6 }, { -14, -2 } } do
		box(geo, "Crate" .. i, c[1] - 2, c[1] + 2, 0, 3, c[2] - 2, c[2] + 2, C.crate, Enum.Material.WoodPlanks)
	end
	dustSheet(-30, -24, 0, 4, 14, 20)

	door("GalleryDoor", -10.5, -9.5, 0, 14, -24, -14, { Wing = "Gallery", StartsLocked = false })
	door("ServantsDoor", -10.5, -9.5, 0, 9, 8.5, 13.5, {
		Wing = "ServantsWing",
		StartsLocked = true,
		LockedText = "Locked. The first crew must have had the key.",
	})

	marker("Spawn_Van", Vector3.new(-124, 3, 0), Vector3.new(0, 3, 0))
	marker("Spawn_HallCamp", Vector3.new(-36, 3, 4), Vector3.new(0, 3, 4))

	------------------------------------------------------------------ gallery
	slab(geo, "GalleryFloor", -10, 110, -30, -8, 0, C.floor, Enum.Material.WoodPlanks)
	box(geo, "GalleryCeiling", -10, 110, 20, 21, -30, -8, C.plaster)
	local galleryWindows = {}
	for _, wx in { 5, 20, 35, 50, 65, 80, 95 } do
		table.insert(galleryWindows, { at = wx, width = 6, height = 13, sill = 3, glass = true })
	end
	wall(geo, "GalleryNorth", "X", -10, 110, -30, 0, 20, galleryWindows, C.stone, Enum.Material.Cobblestone)
	wall(geo, "GallerySouth", "X", -10, 110, -8, 0, 20, {}, C.wallpaper)
	wall(geo, "GalleryEast", "Z", -30, -8, 110, 0, 20, {
		{ at = -19, width = 6, height = 13, sill = 3, glass = true },
	}, C.stone, Enum.Material.Cobblestone)

	-- Portraits of the objects' previous owners, mostly under dust sheets.
	-- Two are torn open at head height: the Dullahan studies faces.
	for i = 0, 8 do
		local px = 2 + i * 12
		box(geo, "Portrait", px - 3, px + 3, 5, 12, -9, -8.5, C.oak, Enum.Material.Wood)
		if px == 50 or px == 86 then
			box(geo, "TornSheet", px - 2, px + 2, 0, 0.4, -11, -9.5, C.sheet, Enum.Material.Fabric)
		else
			dustSheet(px - 3.2, px + 3.2, 4.6, 12.4, -9.3, -9)
		end
	end
	-- Busts under sheets: at a distance, is that a bust or his head?
	for _, bx in { 12.5, 42.5, 72.5 } do
		box(geo, "Pedestal", bx - 1, bx + 1, 0, 4, -27, -25, C.stone, Enum.Material.Marble)
		local bust = part(geo, "Bust", Vector3.new(1.6, 1.6, 1.6), CFrame.new(bx, 4.8, -26), C.bone, Enum.Material.Marble)
		bust.Shape = Enum.PartType.Ball
	end

	-- Lot 114: the tack case at the far end.
	box(geo, "TackCase", 100, 108, 0, 3.5, -22, -16, C.oak, Enum.Material.Wood)
	local whip = part(objects, "SpineWhip", Vector3.new(0.35, 0.35, 5), CFrame.new(104, 3.75, -19) * CFrame.Angles(0, math.rad(20), 0), C.bone)
	setAttributes(whip, { ObjectId = "SpineWhip", EntityId = "Dullahan", Label = "Spine whip", Securable = true })
	crate("SpineWhip", 102, -12.5, 0)

	crewBody("PruittBody", 62, 0, -26, 30)
	note("Memo_Gallery", Vector3.new(59.5, 0.15, -28), "recorder")
	pickup("ammo", "Gallery", Vector3.new(30, 0, -10))
	pickup("ammo", "Gallery", Vector3.new(80, 0, -28.5))
	pickup("ammo", "Gallery", Vector3.new(-6, 0, -28.5))

	marker("Dullahan_Spawn", Vector3.new(94, 4, -19), Vector3.new(0, 4, -19))
	local route = {
		{ 92, -14, Vector3.new(92, 9, -8) },
		{ 74, -24, Vector3.new(80, 9, -30) },
		{ 56, -14, Vector3.new(50, 9, -8) },
		{ 38, -24, Vector3.new(35, 9, -30) },
		{ 20, -14, Vector3.new(14, 9, -8) },
		{ 4, -24, Vector3.new(5, 9, -30) },
	}
	for i, r in route do
		marker(string.format("Dullahan_Route_%02d", i), Vector3.new(r[1], 4, r[2]), nil, { Look = r[3] })
	end
	marker("Body_Gallery", Vector3.new(62, 0, -26))
	marker("BansheeKeen_Gallery_1", Vector3.new(106, 0, -12), Vector3.new(0, 0, -19))
	marker("BansheeKeen_Gallery_2", Vector3.new(45, 0, -27), Vector3.new(45, 0, -8))
	marker("BansheeKeen_Gallery_3", Vector3.new(-5, 0, -27), Vector3.new(100, 0, -19))

	------------------------------------------------------------------ servants' wing
	slab(geo, "CorridorFloor", -10, 110, 8, 14, 0, C.flag, Enum.Material.Slate)
	slab(geo, "KitchenFloor", -10, 30, 14, 30, 0, C.flag, Enum.Material.Slate)
	slab(geo, "SculleryFloor", 30, 60, 14, 24, 0, C.flag, Enum.Material.Slate)
	slab(geo, "SculleryFloor", 30, 36, 24, 30, 0, C.flag, Enum.Material.Slate)
	slab(geo, "SculleryFloor", 58, 60, 24, 30, 0, C.flag, Enum.Material.Slate)
	slab(geo, "HousekeeperFloor", 60, 85, 14, 30, 0, C.floor, Enum.Material.WoodPlanks)
	slab(geo, "ServantsHallFloor", 85, 110, 14, 30, 0, C.floor, Enum.Material.WoodPlanks)
	box(geo, "WingCeiling", -10, 110, 12, 13, 8, 30, C.plaster)

	wall(geo, "CorridorNorth", "X", -10, 110, 8, 0, 12, {}, C.plaster)
	wall(geo, "CorridorSouth", "X", -10, 110, 14, 0, 12, {
		{ at = 10, width = 5, height = 9 },
		{ at = 45, width = 5, height = 9 },
		{ at = 72, width = 4, height = 9 },
		{ at = 97, width = 5, height = 9 },
	}, C.plaster)
	wall(geo, "WingSouth", "X", -10, 110, 30, 0, 12, {
		{ at = 0, width = 4, height = 4, sill = 4, glass = true },
		{ at = 20, width = 4, height = 4, sill = 4, glass = true },
		{ at = 72, width = 3, height = 4, sill = 4 }, -- the rite window fills this
		{ at = 97, width = 4, height = 4, sill = 4, glass = true },
	}, C.stone, Enum.Material.Cobblestone)
	wall(geo, "KitchenScullery", "Z", 14, 30, 30, 0, 12, {}, C.plaster)
	wall(geo, "ScullerySide", "Z", 14, 30, 60, 0, 12, {}, C.plaster)
	wall(geo, "HousekeeperSide", "Z", 14, 30, 85, 0, 12, {}, C.plaster)
	wall(geo, "WingEast", "Z", 8, 30, 110, 0, 12, {}, C.stone, Enum.Material.Cobblestone)
	wall(geo, "CourtyardEast", "Z", -8, 8, 110, 0, 12, {}, C.stone, Enum.Material.Cobblestone)

	-- Bell board, west end of the corridor.
	local bellBoard = Instance.new("Model")
	bellBoard.Name = "BellBoard"
	bellBoard.Parent = interact
	box(bellBoard, "Board", -8, 6, 6, 9.6, 8.5, 8.8, C.oak, Enum.Material.Wood)
	local bellRooms = {
		{ "Gallery", "GALLERY" },
		{ "Kitchen", "KITCHEN" },
		{ "Corridor", "PASSAGE" },
		{ "Scullery", "SCULLERY" },
		{ "Housekeeper", "HOUSEKEEPER" },
		{ "ServantsHall", "SERVANTS' HALL" },
		{ "Vault", "CELLAR" },
	}
	for i, room in bellRooms do
		local bx = -7 + (i - 1) * 2
		local bell = part(bellBoard, "Bell_" .. room[1], Vector3.new(0.7, 0.7, 0.7), CFrame.new(bx, 8.7, 9.2), C.brass, Enum.Material.Metal)
		bell.Shape = Enum.PartType.Ball
		bell:SetAttribute("Room", room[1])
		local plate = part(bellBoard, "Label_" .. room[1], Vector3.new(1.8, 0.6, 0.05), CFrame.lookAt(Vector3.new(bx, 7.4, 8.85), Vector3.new(bx, 7.4, 20)), C.oak)
		label(plate, room[2], Enum.NormalId.Front)
	end
	local bellsNote = note("Bells", Vector3.new(-1, 6.6, 8.9))
	bellsNote.CFrame = CFrame.new(-1, 6.6, 8.9) * CFrame.Angles(math.rad(90), 0, 0)

	-- Kitchen: where Okafor fell.
	box(geo, "KitchenTable", -2, 22, 2.8, 3.3, 19, 23, C.oak, Enum.Material.Wood)
	box(geo, "Range", -9, -3, 0, 5, 24, 29.5, C.iron, Enum.Material.Metal)
	crewBody("OkaforBody", 12, 0, 26.5, -70)
	note("Memo_Kitchen", Vector3.new(14.5, 0.15, 25.2), "recorder", { RequiresMourning = true })
	pickup("battery", "Batteries", Vector3.new(20, 3.3, 21))
	pickup("ammo", "ServantsWing", Vector3.new(-6, 0, 16))

	-- Scullery: Lot 203 and the stairs down.
	box(geo, "Trough", 34, 44, 0, 3, 14.5, 17, C.stone, Enum.Material.Slate)
	box(geo, "Shelf", 56, 59.5, 3, 3.4, 15, 19, C.oak, Enum.Material.Wood)
	local lantern = part(objects, "HollowLantern", Vector3.new(1, 1.6, 1), CFrame.new(57.5, 4.2, 17), Color3.fromRGB(96, 84, 60), Enum.Material.Metal)
	setAttributes(lantern, { ObjectId = "HollowLantern", EntityId = "Lampshy", Label = "Hollow lantern", Securable = true })
	crate("HollowLantern", 53, 20.5, 0)
	box(geo, "Carcass", 46.5, 49.5, 0, 0.6, 20, 22, Color3.fromRGB(70, 46, 40)).CanCollide = false

	box(geo, "StairRail", 36, 58, 0, 3.5, 23.8, 24.2, C.iron, Enum.Material.Metal)
	invisible(box(geo, "StairRailCollider", 36, 58, 0, 12, 23.8, 24.2, C.black)).CanCollide = true
	box(geo, "StairRailEnd", 57.8, 58.2, 0, 3.5, 24, 30, C.iron, Enum.Material.Metal)
	invisible(box(geo, "StairRailEndCollider", 57.8, 58.2, 0, 12, 24, 30, C.black)).CanCollide = true
	local rampAngle = math.atan2(16, 22)
	local rampLength = math.sqrt(22 * 22 + 16 * 16)
	local rampCf = CFrame.new(47, -8, 27) * CFrame.Angles(0, 0, -rampAngle)
	part(geo, "CellarStairs", Vector3.new(rampLength + 1, 1, 6), rampCf * CFrame.new(0, -0.5, 0), C.stone, Enum.Material.Slate)
	part(geo, "CellarStairsRail", Vector3.new(rampLength, 3, 0.4), CFrame.new(47, -8, 24.2) * CFrame.Angles(0, 0, -rampAngle) * CFrame.new(0, 1.5, 0), C.iron, Enum.Material.Metal)
	door("VaultGate", 35.5, 36.5, 0, 9, 24, 30, {
		Wing = "Vault",
		StartsLocked = true,
		LockedText = "Chained shut. Not yet.",
	})

	-- Housekeeper's room: the wake rite.
	box(geo, "Desk", 62, 68, 0, 3, 16, 19, C.oak, Enum.Material.Wood)
	note("Customs", Vector3.new(65, 3.03, 17.5))
	local riteHK = Instance.new("Model")
	riteHK.Name = "Rite_Housekeeper"
	riteHK:SetAttribute("Wing", "ServantsWing")
	riteHK.Parent = rites
	local clock = box(riteHK, "Clock", 62, 64, 0, 7, 27.5, 29, C.oak, Enum.Material.Wood)
	clock:SetAttribute("RiteStep", "clock")
	box(clock, "Face", 62.3, 63.7, 5, 6.4, 27.4, 27.5, C.paper)
	local mirror = box(riteHK, "Mirror", 84.3, 84.5, 4, 8, 20, 24, C.glass, Enum.Material.Glass)
	mirror.Reflectance = 0.5
	mirror:SetAttribute("RiteStep", "mirror")
	local cloth = box(mirror, "Cloth", 84, 84.3, 3.5, 8.5, 19.5, 24.5, C.black, Enum.Material.Fabric)
	cloth.Transparency = 1
	cloth.CanCollide = false
	local window = box(riteHK, "Window", 70.5, 73.5, 4, 8, 29.9, 30.1, C.glass, Enum.Material.Glass)
	window.Transparency = 0.4
	window:SetAttribute("RiteStep", "window")

	-- Servants' hall.
	for i = 0, 2 do
		box(geo, "Bed", 88 + i * 7, 92 + i * 7, 0, 2, 24, 29.5, C.sheet, Enum.Material.Fabric)
	end
	pickup("ammo", "ServantsWing", Vector3.new(90, 0, 16))
	pickup("ammo", "ServantsWing", Vector3.new(105, 0, 16))
	pickup("ammo", "ServantsWing", Vector3.new(70, 0, 9.5))
	pickup("battery", "Batteries", Vector3.new(104, 2, 27))

	marker("Spawn_Stairwell", Vector3.new(33, 3, 18), Vector3.new(60, 3, 18))
	marker("Lampshy_Spawn", Vector3.new(47, 1.5, 18.5), Vector3.new(47, 1.5, 25))
	local lampRoute = {
		Vector3.new(47, 1.5, 18.5),
		Vector3.new(20, 1.5, 11),
		Vector3.new(5, 1.5, 18),
		Vector3.new(72, 1.5, 20),
		Vector3.new(97, 1.5, 21),
		Vector3.new(100, 1.5, 11),
	}
	for i, p in lampRoute do
		marker(string.format("Lampshy_Route_%02d", i), p)
	end
	marker("Body_Kitchen", Vector3.new(12, 0, 26.5))
	marker("BansheeKeen_ServantsWing_1", Vector3.new(-6, 0, 19), Vector3.new(30, 0, 18))
	marker("BansheeKeen_ServantsWing_2", Vector3.new(55, 0, 16), Vector3.new(30, 0, 18))
	marker("BansheeKeen_ServantsWing_3", Vector3.new(82, 0, 27), Vector3.new(60, 0, 18))
	marker("BansheeKeen_ServantsWing_4", Vector3.new(106, 0, 11), Vector3.new(0, 0, 11))

	------------------------------------------------------------------ vault
	slab(geo, "VaultFloor", 20, 80, -20, 30, -16, C.stone, Enum.Material.Slate)
	wall(geo, "VaultNorth", "X", 20, 80, -20, -16, 15, {}, C.stone, Enum.Material.Cobblestone)
	wall(geo, "VaultSouth", "X", 20, 80, 30, -16, 15, {}, C.stone, Enum.Material.Cobblestone)
	wall(geo, "VaultWest", "Z", -20, 30, 20, -16, 15, {}, C.stone, Enum.Material.Cobblestone)
	wall(geo, "VaultEast", "Z", -20, 30, 80, -16, 15, {}, C.stone, Enum.Material.Cobblestone)

	-- Iron cages for the worst of the collection.
	for _, cx in { 30, 42, 66, 76 } do
		for _, corner in { { -1.8, -1.8 }, { 1.8, -1.8 }, { -1.8, 1.8 }, { 1.8, 1.8 } } do
			box(geo, "CageBar", cx + corner[1] - 0.15, cx + corner[1] + 0.15, -16, -9, -14 + corner[2] - 0.15, -14 + corner[2] + 0.15, C.iron, Enum.Material.Metal)
		end
		box(geo, "CageTop", cx - 2, cx + 2, -9, -8.7, -16, -12, C.iron, Enum.Material.Metal)
	end

	-- Lot 001: the sealed box. The seal is broken.
	box(geo, "Plinth", 58, 62, -16, -13, -10, -6, C.stone, Enum.Material.Marble)
	local dybbukBox = box(objects, "DybbukBox", 59, 61, -13, -11.6, -9, -7, C.oak, Enum.Material.Wood)
	setAttributes(dybbukBox, { ObjectId = "DybbukBox", Label = "The sealed box", Securable = false })
	part(geo, "BoxLid", Vector3.new(2, 0.2, 2), CFrame.new(60, -11.3, -9.2) * CFrame.Angles(math.rad(-35), 0, 0), C.oak, Enum.Material.Wood)
	box(geo, "Lectern", 63, 65, -16, -13, -9, -7, C.oak, Enum.Material.Wood)
	note("Vault_Ledger", Vector3.new(64, -12.97, -8))

	local riteVault = Instance.new("Model")
	riteVault.Name = "Rite_Vault"
	riteVault:SetAttribute("Wing", "Vault")
	riteVault.Parent = rites
	local vClock = box(riteVault, "Clock", 22, 24, -16, -9, 25, 27, C.oak, Enum.Material.Wood)
	vClock:SetAttribute("RiteStep", "clock")
	box(vClock, "Face", 24, 24.1, -11, -9.6, 25.3, 26.7, C.paper)
	local vMirror = box(riteVault, "Mirror", 20.5, 20.7, -12, -8, 8, 12, C.glass, Enum.Material.Glass)
	vMirror.Reflectance = 0.5
	vMirror:SetAttribute("RiteStep", "mirror")
	local vCloth = box(vMirror, "Cloth", 20.7, 21, -12.5, -7.5, 7.5, 12.5, C.black, Enum.Material.Fabric)
	vCloth.Transparency = 1
	vCloth.CanCollide = false
	local hatch = box(riteVault, "Window", 20.5, 20.7, -5, -2, -6, -2, C.iron, Enum.Material.Metal)
	hatch:SetAttribute("RiteStep", "window")

	pickup("ammo", "Vault", Vector3.new(72, -16, 2))
	pickup("ammo", "Vault", Vector3.new(25, -16, 0))
	pickup("battery", "Batteries", Vector3.new(50, -16, 25))

	marker("BansheeKeen_Vault_1", Vector3.new(74, -16, 25), Vector3.new(50, -16, 0))
	marker("BansheeKeen_Vault_2", Vector3.new(26, -16, -14), Vector3.new(50, -16, 10))
	marker("BansheeKeen_Vault_3", Vector3.new(50, -16, 12), Vector3.new(60, -16, -8))

	------------------------------------------------------------------ zones
	zone("Grounds", -300, 130, -50, 100, -300, 300, { Wing = "Grounds", Room = "Grounds", Exterior = true, Priority = 0 })
	zone("Van", -156, -116, -5, 30, -16, 16, { Wing = "Van", Room = "Van", Sanctuary = true, Exterior = true, Priority = 5 })
	zone("Hall", -60, -10, -1, 25, -30, 30, { Wing = "Hall", Room = "Hall", Sanctuary = true, PoweredBy = "Hall", Priority = 2 })
	zone("Gallery", -10, 110, -1, 21, -30, -8, { Wing = "Gallery", Room = "Gallery", Priority = 2 })
	zone("Corridor", -10, 110, -1, 13, 8, 14, { Wing = "ServantsWing", Room = "Corridor", Priority = 2 })
	zone("Kitchen", -10, 30, -1, 13, 14, 30, { Wing = "ServantsWing", Room = "Kitchen", Priority = 2 })
	zone("Scullery", 30, 60, -1, 13, 14, 30, { Wing = "ServantsWing", Room = "Scullery", Priority = 2 })
	zone("Housekeeper", 60, 85, -1, 13, 14, 30, { Wing = "ServantsWing", Room = "Housekeeper", Priority = 2 })
	zone("ServantsHall", 85, 110, -1, 13, 14, 30, { Wing = "ServantsWing", Room = "ServantsHall", Priority = 2 })
	zone("Vault", 20, 80, -17, -1, -20, 30, { Wing = "Vault", Room = "Vault", Priority = 3 })

	root.WorldPivot = CFrame.new(0, 0, 0)
	root.Parent = workspace
	return root
end

return Greybox
