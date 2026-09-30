--[[
	KOI SPIRIT  -  Lily Pad Zone  -  "THE KOI SPIRIT AWAKENS"   (~6.9 s)

	Palette  deep teal / warm spirit-white / lotus pink
	Focal    the koi's glow beneath the surface

	The gentlest scene in the set, to suit the lily pads: its hit is a
	tinted half-flash and a light shake, and its rhythm is three chimes.

	0.00  FREEZE    camera lifts to look down on the stone
	0.35            stone tap
	0.50            music bed (plucked strings / flute)
	0.80  BUILD     ring 1 of lily pads blooms  - chime (stir, pitch 1.00)
	1.30            ring 2 blooms               - chime (stir, pitch 1.12)
	1.80            ring 3 blooms               - chime (stir, pitch 1.26)
	1.00            a glow circles upward under the water; camera orbits down
	1.40            rising shimmer (rise)
	3.15  BREATH    music thins out; the koi hangs just under the surface
	3.50  HIT       koi breaches: splash, petals, soft flash (strike)
	4.10  TITLE     koi circles in the air above the pads
	5.90  RETURN
]]

local Fx = require(script.Parent.Parent.Fx)

local Scene = {
	titleAt = 4.1,
	returnAt = 5.9,
}

local HIT = 3.5
local HOVER_Y = 7
local HOVER_R = 1.2

function Scene.placeholder(ctx): Model
	local model, add = Fx.newModel(ctx, "KoiPlaceholder")
	local function blob(size: Vector3, cf: CFrame, color: Color3, transparency: number?)
		local p = add(ctx:part({ Size = size, CFrame = cf, Color = color, Material = Enum.Material.Neon, Transparency = transparency or 0 }))
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	local white = ctx.palette.glow
	local pink = ctx.palette.accent
	blob(Vector3.new(1.4, 1.2, 3.4), CFrame.new(0, 0, 0), white)
	blob(Vector3.new(0.9, 0.5, 1.4), CFrame.new(0.15, 0.45, -0.5), pink)
	blob(Vector3.new(0.7, 0.4, 0.9), CFrame.new(-0.2, 0.42, 0.7), pink)
	blob(Vector3.new(0.12, 1.6, 1.3), CFrame.new(0, 0, 2.1), white, 0.25)
	blob(Vector3.new(0.9, 0.1, 0.7), CFrame.new(0.8, -0.3, -0.4) * CFrame.Angles(0, 0, math.rad(-25)), white, 0.3)
	blob(Vector3.new(0.9, 0.1, 0.7), CFrame.new(-0.8, -0.3, -0.4) * CFrame.Angles(0, 0, math.rad(25)), white, 0.3)
	return model
end

local function lilyPad(ctx, cf: CFrame, diameter: number, withLotus: boolean): (Part, Part?)
	local pad = ctx:part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 0.1, 0.1),
		CFrame = cf * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(62, 134, 74),
		Material = Enum.Material.SmoothPlastic,
	})
	pad:SetAttribute("Diameter", diameter)
	local lotus
	if withLotus then
		lotus = ctx:part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.05,
			CFrame = cf + Vector3.yAxis * 0.35,
			Color = ctx.palette.accent,
			Material = Enum.Material.Neon,
		})
	end
	return pad, lotus
end

