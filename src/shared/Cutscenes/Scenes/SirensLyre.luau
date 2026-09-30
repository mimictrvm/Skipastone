--[[
	SIREN'S LYRE  -  Pebble Cove  -  "THE SIREN SINGS"   (~7.5 s)

	Palette  night navy / moon silver / violet
	Focal    a black silhouette on a rock, framed by the moon

	The quiet scene. Where the others build with noise, this one builds by
	taking sound away: the water stills, the music never starts, and a lone
	voice sings. The hit is one plucked string. There is no camera shake:
	stillness is the effect, so nothing moves the frame.

	0.00  FREEZE    camera settles low on the water, a rock off to the right
	0.35            stone tap
	0.50  BUILD     water goes flat and mirror-like; hush drone (stir)
	                moonlight grade; no music
	1.20            moonbeam lands on the rock; a silhouette fades in
	1.40            the song begins (rise), swelling; camera creeps in
	2.00            slow ripples pulse out from the rock with the song
	3.60  BREATH    the song stops dead. 0.4 s of silence
	4.00  HIT       one lyre pluck (strike): violet flash, a ring races
	                across the still water; the lyre lifts from her hands
	4.20            the siren slips back beneath the water
	4.40            music finally arrives (harp bed): the release
	4.95  TITLE     lyre hangs above the stone
	6.50  RETURN
]]

local Fx = require(script.Parent.Parent.Fx)

local Scene = {
	titleAt = 4.95,
	returnAt = 6.5,
}

local HIT = 4.0
local ROCK = Vector3.new(7, 0, -24)
local SEAT = ROCK + Vector3.new(0, 3.2, 0)
local PUSH_CAM = Vector3.new(-1.5, 2.8, 4)
local REST = Vector3.new(0, 3, 0)

function Scene.placeholder(ctx): Model
	local model, add = Fx.newModel(ctx, "LyrePlaceholder")
	local gold = Color3.fromRGB(226, 196, 120)
	local function block(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?)
		add(ctx:part({ Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.Metal }))
	end
	block(Vector3.new(0.3, 3.2, 0.3), CFrame.new(-0.85, 0, 0) * CFrame.Angles(0, 0, math.rad(-12)), gold)
	block(Vector3.new(0.3, 3.2, 0.3), CFrame.new(0.85, 0, 0) * CFrame.Angles(0, 0, math.rad(12)), gold)
	block(Vector3.new(2.6, 0.28, 0.28), CFrame.new(0, 1.45, 0), gold)
	block(Vector3.new(1.5, 0.45, 0.45), CFrame.new(0, -1.5, 0), gold)
	for _, x in { -1.25, 1.25 } do
		add(ctx:part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.5, CFrame = CFrame.new(x, 1.75, 0), Color = gold, Material = Enum.Material.Metal }))
	end
	for i = -2, 2 do
		block(Vector3.new(0.05, 2.8, 0.05), CFrame.new(i * 0.22, 0, 0), ctx.palette.glow, Enum.Material.Neon)
	end
	return model
end

-- Seated figure on the rock, built from ellipsoids. Painted black later.
local function buildSiren(ctx): Model
	local model, add = Fx.newModel(ctx, "Siren")
	local function blob(size: Vector3, cf: CFrame)
		local p = add(ctx:part({ Size = size, CFrame = cf, Color = Color3.new(0, 0, 0) }))
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	blob(Vector3.new(1.3, 2.2, 0.9), CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(-6)))
	blob(Vector3.new(0.95, 1.05, 0.95), CFrame.new(-0.1, 3.2, 0))
	blob(Vector3.new(1.15, 2.2, 0.6), CFrame.new(-0.35, 2.5, 0.35) * CFrame.Angles(0, 0, math.rad(-10)))
	blob(Vector3.new(0.35, 1.6, 0.35), CFrame.new(0.65, 1.8, -0.2) * CFrame.Angles(0, 0, math.rad(35)))
	blob(Vector3.new(1.6, 1.2, 1.7), CFrame.new(0.2, 0.5, 0.2))
	blob(Vector3.new(1.1, 1.0, 1.9), CFrame.new(0.9, -0.2, -0.9) * CFrame.Angles(math.rad(25), 0, 0))
	blob(Vector3.new(0.8, 0.8, 1.5), CFrame.new(1.4, -0.9, -2.0) * CFrame.Angles(math.rad(40), 0, 0))
	blob(Vector3.new(1.8, 0.15, 1.0), CFrame.new(1.7, -1.2, -2.9) * CFrame.Angles(0, math.rad(20), math.rad(15)))
	return model
