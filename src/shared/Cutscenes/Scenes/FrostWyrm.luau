--[[
	FROST WYRM  -  Frozen Rift  -  "THE FROST WYRM STIRS"   (~7.8 s)

	Palette  ice white / glacier cyan / deep blue
	Focal    the stone at the centre of the cracks, then two eyes in the snow

	The inverted scene. The other scenes pause in darkness before the hit;
	this one pauses in a whiteout. The hit is the air snapping clear, so
	the contrast comes from white-to-clear rather than dark-to-bright.

	0.00  FREEZE    camera looks down over the stone
	0.35            stone tap
	0.50            music bed (low cold strings)
	0.60  BUILD     ice sheet races out across the water (stir)
	1.20-2.45       six cracks split out from the stone, each with a crack
	                (stir, random pitch), each one sooner than the last
	1.40            wind starts to build (rise); camera climbs to see the cracks
	2.60            blizzard whiteout; music thins to nothing
	3.20            two glowing eyes open inside the white. They blink once
	3.90  BREATH    wind cuts; the eyes narrow; silence
	4.10  HIT       air snaps clear, ice shatters, the wyrm bursts up
	                roaring (strike); heavy shake; low hero angle
	4.60  TITLE     wyrm sways, frost breath drifts from its jaws
	6.80  RETURN
]]

local Fx = require(script.Parent.Parent.Fx)

local Scene = {
	titleAt = 4.6,
	returnAt = 6.8,
}

local HIT = 4.1
local WYRM_SIZE = 36
local LAIR = Vector3.new(0, 0, -14)
local ICE = Color3.fromRGB(214, 234, 250)

function Scene.placeholder(ctx): Model
	local model, add = Fx.newModel(ctx, "WyrmPlaceholder")
	local scale = Color3.fromRGB(196, 226, 250)
	local function blob(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?)
		local p = add(ctx:part({ Size = size, CFrame = cf, Color = color, Material = material or Enum.Material.Glacier }))
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
		return p
	end
	-- an S-curved neck rising out of the water, thinning toward the head
	local top = Vector3.zero
	for i = 0, 10 do
		local y = i * 2.3
		local x = math.sin(i * 0.55) * 1.6
		local z = -math.sin(i * 0.3) * 1.2
		local d = 4.4 - i * 0.18
		blob(Vector3.one * d, CFrame.new(x, y, z), scale)
		if i % 2 == 0 then
			local spike = Instance.new("WedgePart")
			spike.Anchored, spike.CanCollide, spike.CanQuery, spike.CastShadow = true, false, false, false
			spike.Size = Vector3.new(0.4, 1.4, 1.4)
			spike.CFrame = CFrame.new(x, y + 0.4, z + d / 2)
			spike.Color, spike.Material = ctx.palette.glow, Enum.Material.Ice
			add(spike)
		end
		top = Vector3.new(x, y, z)
	end
	local head = top + Vector3.new(0, 1.8, -1.6)
	blob(Vector3.new(3.4, 2.4, 5), CFrame.new(head), scale)
	blob(Vector3.new(2.6, 1, 3.6), CFrame.new(head + Vector3.new(0, -1.1, -0.8)), scale:Lerp(Color3.new(0, 0, 0), 0.15))
	for _, side in { -1, 1 } do
		add(ctx:part({
			Size = Vector3.new(0.35, 0.35, 3.4),
			CFrame = CFrame.new(head + Vector3.new(side * 1.1, 1.3, 1.4)) * CFrame.Angles(math.rad(35), math.rad(side * 15), 0),
			Color = ctx.palette.glow,
			Material = Enum.Material.Ice,
		}))
		blob(Vector3.new(0.5, 0.35, 0.6), CFrame.new(head + Vector3.new(side * 1.05, 0.45, -1.9)), ctx.palette.glow, Enum.Material.Neon)
	end
	return model
end

-- Floating glowing eyes that stay visible through the whiteout.
local function eyes(ctx, at: Vector3): (BillboardGui, { Frame })
	local anchor = Fx.anchor(ctx, CFrame.new(at))
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(4, 1)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Adornee = anchor
	bb.Parent = anchor
	local lids = {}
	for i, x in { 0.2, 0.8 } do
		local holder = Instance.new("Frame")
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.Position = UDim2.fromScale(x, 0.5)
		holder.Size = UDim2.fromScale(0.26, 0)
		holder.Rotation = if i == 1 then 12 else -12
		holder.BackgroundColor3 = ctx.palette.glow
		holder.BorderSizePixel = 0
		holder.Parent = bb
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = holder
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Thickness = 2
		stroke.Transparency = 0.3
		stroke.Parent = holder
		table.insert(lids, holder)
	end
	return bb, lids
