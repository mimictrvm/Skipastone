--[[
	Director: runs one cutscene from freeze to hand-back.

	    Director.play(itemId, {
	        full = true,              -- false plays the 3-second replay
	        landing = Vector3,        -- where the stone came down
	        oneIn = 756000000,        -- optional, shown as "1 in 756,000,000"
	    })

	The Director owns the beats every scene shares:
	  Freeze  bars slide in, HUD hides, music ducks, controls lock
	  Title   caption slam + item name + odds, at the scene's titleAt
	  Return  fade to black, world restored, fade up, loot reveal
	The scene module owns everything in between.

	It yields until the loot reveal has been handed off. If a scene errors,
	the world is still restored and the item is still revealed.
]]

local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)
local Context = require(script.Parent.Context)
local Hooks = require(script.Parent.Hooks)
local ShortScene = require(script.Parent.ShortScene)
local Ui = require(script.Parent.Ui)

local RETURN_FADE = 0.35
local RETURN_OPEN = 0.45
local RETURN_TOTAL = 0.95
local RENDER_NAME = "SkipastoneCutscene"

export type PlayOptions = {
	full: boolean,
	landing: Vector3,
	oneIn: number?,
}

export type Scene = {
	freezeTime: number?,
	titleAt: number,
	returnAt: number,
	extra: string?,
	build: (any, any) -> (),
	placeholder: ((any) -> Model)?,
}

local Director = {}

local busy = false

-- 756000000 -> "1 in 756,000,000"
function Director.formatOneIn(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return "1 in " .. out
end

local function horizontalForward(landing: Vector3): Vector3
	local camera = workspace.CurrentCamera
	local dir = (landing - camera.CFrame.Position) * Vector3.new(1, 0, 1)
	if dir.Magnitude < 1 then
		dir = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
	end
	return if dir.Magnitude > 1e-3 then dir.Unit else -Vector3.zAxis
end

-- The stone is the thread through every scene. We always animate our own
-- copy and hide the real one, so the throw system's part is never moved.
local function makeStone(ctx, landing: Vector3, original: BasePart?): BasePart
	local stone: BasePart
	if original then
		stone = original:Clone()
		for _, d in stone:GetDescendants() do
			if d:IsA("BaseScript") or d:IsA("JointInstance") or d:IsA("Constraint") then
				d:Destroy()
			end
		end
		stone.Anchored = true
		stone.CanCollide = false
		stone.Parent = ctx.folder
		local before = original.LocalTransparencyModifier
		original.LocalTransparencyModifier = 1
		ctx:onCleanup(function()
			if original.Parent then
				original.LocalTransparencyModifier = before
			end
		end)
	else
		stone = ctx:part({
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.9, 0.9, 0.9),
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(120, 124, 130),
		})
	end
	stone.CFrame = CFrame.new(landing + Vector3.new(0, 0.2, 0))
	return stone
end

local function run(itemId: string, opts: PlayOptions)
	local entry = Config.items[itemId]
	if not entry then
		Hooks.showLootReveal(itemId)
		return
	end

	local fullScene: Scene = require(script.Parent.Scenes:FindFirstChild(entry.scene) :: ModuleScript) :: any
	local scene: Scene = if opts.full then fullScene else ShortScene :: any

	local camera = workspace.CurrentCamera
	local saved = {
		cf = camera.CFrame,
		type = camera.CameraType,
		subject = camera.CameraSubject,
		fov = camera.FieldOfView,
	}

	local ui = Ui.new()
	local ctx = Context.new(itemId, entry, opts.landing, horizontalForward(opts.landing), ui, opts.oneIn)
	ctx.full = opts.full
	ctx.stone = makeStone(ctx, opts.landing, Hooks.freezeThrow(opts.landing))

	local revealed = false
	local restored = false
	local finished = false

	local function restore()
		if restored then
			return
		end
		restored = true
		-- each step on its own, so one failure can't strand the player
		-- without a HUD or controls
		local steps = {
			function()
				ctx:teardown()
			end,
			function()
				camera.CameraType = saved.type
				camera.CFrame = saved.cf
				camera.FieldOfView = saved.fov
				if saved.subject and saved.subject.Parent then
					camera.CameraSubject = saved.subject
				end
			end,
			Hooks.showHud,
			function()
				Hooks.restoreMusic(1)
			end,
			Hooks.unlockControls,
			Hooks.releaseThrow,
		}
		for _, step in steps do
			local ok, err = pcall(step)
			if not ok then
				warn(`[Cutscene] restore step failed: {err}`)
			end
		end
	end

	local function reveal()
		if revealed then
			return
		end
		revealed = true
		Hooks.showLootReveal(itemId)
	end

	-- Freeze
	local freezeTime = scene.freezeTime or 0.5
	ui:barsIn(freezeTime)
	Hooks.hideHud()
	Hooks.duckMusic(freezeTime)
	Hooks.lockControls()
	camera.CameraType = Enum.CameraType.Scriptable

	local ok, err = pcall(scene.build, ctx, fullScene)
	if not ok then
		warn(`[Cutscene] {itemId} build failed: {err}`)
	end

	-- Title
	ctx:at(scene.titleAt, function()
		ctx:sound("titleSlam", 1)
		ui:title({
			caption = entry.caption,
			itemName = entry.displayName,
			rarity = if opts.oneIn then Director.formatOneIn(opts.oneIn) else nil,
			extra = if opts.full then scene.extra else nil,
			accent = entry.palette.accent,
			hold = scene.returnAt - scene.titleAt,
		})
	end)

	-- Return
	local R = scene.returnAt
	ctx:at(R, function()
		ui:hideTitle(0.3)
		ctx:musicTo(0, RETURN_FADE + 0.1)
		ui:fadeTo(1, RETURN_FADE)
	end)
	ctx:at(R + RETURN_FADE + 0.05, function()
		restore()
		-- bookend: the same tap that opened the scene closes it
		ctx:sound("stoneTap", 0.6, 1.12)
		ui:fadeTo(0, RETURN_OPEN)
		ui:barsOut(RETURN_OPEN)
	end)
	ctx:at(R + RETURN_TOTAL, function()
		reveal()
		finished = true
	end)

	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		ctx:step(dt)
	end)

	local deadline = os.clock() + R + RETURN_TOTAL + 4
	while not finished and os.clock() < deadline do
		task.wait()
	end

	RunService:UnbindFromRenderStep(RENDER_NAME)
	restore()
	reveal()
	task.delay(RETURN_OPEN + 0.1, function()
		ui:destroy()
	end)
end

function Director.play(itemId: string, opts: PlayOptions)
	while busy do
		task.wait()
	end
	busy = true
	local ok, err = pcall(run, itemId, opts)
	if not ok then
		warn(`[Cutscene] {itemId} failed: {err}`)
		-- run() failed before it could clean up: put the player back in control
		pcall(RunService.UnbindFromRenderStep, RunService, RENDER_NAME)
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Custom
		for _, gui in (game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
			if gui.Name == "CutsceneGui" then
				gui:Destroy()
			end
		end
		local leftover = workspace:FindFirstChild("CutsceneFx")
		if leftover then
			leftover:Destroy()
		end
		Hooks.showHud()
		Hooks.restoreMusic(0.5)
		Hooks.unlockControls()
		Hooks.releaseThrow()
		Hooks.showLootReveal(itemId)
	end
	busy = false
end

function Director.isPlaying(): boolean
	return busy
end

return Director
