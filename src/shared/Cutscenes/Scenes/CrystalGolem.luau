--[[
	CRYSTAL GOLEM  -  Crystal Caverns  -  "THE GOLEM WAKES"   (~10 s)
	The rarest item in the game. The biggest, longest scene.

	Palette  cavern violet-black / crystal cyan / magenta
	Focal    the stone. It glows, it rises, and it becomes the golem's heart

	Everything the other scenes do, this one does furthest: the longest
	rhythm (sixteen crystal pulses, accelerating), the longest silence
	(0.8 s), and the only full-strength, long-decay white flash reserved
	for a single item. It ends by coming back to the stone.

	0.00  FREEZE    camera close on the stone
	0.35            stone tap
	0.60  BUILD     the cavern's light dies over half a second; only the
	                stone glows
	1.10-3.30       crystals around the cavern pulse one after another,
	                circling, faster and higher each time (stir, rising
	                pitch); camera orbits with them
	3.40            every crystal fires a magenta beam at one point;
	                a core ignites there; the stone rises into it;
	                cavern rumble (rise), dust falls, shaking builds
	3.90-5.90       shards tear loose and fly in, snapping together from
	                the feet up (stir, pitched down) into a giant
	6.00  BREATH    everything goes dark and silent for 0.8 s. The golem
	                stands unlit
	6.80  HIT       the core ignites: FULL white flash with the longest
	                decay, heaviest shake, every crystal flares, eyes open,
	                awakening boom + choir (strike); low camera
	7.20  TITLE     THE GOLEM WAKES / 1 in N / THE RAREST CATCH IN THE GAME
	8.40            the golem bows; its heart pulses once with the stone
	                tap: the stone the player threw
	9.10  RETURN
]]

local Fx = require(script.Parent.Parent.Fx)

local Scene = {
	titleAt = 7.2,
	returnAt = 9.1,
	extra = "THE RAREST CATCH IN THE GAME",
}

local HIT = 6.8
local GOLEM_SIZE = 18
local STAND = Vector3.new(0, -2, -6)
local CRYSTAL_RING = 22

function Scene.placeholder(ctx): Model
	local model, add = Fx.newModel(ctx, "GolemPlaceholder")
	local rng = Random.new(7)
	local crystal = ctx.palette.glow:Lerp(Color3.new(0, 0, 0), 0.45)
	local function shard(pos: Vector3, size: Vector3)
		add(ctx:part({
			Size = size,
			CFrame = CFrame.new(pos) * CFrame.Angles(rng:NextNumber(-0.12, 0.12), rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.12, 0.12)),
			Color = crystal,
			Material = Enum.Material.Glass,
			Transparency = 0.1,
		}))
	end
	for _, side in { -1, 1 } do
		shard(Vector3.new(side * 1.6, 1.4, 0), Vector3.new(2.4, 2.8, 2.8))
		shard(Vector3.new(side * 1.6, 4.3, 0), Vector3.new(2, 3.2, 2.2))
		shard(Vector3.new(side * 3.8, 11.2, 0), Vector3.new(2.6, 2.4, 2.8))
		shard(Vector3.new(side * 4.1, 8.6, 0), Vector3.new(1.8, 3.4, 1.8))
		shard(Vector3.new(side * 4.3, 5.4, -0.3), Vector3.new(2.3, 3.6, 2.3))
		shard(Vector3.new(side * 1.3, 12.1, 1.8), Vector3.new(0.8, 3, 0.8))
	end
	shard(Vector3.new(0, 6.6, 0), Vector3.new(5, 1.8, 3))
	shard(Vector3.new(0, 8.6, 0), Vector3.new(5, 2.4, 3.2))
	shard(Vector3.new(0, 10.8, 0), Vector3.new(5.8, 2.4, 3.6))
	shard(Vector3.new(0, 13.2, -0.2), Vector3.new(2.8, 2.4, 2.6))
	shard(Vector3.new(0, 12.8, 1.9), Vector3.new(1, 3.6, 1))
	return model
end

local function visibleParts(model: Model): { BasePart }
	local out = {}
	for _, part in Fx.parts(model) do
		local base = part:GetAttribute("CutsceneBaseT") or part.Transparency
		if base < 1 then
			table.insert(out, part)
		end
	end
	return out
end

type Cluster = { parts: { BasePart }, light: PointLight, top: Vector3 }

