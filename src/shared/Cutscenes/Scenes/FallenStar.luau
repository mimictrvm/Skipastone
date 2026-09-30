--[[
	FALLEN STAR  -  Meteor Fall  -  "A STAR HAS FALLEN"   (~7.6 s)

	Palette  indigo night / star white-gold / impact orange
	Focal    one point of light in a darkened sky

	The contrast scene. Just before impact, the whistle cuts and the screen
	dips toward black for a moment, so the full white flash that follows is
	the brightest thing the player has seen in the game so far.

	0.00  FREEZE    camera behind the stone, looking out
	0.35            stone tap
	0.50            music bed (sparse synth pad)
	0.60  BUILD     sky darkens to night; cosmic hum (stir); camera tilts up
	1.80            one star appears and twinkles. Nothing else moves
	2.40            it breaks loose and streaks down (rise: falling whistle);
	                camera tracks it, pulling back
	3.75  BREATH    whistle cuts; screen dips dark for 0.15 s
	3.90  HIT       impact (strike): FULL white flash, heavy shake,
	                shockwave rings, water column, steam
	4.30  REVEAL    the star rises out of the steam, turning slowly
	5.00  TITLE
	6.60  RETURN
]]

local Lighting = game:GetService("Lighting")

local Fx = require(script.Parent.Parent.Fx)

local Scene = {
	titleAt = 5.0,
	returnAt = 6.6,
}

local HIT = 3.9
local SKY = Vector3.new(-60, 140, -260)
local IMPACT = Vector3.new(8, 0, -45)

function Scene.placeholder(ctx): Model
	local model, add = Fx.newModel(ctx, "StarPlaceholder")
	local glow = ctx.palette.glow
	add(ctx:part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1.8, Material = Enum.Material.Neon, Color = glow }))
	for i = 0, 4 do
		local angle = math.rad(i * 72)
		add(ctx:part({
			Size = Vector3.new(0.7, 2.4, 0.5),
			CFrame = CFrame.Angles(0, 0, angle) * CFrame.new(0, 1.5, 0),
			Material = Enum.Material.Neon,
			Color = glow:Lerp(ctx.palette.accent, 0.25),
		}))
	end
	return model
end

