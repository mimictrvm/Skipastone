--[[
	Effect building blocks shared by every scene. All of them are built from
	primitives and Roblox's built-in particle textures, so no uploads are
	needed. Call them from inside ctx:at events; they start at ctx.t.
]]

local TweenService = game:GetService("TweenService")

local Fx = {}

Fx.SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
Fx.SMOKE = "rbxasset://textures/particles/smoke_main.dds"
Fx.FIRE = "rbxasset://textures/particles/fire_main.dds"

function Fx.ease(a: number, style: Enum.EasingStyle, dir: Enum.EasingDirection?): number
	return TweenService:GetValue(a, style, dir or Enum.EasingDirection.Out)
end

function Fx.bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	local u = 1 - t
	return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t)
end

-- Expanding ring on the plane of `cf` (its up vector is the ring's normal).
function Fx.ring(ctx, cf: CFrame, color: Color3, r0: number, r1: number, dur: number, thickness: number?, segments: number?)
	local n = segments or 32
	local thick = thickness or 0.3
	local segs = {}
	for i = 1, n do
		segs[i] = ctx:part({ Material = Enum.Material.Neon, Color = color, Transparency = 0.1 })
	end
	ctx:during(ctx.t, dur, function(a)
		local r = r0 + (r1 - r0) * Fx.ease(a, Enum.EasingStyle.Quad)
		local segLen = 2 * math.pi * r / n * 1.08
		local transparency = 0.1 + 0.9 * Fx.ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for i, p in segs do
			p.Size = Vector3.new(segLen, 0.12, thick)
			p.CFrame = cf * CFrame.Angles(0, (i / n) * math.pi * 2, 0) * CFrame.new(0, 0, -r)
			p.Transparency = transparency
		end
		if a >= 1 then
			for _, p in segs do
				p:Destroy()
			end
		end
	end)
end

-- Empty placeholder model with an unrotated, invisible root as its
-- PrimaryPart, so "facing" is always the model's -Z regardless of how the
-- visible parts are turned. Returns the model and an add(part) function.
function Fx.newModel(ctx, name: string): (Model, (BasePart) -> BasePart)
	local model = Instance.new("Model")
	model.Name = name
	local root = ctx:part({ Transparency = 1, Size = Vector3.one * 0.2 })
	root.Name = "Root"
	root.Parent = model
	model.PrimaryPart = root
	return model, function(p: BasePart): BasePart
		p.Parent = model
		return p
	end
end

-- Invisible part to hang lights, emitters and trails from.
function Fx.anchor(ctx, cf: CFrame): Part
	return ctx:part({ Transparency = 1, Size = Vector3.one * 0.2, CFrame = cf })
end

function Fx.light(parent: Instance, color: Color3, range: number, brightness: number): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
	return l
end

-- Neon sphere with its own light.
function Fx.glow(ctx, cf: CFrame, size: number, color: Color3, range: number, brightness: number): (Part, PointLight)
	local p = ctx:part({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * size,
		Material = Enum.Material.Neon,
		Color = color,
		CFrame = cf,
	})
	return p, Fx.light(p, color, range, brightness)
end

function Fx.emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = Fx.SPARKLE
	e.LightEmission = 1
	e.Rate = 0
	e.LockedToPart = false
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- Cylinder whose ends sit on `from` and `to`.
function Fx.stretch(p: BasePart, from: Vector3, to: Vector3, radius: number)
	local len = math.max((to - from).Magnitude, 0.05)
	p.Size = Vector3.new(len, radius * 2, radius * 2)
	if (to - from).Magnitude < 1e-3 then
		p.CFrame = CFrame.new(from)
	else
		p.CFrame = CFrame.lookAt((from + to) / 2, to) * CFrame.Angles(0, math.rad(90), 0)
	end
end

function Fx.column(ctx, from: Vector3, to: Vector3, radius: number, color: Color3, transparency: number): Part
	local p = ctx:part({
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = transparency,
	})
	Fx.stretch(p, from, to, radius)
	return p
end

function Fx.parts(inst: Instance): { BasePart }
	local out = {}
	if inst:IsA("BasePart") then
		table.insert(out, inst)
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end

-- Fades a model (or part) toward invisible. amount 0 = its own look, 1 = gone.
-- Each part keeps its original transparency as the "fully visible" value.
function Fx.fade(ctx, inst: Instance, amount: number, dur: number)
	for _, p in Fx.parts(inst) do
		local base = p:GetAttribute("CutsceneBaseT")
		if base == nil then
			base = p.Transparency
			p:SetAttribute("CutsceneBaseT", base)
		end
		ctx:tween(p, dur, { Transparency = base + (1 - base) * amount })
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("Decal") or d:IsA("Texture") then
			ctx:tween(d, dur, { Transparency = amount })
		end
	end
end

function Fx.hide(inst: Instance)
	for _, p in Fx.parts(inst) do
		if p:GetAttribute("CutsceneBaseT") == nil then
			p:SetAttribute("CutsceneBaseT", p.Transparency)
		end
		p.Transparency = 1
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("Decal") or d:IsA("Texture") then
			d.Transparency = 1
		end
	end
end

function Fx.highlight(target: Instance, fill: Color3, fillT: number, outline: Color3, outlineT: number): Highlight
	local h = Instance.new("Highlight")
	h.FillColor = fill
	h.FillTransparency = fillT
	h.OutlineColor = outline
	h.OutlineTransparency = outlineT
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = target
	h.Parent = target
	return h
end

-- Trail hanging off a part; move the part and the trail follows.
function Fx.trail(part: BasePart, color: Color3, width: number, lifetime: number): Trail
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, width / 2, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -width / 2, 0)
	a1.Parent = part
	local t = Instance.new("Trail")
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(color)
	t.LightEmission = 1
	t.Lifetime = lifetime
	t.FaceCamera = true
	t.Transparency = NumberSequence.new(0, 1)
	t.WidthScale = NumberSequence.new(1, 0)
	t.Parent = part
	return t
