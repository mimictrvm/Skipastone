--[[
	Hud: everything on screen. Built in code so there's nothing to import.

	Reads the player attributes the server sets (Ammo, Reserve, Reloading,
	Battery, LightOn, HasGold, WardReadyAt, Commit*, Downed, Taken, Hits)
	every frame, and exposes calls for one-off events (captions, notes,
	chapter cards, keens, full-screen states).

	Kept deliberately quiet: no health bar, no minimap, no timer on a keen.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Config = require(Shared:WaitForChild("Config"))
local Notes = require(Shared:WaitForChild("Notes"))

local player = Players.LocalPlayer

local Hud = {}

local PAPER = Color3.fromRGB(226, 218, 196)
local DIM = Color3.fromRGB(150, 146, 136)
local INK = Color3.fromRGB(16, 15, 14)
local BODY_FONT = Enum.Font.SourceSans
local TITLE_FONT = Enum.Font.Garamond

local gui: ScreenGui
local dot: Frame
local ring: Frame
local ammoLabel: TextLabel
local statusLabel: TextLabel
local batteryFill: Frame
local goldLabel: TextLabel
local objectivesFrame: Frame
local captionsFrame: Frame
local commitFrame: Frame
local commitFill: Frame
local commitLabel: TextLabel
local notePanel: Frame
local noteTitle: TextLabel
local noteBody: TextLabel
local noteScroll: ScrollingFrame
local chapterTitle: TextLabel
local chapterSub: TextLabel
local keenLabel: TextLabel
local keenShade: Frame
local hurtFlash: Frame
local overlay: Frame
local overlayText: TextLabel
local helpPanel: Frame

local noteOpenAt: Vector3? = nil
local keenInfo: { [string]: any }? = nil
local lastHits = 0
local screenKind = ""

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function text(props: { [string]: any }, parent: Instance): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = BODY_FONT,
		TextColor3 = PAPER,
		TextSize = 20,
		TextWrapped = true,
	}
	for k, v in props do
		defaults[k] = v
	end
	return new("TextLabel", defaults, parent)
end

local function build()
	gui = new("ScreenGui", {
		Name = "AshgroveHud",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, player:WaitForChild("PlayerGui"))

	-- Crosshair: a dot where the shot will go, and a ring showing how much
	-- the aim is swaying. Stand still and the ring closes in.
	ring = new("Frame", {
		Name = "Ring",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(20, 20),
	}, gui)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
	new("UIStroke", { Color = PAPER, Transparency = 0.65, Thickness = 1 }, ring)
	dot = new("Frame", {
		Name = "Dot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = PAPER,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(4, 4),
	}, gui)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)

	ammoLabel = text({
		Name = "Ammo",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -28, 1, -28),
		Size = UDim2.fromOffset(200, 34),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextSize = 28,
		Font = TITLE_FONT,
	}, gui)
	statusLabel = text({
		Name = "Status",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -28, 1, -62),
		Size = UDim2.fromOffset(240, 22),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = DIM,
		TextSize = 18,
	}, gui)

	local battery = new("Frame", {
		Name = "Battery",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 28, 1, -32),
		Size = UDim2.fromOffset(160, 6),
		BackgroundColor3 = INK,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
	}, gui)
	batteryFill = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = PAPER,
		BorderSizePixel = 0,
	}, battery)
	text({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 0, -4),
		Size = UDim2.fromOffset(160, 18),
		Text = "TORCH",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = DIM,
		TextSize = 14,
	}, battery)
	goldLabel = text({
		Name = "Gold",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 28, 1, -64),
		Size = UDim2.fromOffset(240, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(214, 180, 90),
		TextSize = 16,
		Visible = false,
	}, gui)

	objectivesFrame = new("Frame", {
		Name = "Objectives",
		Position = UDim2.fromOffset(28, 28),
		Size = UDim2.fromOffset(420, 200),
		BackgroundTransparency = 1,
	}, gui)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, objectivesFrame)

	captionsFrame = new("Frame", {
		Name = "Captions",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.new(0.6, 0, 0, 200),
		BackgroundTransparency = 1,
	}, gui)
	new("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, captionsFrame)

	commitFrame = new("Frame", {
		Name = "Commit",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.62, 0),
		Size = UDim2.fromOffset(260, 6),
		BackgroundColor3 = INK,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	commitFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = PAPER, BorderSizePixel = 0 }, commitFrame)
	commitLabel = text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.fromOffset(400, 22),
		TextSize = 18,
	}, commitFrame)

	chapterTitle = text({
		Name = "ChapterTitle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.8, 0, 0, 60),
		Font = TITLE_FONT,
		TextSize = 48,
		TextTransparency = 1,
	}, gui)
	chapterSub = text({
		Name = "ChapterSub",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.3, 46),
		Size = UDim2.new(0.8, 0, 0, 30),
		Font = TITLE_FONT,
		TextSize = 24,
		TextColor3 = DIM,
		TextTransparency = 1,
	}, gui)

	keenShade = new("Frame", {
		Name = "KeenShade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 0,
	}, gui)
	keenLabel = text({
		Name = "Keen",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 34),
		Size = UDim2.new(0.6, 0, 0, 30),
		Font = TITLE_FONT,
		TextSize = 26,
		TextColor3 = Config.banshee.colour,
		Visible = false,
	}, gui)

	hurtFlash = new("Frame", {
		Name = "Hurt",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(120, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, gui)

	notePanel = new("Frame", {
		Name = "Note",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(560, 460),
		BackgroundColor3 = Color3.fromRGB(30, 28, 24),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 10,
	}, gui)
	new("UISizeConstraint", { MaxSize = Vector2.new(560, 460) }, notePanel)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 20),
		PaddingLeft = UDim.new(0, 24),
		PaddingRight = UDim.new(0, 24),
	}, notePanel)
	new("UIStroke", { Color = DIM, Transparency = 0.6 }, notePanel)
	noteTitle = text({
		Size = UDim2.new(1, 0, 0, 32),
		Font = TITLE_FONT,
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
	}, notePanel)
	noteScroll = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 1, -76),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 11,
	}, notePanel)
	noteBody = text({
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = 1.15,
		ZIndex = 11,
	}, noteScroll)
	text({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(200, 20),
		Text = "[Q] put it down",
		TextColor3 = DIM,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 11,
	}, notePanel)

	overlay = new("Frame", {
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 20,
	}, gui)
	overlayText = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.7, 0, 0, 200),
		Font = TITLE_FONT,
		TextSize = 32,
		TextTransparency = 1,
		ZIndex = 21,
	}, overlay)

	helpPanel = new("Frame", {
		Name = "Help",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -28, 0, 28),
		Size = UDim2.fromOffset(300, 260),
		BackgroundColor3 = Color3.fromRGB(20, 19, 17),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
	}, helpPanel)
	text({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 18,
		Text = table.concat({
			"WASD   move",
			"Shift  sprint (loud)",
			"C      crouch (silent)",
			"F      torch",
			"Click  shoot",
			"R      reload (torch goes off)",
			"G      raise the gold, if you have it",
			"E      interact",
			"Q      put a note down",
			"H      this help",
			"",
			"Stand still to steady your aim.",
		}, "\n"),
	}, helpPanel)
