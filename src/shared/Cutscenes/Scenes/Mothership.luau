--[[
	THE MOTHERSHIP  -  UFO Deep  -  "THEY HAVE ARRIVED"   (~7.8 s)

	Palette  black / tractor-beam cyan-green / signal lime
	Focal    three lights in a black sky, then the stone in the beam

	The blackout scene. Every other scene eases the world down; this one
	cuts it off in a single frame, like a power failure. The reveal is the
	reverse: the hull has been overhead for two seconds in the dark, and the
	hit is every light on it coming on at once.

	0.00  FREEZE    camera close on the stone
	0.35            stone tap
	0.70  BUILD     LIGHTS CUT OUT: power-down (stir), world goes black
	1.30            three lights blink on in the sky, one by one;
	                a low hum begins to swell (rise)
	1.90            camera tilts up toward them
	2.40            they descend: the hull above them, only its edges visible;
	                camera sinks under it and the lens widens
	3.20            tractor beam lands on the stone
	3.40            the stone lifts up the beam, turning
	4.40  BREATH    hum cuts, beam flickers out, total darkness 0.3 s
	4.70  HIT       every hull light snaps on: lime flash, BRAAAM (strike),
	                long low shake; the world comes back tinted green
	5.10  TITLE     ship turns slowly overhead; camera pulls back
	6.80  RETURN
]]

local Fx = require(script.Parent.Parent.Fx)

local Scene = {
	titleAt = 5.1,
	returnAt = 6.8,
}

local HIT = 4.7
local HULL_SIZE = 110
local HULL_START = Vector3.new(0, 64, -95)
local HULL_END = Vector3.new(0, 42, -4)

function Scene.placeholder(ctx): Model
	local model, add = Fx.newModel(ctx, "MothershipPlaceholder")
	local metal = Color3.fromRGB(44, 48, 56)
	local upright = CFrame.Angles(0, 0, math.rad(90))
	add(ctx:part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 60, 60), CFrame = upright, Color = metal, Material = Enum.Material.DiamondPlate }))
	add(ctx:part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 40, 40), CFrame = CFrame.new(0, -3, 0) * upright, Color = metal, Material = Enum.Material.Metal }))
	add(ctx:part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 24, CFrame = CFrame.new(0, 2, 0), Color = ctx.palette.glow, Material = Enum.Material.Glass, Transparency = 0.4 }))
	add(ctx:part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 14, 14), CFrame = CFrame.new(0, -4.6, 0) * upright, Color = ctx.palette.glow, Material = Enum.Material.Neon }))
	return model
end