local function buildCrystals(ctx): { Cluster }
	local rng = Random.new(21)
	local clusters = {}
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local base = Vector3.new(math.cos(angle) * CRYSTAL_RING, -1, math.sin(angle) * CRYSTAL_RING - 4)
		local parts = {}
		local top = base
		for k = 1, 3 do
			local h = rng:NextNumber(5, 9) * (if k == 1 then 1.3 else 0.8)
			local offset = Vector3.new(rng:NextNumber(-1.2, 1.2), 0, rng:NextNumber(-1.2, 1.2))
			local cf = ctx:cf(base.X + offset.X, base.Y + h / 2, base.Z + offset.Z)
				* CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3))
			table.insert(parts, ctx:part({
				Size = Vector3.new(1.6, h, 1.6),
				CFrame = cf,
				Color = ctx.palette.glow:Lerp(Color3.new(0, 0, 0), 0.6),
				Material = Enum.Material.Glass,
				Transparency = 0.15,
			}))
			if k == 1 then
				top = (cf * CFrame.new(0, h / 2, 0)).Position
			end
		end
		local light = Fx.light(parts[1], ctx.palette.glow, 16, 0)
		table.insert(clusters, { parts = parts, light = light, top = top })
	end
	return clusters
end

function Scene.build(ctx)
	local p = ctx.palette
	local white = Color3.new(1, 1, 1)
	local rng = Random.new()

	---------------------------------------------------------------- freeze
	ctx:at(0, function()
		ctx:camMove(ctx:look(Vector3.new(0, 4, 12), Vector3.new(0, 2, 0)), 0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end)
	ctx:stoneTap(0.35)

	---------------------------------------------------------------- golem (hidden, in final pose)
	local golem, isPlaceholder = ctx:itemModel(GOLEM_SIZE, Scene.placeholder)
	local swapIn: Model? = nil
	if not isPlaceholder and #visibleParts(golem) < 6 then
		-- The Index model is too simple to fly together piece by piece:
		-- assemble crystal shards instead, and swap it in under the flash.
		swapIn = golem
		golem = Scene.placeholder(ctx)
		ctx:fit(golem, GOLEM_SIZE)
		golem.Parent = ctx.folder
	end

	local _, size = golem:GetBoundingBox()
	local home = ctx:cf(STAND.X, STAND.Y + size.Y / 2, STAND.Z) * Fx.FACE_PLAYER
	local placeGolem = Fx.mover(golem)
	placeGolem(home)
	local placeSwap: ((CFrame) -> ())? = nil
	if swapIn then
		local mover = Fx.mover(swapIn)
		mover(home)
		placeSwap = mover
		Fx.hide(swapIn)
	end

	local coreLocal = CFrame.new(0, size.Y * 0.14, -size.Z * 0.2)
	local corePos = (home * coreLocal).Position
	local eyeLocals = {
		CFrame.new(-size.X * 0.08, size.Y * 0.4, -size.Z * 0.45),
		CFrame.new(size.X * 0.08, size.Y * 0.4, -size.Z * 0.45),
	}

	local pieces = visibleParts(golem)
	table.sort(pieces, function(a, b)
		return a.Position.Y < b.Position.Y
	end)
	Fx.hide(golem)

	---------------------------------------------------------------- lights die
	local stoneLight = Fx.light(ctx.stone, p.glow, 12, 0)
	ctx:at(0.6, function()
		ctx:lighting({
			Brightness = 0.2,
			ExposureCompensation = -2,
			Ambient = Color3.fromRGB(8, 6, 14),
			OutdoorAmbient = Color3.fromRGB(10, 8, 18),
		}, 0.5)
		ctx:grade({ Saturation = -0.2, Contrast = 0.1 }, 0.5)
		ctx:tween(stoneLight, 0.5, { Brightness = 1.5 })
		ctx.stone.Material = Enum.Material.Neon
		ctx.stone.Color = p.glow:Lerp(Color3.new(0, 0, 0), 0.4)
	end)

	---------------------------------------------------------------- crystal pulses
	local clusters = buildCrystals(ctx)
	local dimColor = p.glow:Lerp(Color3.new(0, 0, 0), 0.6)
	local function pulse(c: Cluster, color: Color3, brightness: number, hold: boolean)
		for _, part in c.parts do
			part.Material = Enum.Material.Neon
			part.Color = color
		end
		c.light.Color = color
		c.light.Brightness = brightness
		if not hold then
			ctx:tween(c.light, 0.45, { Brightness = 0.2 })
			ctx:at(ctx.t + 0.3, function()
				for _, part in c.parts do
					part.Material = Enum.Material.Glass
					part.Color = dimColor
				end
			end)
		end
	end

	local t, interval = 1.1, 0.34
	for k = 0, 15 do
		local cluster = clusters[(k % #clusters) + 1]
		local pitch = 0.8 + 0.8 * k / 15
		ctx:at(t, function()
			ctx:sound("stir", 0.75, pitch)
			pulse(cluster, p.glow, 4, false)
		end)
		t += interval
		interval *= 0.86
	end

	ctx:at(1.1, function()
		ctx:camPath(2.3, function(a)
			local angle = math.rad(120) * a
			return ctx:look(Vector3.new(math.sin(angle) * 14, 5, math.cos(angle) * 14), Vector3.new(0, 2, -2))
		end, Enum.EasingStyle.Linear)
	end)

	---------------------------------------------------------------- convergence
	local core, coreLight = Fx.glow(ctx, CFrame.new(corePos), 1.4, p.glow, 20, 0)
	core.Transparency = 1
	local dustSource = ctx:part({ Size = Vector3.new(60, 1, 60), CFrame = ctx:cf(0, 30, -6), Transparency = 1 })
	local dust = Fx.emitter(dustSource, {
		Texture = Fx.SMOKE,
		LightEmission = 0,
		Color = ColorSequence.new(Color3.fromRGB(150, 140, 165)),
		Size = NumberSequence.new(0.35, 0.2),
		Speed = NumberRange.new(0, 1),
		Acceleration = Vector3.new(0, -24, 0),
		Lifetime = NumberRange.new(1.5, 2),
		EmissionDirection = Enum.NormalId.Bottom,
	})

	local rumble: Sound? = nil
	ctx:at(3.4, function()
		rumble = ctx:sound("rise", 0.9)
		ctx:shake(0.3, 2.6, 10)
		dust.Rate = 60
		for _, c in clusters do
			pulse(c, p.accent, 3, true)
			local beam = Fx.column(ctx, c.top, corePos, 0.25, p.accent, 0.15)
			ctx:tween(beam, 0.6, { Transparency = 1 })
		end
		core.Transparency = 0
		ctx:tween(coreLight, 0.3, { Brightness = 3 })
		local from = ctx.stone.Position
		ctx:during(3.4, 0.5, function(a)
			local pos = from:Lerp(corePos, Fx.ease(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
			ctx.stone.CFrame = CFrame.new(pos) * CFrame.Angles(a * 4, a * 6, 0)
			if a >= 1 then
				ctx.stone.Transparency = 1
				stoneLight.Brightness = 0
			end
		end)
		ctx:camMove(ctx:look(Vector3.new(0, 6, 20), Vector3.new(0, 8, STAND.Z)), 0.8)
	end)
	ctx:at(4.0, function()
		for _, c in clusters do
			pulse(c, p.glow, 1.2, false)
		end
	end)

	---------------------------------------------------------------- assembly
	local n = #pieces
	local clackEvery = math.max(1, math.ceil(n / 12))
	local spark = Fx.emitter(core, {
		Color = ColorSequence.new(p.glow, white),
		Size = NumberSequence.new(0.4, 0),
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(0.3, 0.6),
		Drag = 3,
	})
	for i, piece in pieces do
		local final = piece.CFrame
		local angle = rng:NextNumber(math.pi + 0.3, 2 * math.pi - 0.3)
		local radius = rng:NextNumber(20, 26)
		local start = ctx:cf(math.cos(angle) * radius, rng:NextNumber(0, 10), math.sin(angle) * radius)
			* CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6))
		local control = (start.Position + final.Position) / 2 + Vector3.yAxis * 6
		local arrive = 4.2 + (if n > 1 then (i - 1) / (n - 1) else 0) * 1.7
		local launch = math.max(3.9, arrive - 0.75)
		ctx:during(launch, arrive - launch, function(a)
			if piece.Transparency == 1 then
				piece.Transparency = piece:GetAttribute("CutsceneBaseT") or 0
			end
			local e = Fx.ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			piece.CFrame = start.Rotation:Lerp(final.Rotation, e) + Fx.bezier(start.Position, control, final.Position, e)
			if a >= 1 then
				piece.CFrame = final
				if i % clackEvery == 0 then
					ctx:sound("stir", 0.9, rng:NextNumber(0.5, 0.6))
					ctx:shake(0.12, 0.15)
				end
				spark.Parent = piece
				spark:Emit(6)
			end
		end)
	end
	ctx:at(3.9, function()
		ctx:camMove(ctx:look(Vector3.new(0, 3, 26), Vector3.new(0, 8, STAND.Z)), 2.1)
	end)

	---------------------------------------------------------------- breath
	ctx:at(6.0, function()
		ctx:cut(rumble, 0.1)
		dust.Rate = 0
		for _, c in clusters do
			for _, part in c.parts do
				part.Material = Enum.Material.Glass
				part.Color = Color3.fromRGB(24, 30, 48)
			end
			ctx:tween(c.light, 0.3, { Brightness = 0 })
		end
		ctx:tween(coreLight, 0.3, { Brightness = 0.15 })
		ctx:tween(core, 0.3, { Transparency = 0.7 })
		ctx.ui:tintTo(Color3.new(0, 0, 0), 0.45, 0.3)
		ctx:camMove(ctx:look(Vector3.new(0, 2.6, 24), Vector3.new(0, 9, STAND.Z)), 0.8, Enum.EasingStyle.Linear)
	end)

	---------------------------------------------------------------- hit
	local eyes = {}
	for _ in eyeLocals do
		local eye, eyeLight = Fx.glow(ctx, home, math.max(size.Y * 0.035, 0.35), p.glow, 8, 0)
		eye.Transparency = 1
		table.insert(eyes, { part = eye, light = eyeLight })
	end

	local bowFrom = math.huge
	ctx:hit(HIT, {
		flash = { color = white, strength = 1, fade = 1.2 },
		shake = { amp = 1.5, dur = 1.2, freq = 16 },
		fn = function()
			ctx:music(0.9)
			if swapIn then
				Fx.hide(golem)
				Fx.fade(ctx, swapIn, 0, 0.01)
			end
			core.Transparency = 0
			core.Size = Vector3.one * 2
			coreLight.Brightness = 6
			coreLight.Range = 30
			for i, c in clusters do
				pulse(c, if i % 2 == 0 then p.accent else p.glow, 3, true)
			end
			for _, e in eyes do
				e.part.Transparency = 0
				e.light.Brightness = 3
			end
			ctx:lighting({
				Brightness = 1,
				ExposureCompensation = 0.2,
				Ambient = Color3.fromRGB(60, 40, 80),
				OutdoorAmbient = Color3.fromRGB(70, 50, 90),
			}, 0.4)
			ctx:grade({ Saturation = 0.2, Contrast = 0.15 }, 0.4)
			ctx:bloom({ Intensity = 1.6, Size = 40, Threshold = 0.8 }, 0)
			ctx:bloom({ Intensity = 0.6 }, 1.5)
			Fx.ring(ctx, ctx:cf(STAND.X, 0.1, STAND.Z), p.accent, 2, 50, 1.3, 0.7, 48)
			spark.Parent = core
			spark:Emit(60)

			ctx:during(ctx.t, math.huge, function(_, lt)
				local jolt = 0.7 * math.sin(math.min(lt / 0.45, 1) * math.pi)
				local breathe = math.sin(lt * 1.6) * 0.12
				local bow = 0
				if ctx.t > bowFrom then
					local a = math.min((ctx.t - bowFrom) / 0.7, 1)
					bow = math.rad(-10) * Fx.ease(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				end
				local cf = home * CFrame.new(0, jolt + breathe, 0) * CFrame.Angles(bow, 0, 0)
				placeGolem(cf)
				if placeSwap then
					placeSwap(cf)
				end
				core.CFrame = cf * coreLocal
				for i, e in eyes do
					e.part.CFrame = cf * eyeLocals[i]
				end
			end)

			ctx:cam(ctx:look(Vector3.new(0, 0.8, 16), Vector3.new(0, 11, STAND.Z)))
			ctx:camMove(ctx:look(Vector3.new(0, 0.8, 14.5), Vector3.new(0, 11.5, STAND.Z)), 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			ctx:fov(80, 0.3)
		end,
	})

	ctx:at(HIT + 0.4, function()
		ctx:camMove(ctx:look(Vector3.new(0, 1.2, 12.5), Vector3.new(0, 12, STAND.Z)), 1.9, Enum.EasingStyle.Linear)
	end)

	-- shimmer while the title holds
	for k = 0, 5 do
		ctx:at(HIT + 0.9 + k * 0.3, function()
			local c = clusters[rng:NextInteger(1, #clusters)]
			ctx:tween(c.light, 0.15, { Brightness = 5 })
			ctx:at(ctx.t + 0.15, function()
				ctx:tween(c.light, 0.3, { Brightness = 3 })
			end)
		end)
	end

	---------------------------------------------------------------- the bow
	ctx:at(8.4, function()
		bowFrom = ctx.t
	end)
	ctx:at(8.65, function()
		ctx:sound("stoneTap", 1, 0.8)
		core.Size = Vector3.one * 2.8
		ctx:tween(core, 0.4, { Size = Vector3.one * 2 })
		coreLight.Brightness = 10
		ctx:tween(coreLight, 0.5, { Brightness = 6 })
		Fx.ring(ctx, CFrame.new(core.Position) * ctx.origin.Rotation * CFrame.Angles(math.rad(90), 0, 0), p.glow, 1, 6, 0.6, 0.15)
	end)
end

return Scene
