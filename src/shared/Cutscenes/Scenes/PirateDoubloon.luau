--[[
	PIRATE DOUBLOON  -  Starter Beach  -  "THE DEAD MAN'S COIN"   (~7.3 s)

	Palette  fog grey-green / ghost green / gold
	Focal    a single green lantern in the fog, then the coin

	0.00  FREEZE    camera drops low over the water, looking out to sea
	0.35            stone tap
	0.60  BUILD     fog rolls in; ship's bell (stir); music bed starts
	1.20            a green lantern appears far out in the fog
	1.60            timber groan / swell (rise); camera creeps toward it
	2.00            the ghost ship glides out of the fog, lantern on its bow
	3.20  BREATH    music drops out; the hull's green outline brightens
	3.70  HIT       bow cannon fires: flash, boom (strike), shake
	                the coin is shot out, spinning, toward the stone
	4.40  REVEAL    coin slows to a stop face-on above the stone
	4.50  TITLE     THE DEAD MAN'S COIN; ship sinks back into fog
	6.30  RETURN
]]

local Fx = require(script.Parent.Parent.Fx)

local Scene = {
	titleAt = 4.5,
	returnAt = 6.3,
}

local HIT = 3.7

function Scene.placeholder(ctx): Model
	local model, add = Fx.newModel(ctx, "DoubloonPlaceholder")
	local gold = ctx.palette.accent
	-- cylinders run along X; turned 90 degrees so the face looks down -Z
	add(ctx:part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.35, 3, 3),
		Material = Enum.Material.Metal,
		Color = gold,
		Reflectance = 0.25,
		CFrame = CFrame.Angles(0, math.rad(90), 0),
	}))
	add(ctx:part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.45, 2.3, 2.3),
		Material = Enum.Material.Metal,
		Color = gold:Lerp(Color3.new(0, 0, 0), 0.25),
		CFrame = CFrame.Angles(0, math.rad(90), 0),
	}))
	for _, x in { -0.45, 0.45 } do
		add(ctx:part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.5,
			Color = Color3.fromRGB(40, 30, 10),
			CFrame = CFrame.new(x, 0.3, -0.2),
		}))
	end
	return model
end

