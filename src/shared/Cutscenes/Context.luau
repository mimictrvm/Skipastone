--[[
	Context: the timeline a scene is written against.

	One clock drives everything. Scenes schedule work with ctx:at(t, fn) and
	ctx:during(t, duration, fn), always in seconds from the start of the
	scene. Because sound, light, camera and effects all read the same clock,
	cues scheduled for the same time land on the same frame.

	Scene space: ctx:pos / ctx:cf take coordinates relative to the landing
	point. +X is right, +Y is up, -Z is away from the player (out over the
	water). Y = 0 is the water surface where the stone landed.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.Config)
local Hooks = require(script.Parent.Hooks)

type Updater = { t0: number, dur: number, fn: (number, number, number) -> () }
type Shake = { t0: number, dur: number, amp: number, freq: number }
type CamPath = { t0: number, dur: number, fn: (number) -> CFrame, style: Enum.EasingStyle, dir: Enum.EasingDirection }

local Context = {}
Context.__index = Context

function Context.new(itemId: string, entry: Config.Entry, landing: Vector3, forward: Vector3, ui, oneIn: number?)
	local self = setmetatable({}, Context)
	self.itemId = itemId
	self.entry = entry
	self.palette = entry.palette
	self.ui = ui
	self.oneIn = oneIn
	self.origin = CFrame.lookAt(landing, landing + forward)
	self.t = 0

	self.folder = Instance.new("Folder")
	self.folder.Name = "CutsceneFx"
	self.folder.Parent = workspace

	self._events = {} :: { { time: number, seq: number, fn: () -> (), fired: boolean } }
	self._seq = 0
	self._updaters = {} :: { Updater }
	self._shakes = {} :: { Shake }
	self._camPath = nil :: CamPath?
	self._fov = nil :: { t0: number, dur: number, from: number, to: number, style: Enum.EasingStyle }?
	self._tweens = {} :: { Tween }
	self._cleanups = {} :: { () -> () }
	self._saved = {} :: { [Instance]: { [string]: any } }
	self._music = nil :: Sound?

	local camera = workspace.CurrentCamera
	self.camBase = camera.CFrame
	self.fovValue = camera.FieldOfView
	self.cameraLocked = true
	return self
end

---------------------------------------------------------------- scene space

function Context:pos(x: number, y: number, z: number): Vector3
	return self.origin:PointToWorldSpace(Vector3.new(x, y, z))
end

function Context:cf(x: number, y: number, z: number): CFrame
	return self.origin * CFrame.new(x, y, z)
end

-- Camera CFrame at local point `from`, looking at local point `to`.
function Context:look(from: Vector3, to: Vector3): CFrame
	return CFrame.lookAt(self.origin:PointToWorldSpace(from), self.origin:PointToWorldSpace(to))
end

---------------------------------------------------------------- timeline

function Context:at(time: number, fn: () -> ())
	self._seq += 1
	local ev = { time = time, seq = self._seq, fn = fn, fired = false }
	local events = self._events
	local i = #events + 1
	while i > 1 and events[i - 1].time > time do
		i -= 1
	end
	table.insert(events, i, ev)
end

-- fn(alpha 0..1, seconds since t0, dt) runs every frame from t0 for dur
-- seconds, and once more with alpha = 1 when it ends. dur may be math.huge.
function Context:during(t0: number, dur: number, fn: (number, number, number) -> ())
	table.insert(self._updaters, { t0 = t0, dur = dur, fn = fn })
end

function Context:onCleanup(fn: () -> ())
	table.insert(self._cleanups, fn)
end

local function safe(label: string, fn: (...any) -> (), ...): boolean
	local ok, err = pcall(fn, ...)
	if not ok then
		warn(`[Cutscene] {label} failed: {err}`)
	end
	return ok
end

function Context:step(dt: number)
	self.t += dt
	local t = self.t

	for _, ev in self._events do
		if ev.time > t then
			break
		end
		if not ev.fired then
			ev.fired = true
			safe("event", ev.fn)
		end
	end

	local keep = {}
	for _, u in self._updaters do
		if t >= u.t0 then
			local localT = t - u.t0
			local done = localT >= u.dur
			local alpha = if u.dur == math.huge then 0 else math.clamp(localT / u.dur, 0, 1)
			local ok = safe("updater", u.fn, alpha, localT, dt)
			if ok and not done then
				table.insert(keep, u)
			end
		else
			table.insert(keep, u)
		end
	end
	self._updaters = keep

	self:_stepCamera(t)
end

---------------------------------------------------------------- camera

function Context:_stepCamera(t: number)
	local path = self._camPath
	if path and t >= path.t0 then
		local a = math.clamp((t - path.t0) / path.dur, 0, 1)
		self.camBase = path.fn(TweenService:GetValue(a, path.style, path.dir))
		if a >= 1 then
			self._camPath = nil
		end
	end

	local fov = self._fov
	if fov then
		local a = math.clamp((t - fov.t0) / fov.dur, 0, 1)
		self.fovValue = fov.from + (fov.to - fov.from) * TweenService:GetValue(a, fov.style, Enum.EasingDirection.InOut)
		if a >= 1 then
			self._fov = nil
		end
	end

	local offset, rot = Vector3.zero, Vector3.zero
	local live = {}
	for _, s in self._shakes do
		local p = (t - s.t0) / s.dur
		if p < 1 then
			table.insert(live, s)
			local amp = s.amp * (1 - p) ^ 2
			local n = t * s.freq
			offset += Vector3.new(math.noise(n, 1.3), math.noise(2.1, n), math.noise(n, n + 3.7)) * amp * 0.4
			rot += Vector3.new(math.noise(n + 5.2, 0.4), math.noise(0.8, n + 9.1), 0) * amp * 0.015
		end
	end
	self._shakes = live

	if self.cameraLocked then
		local camera = workspace.CurrentCamera
		camera.CFrame = self.camBase * CFrame.new(offset) * CFrame.Angles(rot.X, rot.Y, 0)
		camera.FieldOfView = self.fovValue
	end
end

-- Hard cut.
function Context:cam(cf: CFrame)
	self._camPath = nil
	self.camBase = cf
end

-- Custom camera move: fn(eased alpha) -> CFrame. Starts at the current time.
function Context:camPath(dur: number, fn: (number) -> CFrame, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	self._camPath = {
		t0 = self.t,
		dur = math.max(dur, 1e-3),
		fn = fn,
		style = style or Enum.EasingStyle.Sine,
		dir = dir or Enum.EasingDirection.InOut,
	}
end

-- Glide from wherever the camera is now to `to`.
function Context:camMove(to: CFrame, dur: number, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local from = self.camBase
	self:camPath(dur, function(a)
		return from:Lerp(to, a)
	end, style, dir)
end

function Context:fov(to: number, dur: number, style: Enum.EasingStyle?)
	self._fov = { t0 = self.t, dur = math.max(dur, 1e-3), from = self.fovValue, to = to, style = style or Enum.EasingStyle.Sine }
end

-- amp ~0.2 is a tremor, ~1 a heavy hit, ~1.5 the biggest moment in the game.
function Context:shake(amp: number, dur: number, freq: number?)
	table.insert(self._shakes, { t0 = self.t, dur = dur, amp = amp, freq = freq or 18 })
end

---------------------------------------------------------------- sound

local function soundId(entry: Config.Entry, name: string): string
	local id = (entry.sounds :: any)[name] or (Config.shared :: any)[name]
	return id or ""
end

-- Plays one of the scene's cues (music/stir/rise/strike) or a shared cue
-- (stoneTap/titleSlam). Returns nil when the slot has no id yet.
function Context:sound(name: string, volume: number?, speed: number?): Sound?
	local id = soundId(self.entry, name)
	if id == "" then
		return nil
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 1
	s.PlaybackSpeed = speed or 1
	s.Parent = self.ui.gui
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	return s
end

function Context:music(volume: number)
	local id = soundId(self.entry, "music")
	if id == "" or self._music then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Looped = true
	s.Volume = volume
	s.Parent = self.ui.gui
	s:Play()
	self._music = s
end

function Context:musicTo(volume: number, dur: number)
	if self._music then
		self:tween(self._music, dur, { Volume = volume })
	end
end

-- Fades a playing cue out quickly; used to cut sound before a hit.
function Context:cut(s: Sound?, dur: number?)
	if s and s.Parent then
		self:tween(s, dur or 0.08, { Volume = 0 })
	end
end

---------------------------------------------------------------- world

function Context:tween(inst: Instance, dur: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween?
	if dur <= 0 then
		for k, v in props do
			(inst :: any)[k] = v
		end
		return nil
	end
	local tw = TweenService:Create(inst, TweenInfo.new(dur, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.InOut), props)
	tw:Play()
	table.insert(self._tweens, tw)
	return tw
end

function Context:part(props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	if not (props and props.Parent) then
		p.Parent = self.folder
	end
	return p
end

-- Remembers a property's value the first time a scene changes it, so
-- teardown can put the world back exactly as it was.
function Context:_remember(inst: Instance, props: { [string]: any })
	local saved = self._saved[inst]
	if not saved then
		saved = {}
		self._saved[inst] = saved
	end
	for k in props do
		if saved[k] == nil then
			saved[k] = (inst :: any)[k]
		end
	end
end

-- Temporarily changes a world property (Lighting, Terrain, Atmosphere...).
function Context:setWorld(inst: Instance, props: { [string]: any }, dur: number, style: Enum.EasingStyle?)
	self:_remember(inst, props)
	self:tween(inst, dur, props, style)
end

function Context:lighting(props: { [string]: any }, dur: number, style: Enum.EasingStyle?)
	self:setWorld(Lighting, props, dur, style)
end

function Context:terrain(props: { [string]: any }, dur: number)
	self:setWorld(workspace.Terrain, props, dur)
end

-- Uses the place's Atmosphere if it has one, otherwise a temporary one.
function Context:atmosphere(props: { [string]: any }, dur: number)
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmo then
		atmo = Instance.new("Atmosphere")
		atmo.Density = 0
		atmo.Haze = 0
		atmo.Glare = 0
		atmo.Parent = Lighting
		local created = atmo
		self:onCleanup(function()
			created:Destroy()
		end)
	end
	self:setWorld(atmo :: Atmosphere, props, dur)
end

local function ownEffect(self, className: string): Instance
	local key = "_" .. className
	if not self[key] then
		local fx = Instance.new(className)
		fx.Name = "Cutscene" .. className
		fx.Parent = Lighting
		self[key] = fx
		self:onCleanup(function()
			fx:Destroy()
		end)
	end
	return self[key]
end

-- ColorCorrection owned by the cutscene, stacked on top of the place's own.
function Context:grade(props: { [string]: any }, dur: number, style: Enum.EasingStyle?)
	self:tween(ownEffect(self, "ColorCorrectionEffect"), dur, props, style)
end

function Context:bloom(props: { [string]: any }, dur: number)
	local b = ownEffect(self, "BloomEffect") :: BloomEffect
	if b:GetAttribute("init") == nil then
		b:SetAttribute("init", true)
		b.Intensity, b.Size, b.Threshold = 0, 24, 0.95
	end
	self:tween(b, dur, props)
end

---------------------------------------------------------------- models

local function prepare(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("ModuleScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
end

-- Normalises a model so its largest dimension is `size` studs.
function Context:fit(model: Model, size: number)
	local _, extents = model:GetBoundingBox()
	local largest = math.max(extents.X, extents.Y, extents.Z)
	if largest > 0 then
		model:ScaleTo(model:GetScale() * size / largest)
	end
end

-- Clones the Index model for this item, scaled up. Falls back to the
-- scene's placeholder builder when the Index has no model.
function Context:itemModel(size: number, placeholder: ((any) -> Model)?): (Model, boolean)
	local source = Hooks.getItemModel(self.itemId)
	local model: Model
	local isPlaceholder = false
	if source then
		model = source:Clone()
	elseif placeholder then
		model = placeholder(self)
		isPlaceholder = true
	else
		model = Instance.new("Model")
		local p = self:part({ Shape = Enum.PartType.Ball, Size = Vector3.one, Material = Enum.Material.Neon, Color = self.palette.glow })
		p.Parent = model
		model.PrimaryPart = p
		isPlaceholder = true
	end
	prepare(model)
	self:fit(model, size)
	model.Parent = self.folder
	return model, isPlaceholder
end

---------------------------------------------------------------- shared beats

-- The opening "click": the stone taps the water and a ripple goes out.
-- Every scene starts on this, so players learn to read it.
function Context:stoneTap(time: number, color: Color3?)
	local Fx = require(script.Parent.Fx)
	self:at(time, function()
		self:sound("stoneTap", 0.9)
		Fx.ring(self, self:cf(0, 0.05, 0), color or self.palette.glow, 0.4, 7, 0.9, 0.25)
	end)
end

type HitSpec = {
	flash: { color: Color3, strength: number, fade: number }?,
	shake: { amp: number, dur: number, freq: number? }?,
	sound: string?,
	music: number?,
	fn: (() -> ())?,
}

-- The reveal. Flash, sound, shake, music and the scene's own change all
-- fire on the same frame; that coincidence is what makes it feel like a hit.
function Context:hit(time: number, spec: HitSpec)
	self:at(time, function()
		self.ui:tintTo(Color3.new(0, 0, 0), 0, 0)
		if spec.flash then
			self.ui:flash(spec.flash.color, spec.flash.strength, spec.flash.fade)
		end
		self:sound(spec.sound or "strike", 1)
		if spec.shake then
			self:shake(spec.shake.amp, spec.shake.dur, spec.shake.freq)
		end
		if spec.music then
			self:musicTo(spec.music, 0.05)
		end
		if spec.fn then
			spec.fn()
		end
	end)
end

---------------------------------------------------------------- teardown

function Context:teardown()
	self.cameraLocked = false
	for _, tw in self._tweens do
		tw:Cancel()
	end
	table.clear(self._tweens)
	table.clear(self._updaters)
	for inst, props in self._saved do
		for k, v in props do
			pcall(function()
				(inst :: any)[k] = v
			end)
		end
	end
	table.clear(self._saved)
	for _, fn in self._cleanups do
		safe("cleanup", fn)
	end
	table.clear(self._cleanups)
	if self._music then
		self._music:Destroy()
		self._music = nil
	end
	self.folder:Destroy()
end

return Context
