--[[
	Rigs: greybox bodies for the entities, built from blocks so the game
	runs before the art team's models exist.

	REPLACING WITH ART: keep the contract, not the blocks.
	  - Killable entities: a Model with a Humanoid and an unrotated,
	    invisible "HumanoidRootPart" whose -Z is the facing. Every part a
	    bullet can hit carries a Hitbox attribute ("Head" or "Body").
	  - Dullahan: the carried head is a separate part named "CarriedHead",
	    held by a Weld (not a WeldConstraint) whose C0 the AI turns.
	  - Banshee: a Model with an invisible "Root" at her feet and a part
	    named "Face". Anchored, no collisions; she never walks.
	Sizes follow the art brief (studs; a player is about 5.5 tall).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Config"))

local Rigs = {}

local function newRig(name: string, rootSize: Vector3, hipHeight: number): (Model, Part, Humanoid)
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = rootSize
	root.Transparency = 1
	root.CanCollide = true
	root.CFrame = CFrame.new(0, hipHeight + rootSize.Y / 2, 0)
	root:SetAttribute("Hitbox", "Body")
	root.Parent = model
	model.PrimaryPart = root

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = hipHeight
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false -- greybox rigs have no neck joint
	humanoid.MaxHealth = 1e6
	humanoid.Health = 1e6
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.WalkSpeed = 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid.Parent = model
	return model, root, humanoid
end

-- A part welded rigidly to the root, placed at root * offset.
local function limb(model: Model, root: BasePart, name: string, size: Vector3, offset: CFrame, colour: Color3, material: Enum.Material?, hitbox: string?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = root.CFrame * offset
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if hitbox then
		p:SetAttribute("Hitbox", hitbox)
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
	p.Parent = model
	return p
end

Rigs.DULLAHAN_HEAD_OFFSET = Vector3.new(1.9, 1.7, -1.7)

-- Tall, headless, coated. Carries a glowing head in the right hand and a
-- whip of spine in the left. About 7.9 studs to the shoulders.
function Rigs.dullahan(): (Model, Part, Humanoid, { head: Part, headWeld: Weld })
	local model, root, humanoid = newRig("Dullahan", Vector3.new(2, 2, 1), 2.5)
	local coat = Color3.fromRGB(28, 26, 28)
	local cloth = Color3.fromRGB(46, 42, 40)
	limb(model, root, "LegL", Vector3.new(1.2, 3.6, 1.2), CFrame.new(-0.75, -1.7, 0), cloth, nil, "Body")
	limb(model, root, "LegR", Vector3.new(1.2, 3.6, 1.2), CFrame.new(0.75, -1.7, 0), cloth, nil, "Body")
	limb(model, root, "Torso", Vector3.new(3, 3.6, 1.6), CFrame.new(0, 1.9, 0), cloth, nil, "Body")
	limb(model, root, "Coat", Vector3.new(3.4, 4.6, 1.9), CFrame.new(0, 1.1, 0.2), coat, Enum.Material.Fabric, "Body")
	limb(model, root, "Neck", Vector3.new(1.1, 0.4, 1.1), CFrame.new(0, 3.9, 0), Color3.fromRGB(70, 30, 26), nil, "Body")
	limb(model, root, "ArmL", Vector3.new(0.9, 3.4, 0.9), CFrame.new(-2, 1.7, 0), cloth, nil, "Body")
	limb(model, root, "ArmR", Vector3.new(0.9, 3, 0.9), CFrame.new(2, 2.6, -0.8) * CFrame.Angles(math.rad(-60), 0, 0), cloth, nil, "Body")
	limb(model, root, "Whip", Vector3.new(0.25, 4.2, 0.25), CFrame.new(-2.1, -1.9, -0.3), Color3.fromRGB(206, 196, 168), nil, "Body")

	local head = Instance.new("Part")
	head.Name = "CarriedHead"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.one * 1.6
	head.Color = Color3.fromRGB(188, 176, 148)
	head.CanCollide = false
	head.Massless = true
	head:SetAttribute("Hitbox", "Head")
	head.CFrame = root.CFrame * CFrame.new(Rigs.DULLAHAN_HEAD_OFFSET)
	for _, side in { -0.3, 0.3 } do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.one * 0.25
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.fromRGB(255, 240, 190)
		eye.CanCollide = false
		eye.Massless = true
		eye:SetAttribute("Hitbox", "Head")
		eye.CFrame = head.CFrame * CFrame.new(side, 0.15, -0.72)
		local w = Instance.new("WeldConstraint")
		w.Part0 = head
		w.Part1 = eye
		w.Parent = eye
		eye.Parent = head
	end
	local grin = Instance.new("Part")
	grin.Name = "Grin"
	grin.Size = Vector3.new(0.8, 0.1, 0.1)
	grin.Color = Color3.fromRGB(20, 12, 10)
	grin.CanCollide = false
	grin.Massless = true
	grin:SetAttribute("Hitbox", "Head")
	grin.CFrame = head.CFrame * CFrame.new(0, -0.35, -0.7)
	local gw = Instance.new("WeldConstraint")
	gw.Part0 = head
	gw.Part1 = grin
	gw.Parent = grin
	grin.Parent = head
	local glow = Instance.new("PointLight")
	glow.Range = Config.entities.Dullahan.headGlowRadius
	glow.Brightness = 1.2
	glow.Color = Color3.fromRGB(255, 226, 170)
	glow.Parent = head

	local headWeld = Instance.new("Weld")
	headWeld.Name = "HeadWeld"
	headWeld.Part0 = root
	headWeld.Part1 = head
	headWeld.C0 = CFrame.new(Rigs.DULLAHAN_HEAD_OFFSET)
	headWeld.Parent = head
	head.Parent = model

	return model, root, humanoid, { head = head, headWeld = headWeld }
end

-- PLACEHOLDER minor entity (decision #1): a low, pale crawler.
function Rigs.lampshy(): (Model, Part, Humanoid)
	local model, root, humanoid = newRig("Lampshy", Vector3.new(2, 1.4, 3), 0.3)
	local skin = Color3.fromRGB(200, 196, 186)
	limb(model, root, "Body", Vector3.new(1.8, 1.1, 3.6), CFrame.new(0, 0.1, 0), skin, nil, "Body")
	limb(model, root, "Head", Vector3.new(1.2, 0.9, 1.3), CFrame.new(0, 0.25, -2.3), skin, nil, "Body")
	limb(model, root, "Mouth", Vector3.new(0.8, 0.12, 0.05), CFrame.new(0, 0.1, -2.96), Color3.fromRGB(16, 10, 10), nil, "Body")
	for _, leg in {
		{ -1.3, -1.2, 35 },
		{ 1.3, -1.2, -35 },
		{ -1.3, 1.2, -35 },
		{ 1.3, 1.2, 35 },
	} do
		limb(model, root, "Leg", Vector3.new(0.3, 0.3, 2.4), CFrame.new(leg[1], -0.3, leg[2]) * CFrame.Angles(0, math.rad(leg[3]), math.rad(if leg[1] < 0 then 25 else -25)), skin, nil, "Body")
	end
	return model, root, humanoid
end

-- The Banshee: tall, still, robed in her reserved colour. Anchored; she
-- appears and disappears, she never walks.
function Rigs.banshee(): Model
	local model = Instance.new("Model")
	model.Name = "Banshee"
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Anchored = true
	root.Transparency = 1
	root.Size = Vector3.one * 0.5
	root.CFrame = CFrame.new(0, 0, 0)
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Parent = model
	model.PrimaryPart = root

	local colour = Config.banshee.colour
	local function add(name: string, size: Vector3, cf: CFrame, c: Color3, material: Enum.Material?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = c
		p.Material = material or Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p:SetAttribute("BaseTransparency", 0)
		p.Parent = model
		return p
	end
	add("Hem", Vector3.new(3.4, 1.2, 2.2), CFrame.new(0, 0.6, 0), colour, Enum.Material.Fabric)
	add("Robe", Vector3.new(2.8, 5.8, 1.8), CFrame.new(0, 3.5, 0), colour, Enum.Material.Fabric)
	add("Chest", Vector3.new(2.2, 2.4, 1.3), CFrame.new(0, 7.4, 0), colour, Enum.Material.Fabric)
	add("ArmL", Vector3.new(0.6, 3.2, 0.6), CFrame.new(-1.4, 6.6, -0.2) * CFrame.Angles(0, 0, math.rad(-8)), colour, Enum.Material.Fabric)
	add("ArmR", Vector3.new(0.6, 3.2, 0.6), CFrame.new(1.4, 6.6, -0.2) * CFrame.Angles(0, 0, math.rad(8)), colour, Enum.Material.Fabric)
	local pale = Color3.fromRGB(206, 206, 198)
	add("Face", Vector3.new(1.1, 1.35, 1.1), CFrame.new(0, 9.3, 0), pale)
	local dark = Color3.fromRGB(10, 10, 12)
	add("EyeL", Vector3.new(0.22, 0.14, 0.05), CFrame.new(-0.25, 9.5, -0.56), dark)
	add("EyeR", Vector3.new(0.22, 0.14, 0.05), CFrame.new(0.25, 9.5, -0.56), dark)
	add("Mouth", Vector3.new(0.3, 0.45, 0.05), CFrame.new(0, 8.95, -0.56), dark)
	local hair = Color3.fromRGB(206, 210, 204)
	add("HairBack", Vector3.new(1.3, 4.4, 0.4), CFrame.new(0, 7.8, 0.6), hair, Enum.Material.Fabric)
	add("HairL", Vector3.new(0.3, 3.6, 0.9), CFrame.new(-0.65, 8.2, -0.05), hair, Enum.Material.Fabric)
	add("HairR", Vector3.new(0.3, 3.6, 0.9), CFrame.new(0.65, 8.2, -0.05), hair, Enum.Material.Fabric)
	local light = Instance.new("PointLight")
	light.Color = colour
	light.Range = 12
	light.Brightness = 0.7
	light.Parent = model:FindFirstChild("Chest")
	return model
end

return Rigs