function Scene.build(ctx)
	local p = ctx.palette
	local white = Color3.new(1, 1, 1)

	---------------------------------------------------------------- freeze
	ctx:at(0, function()
		ctx:camMove(ctx:look(Vector3.new(0, 4, 10), Vector3.new(0, 2, -10)), 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end)
	ctx:stoneTap(0.35)
	ctx:at(0.5, function()
		ctx:music(0.4)
	end)

	---------------------------------------------------------------- build
	ctx:at(0.6, function()
		ctx:sound("stir", 0.9)
		local clock = Lighting.ClockTime
		if clock > 5 and clock < 21.5 then
			ctx:lighting({ ClockTime = 22.5 }, 1.4)
		end
		ctx:lighting({ ExposureCompensation = -0.6 }, 1.4)
		ctx:grade({ TintColor = Color3.fromRGB(200, 200, 255), Saturation = -0.2 }, 1.4)
		ctx:atmosphere({ Density = 0.2, Haze = 0, Glare = 0, Color = p.base, Decay = p.base }, 1.4)
		ctx:camMove(ctx:look(Vector3.new(0, 3, 10), SKY), 1.3, Enum.EasingStyle.Sine)
	end)

	local meteor, meteorLight = Fx.glow(ctx, ctx:cf(SKY.X, SKY.Y, SKY.Z), 7, p.glow, 60, 0)
	meteor.Transparency = 1
	local trail = Fx.trail(meteor, p.glow:Lerp(p.accent, 0.3), 5, 0.7)
	trail.Enabled = false

	-- a lone star, twinkling
	ctx:at(1.8, function()
		ctx:tween(meteor, 0.4, { Transparency = 0 })
		ctx:tween(meteorLight, 0.4, { Brightness = 3 })
		ctx:during(1.8, 0.6, function(_, lt)
			meteor.Size = Vector3.one * (6 + math.sin(lt * 22) * 1.2)
		end)
	end)

	local function meteorAt(a: number): Vector3
		-- slight curve so it reads as falling, not sliding
		local mid = (SKY + IMPACT) / 2 + Vector3.new(0, 25, 0)
		return Fx.bezier(SKY, mid, IMPACT, Fx.ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
	end

	local whistle: Sound? = nil
	ctx:at(2.4, function()
		whistle = ctx:sound("rise", 0.9)
		trail.Enabled = true
		ctx:tween(meteorLight, 1.5, { Range = 60, Brightness = 8 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		ctx:during(2.4, HIT - 2.4, function(a)
			local here = meteorAt(a)
			meteor.CFrame = ctx:cf(here.X, here.Y, here.Z)
		end)
		ctx:camPath(HIT - 2.4, function(a)
			local here = meteorAt(a)
			local from = Vector3.new(0, 3, 10):Lerp(Vector3.new(-4, 2.5, 13), a)
			return ctx:look(from, here:Lerp(IMPACT + Vector3.new(0, 4, 0), 0.35 + 0.4 * a))
		end, Enum.EasingStyle.Linear)
		ctx:shake(0.2, 1.5, 12)
	end)

	---------------------------------------------------------------- breath
	ctx:at(HIT - 0.15, function()
		ctx:cut(whistle, 0.05)
		ctx.ui:tintTo(Color3.new(0, 0, 0), 0.4, 0.08)
	end)

	---------------------------------------------------------------- hit
	local impactCf = ctx:cf(IMPACT.X, 0.1, IMPACT.Z)
	local impactAnchor = Fx.anchor(ctx, impactCf)
	local impactLight = Fx.light(impactAnchor, p.accent, 70, 0)
	local steam = Fx.emitter(impactAnchor, {
		Texture = Fx.SMOKE,
		LightEmission = 0.3,
		Color = ColorSequence.new(white, p.glow),
		Size = NumberSequence.new(4, 14),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.55), NumberSequenceKeypoint.new(1, 1) }),
		Speed = NumberRange.new(3, 7),
		SpreadAngle = Vector2.new(30, 30),
		Lifetime = NumberRange.new(2, 3.5),
		EmissionDirection = Enum.NormalId.Top,
	})
	local spray = Fx.emitter(impactAnchor, {
		LightEmission = 0.6,
		Color = ColorSequence.new(white),
		Size = NumberSequence.new(1.2, 0.2),
		Speed = NumberRange.new(30, 55),
		SpreadAngle = Vector2.new(35, 35),
		Acceleration = Vector3.new(0, -60, 0),
		Lifetime = NumberRange.new(1, 1.6),
		EmissionDirection = Enum.NormalId.Top,
	})

	local star = ctx:itemModel(5, Scene.placeholder)
	local placeStar = Fx.mover(star)
	Fx.hide(star)
	placeStar(ctx:cf(IMPACT.X, -3, IMPACT.Z))
	local starAnchor = Fx.anchor(ctx, ctx:cf(IMPACT.X, -3, IMPACT.Z))
	local starLight = Fx.light(starAnchor, p.glow, 22, 0)
	local sparkle = Fx.emitter(starAnchor, {
		Color = ColorSequence.new(p.glow, p.accent),
		Size = NumberSequence.new(0.5, 0),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(0.8, 1.4),
		Drag = 1,
	})

	ctx:hit(HIT, {
		flash = { color = white, strength = 1, fade = 0.9 },
		shake = { amp = 1.2, dur = 0.9 },
		music = 0.8,
		fn = function()
			meteor.Transparency = 1
			meteorLight.Enabled = false
			trail.Enabled = false
			impactLight.Brightness = 12
			ctx:tween(impactLight, 1.4, { Brightness = 0 })
			ctx:lighting({ ExposureCompensation = 1.2 }, 0)
			ctx:lighting({ ExposureCompensation = -0.6 }, 1.1)
			Fx.ring(ctx, impactCf, p.accent, 2, 60, 1.0, 0.8, 48)
			Fx.ring(ctx, impactCf, white, 1, 35, 0.7, 0.4, 40)
			spray:Emit(90)
			steam.Rate = 14
			local column = Fx.column(ctx, impactCf.Position, impactCf.Position + Vector3.yAxis * 0.1, 3, white, 0.3)
			ctx:during(ctx.t, 1.1, function(a)
				local h = 28 * Fx.ease(math.min(a / 0.35, 1), Enum.EasingStyle.Quart)
				Fx.stretch(column, impactCf.Position, impactCf.Position + Vector3.yAxis * math.max(h, 0.1), 3 + 2 * a)
				column.Transparency = 0.3 + 0.7 * math.clamp((a - 0.3) / 0.7, 0, 1)
			end)
			ctx:cam(ctx:look(Vector3.new(-4, 2.5, 13), IMPACT + Vector3.new(0, 6, 0)))
		end,
	})

	---------------------------------------------------------------- reveal
	ctx:at(HIT + 0.4, function()
		Fx.fade(ctx, star, 0, 0.5)
		ctx:tween(starLight, 0.8, { Brightness = 3 })
		sparkle.Rate = 12
		ctx:during(ctx.t, math.huge, function(_, lt)
			local rise = Fx.ease(math.min(lt / 1.0, 1), Enum.EasingStyle.Sine)
			local y = -3 + 9 * rise + math.sin(lt * 1.8) * 0.2
			local cf = ctx:cf(IMPACT.X, y, IMPACT.Z) * Fx.FACE_PLAYER * CFrame.Angles(0, lt * 0.6, 0)
			placeStar(cf)
			starAnchor.CFrame = cf
		end)
		ctx:camMove(ctx:look(Vector3.new(4, 4.5, -28), IMPACT + Vector3.new(0, 6, 0)), 1.3, Enum.EasingStyle.Sine)
	end)
	ctx:at(HIT + 1.2, function()
		steam.Rate = 5
	end)
end

return Scene