end

function Scene.build(ctx)
	local p = ctx.palette
	local white = Color3.new(1, 1, 1)

	---------------------------------------------------------------- freeze
	ctx:at(0, function()
		ctx:camMove(ctx:look(Vector3.new(0, 5, 12), Vector3.new(0, 0, -6)), 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end)
	ctx:stoneTap(0.35)
	ctx:at(0.5, function()
		ctx:music(0.45)
	end)

	---------------------------------------------------------------- build: ice
	local sheet = ctx:part({
		Size = Vector3.new(0.1, 0.6, 0.1),
		CFrame = ctx:cf(0, 0.12, -10),
		Color = ICE,
		Material = Enum.Material.Ice,
		Transparency = 0.15,
	})
	ctx:at(0.6, function()
		ctx:sound("stir", 0.8, 0.8)
		ctx:tween(sheet, 0.6, { Size = Vector3.new(90, 0.6, 90) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		ctx:grade({ TintColor = Color3.fromRGB(226, 240, 255), Saturation = -0.25 }, 0.8)
	end)

	---------------------------------------------------------------- build: cracks
	local rng = Random.new()
	local crackParts = {}
	local crackTimes = { 1.2, 1.55, 1.85, 2.1, 2.3, 2.45 }
	for i, t in crackTimes do
		local base = math.rad(-70 + (i - 1) * 28 + rng:NextNumber(-8, 8))
		local length = rng:NextNumber(10, 22)
		local points = { Vector3.new(0, 0.45, 0) }
		local heading = base
		for s = 1, 3 do
			heading += math.rad(rng:NextNumber(-22, 22))
			local prev = points[s]
			table.insert(points, prev + Vector3.new(math.sin(heading), 0, -math.cos(heading)) * (length / 3))
		end
		ctx:at(t, function()
			ctx:sound("stir", 0.7, rng:NextNumber(0.9, 1.3))
			ctx:shake(0.1 + i * 0.04, 0.3)
			for s = 1, 3 do
				local a, b = ctx:pos(points[s].X, points[s].Y, points[s].Z), ctx:pos(points[s + 1].X, points[s + 1].Y, points[s + 1].Z)
				local dir = (b - a).Unit
				local seg = ctx:part({ Material = Enum.Material.Neon, Color = p.glow, Size = Vector3.new(0.22, 0.05, 0.05) })
				table.insert(crackParts, seg)
				ctx:during(ctx.t + (s - 1) * 0.08, 0.1, function(alpha)
					local tip = a:Lerp(b, alpha)
					local len = math.max((tip - a).Magnitude, 0.05)
					seg.Size = Vector3.new(0.22 - s * 0.04, 0.05, len)
					local mid = (a + tip) / 2
					seg.CFrame = CFrame.lookAt(mid, mid + dir)
				end)
			end
		end)
	end

	local wind: Sound? = nil
	ctx:at(1.2, function()
		ctx:camMove(ctx:look(Vector3.new(0, 12, 15), Vector3.new(0, 0, -8)), 1.4)
	end)
	ctx:at(1.4, function()
		wind = ctx:sound("rise", 0.3)
		if wind then
			ctx:tween(wind, 2.2, { Volume = 1 })
		end
	end)

	---------------------------------------------------------------- whiteout
	local snowSource = ctx:part({ Size = Vector3.new(4, 24, 30), Transparency = 1 })
	local snow = Fx.emitter(snowSource, {
		LightEmission = 0.5,
		Color = ColorSequence.new(white),
		Size = NumberSequence.new(0.25, 0.15),
		Speed = NumberRange.new(40, 60),
		SpreadAngle = Vector2.new(10, 10),
		Lifetime = NumberRange.new(0.5, 0.8),
		EmissionDirection = Enum.NormalId.Right,
	})
	ctx:during(0, math.huge, function()
		-- blows across the frame, from just off the left edge
		snowSource.CFrame = ctx.camBase * CFrame.new(-14, 0, -10)
	end)

	ctx:at(2.6, function()
		ctx:atmosphere({ Density = 0.78, Offset = 0, Color = Color3.fromRGB(236, 244, 255), Decay = Color3.fromRGB(220, 234, 252), Haze = 3, Glare = 0 }, 0.8)
		ctx:grade({ Brightness = 0.25, Contrast = -0.35, Saturation = -0.6 }, 0.8)
		ctx:musicTo(0.05, 0.6)
		snow.Rate = 320
		ctx:camMove(ctx:look(Vector3.new(0, 3, 12), LAIR + Vector3.new(0, 7, 0)), 1.0)
	end)

	local eyesGui, lids = eyes(ctx, ctx:pos(LAIR.X, 7.5, LAIR.Z))
	local function lidsTo(y: number, dur: number)
		for _, lid in lids do
			ctx:tween(lid, dur, { Size = UDim2.fromScale(0.26, y) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end
	end
	ctx:at(3.2, function()
		lidsTo(0.9, 0.25)
	end)
	ctx:at(3.55, function()
		lidsTo(0.05, 0.06)
	end)
	ctx:at(3.63, function()
		lidsTo(0.9, 0.1)
	end)

	---------------------------------------------------------------- breath
	ctx:at(3.9, function()
		ctx:cut(wind, 0.1)
		lidsTo(0.4, 0.15)
	end)

	---------------------------------------------------------------- hit
	local wyrm = ctx:itemModel(WYRM_SIZE, Scene.placeholder)
	local placeWyrm = Fx.mover(wyrm)
	local _, wyrmSize = wyrm:GetBoundingBox()
	local restY = wyrmSize.Y / 2 - 8
	placeWyrm(ctx:cf(LAIR.X, -wyrmSize.Y, LAIR.Z) * Fx.FACE_PLAYER)
	Fx.hide(wyrm)

	local breathAnchor = Fx.anchor(ctx, ctx:cf(LAIR.X, restY + wyrmSize.Y / 2 - 3, LAIR.Z + 3))
	local frostBreath = Fx.emitter(breathAnchor, {
		Texture = Fx.SMOKE,
		LightEmission = 0.3,
		Color = ColorSequence.new(white, p.glow),
		Size = NumberSequence.new(1, 4),
		Transparency = NumberSequence.new(0.5, 1),
		Speed = NumberRange.new(3, 6),
		SpreadAngle = Vector2.new(20, 20),
		Acceleration = Vector3.new(0, -2, 0),
		Lifetime = NumberRange.new(1, 1.8),
		EmissionDirection = Enum.NormalId.Back,
	})
	local wyrmLight = Fx.light(breathAnchor, p.accent, 40, 0)

	ctx:hit(HIT, {
		flash = { color = p.glow, strength = 0.5, fade = 0.5 },
		shake = { amp = 1.1, dur = 1.0, freq = 14 },
		music = 0.85,
		fn = function()
			-- the white is gone in a single frame
			ctx:atmosphere({ Density = 0.12, Haze = 0.5, Color = Color3.fromRGB(210, 230, 255), Decay = Color3.fromRGB(150, 190, 240) }, 0)
			ctx:grade({ Brightness = 0, Contrast = 0.25, Saturation = -0.1 }, 0)
			snow.Rate = 0
			eyesGui.Enabled = false
			sheet.Transparency = 1
			ctx.stone.Transparency = 1
			for _, c in crackParts do
				c.Transparency = 1
			end
			Fx.debris(ctx, ctx:pos(LAIR.X, 0.5, LAIR.Z), {
				count = 34,
				size = NumberRange.new(1.5, 4),
				color = ICE,
				material = Enum.Material.Ice,
				transparency = 0.1,
				speed = NumberRange.new(12, 30),
				up = NumberRange.new(18, 38),
				life = 1.8,
			})
			Fx.ring(ctx, ctx:cf(LAIR.X, 0.2, LAIR.Z), p.glow, 3, 40, 0.9, 0.6, 40)
			Fx.fade(ctx, wyrm, 0, 0.05)
			ctx:tween(wyrmLight, 0.2, { Brightness = 3 })
			frostBreath.Rate = 18

			ctx:during(ctx.t, math.huge, function(_, lt)
				local burst = Fx.ease(math.min(lt / 0.55, 1), Enum.EasingStyle.Quart)
				local y = -wyrmSize.Y + (restY + wyrmSize.Y) * burst
				local rear = math.rad(18) * Fx.ease(math.min(lt / 1.2, 1), Enum.EasingStyle.Sine) * math.exp(-lt * 0.8)
				local sway = math.sin(lt * 1.3) * math.rad(3)
				placeWyrm(ctx:cf(LAIR.X, y + math.sin(lt * 1.1) * 0.3, LAIR.Z) * Fx.FACE_PLAYER * CFrame.Angles(rear, sway, 0))
			end)
			ctx:cam(ctx:look(Vector3.new(0, 1.5, 11), LAIR + Vector3.new(0, 10, 0)))
			ctx:camMove(ctx:look(Vector3.new(0, 1.5, 10), LAIR + Vector3.new(0, 12, 0)), 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end,
	})

	ctx:at(HIT + 0.4, function()
		ctx:camMove(ctx:look(Vector3.new(0.5, 2, 8), LAIR + Vector3.new(0, 14, 0)), 2.3, Enum.EasingStyle.Linear)
	end)
end

return Scene
