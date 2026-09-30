--[[
	Screen layer for cutscenes: letterbox bars, a tint layer, a flash layer,
	a fade layer and the caption block. Layers are stacked in that order.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local BAR_HEIGHT = 0.12

local Ui = {}
Ui.__index = Ui

local function tween(inst: Instance, duration: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local t = TweenService:Create(
		inst,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function frame(parent: Instance, name: string, z: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BackgroundTransparency = 1
	f.ZIndex = z
	f.Parent = parent
	return f
end

local function label(parent: Instance, name: string, y: number, height: number, width: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, y)
	l.Size = UDim2.fromScale(width, height)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextTransparency = 1
	l.Text = ""
	l.ZIndex = 10
	l.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 3
	stroke.Transparency = 1
	stroke.Parent = l
	return l
end

function Ui.new()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CutsceneGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

	local self = setmetatable({}, Ui)
	self.gui = gui
	self.tint = frame(gui, "Tint", 1)
	self.flashFrame = frame(gui, "Flash", 2)
	self.fadeFrame = frame(gui, "Fade", 3)

	self.topBar = frame(gui, "TopBar", 4)
	self.topBar.BackgroundTransparency = 0
	self.topBar.AnchorPoint = Vector2.new(0, 1)
	self.topBar.Size = UDim2.fromScale(1, BAR_HEIGHT)
	self.topBar.Position = UDim2.fromScale(0, 0)

	self.bottomBar = frame(gui, "BottomBar", 4)
	self.bottomBar.BackgroundTransparency = 0
	self.bottomBar.Size = UDim2.fromScale(1, BAR_HEIGHT)
	self.bottomBar.Position = UDim2.fromScale(0, 1)

	local titleRoot = Instance.new("Frame")
	titleRoot.Name = "Title"
	titleRoot.BackgroundTransparency = 1
	titleRoot.Size = UDim2.fromScale(1, 1)
	titleRoot.ZIndex = 10
	titleRoot.Parent = gui
	self.titleScale = Instance.new("UIScale")
	self.titleScale.Parent = titleRoot

	self.caption = label(titleRoot, "Caption", 0.42, 0.15, 0.9)
	self.caption:FindFirstChildOfClass("UIStroke").Thickness = 5
	local sizeLimit = Instance.new("UITextSizeConstraint")
	sizeLimit.MaxTextSize = 110
	sizeLimit.Parent = self.caption

	self.itemName = label(titleRoot, "ItemName", 0.555, 0.06, 0.6)
	self.rarity = label(titleRoot, "Rarity", 0.615, 0.045, 0.5)
	self.extra = label(titleRoot, "Extra", 0.67, 0.035, 0.5)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return self
end

function Ui:barsIn(duration: number)
	tween(self.topBar, duration, { Position = UDim2.fromScale(0, BAR_HEIGHT) })
	tween(self.bottomBar, duration, { Position = UDim2.fromScale(0, 1 - BAR_HEIGHT) })
end

function Ui:barsOut(duration: number)
	tween(self.topBar, duration, { Position = UDim2.fromScale(0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(self.bottomBar, duration, { Position = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

-- Instant hit of colour that decays. strength 1 = fully opaque.
function Ui:flash(color: Color3, strength: number, fadeTime: number)
	self.flashFrame.BackgroundColor3 = color
	self.flashFrame.BackgroundTransparency = 1 - strength
	tween(self.flashFrame, fadeTime, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

-- Lasting tint over the world (whiteout, blackout). strength 0 clears it.
function Ui:tintTo(color: Color3, strength: number, duration: number)
	self.tint.BackgroundColor3 = color
	if duration <= 0 then
		self.tint.BackgroundTransparency = 1 - strength
	else
		tween(self.tint, duration, { BackgroundTransparency = 1 - strength })
	end
end

function Ui:fadeTo(strength: number, duration: number)
	tween(self.fadeFrame, duration, { BackgroundTransparency = 1 - strength }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
end

local function show(l: TextLabel, text: string, color: Color3, duration: number)
	l.Text = text
	l.TextColor3 = color
	tween(l, duration, { TextTransparency = 0 })
	tween(l:FindFirstChildOfClass("UIStroke") :: UIStroke, duration, { Transparency = 0 })
end

type TitleInfo = {
	caption: string,
	itemName: string,
	rarity: string?,
	extra: string?,
	accent: Color3,
	hold: number,
}

-- Caption slams in large and settles; the item name and odds follow.
function Ui:title(info: TitleInfo)
	self.titleScale.Scale = 1.6
	tween(self.titleScale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	show(self.caption, info.caption, info.accent, 0.1)
	task.delay(0.22, function()
		-- slow drift keeps the held caption alive instead of frozen
		tween(self.titleScale, info.hold, { Scale = 1.05 }, Enum.EasingStyle.Linear)
	end)
	task.delay(0.3, function()
		show(self.itemName, info.itemName, Color3.new(1, 1, 1), 0.25)
	end)
	if info.rarity then
		task.delay(0.5, function()
			show(self.rarity, info.rarity :: string, info.accent:Lerp(Color3.new(1, 1, 1), 0.5), 0.25)
		end)
	end
	if info.extra then
		task.delay(0.8, function()
			show(self.extra, info.extra :: string, Color3.new(1, 1, 1), 0.3)
		end)
	end
end

function Ui:hideTitle(duration: number)
	for _, l in { self.caption, self.itemName, self.rarity, self.extra } do
		tween(l, duration, { TextTransparency = 1 })
		tween(l:FindFirstChildOfClass("UIStroke") :: UIStroke, duration, { Transparency = 1 })
	end
end

function Ui:destroy()
	self.gui:Destroy()
end

return Ui