end

type DebrisOpts = {
	count: number,
	size: NumberRange,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	speed: NumberRange,
	up: NumberRange,
	life: number,
	gravity: number?,
}

-- Anchored chunks thrown outward on a ballistic arc (no physics, so they
-- behave the same on every device).
function Fx.debris(ctx, center: Vector3, opts: DebrisOpts)
	local rng = Random.new()
	local chunks = {}
	for _ = 1, opts.count do
		local s = rng:NextNumber(opts.size.Min, opts.size.Max)
		local p = ctx:part({
			Size = Vector3.new(s, s * rng:NextNumber(0.4, 1), s * rng:NextNumber(0.6, 1.2)),
			Color = opts.color,
			Material = opts.material or Enum.Material.Ice,
			Transparency = opts.transparency or 0,
		})
		local dir = rng:NextUnitVector() * Vector3.new(1, 0, 1)
		dir = if dir.Magnitude > 1e-3 then dir.Unit else Vector3.xAxis
		table.insert(chunks, {
			part = p,
			pos = center + dir * rng:NextNumber(0, s),
			vel = dir * rng:NextNumber(opts.speed.Min, opts.speed.Max) + Vector3.yAxis * rng:NextNumber(opts.up.Min, opts.up.Max),
			spin = rng:NextUnitVector() * rng:NextNumber(4, 12),
			rot = CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), 0),
			base = opts.transparency or 0,
		})
	end
	local g = opts.gravity or 70
	ctx:during(ctx.t, opts.life, function(a, _, dt)
		for _, c in chunks do
			c.vel -= Vector3.yAxis * g * dt
			c.pos += c.vel * dt
			c.rot = c.rot * CFrame.Angles(c.spin.X * dt, c.spin.Y * dt, c.spin.Z * dt)
			c.part.CFrame = CFrame.new(c.pos) * c.rot
			c.part.Transparency = c.base + (1 - c.base) * math.clamp((a - 0.6) / 0.4, 0, 1)
		end
		if a >= 1 then
			for _, c in chunks do
				c.part:Destroy()
			end
		end
	end)
end

-- Returns place(cf), which puts the model's bounding-box centre on cf.
-- Cheap enough to call every frame to fly a model along a path.
function Fx.mover(model: Model): (CFrame) -> ()
	local boxCf = model:GetBoundingBox()
	local pivotFromBox = boxCf:ToObjectSpace(model:GetPivot())
	return function(cf: CFrame)
		model:PivotTo(cf * pivotFromBox)
	end
end

-- Turns a scene-space CFrame around so a model placed there faces the player.
Fx.FACE_PLAYER = CFrame.Angles(0, math.pi, 0)

return Fx
