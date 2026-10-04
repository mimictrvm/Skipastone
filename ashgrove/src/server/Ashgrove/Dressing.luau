--[[
	Dressing: everything that makes the layout look like Ashgrove House.
	Panelled rooms get furniture, the collection gets its cases and crates,
	the house gets an upper storey, roofs with crow-stepped gables and
	chimneys, and the grounds get the drive, the dead trees, the family
	plot, the cliff and a lighthouse out at sea.

	Nothing here is read by the gameplay. Move it, delete it, or replace it
	with the art brief's AH_Prop_* / AH_Kit_* models freely. After big
	changes run tools/check_greybox.luau: it fails if something solid now
	blocks a route, a marker or a pickup.

	Rules this file keeps (so the game still plays):
	  - nothing solid in doorways, on walking routes or on markers
	  - the gallery's sight line (x -8..99 at z -19, eye height) stays open
	  - decorative lights only where no entity cares about light (the
	    hall, the gallery, outside). Gameplay light is Interact/Lamps.
	  - lights with a Flicker attribute ("bulb" | "window") are animated at
	    runtime by Storm; a part with Spin = true is turned (the
	    lighthouse beam)
]]

local Build = require(script.Parent.Build)

local part, box, column, rod, decor = Build.part, Build.box, Build.column, Build.rod, Build.decor

local Dressing = {}

local C = {
	oak = Color3.fromRGB(70, 50, 36),
	oakDark = Color3.fromRGB(48, 34, 26),
	walnut = Color3.fromRGB(60, 40, 30),
	sheet = Color3.fromRGB(194, 188, 174),
	sheetGrey = Color3.fromRGB(150, 146, 136),
	brass = Color3.fromRGB(150, 118, 60),
	iron = Color3.fromRGB(40, 40, 44),
	glass = Color3.fromRGB(110, 128, 146),
	stone = Color3.fromRGB(96, 95, 90),
	stoneDark = Color3.fromRGB(70, 70, 68),
	limestone = Color3.fromRGB(150, 148, 138),
	marbleWhite = Color3.fromRGB(196, 192, 182),
	marbleBlack = Color3.fromRGB(34, 34, 36),
	rugRed = Color3.fromRGB(92, 30, 28),
	rugGreen = Color3.fromRGB(34, 52, 40),
	rugGold = Color3.fromRGB(140, 104, 48),
	fabricBrown = Color3.fromRGB(86, 60, 44),
	fabricGreen = Color3.fromRGB(44, 62, 50),
	crate = Color3.fromRGB(108, 84, 56),
	canvas = Color3.fromRGB(44, 38, 32),
	paper = Color3.fromRGB(218, 210, 188),
	black = Color3.fromRGB(14, 14, 16),
	wax = Color3.fromRGB(220, 210, 180),
	stain = Color3.fromRGB(20, 18, 14),
	web = Color3.fromRGB(220, 220, 214),
	roof = Color3.fromRGB(50, 52, 58),
	bark = Color3.fromRGB(44, 36, 30),
	hedge = Color3.fromRGB(30, 44, 28),
	earth = Color3.fromRGB(46, 36, 28),
	lamp = Color3.fromRGB(255, 214, 160),
	white = Color3.fromRGB(214, 214, 206),
	red = Color3.fromRGB(140, 40, 34),
}

local M = Enum.Material

------------------------------------------------------------------ helpers