function Scene.build(ctx)
	local p = ctx.palette
	local white = Color3.new(1, 1, 1)

	---------------------------------------------------------------- freeze
	ctx:at(0, function()
		ctx:camMove(ctx:look(Vector3.new(0, 14, 12), Vector3.new(0, 0, -1)), 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end)
	ctx:stoneTap(0.35)
	ctx:at(0.5, function()
		ctx:music(0.5)
	end)
	ctx:at(0.6, function()
		ctx:lighting({ ExposureCompensation = -0.5 }, 1.2)
		ctx:grade({ TintColor = Color3.fromRGB(214, 240, 238), Saturation = 0.1 }, 1.2)
		-- orbit down and around while the pads bloom
		ctx:camPath(2.7, function(a)
			local angle = math.rad(40) * a
			local radius = 15 - 2 * a
			local height = 14 - 9 * a
			return ctx:look(Vector3.new(math.sin(angle) * radius, height, math.cos(angle) * radius), Vector3.new(0, -1 + a, -1))
		end)
	end)

	---------------------------------------------------------------- build: pads
	local rng = Random.new()
	local rings = {
		{ at = 0.8, radius = 5, count = 7, pitch = 1.0 },
		{ at = 1.3, radius = 9, count = 11, pitch = 1.122 },
		{ at = 1.8, radius = 13.5, count = 15, pitch = 1.26 },
	}
	local lotuses = {}
	for ringIndex, ring in rings do
		local pads = {}
		for i = 1, ring.count do
			local angle = (i / ring.count) * math.pi * 2 + ringIndex * 0.4
			local r = ring.radius + rng:NextNumber(-0.6, 0.6)
			local cf = ctx:cf(math.cos(angle) * r, 0.1, math.sin(angle) * r)
			local pad, lotus = lilyPad(ctx, cf, rng:NextNumber(2.4, 3.4), i % 3 == 0)
			pad.Transparency = 1
			table.insert(pads, { pad = pad, lotus = lotus, delay = i * 0.02 })
			if lotus then
				lotus.Transparency = 1
				table.insert(lotuses, lotus)
			end
		end
		ctx:at(ring.at, function()
			ctx:sound("stir", 0.8, ring.pitch)
			Fx.ring(ctx, ctx:cf(0, 0.08, 0), p.glow, ring.radius - 3, ring.radius + 1.5, 0.7, 0.2)
		end)
		-- pads in a ring open a beat apart, so each ring shimmers outward
		for _, entry in pads do
			ctx:at(ring.at + entry.delay, function()
				local d = entry.pad:GetAttribute("Diameter")
				entry.pad.Transparency = 0
				ctx:tween(entry.pad, 0.45, { Size = Vector3.new(0.2, d, d) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				if entry.lotus then
					entry.lotus.Transparency = 0.1
					ctx:tween(entry.lotus, 0.5, { Size = Vector3.one * 0.8 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end
			end)
		end
	end

	---------------------------------------------------------------- build: koi
	local koi = ctx:itemModel(5, Scene.placeholder)
	local placeKoi = Fx.mover(koi)
	local carrier = Fx.anchor(ctx, ctx:cf(0, -12, 0))
	local koiLight = Fx.light(carrier, p.glow, 16, 0)
	local trail = Fx.trail(carrier, p.glow, 0.9, 0.5)
	local surfaceGlow = ctx:part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.05, 4.5, 4.5),
		Material = Enum.Material.Neon,
		Color = p.glow,
		Transparency = 1,
	})
	Fx.hide(koi)
	placeKoi(ctx:cf(0, -12, 0))

	local spiralStart, spiralTurns = math.rad(200), 2
	local function spiral(a: number): Vector3
		local angle = spiralStart + spiralTurns * math.pi * 2 * a
		local r = 7 - 5 * a
		return Vector3.new(math.cos(angle) * r, -9 + 7.8 * a, math.sin(angle) * r)
	end

	local lastLocal = spiral(0)
	ctx:at(1.0, function()
		Fx.fade(ctx, koi, 0, 0.6)
		ctx:tween(koiLight, 1.2, { Brightness = 2.5 })
		ctx:during(1.0, HIT - 1.0, function(a)
			local e = Fx.ease(math.min(a * 1.1, 1), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			local here = spiral(e)
			local ahead = spiral(math.min(e + 0.02, 1))
			if (ahead - here).Magnitude < 1e-3 then
				ahead = here + (here - lastLocal)
			end
			lastLocal = here
			local world = ctx:pos(here.X, here.Y, here.Z)
			placeKoi(CFrame.lookAt(world, ctx:pos(ahead.X, ahead.Y, ahead.Z)))
			carrier.CFrame = CFrame.new(world)
			surfaceGlow.CFrame = ctx:cf(here.X, 0.06, here.Z) * CFrame.Angles(0, 0, math.rad(90))
			if a < 1 then
				surfaceGlow.Transparency = 0.9 - 0.45 * e
			end
		end)
	end)
	ctx:at(1.4, function()
		ctx:sound("rise", 0.8)
	end)

	---------------------------------------------------------------- breath
	ctx:at(3.15, function()
		ctx:musicTo(0.08, 0.2)
		for _, lotus in lotuses do
			ctx:tween(lotus, 0.35, { Size = Vector3.one * 1.05 })
		end
	end)

	---------------------------------------------------------------- hit
	local splashAnchor = Fx.anchor(ctx, ctx:cf(0, 0.2, 0))
	local spray = Fx.emitter(splashAnchor, {
		LightEmission = 0.4,
		Color = ColorSequence.new(white),
		Size = NumberSequence.new(0.5, 0.1),
		Speed = NumberRange.new(14, 24),
		SpreadAngle = Vector2.new(22, 22),
		Acceleration = Vector3.new(0, -45, 0),
		Lifetime = NumberRange.new(0.6, 1),
		EmissionDirection = Enum.NormalId.Top,
	})
	local petals = Fx.emitter(splashAnchor, {
		LightEmission = 0.2,
		Color = ColorSequence.new(p.accent, p.accent:Lerp(white, 0.4)),
		Size = NumberSequence.new(0.45, 0.2),
		Speed = NumberRange.new(6, 13),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -3, 0),
		Drag = 1.2,
		RotSpeed = NumberRange.new(-180, 180),
		Lifetime = NumberRange.new(2, 3),
	})

	local hoverPhase = -math.pi / 2
	local hoverStart = Vector3.new(math.cos(hoverPhase) * HOVER_R, HOVER_Y, math.sin(hoverPhase) * HOVER_R)

	ctx:hit(HIT, {
		flash = { color = p.glow:Lerp(p.accent, 0.3), strength = 0.55, fade = 0.6 },
		shake = { amp = 0.25, dur = 0.4 },
		music = 0.7,
		fn = function()
			ctx.stone.Transparency = 1
			spray:Emit(70)
			petals:Emit(55)
			Fx.ring(ctx, ctx:cf(0, 0.08, 0), p.accent, 1, 22, 1.2, 0.35)
			surfaceGlow.Transparency = 1
			for _, lotus in lotuses do
				ctx:tween(lotus, 0.6, { Size = Vector3.one * 0.8 })
			end

			local from = lastLocal
			local rotBreach = ctx.origin.Rotation * CFrame.Angles(math.rad(90), 0, 0)
			local rotEnd = CFrame.lookAt(Vector3.zero, ctx.origin:VectorToWorldSpace(Vector3.xAxis))
			ctx:during(ctx.t, math.huge, function(_, lt)
				local here: Vector3
				local rot: CFrame
				if lt < 0.65 then
					local a = lt / 0.65
					here = from:Lerp(hoverStart, Fx.ease(a, Enum.EasingStyle.Quad))
					rot = rotBreach:Lerp(rotEnd, Fx.ease(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
					local world = ctx:pos(here.X, here.Y, here.Z)
					placeKoi(rot + world)
				else
					-- circle slowly in the air, always facing along the circle
					local phase = hoverPhase + (lt - 0.65) * 1.1
					here = Vector3.new(math.cos(phase) * HOVER_R, HOVER_Y + math.sin(lt * 1.7) * 0.25, math.sin(phase) * HOVER_R)
					local tangent = Vector3.new(-math.sin(phase), 0, math.cos(phase))
					local world = ctx:pos(here.X, here.Y, here.Z)
					placeKoi(CFrame.lookAt(world, world + ctx.origin:VectorToWorldSpace(tangent)))
				end
				carrier.CFrame = CFrame.new(ctx:pos(here.X, here.Y, here.Z))
			end)
			ctx:tween(koiLight, 0.3, { Brightness = 4, Range = 20 })
			ctx:camMove(ctx:look(Vector3.new(-3, 4, 13), Vector3.new(0, 6.5, -1)), 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end,
	})

	---------------------------------------------------------------- title
	ctx:at(HIT + 0.7, function()
		trail.Lifetime = 0.8
		ctx:camMove(ctx:look(Vector3.new(-2, 5, 10.5), Vector3.new(0, 7, -1)), 1.7, Enum.EasingStyle.Linear)
	end)
end

return Scene