-- Ghost ship, bow toward the player. Returns the model, its lantern and
-- the bow cannon's muzzle offset (relative to the ship's pivot).
local function buildShip(ctx): (Model, Part, CFrame)
	local ship = Instance.new("Model")
	ship.Name = "GhostShip"
	local wood = Color3.fromRGB(34, 40, 37)
	local cloth = Color3.fromRGB(170, 190, 176)

	local function add(props)
		local p = ctx:part(props)
		p.Parent = ship
		return p
	end

	local hull = add({ Size = Vector3.new(10, 6, 30), CFrame = CFrame.new(0, 1, 0), Color = wood, Material = Enum.Material.Wood, Transparency = 0.2 })
	add({ Size = Vector3.new(10, 3, 6), CFrame = CFrame.new(0, 5.5, 13), Color = wood, Material = Enum.Material.Wood, Transparency = 0.2 })
	local bow = Instance.new("WedgePart")
	bow.Anchored, bow.CanCollide, bow.CanQuery, bow.CastShadow = true, false, false, false
	bow.Size = Vector3.new(10, 6, 9)
	bow.CFrame = CFrame.new(0, 1, -19.5)
	bow.Color, bow.Material, bow.Transparency = wood, Enum.Material.Wood, 0.2
	bow.Parent = ship

	for _, m in { { z = -6, h = 22, sail = 12 }, { z = 7, h = 19, sail = 10 } } do
		add({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(m.h, 0.8, 0.8),
			CFrame = CFrame.new(0, 4 + m.h / 2, m.z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = wood,
			Material = Enum.Material.Wood,
			Transparency = 0.2,
		})
		-- tattered sails: two offset panels so the edges look torn
		add({ Size = Vector3.new(m.sail, m.sail * 0.55, 0.15), CFrame = CFrame.new(0, 4 + m.h * 0.72, m.z + 0.4), Color = cloth, Material = Enum.Material.Fabric, Transparency = 0.45 })
		add({ Size = Vector3.new(m.sail * 0.8, m.sail * 0.35, 0.15), CFrame = CFrame.new(0.8, 4 + m.h * 0.38, m.z + 0.4), Color = cloth, Material = Enum.Material.Fabric, Transparency = 0.55 })
	end

	local lantern = add({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.4,
		CFrame = CFrame.new(0, 8.5, -21),
		Material = Enum.Material.Neon,
		Color = ctx.palette.glow,
	})
	ship.PrimaryPart = hull
	return ship, lantern, CFrame.new(0, 4.2, -24)
end

function Scene.build(ctx)
	local p = ctx.palette
	local white = Color3.new(1, 1, 1)

	---------------------------------------------------------------- freeze
	ctx:at(0, function()
		ctx:camMove(ctx:look(Vector3.new(5, 3, 11), Vector3.new(0, 1.5, -12)), 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end)
	ctx:stoneTap(0.35)

	---------------------------------------------------------------- build
	local fogSource = ctx:part({ Size = Vector3.new(120, 1, 80), CFrame = ctx:cf(0, 0.5, -50), Transparency = 1 })
	local fog = Fx.emitter(fogSource, {
		Texture = Fx.SMOKE,
		LightEmission = 0,
		Color = ColorSequence.new(p.base:Lerp(white, 0.55)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 12), NumberSequenceKeypoint.new(1, 24) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.72), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(5, 7),
		Speed = NumberRange.new(1, 3),
		RotSpeed = NumberRange.new(-8, 8),
		EmissionDirection = Enum.NormalId.Top,
	})

	ctx:at(0.55, function()
		ctx:music(0.45)
	end)

	ctx:at(0.6, function()
		fog.Rate = 28
		ctx:atmosphere({ Density = 0.55, Offset = 0.15, Color = p.base:Lerp(white, 0.4), Decay = p.base, Haze = 2.5, Glare = 0 }, 1.6)
		ctx:lighting({ ExposureCompensation = -0.4 }, 1.4)
		ctx:grade({ Saturation = -0.35, TintColor = Color3.fromRGB(214, 236, 222) }, 1.4)
	end)
	ctx:at(0.8, function()
		ctx:sound("stir", 0.9)
	end)

	local ship, lantern, muzzleOffset = buildShip(ctx)
	local highlight = Fx.highlight(ship, p.glow, 1, p.glow, 1)
	local lanternLight = Fx.light(lantern, p.glow, 24, 0)
	Fx.hide(ship)
	lantern.Transparency = 1

	local shipFrom = ctx:cf(0, -2, -140) * Fx.FACE_PLAYER
	local shipTo = ctx:cf(-4, -2, -58) * Fx.FACE_PLAYER * CFrame.Angles(0, math.rad(-8), 0)
	local placeShip = Fx.mover(ship)
	local shipCf = shipFrom
	placeShip(shipFrom)

	-- The lantern arrives first, alone: one small light to look at.
	ctx:at(1.2, function()
		Fx.fade(ctx, lantern, 0, 0.8)
		ctx:tween(lanternLight, 0.8, { Brightness = 4 })
		ctx:camMove(ctx:look(Vector3.new(2.5, 3.2, 6), Vector3.new(-2, 7, -80)), 2.3)
	end)

	ctx:at(1.6, function()
		ctx:sound("rise", 0.85)
		ctx:shake(0.15, 2)
	end)

	ctx:at(2.0, function()
		Fx.fade(ctx, ship, 0, 1.4)
		ctx:tween(highlight, 1.4, { FillTransparency = 0.88, OutlineTransparency = 0.55 })
	end)

	local recoilAt = math.huge
	ctx:during(0, math.huge, function(_, t)
		local a = math.clamp((t - 2.0) / 2.6, 0, 1)
		local recoil = if t > recoilAt then 1.6 * math.exp(-(t - recoilAt) * 5) else 0
		local bob = math.sin(t * 1.3) * 0.25
		shipCf = shipFrom:Lerp(shipTo, Fx.ease(a, Enum.EasingStyle.Sine)) * CFrame.new(0, bob, recoil) * CFrame.Angles(math.rad(recoil * 2), 0, math.sin(t * 0.9) * math.rad(2))
		placeShip(shipCf)
	end)

	---------------------------------------------------------------- breath
	ctx:at(3.2, function()
		ctx:musicTo(0, 0.2)
		ctx:tween(highlight, 0.5, { OutlineTransparency = 0.1 })
		ctx:tween(lanternLight, 0.5, { Brightness = 7, Range = 34 })
	end)

	---------------------------------------------------------------- hit
	local coin = ctx:itemModel(3.2, Scene.placeholder)
	local placeCoin = Fx.mover(coin)
	Fx.hide(coin)
	local coinCarrier = Fx.anchor(ctx, ctx:cf(0, -20, 0))
	local trail = Fx.trail(coinCarrier, p.accent, 1.2, 0.35)
	trail.Enabled = false
	local coinLight = Fx.light(coinCarrier, p.accent, 14, 0)
	local sparkle = Fx.emitter(coinCarrier, {
		Color = ColorSequence.new(p.accent),
		Size = NumberSequence.new(0.5, 0),
		Speed = NumberRange.new(4, 9),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(0.5, 1),
		Drag = 3,
	})
	local rest = ctx:cf(0, 3.5, 0)

	ctx:hit(HIT, {
		flash = { color = p.accent:Lerp(white, 0.6), strength = 0.85, fade = 0.5 },
		shake = { amp = 0.8, dur = 0.6 },
		music = 0.8,
		fn = function()
			recoilAt = ctx.t
			local muzzle = shipCf * muzzleOffset
			local blast, blastLight = Fx.glow(ctx, muzzle, 4, Color3.fromRGB(255, 220, 160), 50, 14)
			ctx:tween(blast, 0.35, { Size = Vector3.one * 9, Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			ctx:tween(blastLight, 0.5, { Brightness = 0 })
			local smoke = Fx.emitter(blast, {
				Texture = Fx.SMOKE,
				LightEmission = 0,
				Color = ColorSequence.new(Color3.fromRGB(150, 160, 150)),
				Size = NumberSequence.new(3, 9),
				Transparency = NumberSequence.new(0.4, 1),
				Speed = NumberRange.new(6, 14),
				SpreadAngle = Vector2.new(35, 35),
				Lifetime = NumberRange.new(1, 2),
				Drag = 2,
			})
			smoke.EmissionDirection = Enum.NormalId.Front
			smoke:Emit(26)
			ctx:tween(lanternLight, 0.3, { Brightness = 3, Range = 24 })

			Fx.fade(ctx, coin, 0, 0.05)
			trail.Enabled = true
			ctx:tween(coinLight, 0.2, { Brightness = 3 })
			local from = muzzle.Position
			local to = rest.Position
			local apex = (from + to) / 2 + Vector3.yAxis * 10
			ctx:during(ctx.t, math.huge, function(_, lt)
				local fly = math.min(lt / 0.7, 1)
				local pos = Fx.bezier(from, apex, to, Fx.ease(fly, Enum.EasingStyle.Sine))
				-- five fast turns that decelerate to rest facing the player
				local spin = 10 * math.pi * Fx.ease(math.min(lt / 1.3, 1), Enum.EasingStyle.Quart)
				local bob = if lt > 0.7 then math.sin((lt - 0.7) * 2.2) * 0.18 else 0
				local cf = rest.Rotation * Fx.FACE_PLAYER * CFrame.Angles(0, spin, 0) + pos + Vector3.yAxis * bob
				placeCoin(cf)
				coinCarrier.CFrame = CFrame.new(pos)
				if lt >= 0.7 and trail.Enabled then
					trail.Enabled = false
					sparkle:Emit(30)
					Fx.ring(ctx, rest, p.accent, 0.5, 6, 0.7, 0.2)
				end
			end)
			ctx:camMove(ctx:look(Vector3.new(0.8, 3.9, 7.5), Vector3.new(0, 3.4, 0)), 0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		end,
	})

	---------------------------------------------------------------- reveal / title
	ctx:at(HIT + 0.6, function()
		ctx:camMove(ctx:look(Vector3.new(0.5, 3.8, 6), Vector3.new(0, 3.5, 0)), 2.2, Enum.EasingStyle.Linear)
		sparkle.Rate = 6
	end)
	ctx:at(5.0, function()
		-- the ship goes back where it came from
		Fx.fade(ctx, ship, 1, 1.2)
		ctx:tween(highlight, 1.2, { FillTransparency = 1, OutlineTransparency = 1 })
		ctx:tween(lanternLight, 1.2, { Brightness = 0 })
		fog.Rate = 10
	end)
end

return Scene