end

------------------------------------------------------------------ calls

function Hud.setCrosshair(position: Vector2, ringPixels: number, visible: boolean)
	dot.Visible = visible
	ring.Visible = visible
	dot.Position = UDim2.fromOffset(position.X, position.Y)
	ring.Position = UDim2.fromOffset(position.X, position.Y)
	local size = math.clamp(ringPixels * 2, 8, 400)
	ring.Size = UDim2.fromOffset(size, size)
end

local captionOrder = 0
function Hud.caption(message: string, seconds: number?, style: string?)
	captionOrder += 1
	local colour = if style == "sound" then DIM elseif style == "hint" then Color3.fromRGB(180, 196, 210) else PAPER
	local label = text({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = message,
		TextColor3 = colour,
		TextSize = if style == "sound" then 19 else 21,
		Font = if style == "sound" then Enum.Font.SourceSansItalic else BODY_FONT,
		TextStrokeTransparency = 0.6,
		LayoutOrder = captionOrder,
	}, captionsFrame)
	local labels = {}
	for _, child in captionsFrame:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	table.sort(labels, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #labels > 5 do
		local oldest = table.remove(labels, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	task.delay(seconds or 4, function()
		if label.Parent then
			local fade = TweenService:Create(label, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			label:Destroy()
		end
	end)
end

function Hud.setObjectives(list: { { text: string, done: boolean? } })
	for _, child in objectivesFrame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for i, objective in list do
		text({
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = (if objective.done then "x  " else "-  ") .. objective.text,
			TextColor3 = if objective.done then DIM else PAPER,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 18,
			TextStrokeTransparency = 0.7,
			LayoutOrder = i,
		}, objectivesFrame)
	end
end

function Hud.chapter(title: string, subtitle: string)
	chapterTitle.Text = title
	chapterSub.Text = subtitle
	for _, label in { chapterTitle, chapterSub } do
		label.TextTransparency = 1
		TweenService:Create(label, TweenInfo.new(1.5), { TextTransparency = 0 }):Play()
	end
	task.delay(5, function()
		for _, label in { chapterTitle, chapterSub } do
			TweenService:Create(label, TweenInfo.new(2), { TextTransparency = 1 }):Play()
		end
	end)
end

function Hud.showNote(noteId: string)
	local note = Notes[noteId]
	if not note then
		return
	end
	noteTitle.Text = note.title
	noteBody.Text = note.body
	noteScroll.CanvasPosition = Vector2.zero
	notePanel.Visible = true
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	noteOpenAt = if root then (root :: BasePart).Position else nil
end

function Hud.closeNote()
	notePanel.Visible = false
	noteOpenAt = nil
end

function Hud.isNoteOpen(): boolean
	return notePanel.Visible
end

function Hud.toggleHelp()
	helpPanel.Visible = not helpPanel.Visible
end

function Hud.keen(state: string, info: { [string]: any })
	if state == "start" then
		keenInfo = info
		keenLabel.Visible = true
		keenLabel.Text = if info.target == player.UserId then "She is facing you." else `She is facing {info.targetName}.`
	else
		keenInfo = nil
		keenLabel.Visible = false
		TweenService:Create(keenShade, TweenInfo.new(2), { BackgroundTransparency = 1 }):Play()
	end
end

-- Full-screen states: "wipe", "end", "clear".
function Hud.screen(kind: string, message: string)
	screenKind = if kind == "clear" then "" else kind
	if kind == "clear" then
		TweenService:Create(overlay, TweenInfo.new(1.5), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(overlayText, TweenInfo.new(1), { TextTransparency = 1 }):Play()
		return
	end
	overlayText.Text = message
	TweenService:Create(overlay, TweenInfo.new(if kind == "end" then 4 else 1.5), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(overlayText, TweenInfo.new(2), { TextTransparency = 0 }):Play()
end

------------------------------------------------------------------ per frame

local function update()
	local ammo = player:GetAttribute("Ammo")
	local reserve = player:GetAttribute("Reserve")
	ammoLabel.Text = if ammo then `{ammo}  /  {reserve or 0}` else ""
	local status = ""
	if player:GetAttribute("Reloading") then
		status = "reloading"
	elseif ammo == 0 then
		status = if (reserve or 0) > 0 then "empty. [R] reload" else "empty"
	end
	statusLabel.Text = status

	local battery = (player:GetAttribute("Battery") or 0) / Config.flashlight.maxBattery
	batteryFill.Size = UDim2.fromScale(math.clamp(battery, 0, 1), 1)
	batteryFill.BackgroundTransparency = if player:GetAttribute("LightOn") then 0 else 0.6

	if player:GetAttribute("HasGold") then
		goldLabel.Visible = true
		local readyAt = player:GetAttribute("WardReadyAt") or 0
		local wait = readyAt - workspace:GetServerTimeNow()
		goldLabel.Text = if player:GetAttribute("WardRaised")
			then "GOLD raised"
			elseif wait > 0 then `GOLD  {math.ceil(wait)}s`
			else "GOLD  [G]"
	else
		goldLabel.Visible = false
	end

	local label = player:GetAttribute("CommitLabel")
	if label then
		commitFrame.Visible = true
		commitLabel.Text = label
		local length = player:GetAttribute("CommitLength") or 1
		local ends = player:GetAttribute("CommitEnds") or 0
		local progress = 1 - math.clamp((ends - workspace:GetServerTimeNow()) / length, 0, 1)
		commitFill.Size = UDim2.fromScale(progress, 1)
	else
		commitFrame.Visible = false
	end

	-- The one she faces sees the dark close in as the window runs out.
	if keenInfo and keenInfo.target == player.UserId then
		local left = math.clamp((keenInfo.endsAt - workspace:GetServerTimeNow()) / keenInfo.length, 0, 1)
		keenShade.BackgroundTransparency = 0.45 + 0.55 * left
	end

	local hits = player:GetAttribute("Hits") or 0
	if hits > lastHits then
		hurtFlash.BackgroundTransparency = 0.55
		TweenService:Create(hurtFlash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	end
	lastHits = hits

	if screenKind ~= "wipe" and screenKind ~= "end" then
		if player:GetAttribute("Taken") then
			overlay.BackgroundTransparency = 0.15
			overlayText.TextTransparency = 0
			overlayText.Text = "Taken.\n\nYou'll come back when the others reach somewhere safe.\n(Click to watch someone else.)"
		elseif player:GetAttribute("Downed") then
			overlay.BackgroundTransparency = 0.55
			overlayText.TextTransparency = 0
			overlayText.Text = "You're down.\nA crewmate can get you up."
		elseif overlay.BackgroundTransparency < 1 then
			overlay.BackgroundTransparency = 1
			overlayText.TextTransparency = 1
		end
	end

	if noteOpenAt then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or ((root :: BasePart).Position - noteOpenAt).Magnitude > 10 then
			Hud.closeNote()
		end
	end
end

function Hud.start()
	build()
	RunService.RenderStepped:Connect(update)
end

return Hud