end

local function buildRock(ctx)
	local slate = Color3.fromRGB(46, 50, 60)
	for _, r in {
		{ size = Vector3.new(7, 4.2, 6), offset = Vector3.new(0, 1, 0), rot = Vector3.new(0, 20, 6) },
		{ size = Vector3.new(5, 5, 4.5), offset = Vector3.new(2.5, 0.2, -1.5), rot = Vector3.new(10, -30, -8) },
		{ size = Vector3.new(4, 3, 4), offset = Vector3.new(-2.8, 0, 1.2), rot = Vector3.new(-6, 50, 12) },
	} do
		ctx:part({
			Size = r.size,
			CFrame = ctx:cf(ROCK.X + r.offset.X, r.offset.Y, ROCK.Z + r.offset.Z)
				* CFrame.Angles(math.rad(r.rot.X), math.rad(r.rot.Y), math.rad(r.rot.Z)),
			Color = slate,
			Material = Enum.Material.Slate,
		})
	end
end

function Scene.build(ctx)
	local p = ctx.palette
	local white = Color3.new(1, 1, 1)

	---------------------------------------------------------------- freeze
	ctx:at(0, function()
		ctx:camMove(ctx:look(Vector3.new(-3, 2.5, 8), Vector3.new(3, 2, -12)), 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end)
	ctx:stoneTap(0.35)

	---------------------------------------------------------------- build
	buildRock(ctx)
	local siren = buildSiren(ctx)
	local placeSiren = Fx.mover(siren)
	local sirenHome = ctx:cf(SEAT.X, SEAT.Y + 1.2, SEAT.Z) * Fx.FACE_PLAYER * CFrame.Angles(0, math.rad(-35), 0)
	placeSiren(sirenHome)
	Fx.hide(siren)

	-- The moon sits directly behind her from where the camera ends up,
	-- so she reads as a black shape cut out of it.
	local sirenCentre = ctx:pos(SEAT.X, SEAT.Y + 1.6, SEAT.Z)
	local camWorld = ctx:pos(PUSH_CAM.X, PUSH_CAM.Y, PUSH_CAM.Z)
	local moonDir = (sirenCentre - camWorld).Unit
	local moon = ctx:part({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 26,
		CFrame = CFrame.new(sirenCentre + moonDir * 90),
		Material = Enum.Material.Neon,
		Color = p.glow,
		Transparency = 1,
	})

	local beamTop = ctx:pos(SEAT.X - 10, 60, SEAT.Z - 30)
	local beam = Fx.column(ctx, beamTop, ctx:pos(SEAT.X, 0, SEAT.Z), 3.2, p.glow, 1)

	local mistSource = ctx:part({ Size = Vector3.new(40, 1, 30), CFrame = ctx:cf(ROCK.X, 0.3, ROCK.Z), Transparency = 1 })
	local mist = Fx.emitter(mistSource, {
		Texture = Fx.SMOKE,
		LightEmission = 0.1,
		Color = ColorSequence.new(p.glow),
		Size = NumberSequence.new(6, 12),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.85), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(4, 6),
		Speed = NumberRange.new(0.3, 1),
		EmissionDirection = Enum.NormalId.Top,
	})

	ctx:at(0.5, function()
		ctx:sound("stir", 0.8)
		ctx:terrain({ WaterWaveSize = 0, WaterWaveSpeed = 0, WaterReflectance = 1 }, 1.2)
		ctx:lighting({ ExposureCompensation = -1.1 }, 1.4)
		ctx:grade({ TintColor = Color3.fromRGB(188, 204, 255), Saturation = -0.45, Contrast = 0.15 }, 1.4)
		ctx:atmosphere({ Density = 0.25, Haze = 0, Glare = 0, Color = p.base, Decay = p.base }, 1.4)
		Fx.fade(ctx, moon, 0, 1.4)
		mist.Rate = 8
	end)

	ctx:at(1.2, function()
		ctx:tween(beam, 1, { Transparency = 0.86 })
		Fx.fade(ctx, siren, 0, 1)
		ctx:camMove(ctx:look(PUSH_CAM, SEAT + Vector3.new(0, 1.6, 0)), 2.8, Enum.EasingStyle.Sine)
	end)

	local lyre = ctx:itemModel(2.4, Scene.placeholder)
	local placeLyre = Fx.mover(lyre)
	local lyreHome = sirenHome * CFrame.new(1.1, -0.1, -0.6) * CFrame.Angles(0, 0, math.rad(-15))
	placeLyre(lyreHome)
	Fx.hide(lyre)
	local lyreCarrier = Fx.anchor(ctx, lyreHome)
	local lyreLight = Fx.light(lyreCarrier, p.accent, 10, 0)

	local song: Sound? = nil
	ctx:at(1.4, function()
		song = ctx:sound("rise", 0)
		if song then
			ctx:tween(song, 1.5, { Volume = 0.9 })
		end
	end)

	ctx:at(2.2, function()
		Fx.fade(ctx, lyre, 0, 0.6)
		ctx:tween(lyreLight, 1.2, { Brightness = 1.2 })
	end)

	-- the song, made visible: slow ripples in time with it
	for t = 2.0, 3.4, 0.7 do
		ctx:at(t, function()
			Fx.ring(ctx, ctx:cf(SEAT.X, 0.05, SEAT.Z), p.glow, 3, 11, 1.6, 0.12)
		end)
	end

	---------------------------------------------------------------- breath
	ctx:at(3.6, function()
		ctx:cut(song, 0.06)
		ctx:tween(beam, 0.4, { Transparency = 0.74 })
		mist.Rate = 0
	end)

	---------------------------------------------------------------- hit
	local sparks = Fx.emitter(lyreCarrier, {
		Color = ColorSequence.new(p.accent, white),
		Size = NumberSequence.new(0.35, 0),
		Speed = NumberRange.new(3, 8),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(0.6, 1.2),
		Drag = 2,
	})

	ctx:hit(HIT, {
		flash = { color = p.accent:Lerp(white, 0.35), strength = 0.6, fade = 0.7 },
		fn = function()
			ctx.stone.Transparency = 1
			sparks:Emit(40)
			ctx:tween(lyreLight, 0.15, { Brightness = 5, Range = 24 })
			Fx.ring(ctx, ctx:cf(SEAT.X, 0.06, SEAT.Z), p.accent, 2, 45, 1.4, 0.5, 48)
			local lyreFrom = lyreHome
			local lyreTo = ctx:cf(REST.X, REST.Y, REST.Z) * Fx.FACE_PLAYER
			ctx:during(ctx.t, math.huge, function(_, lt)
				local a = math.min(lt / 0.9, 1)
				local cf = lyreFrom:Lerp(lyreTo, Fx.ease(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
				if a >= 1 then
					cf = lyreTo * CFrame.new(0, math.sin((lt - 0.9) * 2) * 0.12, 0) * CFrame.Angles(0, math.sin((lt - 0.9) * 0.9) * 0.25, 0)
				end
				placeLyre(cf)
				lyreCarrier.CFrame = cf
			end)
			ctx:camMove(ctx:look(Vector3.new(0, 3.4, 7.5), REST), 0.9, Enum.EasingStyle.Sine)
		end,
	})
	ctx:at(HIT + 0.15, function()
		Fx.ring(ctx, ctx:cf(SEAT.X, 0.06, SEAT.Z), p.glow, 1, 30, 1.3, 0.25, 40)
	end)

	ctx:at(HIT + 0.2, function()
		ctx:during(ctx.t, 1, function(a)
			local e = Fx.ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			placeSiren(sirenHome * CFrame.new(0, -5 * e, 1.5 * e) * CFrame.Angles(math.rad(30) * e, 0, 0))
		end)
		Fx.fade(ctx, siren, 1, 1)
		ctx:tween(beam, 1.2, { Transparency = 1 })
	end)

	ctx:at(HIT + 0.4, function()
		ctx:music(0)
		ctx:musicTo(0.6, 0.8)
	end)
end

return Scene