function Scene.build(ctx)
	local p = ctx.palette
	local black = Color3.new(0, 0, 0)

	---------------------------------------------------------------- freeze
	ctx:at(0, function()
		ctx:camMove(ctx:look(Vector3.new(3, 3, 9), Vector3.new(0, 1.5, 0)), 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end)
	ctx:stoneTap(0.35)

	---------------------------------------------------------------- hull + lights (hidden)
	local hull = ctx:itemModel(HULL_SIZE, Scene.placeholder)
	local placeHull = Fx.mover(hull)
	local _, hullSize = hull:GetBoundingBox()
	local startCf = ctx:cf(HULL_START.X, HULL_START.Y, HULL_START.Z)
	placeHull(startCf)
	local highlight = Fx.highlight(hull, p.glow, 1, p.glow, 1)
	local underside = -hullSize.Y / 2 - 0.4
	local ringRadius = math.min(hullSize.X, hullSize.Z) * 0.42

	local function hullLight(offset: Vector3, size: number, lit: boolean): (Part, PointLight?)
		local ball = ctx:part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * size,
			CFrame = startCf * CFrame.new(offset),
			Material = Enum.Material.Neon,
			Color = p.glow,
			Transparency = 1,
		})
		ball.Parent = hull
		local light = if lit then Fx.light(ball, p.glow, 34, 0) else nil
		return ball, light
	end

	local formation = {}
	for i = 0, 2 do
		local angle = math.rad(90 + i * 120)
		local ball, light = hullLight(Vector3.new(math.cos(angle) * ringRadius * 0.45, underside - 0.6, math.sin(angle) * ringRadius * 0.45), 3.5, true)
		table.insert(formation, { ball = ball, light = light :: PointLight })
	end
	local ring = {}
	for i = 1, 18 do
		local angle = (i / 18) * math.pi * 2
		local ball, light = hullLight(Vector3.new(math.cos(angle) * ringRadius, underside, math.sin(angle) * ringRadius), 2, i % 3 == 0)
		table.insert(ring, { ball = ball, light = light })
	end
	local core, coreLight = hullLight(Vector3.new(0, underside - 0.3, 0), 6, true)

	---------------------------------------------------------------- build: blackout
	ctx:at(0.7, function()
		ctx:sound("stir", 1)
		ctx:lighting({
			ClockTime = 0,
			Brightness = 0,
			ExposureCompensation = -1.5,
			Ambient = black,
			OutdoorAmbient = black,
		}, 0)
		ctx:atmosphere({ Density = 0.35, Haze = 0, Glare = 0, Color = p.base, Decay = p.base }, 0)
		ctx:grade({ Saturation = -0.5, Brightness = -0.08 }, 0)
		ctx.ui:tintTo(black, 0.3, 0)
	end)

	local hum: Sound? = nil
	for i, f in formation do
		ctx:at(1.3 + (i - 1) * 0.2, function()
			f.ball.Transparency = 0
			f.light.Brightness = 2
			if i == 1 then
				hum = ctx:sound("rise", 0.45)
				if hum then
					ctx:tween(hum, 1.9, { Volume = 1 })
				end
			end
		end)
	end

	ctx:at(1.9, function()
		ctx:camMove(ctx:look(Vector3.new(3, 2, 9), HULL_START + Vector3.new(0, -12, 30)), 1.2)
	end)

	---------------------------------------------------------------- build: descent
	local hullCf = startCf
	local turnFrom = math.huge
	ctx:at(2.4, function()
		ctx.ui:tintTo(black, 0, 1)
		ctx:tween(highlight, 1.6, { OutlineTransparency = 0.75 })
		ctx:during(2.4, math.huge, function(_, lt)
			local a = Fx.ease(math.min(lt / 1.6, 1), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			local pos = HULL_START:Lerp(HULL_END, a)
			local spin = if ctx.t > turnFrom then (ctx.t - turnFrom) * math.rad(8) else 0
			hullCf = ctx:cf(pos.X, pos.Y + math.sin(lt * 1.4) * 0.4, pos.Z) * CFrame.Angles(0, spin, 0)
			placeHull(hullCf)
		end)
		ctx:camMove(ctx:look(Vector3.new(0, 1.5, 6), HULL_END + Vector3.new(0, 0, -8)), 2.0, Enum.EasingStyle.Sine)
		ctx:fov(92, 2.0)
	end)

	---------------------------------------------------------------- build: beam
	local beamOuter = Fx.column(ctx, Vector3.zero, Vector3.yAxis * 0.1, 3.2, p.glow, 1)
	local beamInner = Fx.column(ctx, Vector3.zero, Vector3.yAxis * 0.1, 1, Color3.new(1, 1, 1), 1)
	local stoneFrom = ctx.stone.CFrame
	local stoneLight = Fx.light(ctx.stone, p.glow, 10, 0)
	local beamParticles = Fx.emitter(ctx.stone, {
		Color = ColorSequence.new(p.glow),
		Size = NumberSequence.new(0.35, 0),
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(12, 12),
		Lifetime = NumberRange.new(1.5, 2.5),
		EmissionDirection = Enum.NormalId.Top,
	})
	local liftFrom = math.huge

	ctx:during(3.2, math.huge, function(_, lt)
		local top = (hullCf * CFrame.new(0, underside, 0)).Position
		local target = stoneFrom.Position
		local bottom = top:Lerp(target, math.min(lt / 0.35, 1))
		Fx.stretch(beamOuter, top, bottom, 3.2)
		Fx.stretch(beamInner, top, bottom, 1)
		if ctx.t >= liftFrom then
			local a = math.min((ctx.t - liftFrom) / 1.2, 1)
			local pos = target:Lerp(top, Fx.ease(a, Enum.EasingStyle.Sine, Enum.EasingDirection.In))
			ctx.stone.CFrame = CFrame.new(pos) * CFrame.Angles(ctx.t * 2, ctx.t * 3, 0)
			if a >= 1 then
				ctx.stone.Transparency = 1
			end
		end
	end)

	ctx:at(3.2, function()
		beamOuter.Transparency = 0.78
		beamInner.Transparency = 0.55
		core.Transparency = 0
		ctx:tween(coreLight :: PointLight, 0.3, { Brightness = 3 })
		ctx:tween(stoneLight, 0.3, { Brightness = 2 })
		beamParticles.Rate = 30
	end)
	ctx:at(3.4, function()
		liftFrom = 3.4
	end)

	---------------------------------------------------------------- breath
	ctx:at(4.4, function()
		ctx:cut(hum, 0.05)
		beamParticles.Rate = 0
		beamOuter.Transparency = 1
		beamInner.Transparency = 1
		core.Transparency = 1
		for _, f in formation do
			f.ball.Transparency = 1
			f.light.Brightness = 0
		end
		if coreLight then
			coreLight.Brightness = 0
		end
		ctx.ui:tintTo(black, 0.65, 0.06)
	end)
	-- one last flicker of the beam in the dark
	ctx:at(4.5, function()
		beamOuter.Transparency = 0.85
	end)
	ctx:at(4.55, function()
		beamOuter.Transparency = 1
	end)

	---------------------------------------------------------------- hit
	ctx:hit(HIT, {
		flash = { color = p.accent, strength = 0.8, fade = 0.6 },
		shake = { amp = 0.9, dur = 1.1, freq = 8 },
		music = 0.8,
		fn = function()
			ctx:music(0.8)
			turnFrom = ctx.t
			for _, r in ring do
				r.ball.Transparency = 0
				if r.light then
					r.light.Brightness = 2.5
				end
			end
			for _, f in formation do
				f.ball.Transparency = 0
				f.light.Brightness = 3
			end
			core.Transparency = 0
			if coreLight then
				coreLight.Brightness = 4
			end
			highlight.FillTransparency = 0.8
			highlight.OutlineTransparency = 0
			ctx:tween(highlight, 1.2, { FillTransparency = 0.9, OutlineTransparency = 0.4 })
			ctx:lighting({
				Brightness = 1.2,
				ExposureCompensation = -0.6,
				Ambient = Color3.fromRGB(20, 52, 40),
				OutdoorAmbient = Color3.fromRGB(30, 72, 60),
			}, 0.3)
			ctx:grade({ Saturation = -0.1, Brightness = 0, TintColor = Color3.fromRGB(220, 255, 235) }, 0.3)
			ctx:camMove(ctx:look(Vector3.new(0, 3, 17), HULL_END + Vector3.new(0, -2, 0)), 2.6, Enum.EasingStyle.Sine)
			ctx:fov(80, 2.6)
		end,
	})
end

return Scene