-- A frame on the floor at (x, z) turned `yaw` degrees. Furniture faces -Z
-- of this frame (a chair's seat faces -Z, its back is at +Z).
local function at(x: number, z: number, yaw: number?, y: number?): CFrame
	return CFrame.new(x, y or 0, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

local function piece(f: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?, cosmetic: boolean?): Part
	local p = part(f, name, size, cf, colour, material)
	if cosmetic then
		decor(p)
	end
	return p
end

-- Flat things on the floor (rugs, stains): cosmetic, a hair above it.
local function floorPatch(f: Instance, name: string, x1: number, x2: number, z1: number, z2: number, y: number, colour: Color3, material: Enum.Material, transparency: number?)
	local p = decor(box(f, name, x1, x2, y + 0.02, y + 0.07, z1, z2, colour, material))
	p.Transparency = transparency or 0
	return p
end

local function rug(f: Instance, x1: number, x2: number, z1: number, z2: number, y: number, colour: Color3, border: Color3)
	floorPatch(f, "RugBorder", x1, x2, z1, z2, y, border, M.Fabric)
	decor(box(f, "Rug", x1 + 0.8, x2 - 0.8, y + 0.07, y + 0.1, z1 + 0.8, z2 - 0.8, colour, M.Fabric))
end

local function chair(f: Instance, cf: CFrame, colour: Color3)
	piece(f, "ChairSeat", Vector3.new(1.6, 0.25, 1.6), cf * CFrame.new(0, 1.7, 0), colour, M.Wood)
	for _, sx in { -0.65, 0.65 } do
		for _, sz in { -0.65, 0.65 } do
			piece(f, "ChairLeg", Vector3.new(0.2, 1.6, 0.2), cf * CFrame.new(sx, 0.8, sz), colour, M.Wood)
		end
	end
	piece(f, "ChairBack", Vector3.new(1.6, 2.2, 0.2), cf * CFrame.new(0, 2.95, 0.7), colour, M.Wood)
end

local function armchair(f: Instance, cf: CFrame, colour: Color3, sheeted: boolean?)
	local c = if sheeted then C.sheet else colour
	local m = M.Fabric
	piece(f, "ArmchairBase", Vector3.new(3, 1.6, 2.8), cf * CFrame.new(0, 0.8, 0), c, m)
	piece(f, "ArmchairBack", Vector3.new(3, 2.6, 0.6), cf * CFrame.new(0, 2.6, 1.1), c, m)
	piece(f, "ArmchairArm", Vector3.new(0.5, 1, 2.8), cf * CFrame.new(-1.25, 2.1, 0), c, m)
	piece(f, "ArmchairArm", Vector3.new(0.5, 1, 2.8), cf * CFrame.new(1.25, 2.1, 0), c, m)
end

local function bookcase(f: Instance, cf: CFrame, w: number, h: number, rng: Build.Rng)
	piece(f, "BookcaseBack", Vector3.new(w, h, 0.2), cf * CFrame.new(0, h / 2, 0.6), C.walnut, M.Wood)
	piece(f, "BookcaseSide", Vector3.new(0.25, h, 1.4), cf * CFrame.new(-w / 2 + 0.125, h / 2, 0), C.walnut, M.Wood)
	piece(f, "BookcaseSide", Vector3.new(0.25, h, 1.4), cf * CFrame.new(w / 2 - 0.125, h / 2, 0), C.walnut, M.Wood)
	local shelves = math.max(2, math.floor(h / 1.6))
	for i = 0, shelves do
		local y = 0.1 + i * (h - 0.2) / shelves
		piece(f, "Shelf", Vector3.new(w - 0.5, 0.15, 1.3), cf * CFrame.new(0, y, 0), C.walnut, M.Wood)
		if i < shelves then
			local x = -w / 2 + 0.4
			while x < w / 2 - 0.6 do
				local bw = rng:number(0.18, 0.4)
				local bh = rng:number(0.8, 1.3)
				if rng:number(0, 1) > 0.12 then
					local colour = Color3.fromHSV(rng:number(0, 1), rng:number(0.2, 0.6), rng:number(0.15, 0.4))
					piece(f, "Book", Vector3.new(bw, bh, 1), cf * CFrame.new(x + bw / 2, y + 0.075 + bh / 2, 0.05), colour, M.SmoothPlastic, true)
				end
				x += bw + 0.02
			end
		end
	end
end

local function wardrobe(f: Instance, cf: CFrame)
	piece(f, "Wardrobe", Vector3.new(3.6, 7.5, 1.8), cf * CFrame.new(0, 3.75, 0), C.walnut, M.Wood)
	piece(f, "WardrobeCornice", Vector3.new(4, 0.4, 2.1), cf * CFrame.new(0, 7.7, 0), C.oakDark, M.Wood)
	piece(f, "WardrobeHandle", Vector3.new(0.1, 0.6, 0.1), cf * CFrame.new(-0.2, 3.8, -0.95), C.brass, M.Metal, true)
	piece(f, "WardrobeHandle", Vector3.new(0.1, 0.6, 0.1), cf * CFrame.new(0.2, 3.8, -0.95), C.brass, M.Metal, true)
end

local function bed(f: Instance, cf: CFrame, w: number, l: number, blanket: Color3)
	piece(f, "BedFrame", Vector3.new(w, 1.2, l), cf * CFrame.new(0, 0.6, 0), C.oakDark, M.Wood)
	piece(f, "Mattress", Vector3.new(w - 0.3, 0.6, l - 0.3), cf * CFrame.new(0, 1.5, 0), C.sheet, M.Fabric)
	piece(f, "Blanket", Vector3.new(w - 0.1, 0.25, l * 0.6), cf * CFrame.new(0, 1.85, -l * 0.18), blanket, M.Fabric, true)
	piece(f, "Pillow", Vector3.new(w - 1, 0.4, 1), cf * CFrame.new(0, 1.95, l / 2 - 0.8), C.sheet, M.Fabric, true)
	piece(f, "Headboard", Vector3.new(w, 3.2, 0.3), cf * CFrame.new(0, 1.6, l / 2 - 0.15), C.oakDark, M.Wood)
end

-- A dust-sheeted lump: something under a sheet, lumpy on top.
local function sheeted(f: Instance, cf: CFrame, size: Vector3, rng: Build.Rng)
	piece(f, "DustSheet", size, cf * CFrame.new(0, size.Y / 2, 0), C.sheet, M.Fabric)
	piece(f, "DustSheetLump", Vector3.new(size.X * rng:number(0.4, 0.7), 0.6, size.Z * rng:number(0.4, 0.7)), cf * CFrame.new(rng:number(-0.3, 0.3), size.Y + 0.25, rng:number(-0.3, 0.3)), C.sheet, M.Fabric, true)
	piece(f, "DustSheetHem", Vector3.new(size.X + 0.3, 0.3, size.Z + 0.3), cf * CFrame.new(0, 0.15, 0), C.sheetGrey, M.Fabric, true)
end

local function crateStack(f: Instance, x: number, z: number, y: number, count: number, rng: Build.Rng)
	local height = y
	for i = 1, count do
		local s = rng:number(2.4, 3.6)
		local yaw = rng:number(-12, 12)
		local c = piece(f, "Crate", Vector3.new(s, s * 0.8, s), at(x + rng:number(-0.3, 0.3), z + rng:number(-0.3, 0.3), yaw, height + s * 0.4), C.crate, M.WoodPlanks)
		if i == 1 then
			Build.label(piece(f, "CrateStencil", Vector3.new(s * 0.7, s * 0.35, 0.05), c.CFrame * CFrame.new(0, 0, -s / 2 - 0.03), C.crate, M.WoodPlanks, true), `LOT {rng:integer(120, 480)}`, Enum.NormalId.Front, C.black, Enum.Font.Arcade)
		end
		height += s * 0.8
	end
end

local function chandelier(f: Instance, x: number, ceiling: number, z: number, drop: number, radius: number)
	local y = ceiling - drop
	decor(rod(f, "ChandelierChain", Vector3.new(x, ceiling, z), Vector3.new(x, y + 0.5, z), 0.15, C.iron, M.Metal))
	piece(f, "ChandelierHub", Vector3.new(0.8, 1.4, 0.8), CFrame.new(x, y, z), C.brass, M.Metal, true)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local tip = Vector3.new(x + math.cos(a) * radius, y + 0.4, z + math.sin(a) * radius)
		decor(rod(f, "ChandelierArm", Vector3.new(x, y - 0.3, z), tip, 0.12, C.brass, M.Metal))
		piece(f, "CandleStub", Vector3.new(0.2, 0.5, 0.2), CFrame.new(tip + Vector3.new(0, 0.3, 0)), C.wax, M.SmoothPlastic, true)
	end
end

-- A framed painting hung on a wall face. `axis` is the wall's axis ("X":
-- the wall runs along X, its face at z = `face`); `side` is the way the
-- face looks (+1 towards +Z / +X).
local function painting(f: Instance, axis: string, face: number, side: number, along: number, yMid: number, w: number, h: number, canvas: Color3, title: string?)
	local function plate(name: string, a1: number, a2: number, y1: number, y2: number, out1: number, out2: number, colour: Color3, material: Enum.Material): Part
		local d1, d2 = face + side * out1, face + side * out2
		if d1 > d2 then
			d1, d2 = d2, d1
		end
		if axis == "X" then
			return decor(box(f, name, a1, a2, y1, y2, d1, d2, colour, material)) :: Part
		end
		return decor(box(f, name, d1, d2, y1, y2, a1, a2, colour, material)) :: Part
	end
	plate("PaintingFrame", along - w / 2, along + w / 2, yMid - h / 2, yMid + h / 2, 0, 0.2, C.brass, M.Wood)
	plate("PaintingCanvas", along - w / 2 + 0.35, along + w / 2 - 0.35, yMid - h / 2 + 0.35, yMid + h / 2 - 0.35, 0.2, 0.25, canvas, M.Fabric)
	if title then
		local plateY = yMid - h / 2 - 0.45
		local brass = plate("PaintingPlate", along - 1.2, along + 1.2, plateY - 0.25, plateY + 0.25, 0, 0.2, C.brass, M.Metal)
		local faceId = if axis == "X" then (if side > 0 then Enum.NormalId.Back else Enum.NormalId.Front) else (if side > 0 then Enum.NormalId.Right else Enum.NormalId.Left)
		Build.label(brass, title, faceId, C.black)
	end
end

local function cobweb(f: Instance, position: Vector3, yaw: number)
	local p = piece(f, "Cobweb", Vector3.new(3, 3, 0.05), CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(0, 0, math.rad(45)), C.web, M.SmoothPlastic, true)
	p.Transparency = 0.82
end

local function candle(f: Instance, position: Vector3, lit: boolean)
	piece(f, "Candle", Vector3.new(0.25, 0.8, 0.25), CFrame.new(position + Vector3.new(0, 0.4, 0)), C.wax, M.SmoothPlastic, true)
	if lit then
		local flame = piece(f, "Flame", Vector3.new(0.12, 0.25, 0.12), CFrame.new(position + Vector3.new(0, 0.95, 0)), C.lamp, M.Neon, true)
		local light = Instance.new("PointLight")
		light.Range = 8
		light.Brightness = 0.6
		light.Color = C.lamp
		light:SetAttribute("Flicker", "bulb")
		light.Parent = flame
	end
end

local function sconce(f: Instance, axis: string, face: number, side: number, along: number, y: number, live: boolean?)
	local n = face + side * 0.3
	local x, z = if axis == "X" then along else n, if axis == "X" then n else along
	piece(f, "Sconce", Vector3.new(0.5, 0.9, 0.5), CFrame.new(x, y, z), C.brass, M.Metal, true)
	local shade = piece(f, "SconceShade", Vector3.new(0.7, 0.6, 0.7), CFrame.new(x, y + 0.75, z), if live then C.lamp else C.sheetGrey, if live then M.Neon else M.Glass, true)
	if live then
		local light = Instance.new("PointLight")
		light.Range = 14
		light.Brightness = 0.7
		light.Color = C.lamp
		light.Shadows = true
		light:SetAttribute("Flicker", "bulb")
		light.Parent = shade
	end
end

local function displayCase(f: Instance, cf: CFrame, lot: string, rng: Build.Rng)
	piece(f, "CaseBase", Vector3.new(3, 3, 4), cf * CFrame.new(0, 1.5, 0), C.walnut, M.Wood)
	local glass = piece(f, "CaseGlass", Vector3.new(3, 2.6, 4), cf * CFrame.new(0, 4.3, 0), C.glass, M.Glass)
	glass.Transparency = 0.75
	piece(f, "CaseTop", Vector3.new(3.2, 0.2, 4.2), cf * CFrame.new(0, 5.7, 0), C.walnut, M.Wood)
	piece(f, "CaseCushion", Vector3.new(2, 0.3, 2.6), cf * CFrame.new(0, 3.15, 0), C.rugRed, M.Fabric, true)
	local shapes = { Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder }
	local relic = piece(f, "Relic", Vector3.new(0.8, 0.8, 0.8), cf * CFrame.new(0, 3.75, 0) * CFrame.Angles(0, rng:number(0, 6.28), 0), Color3.fromHSV(rng:number(0, 1), 0.2, rng:number(0.3, 0.6)), M.Metal, true)
	relic.Shape = shapes[rng:integer(1, #shapes)]
	local plate = piece(f, "CaseLabel", Vector3.new(1.8, 0.5, 0.05), cf * CFrame.new(0, 2.2, -2.03), C.paper, M.SmoothPlastic, true)
	Build.label(plate, lot, Enum.NormalId.Front, C.black)
end

local function barrel(f: Instance, x: number, y: number, z: number)
	column(f, "Barrel", x, y, z, 3, 2.2, C.oak, M.WoodPlanks)
	column(f, "BarrelHoop", x, y + 0.5, z, 0.2, 2.3, C.iron, M.Metal)
	decor(column(f, "BarrelHoop", x, y + 2.3, z, 0.2, 2.3, C.iron, M.Metal))
end

------------------------------------------------------------------ hall

local function hall(f: Instance, rng: Build.Rng)
	-- Chequered marble over the boards.
	for i = 0, 9 do
		for j = 0, 11 do
			local colour = if (i + j) % 2 == 0 then C.marbleWhite else C.marbleBlack
			floorPatch(f, "FloorTile", -60 + i * 5, -55 + i * 5, -30 + j * 5, -25 + j * 5, 0, colour, M.Marble)
		end
	end
	rug(f, -47, -25, -3, 9, 0.05, C.rugRed, C.rugGold)

	-- The cold fireplace and Cornelius over it.
	box(f, "Hearth", -40, -30, 0, 0.3, -29.5, -27, C.marbleWhite, M.Marble)
	box(f, "FireplaceJamb", -40, -38.5, 0, 7, -29.5, -28, C.marbleWhite, M.Marble)
	box(f, "FireplaceJamb", -31.5, -30, 0, 7, -29.5, -28, C.marbleWhite, M.Marble)
	box(f, "Mantel", -41, -29, 7, 7.8, -29.5, -27.6, C.marbleWhite, M.Marble)
	decor(box(f, "Firebox", -38.5, -31.5, 0.3, 5.5, -29.5, -29.3, C.black, M.Slate))
	decor(box(f, "Ash", -37.5, -32.5, 0.3, 0.6, -29.2, -28.2, C.stoneDark, M.Sand))
	painting(f, "X", -29.5, 1, -35, 13, 7, 8, C.canvas, "CORNELIUS ASHGROVE")
	for _, cx in { -39.5, -30.5 } do
		candle(f, Vector3.new(cx, 7.8, -28.4), false)
	end

	chandelier(f, -35, 24, 3, 6, 3.5)

	-- The collection's cases along the west wall.
	-- Turned -90 so their labels face into the room (+X).
	displayCase(f, at(-56.5, 8, -90), "LOT 044", rng)
	displayCase(f, at(-56.5, 13.5, -90), "LOT 061", rng)
	displayCase(f, at(-56.5, -10, -90), "LOT 090", rng)
	sheeted(f, at(-55.5, -23.5, 0), Vector3.new(5, 4, 4.5), rng) -- the piano

	-- The first crew's things.
	piece(f, "Duffel", Vector3.new(2.4, 1.1, 1.2), at(-46, -2, 20, 0.55), C.fabricGreen, M.Fabric)
	piece(f, "Duffel", Vector3.new(2.2, 1, 1.1), at(-47.5, -3.4, -15, 0.5), C.black, M.Fabric)
	decor(rod(f, "Cable", Vector3.new(-28, 0.1, -10.5), Vector3.new(-32, 0.1, -4), 0.15, C.black, M.Rubber))
	decor(rod(f, "Cable", Vector3.new(-30, 0.1, -9), Vector3.new(-40, 0.1, -7), 0.12, C.black, M.Rubber))
	chair(f, at(-40, -11, 180), C.oakDark)

	-- The way in.
	column(f, "CoatStand", -57.5, 0, -5, 6.5, 0.35, C.oakDark, M.Wood)
	piece(f, "Coat", Vector3.new(1.2, 3, 0.6), at(-57.5, -5.5, 0, 4.6), C.fabricBrown, M.Fabric, true)
	box(f, "GrandfatherClock", -14, -12, 0, 7.5, -29.4, -28, C.walnut, M.Wood)
	decor(box(f, "ClockFace", -13.7, -12.3, 5.6, 6.9, -28, -27.95, C.paper, M.SmoothPlastic))

	-- The stair's banister.
	decor(rod(f, "Banister", Vector3.new(-56.2, 4, 21.7), Vector3.new(-38.6, 15, 21.7), 0.3, C.oakDark, M.Wood))
	for i = 0, 11, 2 do
		decor(rod(f, "Baluster", Vector3.new(-56.2 + i * 1.6, 1 + i, 21.7), Vector3.new(-56.2 + i * 1.6, 4 + i * (11 / 17.6) * 1.6, 21.7), 0.18, C.oakDark, M.Wood))
	end
	crateStack(f, -14, 24, 0, 3, rng)
	crateStack(f, -24, 27, 0, 1, rng)

	-- Ceiling beams.
	for x = -55, -15, 10 do
		decor(box(f, "Beam", x - 0.6, x + 0.6, 22.8, 24, -30, 30, C.oakDark, M.Wood))
	end
	for _, corner in { Vector3.new(-58.5, 22.5, -28.5), Vector3.new(-11.5, 22.5, 28.5), Vector3.new(-58.5, 22.5, 28.5) } do
		cobweb(f, corner, 45)
	end
end

------------------------------------------------------------------ gallery

local function gallery(f: Instance, rng: Build.Rng)
	rug(f, -8, 98, -21, -17, 0, C.rugGreen, C.rugGold)
	for _, cx in { 20, 50, 80 } do
		chandelier(f, cx, 20, -19, 5, 3)
	end
	for x = -4, 104, 12 do
		decor(box(f, "Beam", x - 0.5, x + 0.5, 19, 20, -30, -8, C.oakDark, M.Wood))
	end
	-- Sconces between the portraits; only the first still works, just.
	for i = 0, 8 do
		sconce(f, "X", -8.5, -1, 8 + i * 12, 10, i == 0)
	end
	-- A second row, smaller, above the portraits.
	for i, x in { 2, 26, 50, 74, 98 } do
		painting(f, "X", -8.5, -1, x, 15.5, 4, 3.4, Color3.fromHSV(rng:number(0, 1), 0.3, 0.22), if i == 3 then "LOT 114 PROVENANCE" else nil)
	end
	armchair(f, at(30, -27.6, 180), C.fabricGreen, true)
	armchair(f, at(84, -27.6, 180), C.fabricGreen, true)
	floorPatch(f, "WaterStain", 92, 98, -29.5, -26.5, 0, C.stain, M.Slate, 0.45)
	decor(box(f, "TackCasePlate", 103, 105, 2, 2.6, -22.05, -22, C.brass, M.Metal))
	for _, corner in { Vector3.new(-8.5, 18.5, -28.5), Vector3.new(108.5, 18.5, -9.5) } do
		cobweb(f, corner, -45)
	end
end

------------------------------------------------------------------ servants' wing

local function servants(f: Instance, rng: Build.Rng)
	-- Corridor: coats on hooks, dead oil lamps.
	for i = 0, 3 do
		local x = 14 + i * 1.6
		piece(f, "Hook", Vector3.new(0.2, 0.2, 0.5), CFrame.new(x, 8.2, 8.75), C.iron, M.Metal, true)
		piece(f, "Coat", Vector3.new(1.2, 3.2, 0.5), CFrame.new(x, 6.4, 9), if i % 2 == 0 then C.fabricBrown else C.black, M.Fabric, true)
	end
	for x = 25, 105, 20 do
		sconce(f, "X", 8.5, 1, x, 8, false)
	end
	column(f, "Bucket", 108.4, 0, 9.2, 1.4, 1.2, C.iron, M.Metal)

	-- Kitchen.
	for _, x in { 2, 8, 14, 19 } do
		chair(f, at(x, 17.6, 180), C.oakDark)
	end
	for _, x in { 0, 4 } do
		chair(f, at(x, 24.4, 0), C.oakDark)
	end
	box(f, "Dresser", -9.5, -8, 0, 3.5, 15, 18.5, C.walnut, M.Wood)
	box(f, "DresserRack", -9.5, -8.8, 3.5, 8, 15, 18.5, C.walnut, M.Wood)
	for row = 0, 1 do
		for i = 0, 3 do
			local plate = decor(part(f, "Plate", Vector3.new(0.1, 0.8, 0.8), CFrame.new(-8.7, 4.6 + row * 1.6, 15.6 + i * 0.85), C.white, M.SmoothPlastic))
			plate.Shape = Enum.PartType.Cylinder
		end
	end
	decor(box(f, "PotRack", 1, 19, 10.6, 10.8, 20.6, 21.4, C.iron, M.Metal))
	for x = 3, 17, 3.5 do
		decor(rod(f, "PotHook", Vector3.new(x, 10.6, 21), Vector3.new(x, 9.6, 21), 0.08, C.iron, M.Metal))
		decor(box(f, "Pot", x - 0.45, x + 0.45, 8.9, 9.6, 20.55, 21.45, C.stoneDark, M.Metal))
	end
	box(f, "Sink", 17, 23, 0, 3, 28.6, 29.5, C.stone, M.Slate)
	column(f, "StovePipe", -6, 5, 28.5, 7, 0.9, C.iron, M.Metal)
	for _, p in { Vector3.new(-7.5, 5, 26), Vector3.new(-4.5, 5, 27.5) } do
		column(f, "Pan", p.X, p.Y, p.Z, 0.6, 1.4, C.stoneDark, M.Metal)
	end
	piece(f, "Sack", Vector3.new(1.6, 2.2, 1.4), at(27.5, 16.2, 10, 1.1), C.fabricBrown, M.Fabric)
	piece(f, "Sack", Vector3.new(1.5, 1.9, 1.3), at(26.6, 27.6, -20, 0.95), C.fabricBrown, M.Fabric)
	barrel(f, 28, 0, 22)

	-- Scullery.
	piece(f, "Mangle", Vector3.new(2.5, 3.5, 2.2), at(40.2, 21.2), C.iron, M.Metal)
	decor(rod(f, "MangleRoller", Vector3.new(39, 3.3, 21.2), Vector3.new(41.4, 3.3, 21.2), 0.6, C.oak, M.Wood))
	column(f, "Bucket", 31, 0, 15, 1.4, 1.2, C.iron, M.Metal)
	decor(rod(f, "DryingLine", Vector3.new(32, 9.5, 20.6), Vector3.new(44, 9.5, 20.6), 0.08, C.black, M.Fabric))
	for x = 33, 42, 3 do
		decor(box(f, "HungSheet", x, x + 2.4, 6.4, 9.4, 20.5, 20.7, C.sheetGrey, M.Fabric))
	end
	floorPatch(f, "DrainStain", 46.5, 50.5, 16.5, 19, 0, C.stain, M.Slate, 0.5)
	box(f, "SculleryShelf", 56.5, 59.5, 6, 6.3, 20, 23, C.oak, M.Wood)
	for i = 0, 3 do
		column(f, "Jar", 57.2 + (i % 2) * 1.4, 6.3, 20.7 + math.floor(i / 2) * 1.4, 1, 0.8, C.glass, M.Glass)
	end

	-- Housekeeper's room.
	rug(f, 64, 80, 20, 27, 0, C.rugRed, C.rugGold)
	bookcase(f, at(61.4, 23.8, -90), 5.2, 8, rng)
	chair(f, at(65, 20.4, 0), C.walnut)
	armchair(f, at(70, 25.5, 200), C.fabricGreen)
	bed(f, at(79.6, 16.8, 90), 3.6, 7, C.rugRed)
	decor(box(f, "KeyBoard", 64, 67.5, 5, 7.2, 14.5, 14.7, C.oak, M.Wood))
	for i = 0, 5 do
		decor(box(f, "Key", 64.4 + i * 0.55, 64.6 + i * 0.55, 5.5, 6.3, 14.7, 14.8, C.brass, M.Metal))
	end
	painting(f, "X", 14.5, 1, 78.5, 7.5, 3.2, 4, C.canvas, "MRS DUNNE")
	candle(f, Vector3.new(66.8, 3, 16.6), false)

	-- Servants' hall.
	for _, x in { 90, 97, 104 } do
		piece(f, "Blanket", Vector3.new(4.1, 0.25, 3.4), CFrame.new(x, 2.12, 25.5), C.fabricBrown, M.Fabric, true)
		piece(f, "Pillow", Vector3.new(2.8, 0.4, 1), CFrame.new(x, 2.2, 28.6), C.sheet, M.Fabric, true)
	end
	for _, x in { 90, 104 } do
		box(f, "Footlocker", x - 1.3, x + 1.3, 0, 1.6, 22, 23.4, C.oak, M.Wood)
	end
	wardrobe(f, at(86.9, 15.8, 180))
	box(f, "Washstand", 107.5, 109.5, 0, 3, 15, 17, C.walnut, M.Wood)
	column(f, "Basin", 108.5, 3, 16, 0.4, 1.4, C.white, M.Marble)
	decor(rod(f, "ClothesLine", Vector3.new(86, 9.5, 21), Vector3.new(109, 9.5, 21), 0.06, C.black, M.Fabric))
	for x = 88, 106, 4.5 do
		decor(box(f, "HungShirt", x, x + 1.4, 7.6, 9.4, 20.9, 21.1, C.sheetGrey, M.Fabric))
	end
	cobweb(f, Vector3.new(109, 11, 29), 45)
	cobweb(f, Vector3.new(-9, 11, 29), -45)
end

------------------------------------------------------------------ vault

local function vault(f: Instance, rng: Build.Rng)
	for _, p in { Vector3.new(35, 0, 5), Vector3.new(35, 0, 18), Vector3.new(70, 0, 15) } do
		box(f, "VaultPillar", p.X - 1, p.X + 1, -16, -1, p.Z - 1, p.Z + 1, Color3.fromRGB(96, 66, 54), M.Brick)
	end
	box(f, "WineRack", 78, 79.5, -16, -8, -2, 20, C.walnut, M.Wood)
	for row = 0, 4 do
		for i = 0, 9 do
			local bottle = decor(part(f, "BottleEnd", Vector3.new(0.3, 0.6, 0.6), CFrame.new(77.9, -15 + row * 1.5, -0.8 + i * 2.1), Color3.fromRGB(30, 46, 30), M.Glass))
			bottle.Shape = Enum.PartType.Cylinder
		end
	end
	crateStack(f, 45, -2, -16, 2, rng)
	crateStack(f, 28, 8, -16, 1, rng)
	crateStack(f, 66, 22, -16, 2, rng)
	box(f, "Trunk", 48, 51.5, -16, -13.8, -19.5, -17.5, C.oakDark, M.Wood)
	box(f, "Trunk", 53, 56, -16, -14.2, -19.5, -17.8, C.walnut, M.Wood)
	for i = 0, 3 do
		decor(rod(f, "Chain", Vector3.new(56 + i * 0.6, -15.9, -12), Vector3.new(57 + i * 0.4, -15.9, -4.5), 0.2, C.iron, M.Metal))
	end
	for i = 0, 2 do
		candle(f, Vector3.new(58.4 + i * 1.6, -13, -6.4), false)
	end
	for _, cx in { 30, 42, 66, 76 } do
		floorPatch(f, "Straw", cx - 1.6, cx + 1.6, -15.6, -12.4, -16, Color3.fromRGB(150, 128, 70), M.Fabric, 0.2)
	end
	cobweb(f, Vector3.new(21, -2.5, -19), 45)
	cobweb(f, Vector3.new(79, -2.5, 29), 45)
end

------------------------------------------------------------------ exterior

-- One slope of a pitched roof. `axis` is the ridge's direction.
local function roofSlope(f: Instance, axis: string, ridgeFrom: number, ridgeTo: number, eaveAt: number, ridgeAt: number, eaveY: number, pitch: number)
	local run = math.abs(ridgeAt - eaveAt)
	local rise = run * math.tan(pitch)
	local length = run / math.cos(pitch) + 1.5
	local mid = (eaveAt + ridgeAt) / 2
	local centreY = eaveY + rise / 2 + 0.4
	local long = ridgeTo - ridgeFrom + 2
	local alongMid = (ridgeFrom + ridgeTo) / 2
	local up = if ridgeAt > eaveAt then 1 else -1
	local cf
	if axis == "X" then
		-- Slope rises along Z.
		cf = CFrame.new(alongMid, centreY, mid) * CFrame.Angles(-up * pitch, 0, 0)
		part(f, "Roof", Vector3.new(long, 0.8, length), cf, C.roof, M.RoofShingles)
	else
		-- Slope rises along X.
		cf = CFrame.new(mid, centreY, alongMid) * CFrame.Angles(0, 0, up * pitch)
		part(f, "Roof", Vector3.new(length, 0.8, long), cf, C.roof, M.RoofShingles)
	end
end

-- A crow-stepped gable on a wall plane, rising above the roof line.
local function steppedGable(f: Instance, axis: string, fixed: number, from: number, to: number, eaveY: number, pitch: number, steps: number)
	local width = to - from
	local centre = (from + to) / 2
	local height = width / 2 * math.tan(pitch)
	for k = 0, steps - 1 do
		local w = width * (1 - k / steps)
		local y1 = eaveY + k * height / steps
		local y2 = y1 + height / steps + 0.8
		if axis == "X" then
			box(f, "Gable", centre - w / 2, centre + w / 2, y1, y2, fixed - 0.6, fixed + 0.6, C.stone, M.Cobblestone)
		else
			box(f, "Gable", fixed - 0.6, fixed + 0.6, y1, y2, centre - w / 2, centre + w / 2, C.stone, M.Cobblestone)
		end
	end
end

local function chimney(f: Instance, x: number, z: number, y1: number, y2: number)
	box(f, "Chimney", x - 1.5, x + 1.5, y1, y2, z - 1.5, z + 1.5, C.stone, M.Cobblestone)
	box(f, "ChimneyCap", x - 1.9, x + 1.9, y2, y2 + 0.5, z - 1.9, z + 1.9, C.stoneDark, M.Slate)
	for _, dx in { -0.7, 0.7 } do
		column(f, "ChimneyPot", x + dx, y2 + 0.5, z, 1.4, 0.8, Color3.fromRGB(120, 70, 50), M.Brick)
	end
end

-- An upper-floor window, painted on: glass and a frame on the outer face.
local function upperWindow(f: Instance, axis: string, face: number, side: number, along: number, y1: number, y2: number, lit: boolean?)
	local n1, n2 = face, face + side * 0.2
	if n1 > n2 then
		n1, n2 = n2, n1
	end
	local function plate(name: string, a1: number, a2: number, b1: number, b2: number, colour: Color3, material: Enum.Material): Part
		if axis == "X" then
			return decor(box(f, name, a1, a2, b1, b2, n1, n2, colour, material)) :: Part
		end
		return decor(box(f, name, n1, n2, b1, b2, a1, a2, colour, material)) :: Part
	end
	plate("UpperWindowFrame", along - 2, along + 2, y1 - 0.3, y2 + 0.3, C.oakDark, M.Wood)
	local pane = plate("UpperWindow", along - 1.6, along + 1.6, y1, y2, if lit then Color3.fromRGB(150, 110, 60) else Color3.fromRGB(24, 28, 34), if lit then M.Neon else M.Glass)
	if lit then
		pane.Transparency = 0.35
		local light = Instance.new("PointLight")
		light.Range = 12
		light.Brightness = 0.9
		light.Color = Color3.fromRGB(255, 190, 120)
		light:SetAttribute("Flicker", "window")
		light.Parent = pane
	end
end

local function deadTree(f: Instance, x: number, z: number, rng: Build.Rng)
	local height = rng:number(14, 22)
	column(f, "TreeTrunk", x, 0, z, height, rng:number(1.4, 2.2), C.bark, M.Wood)
	for _ = 1, rng:integer(4, 6) do
		local h = height * rng:number(0.5, 0.95)
		local a = rng:number(0, math.pi * 2)
		local reach = rng:number(3, 7)
		local base = Vector3.new(x, h, z)
		local tip = base + Vector3.new(math.cos(a) * reach, rng:number(2, 5), math.sin(a) * reach)
		decor(rod(f, "Branch", base, tip, rng:number(0.35, 0.6), C.bark, M.Wood))
		local twig = tip + Vector3.new(math.cos(a + 0.6) * 2.5, rng:number(1, 2.5), math.sin(a + 0.6) * 2.5)
		decor(rod(f, "Twig", tip, twig, 0.2, C.bark, M.Wood))
	end
end

local function exterior(f: Instance, interact: Instance, rng: Build.Rng)
	local pitch = math.rad(35)
	local eave = 26

	-- The upper storey: walls up to the eaves, windows on the outside.
	box(f, "UpperHall", -60.5, -59.5, 24, eave, -30.5, 30.5, C.stone, M.Cobblestone)
	box(f, "UpperHall", -60.5, -9.5, 24, eave, -30.5, -29.5, C.stone, M.Cobblestone)
	box(f, "UpperHall", -60.5, -9.5, 24, eave, 29.5, 30.5, C.stone, M.Cobblestone)
	box(f, "UpperHall", -10.5, -9.5, 24, eave, -30.5, 30.5, C.stone, M.Cobblestone)
	box(f, "UpperGallery", -10, 110.5, 20, eave, -30.5, -29.5, C.stone, M.Cobblestone)
	box(f, "UpperGallery", -10, 110.5, 20, eave, -8.5, -7.5, C.stone, M.Cobblestone)
	box(f, "UpperGallery", 109.5, 110.5, 20, eave, -30.5, -7.5, C.stone, M.Cobblestone)
	box(f, "UpperWing", -10, 110.5, 12, eave, 29.5, 30.5, C.stone, M.Cobblestone)
	box(f, "UpperWing", -10, 110.5, 12, eave, 7.5, 8.5, C.stone, M.Cobblestone)
	box(f, "UpperWing", 109.5, 110.5, 12, eave, 7.5, 30.5, C.stone, M.Cobblestone)
	for x = 0, 100, 14 do
		upperWindow(f, "X", 30.5, 1, x, 16, 21, x == 70) -- someone's up there
		upperWindow(f, "X", -30.5, -1, x + 7, 21.5, 25)
	end
	for _, z in { -18, -6, 6, 18 } do
		upperWindow(f, "Z", -60.5, -1, z, 15, 21)
	end

	-- Roofs.
	roofSlope(f, "X", -10, 110, -30.5, -19, eave, pitch)
	roofSlope(f, "X", -10, 110, -7.5, -19, eave, pitch)
	roofSlope(f, "X", -10, 110, 7.5, 19, eave, pitch)
	roofSlope(f, "X", -10, 110, 30.5, 19, eave, pitch)
	roofSlope(f, "Z", -30.5, 30.5, -60.5, -35, eave, pitch)
	roofSlope(f, "Z", -30.5, 30.5, -9.5, -35, eave, pitch)
	steppedGable(f, "Z", 110.5, -30.5, -7.5, eave, pitch, 5)
	steppedGable(f, "Z", 110.5, 7.5, 30.5, eave, pitch, 5)
	steppedGable(f, "X", -30.5, -60.5, -9.5, eave, pitch, 7)
	steppedGable(f, "X", 30.5, -60.5, -9.5, eave, pitch, 7)
	chimney(f, -50, -18, 26, 46)
	chimney(f, -20, 18, 26, 46)
	chimney(f, -6, 27, 26, 36) -- the kitchen range
	chimney(f, 104, -12, 26, 34)

	-- The porch.
	for _, z in { -5.5, 5.5 } do
		column(f, "PorchColumn", -67, 0, z, 13, 1.6, C.limestone, M.Limestone)
	end
	box(f, "PorchRoof", -70, -60.5, 13, 14, -7.5, 7.5, C.stone, M.Cobblestone)
	box(f, "PorchPediment", -70, -60.5, 14, 15.5, -6.5, 6.5, C.stone, M.Cobblestone)
	box(f, "PorchStep", -66, -60.5, 0, 0.3, -5, 5, C.limestone, M.Limestone).CanCollide = false
	for _, z in { -4.8, 4.8 } do
		piece(f, "DoorLantern", Vector3.new(0.8, 1.4, 0.8), CFrame.new(-61.1, 9, z), C.iron, M.Metal, true)
	end

	-- The drive: gravel, a turning circle, a dead fountain.
	local circle = decor(column(f, "TurningCircle", -92, 0, 0, 0.12, 34, Color3.fromRGB(78, 76, 72), M.Pebble))
	circle.CFrame = CFrame.new(-92, 0.06, 0) * CFrame.Angles(0, 0, math.rad(90))
	column(f, "FountainBasin", -92, 0, -27, 1.6, 10, C.limestone, M.Limestone)
	column(f, "FountainStem", -92, 1.6, -27, 4, 1.2, C.limestone, M.Limestone)
	column(f, "FountainBowl", -92, 5.6, -27, 0.6, 4, C.limestone, M.Limestone)
	decor(column(f, "FountainWater", -92, 1.3, -27, 0.2, 9, Color3.fromRGB(26, 34, 30), M.Glass))

	-- Gate piers and railings across the drive.
	for _, z in { -8, 8 } do
		box(f, "GatePier", -109.5, -106.5, 0, 7.5, z - 1.5, z + 1.5, C.stone, M.Cobblestone)
		local ball = part(f, "PierBall", Vector3.one * 2, CFrame.new(-108, 8.5, z), C.limestone, M.Limestone)
		ball.Shape = Enum.PartType.Ball
	end
	for _, side in { -1, 1 } do
		local z1, z2 = side * 9.5, side * 90
		local lo, hi = math.min(z1, z2), math.max(z1, z2)
		local fence = Build.invisible(box(f, "FenceCollider", -108.3, -107.7, 0, 7, lo, hi, C.black))
		fence.CanCollide = true
		decor(box(f, "FenceRail", -108.1, -107.9, 1, 1.2, lo, hi, C.iron, M.Metal))
		decor(box(f, "FenceRail", -108.1, -107.9, 5.6, 5.8, lo, hi, C.iron, M.Metal))
		for z = lo, hi, 2.5 do
			decor(box(f, "FencePost", -108.15, -107.85, 0, 6.4, z - 0.12, z + 0.12, C.iron, M.Metal))
		end
	end
	for _, side in { -1, 1 } do
		local z = side * 11
		box(f, "Hedge", -104, -76, 0, 4.5, z - 1, z + 1, C.hedge, M.LeafyGrass)
	end

	-- Dead trees.
	for _, p in {
		{ -200, -60 }, { -180, 40 }, { -230, -120 }, { -170, 110 }, { -260, 30 }, { -140, -80 },
		{ -150, 70 }, { -210, 160 }, { -120, -140 }, { -40, -80 }, { 10, -60 }, { 60, -95 },
		{ -30, 70 }, { 30, 62 }, { 80, 90 }, { -90, 60 }, { -78, -62 }, { 95, 48 },
	} do
		deadTree(f, p[1], p[2], rng)
	end

	-- The family plot by the cliff, and one grave dug and left open.
	for i = 0, 9 do
		local gx = 112 + (i % 5) * 3.4
		local gz = -72 + math.floor(i / 5) * 9
		local stone = part(f, "Headstone", Vector3.new(2.2, 3, 0.5), CFrame.new(gx, 1.3, gz) * CFrame.Angles(math.rad(rng:number(-9, 9)), 0, math.rad(rng:number(-6, 6))), C.limestone, M.Limestone)
		if i == 2 then
			Build.label(decor(part(f, "Epitaph", Vector3.new(1.8, 1.4, 0.05), stone.CFrame * CFrame.new(0, 0.3, 0.28), C.limestone, M.Limestone)), "ASHGROVE", Enum.NormalId.Back, C.black)
		end
	end
	box(f, "OpenGrave", 113, 117, -0.6, 0.02, -52, -50, C.black, M.Mud).CanCollide = false
	box(f, "SpoilHeap", 117.5, 120, 0, 1.4, -53, -49, C.earth, M.Mud)
	decor(rod(f, "Spade", Vector3.new(118.5, 0, -48.5), Vector3.new(119.2, 4.5, -48.2), 0.2, C.oak, M.Wood))
	local chit = part(interact:FindFirstChild("Notes") :: Instance, "Grave_Receipt", Vector3.new(1, 0.05, 1.4), CFrame.new(118.9, 3, -48.1) * CFrame.Angles(math.rad(80), 0, 0), C.paper)
	chit:SetAttribute("NoteId", "Grave_Receipt")
	for z = -78, -42, 3 do
		decor(box(f, "PlotRailing", 109, 109.2, 0, 3, z - 0.1, z + 0.1, C.iron, M.Metal))
	end
	decor(box(f, "PlotRail", 109, 109.2, 2.6, 2.8, -78, -42, C.iron, M.Metal))

	-- The cliff stair down to the boathouse: Story 2. Chained for now.
	box(f, "CliffArchPier", 123, 125, 0, 9, -89, -87, C.stone, M.Cobblestone)
	box(f, "CliffArchPier", 123, 125, 0, 9, -82, -80, C.stone, M.Cobblestone)
	box(f, "CliffArchTop", 123, 125, 9, 11, -89, -80, C.stone, M.Cobblestone)
	local gate = box(interact:FindFirstChild("Doors") :: Instance, "CliffStairGate", 123.7, 124.3, 0, 9, -87, -82, C.iron, M.Metal)
	gate:SetAttribute("DoorId", "CliffStairGate")
	gate:SetAttribute("StartsLocked", true)
	gate:SetAttribute("LockedText", "The cliff stair down to the boathouse. Chained, and the chain is wet.")

	-- Rocks at the foot of the cliff.
	for _ = 1, 26 do
		local s = rng:number(6, 16)
		part(f, "Rock", Vector3.new(s, s * rng:number(0.5, 1), s * rng:number(0.7, 1.2)), CFrame.new(rng:number(133, 160), rng:number(-126, -118), rng:number(-280, 280)) * CFrame.Angles(rng:number(0, 1), rng:number(0, 6), rng:number(0, 1)), C.stoneDark, M.Basalt)
	end

	-- A lighthouse out at sea, its beam going round.
	local lx, lz = 330, -200
	box(f, "LighthouseRock", lx - 20, lx + 20, -130, -112, lz - 20, lz + 20, C.stoneDark, M.Basalt)
	column(f, "Lighthouse", lx, -112, lz, 70, 14, C.white, M.Concrete)
	for i = 0, 2 do
		decor(column(f, "LighthouseBand", lx, -100 + i * 20, lz, 5, 14.3, C.red, M.Concrete))
	end
	column(f, "LighthouseGallery", lx, -42, lz, 1, 18, C.iron, M.Metal)
	local lamp = column(f, "LighthouseLamp", lx, -41, lz, 6, 9, C.lamp, M.Neon)
	local lampLight = Instance.new("PointLight")
	lampLight.Range = 60
	lampLight.Brightness = 2
	lampLight.Color = C.lamp
	lampLight.Parent = lamp
	column(f, "LighthouseCap", lx, -35, lz, 3, 11, C.iron, M.Metal)
	local beam = decor(part(f, "LighthouseBeam", Vector3.new(4, 4, 360), CFrame.new(lx, -38, lz) * CFrame.new(0, 0, -180), C.lamp, M.Neon))
	beam.Transparency = 0.86
	beam:SetAttribute("Spin", true)
	beam:SetAttribute("SpinCentre", Vector3.new(lx, -38, lz))
end

------------------------------------------------------------------ entry

function Dressing.dress(root: Model)
	local geo = root:FindFirstChild("Geometry") :: Instance
	local interact = root:FindFirstChild("Interact") :: Instance
	local rng = Build.random(1907)
	hall(Build.folder(geo, "HallDressing"), rng)
	gallery(Build.folder(geo, "GalleryDressing"), rng)
	servants(Build.folder(geo, "ServantsDressing"), rng)
	vault(Build.folder(geo, "VaultDressing"), rng)
	exterior(Build.folder(geo, "Exterior"), interact, rng)
end

return Dressing
