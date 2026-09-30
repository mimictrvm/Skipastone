--[[
	The 3-second replay, used for every find after the first.

	It keeps each scene's identity (palette, strike sound, the creature
	itself) but none of the build-up. The flash is held to half strength:
	full-strength flashes belong to first finds only, so they stay special.

	0.00  bars in (0.3 s), camera pushes to the stone
	0.25  stone tap
	0.55  hit: strike + half flash + item pops from the water
	0.75  caption
	2.05  return; loot reveal at ~3.0
]]

local Fx = require(script.Parent.Fx)

local ShortScene = {
	freezeTime = 0.3,
	titleAt = 0.75,
	returnAt = 2.05,
}

function ShortScene.build(ctx, fullScene)
	local p = ctx.palette

	ctx:at(0, function()
		ctx:camMove(ctx:look(Vector3.new(2.5, 4, 11), Vector3.new(0, 3, 0)), 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end)
	ctx:stoneTap(0.25)

	local model = ctx:itemModel(6, fullScene.placeholder)
	local place = Fx.mover(model)
	Fx.hide(model)
	place(ctx:cf(0, -4, 0) * Fx.FACE_PLAYER)

	local holder = Fx.anchor(ctx, ctx:cf(0, 3, 0))
	local light = Fx.light(holder, p.glow, 16, 0)
	local sparks = Fx.emitter(holder, {
		Color = ColorSequence.new(p.glow, p.accent),
		Size = NumberSequence.new(0.6, 0),
		Speed = NumberRange.new(10, 18),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(0.4, 0.8),
		Drag = 4,
	})

	ctx:hit(0.55, {
		flash = { color = p.accent:Lerp(Color3.new(1, 1, 1), 0.5), strength = 0.5, fade = 0.4 },
		shake = { amp = 0.3, dur = 0.35 },
		fn = function()
			Fx.fade(ctx, model, 0, 0.1)
			sparks:Emit(40)
			ctx:tween(light, 0.1, { Brightness = 3 })
			ctx.stone.Transparency = 1
			Fx.ring(ctx, ctx:cf(0, 0.05, 0), p.accent, 1, 14, 0.8, 0.35)
			ctx:during(ctx.t, math.huge, function(_, lt)
				local rise = Fx.ease(math.min(lt / 0.35, 1), Enum.EasingStyle.Back)
				local y = -4 + 7 * rise + math.sin(lt * 2) * 0.15
				place(ctx:cf(0, y, 0) * Fx.FACE_PLAYER * CFrame.Angles(0, lt * 0.8, 0))
			end)
		end,
	})
end

return ShortScene
