--[[
	Build: small part-making helpers shared by House (layout) and Dressing
	(furniture and detail). Everything is anchored and smooth-surfaced.
]]

local Build = {}

function Build.part(parent: Instance, name: string, size: Vector3, cf: CFrame, colour: Color3, material: Enum.Material?): Part
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

-- Axis-aligned box from two corners.
function Build.box(parent: Instance, name: string, x1: number, x2: number, y1: number, y2: number, z1: number, z2: number, colour: Color3, material: Enum.Material?): Part
	local size = Vector3.new(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1))
	local centre = Vector3.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)
	return Build.part(parent, name, size, CFrame.new(centre), colour, material)
end

-- A vertical cylinder standing on (x, y, z).
function Build.column(parent: Instance, name: string, x: number, y: number, z: number, height: number, diameter: number, colour: Color3, material: Enum.Material?): Part
	local p = Build.part(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(x, y + height / 2, z) * CFrame.Angles(0, 0, math.rad(90)), colour, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- A cylinder between two points (branches, chains, rails).
function Build.rod(parent: Instance, name: string, a: Vector3, b: Vector3, diameter: number, colour: Color3, material: Enum.Material?): Part
	local length = (b - a).Magnitude
	local dir = (b - a).Unit
	-- lookAt can't use "up" as its up vector when the rod is vertical.
	local upVector = if math.abs(dir.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	-- Cylinders run along X: aim X along a->b.
	local cf = CFrame.lookAt((a + b) / 2, b, upVector) * CFrame.Angles(0, math.rad(90), 0)
	local p = Build.part(parent, name, Vector3.new(length, diameter, diameter), cf, colour, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Cosmetic only: no collisions, invisible to raycasts.
function Build.decor(p: BasePart): BasePart
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

function Build.invisible(p: BasePart): BasePart
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

function Build.folder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function Build.attributes(inst: Instance, attrs: { [string]: any }?)
	if attrs then
		for k, v in attrs do
			inst:SetAttribute(k, v)
		end
	end
end

function Build.label(p: BasePart, text: string, face: Enum.NormalId, colour: Color3?, font: Enum.Font?)
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
	t.Font = font or Enum.Font.Garamond
	t.TextColor3 = colour or Color3.fromRGB(218, 210, 188)
	t.Parent = gui
	gui.Parent = p
end

export type Rng = {
	number: (self: Rng, min: number, max: number) -> number,
	integer: (self: Rng, min: number, max: number) -> number,
}

-- Deterministic random numbers, so the dressing comes out the same every
-- build (nothing jumps around between edits). A small LCG, so it runs the
-- same outside Roblox too (the offline checks).
function Build.random(seed: number): Rng
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	local function nextUnit(): number
		state = (state * 48271) % 2147483647
		return state / 2147483647
	end
	return {
		number = function(_self, min: number, max: number): number
			return min + (max - min) * nextUnit()
		end,
		integer = function(_self, min: number, max: number): number
			return math.min(max, min + math.floor((max - min + 1) * nextUnit()))
		end,
	} :: any
end

return Build
