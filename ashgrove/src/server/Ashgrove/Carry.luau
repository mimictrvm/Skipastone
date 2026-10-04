--[[
	Carry: picking things up and putting them where they go. The puzzles'
	hands.

	ITEMS are parts in Interact/Items with ItemType and Label attributes
	(a salt tin, a candle, a torn page). Prompt: "Take". A player carries
	ONE thing at a time; the HUD shows it.

	SOCKETS are any parts in Interact with an Accepts attribute (a comma
	list of ItemTypes) and a SocketLabel. Prompt: "Use <label>". Putting
	something in a socket is a short committed action, then Carry.placed
	fires and the puzzle decides what it means. Capacity (default 1) is
	how many things a socket takes.

	Puzzles can also hand a player something directly (Carry.give), like a
	key found inside a box.

	If a carrier goes down, is taken or leaves, what they held drops where
	they were, so nothing important is ever lost.

	Player attributes: Carrying (label), CarryingType.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Signal = require(Shared:WaitForChild("Signal"))

local Crew = require(script.Parent.Crew)
local Map = require(script.Parent.Map)
local Say = require(script.Parent.Say)

local Carry = {}

Carry.placed = Signal.new() -- (socket: BasePart, itemType: string, player: Player)
Carry.taken = Signal.new() -- (itemPart: BasePart?, itemType: string, player: Player)

type Held = { itemType: string, label: string, part: BasePart? }

local held: { [Player]: Held } = {}

local function publish(player: Player)
	local h = held[player]
	player:SetAttribute("Carrying", if h then h.label else nil)
	player:SetAttribute("CarryingType", if h then h.itemType else nil)
end

local function showItem(p: BasePart, visible: boolean)
	p.Transparency = if visible then (p:GetAttribute("BaseTransparency") or 0) else 1
	p:SetAttribute("Live", visible)
	local prompt = p:FindFirstChild("TakePrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = visible
	end
end

function Carry.holding(player: Player): string?
	local h = held[player]
	return h and h.itemType
end

local function take(p: BasePart, player: Player)
	if not p:GetAttribute("Live") or not Crew.isActive(player) then
		return
	end
	if held[player] then
		Say.to(player, `Your hands are full ({held[player].label}).`, 3, "hint")
		return
	end
	local itemType = p:GetAttribute("ItemType") :: string
	held[player] = { itemType = itemType, label = p:GetAttribute("Label") or itemType, part = p }
	showItem(p, false)
	publish(player)
	Audio.play("pickup", p, 0.5)
	Carry.taken:Fire(p, itemType, player)
end

local function wire(p: BasePart)
	if p:FindFirstChild("TakePrompt") then
		return
	end
	if p:GetAttribute("BaseTransparency") == nil then
		p:SetAttribute("BaseTransparency", p.Transparency)
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TakePrompt"
	prompt.ActionText = "Take"
	prompt.ObjectText = p:GetAttribute("Label") or p.Name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = p
	prompt.Triggered:Connect(function(player)
		take(p, player)
	end)
	if p:GetAttribute("Live") == nil then
		p:SetAttribute("Live", p.Transparency < 1)
	end
	showItem(p, p:GetAttribute("Live") == true)
end

-- Show or hide an item in the world (puzzles hide decoy spots, etc).
function Carry.setLive(p: BasePart, live: boolean)
	wire(p)
	showItem(p, live)
end

-- Put something straight into a player's hands. Returns false if full.
function Carry.give(player: Player, itemType: string, label: string): boolean
	if held[player] then
		Say.to(player, `Your hands are full ({held[player].label}). Put that down first.`, 3, "hint")
		return false
	end
	held[player] = { itemType = itemType, label = label, part = nil }
	publish(player)
	return true
end

-- Drops what a player holds where they stand.
function Carry.drop(player: Player)
	local h = held[player]
	if not h then
		return
	end
	held[player] = nil
	publish(player)
	local root = Crew.root(player)
	local at = if root then root.Position - Vector3.new(0, 2.6, 0) else nil
	local p = h.part
	if not p then
		p = Instance.new("Part")
		p.Name = h.itemType
		p.Size = Vector3.new(0.7, 0.3, 0.7)
		p.Color = Color3.fromRGB(150, 118, 60)
		p.Material = Enum.Material.Metal
		p.Anchored = true
		p.CanCollide = false
		p:SetAttribute("ItemType", h.itemType)
		p:SetAttribute("Label", h.label)
		p:SetAttribute("Live", false)
		p.Parent = Map.interact("Items")
	end
	if at and Map.wingAt(at + Vector3.new(0, 2, 0)) ~= nil then
		p.CFrame = CFrame.new(at)
	end
	wire(p)
	showItem(p, true)
	Say.near(p.Position, 40, `[{h.label} drops to the floor]`, 3, "sound")
end

local function accepts(socket: BasePart, itemType: string): boolean
	local list = socket:GetAttribute("Accepts")
	if typeof(list) ~= "string" then
		return false
	end
	for entry in string.gmatch(list, "[^,%s]+") do
		if entry == itemType then
			return true
		end
	end
	return false
end

function Carry.wireSocket(socket: BasePart)
	if socket:FindFirstChild("UsePrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UsePrompt"
	prompt.ActionText = "Use"
	prompt.ObjectText = socket:GetAttribute("SocketLabel") or socket.Name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = socket
	prompt.Triggered:Connect(function(player)
		local h = held[player]
		if not h then
			return
		end
		if not accepts(socket, h.itemType) then
			Say.to(player, `The {h.label} doesn't go there.`, 2, "hint")
			return
		end
		local capacity = socket:GetAttribute("Capacity") or 1
		local filled = socket:GetAttribute("Filled") or 0
		if filled >= capacity then
			Say.to(player, "There's no room for more there.", 2, "hint")
			return
		end
		local item = h
		Crew.commit(player, 1, `{prompt.ObjectText}: {item.label}`, function()
			if held[player] ~= item then
				return
			end
			held[player] = nil
			publish(player)
			socket:SetAttribute("Filled", filled + 1)
			if filled + 1 >= capacity then
				prompt.Enabled = false
			end
			Carry.placed:Fire(socket, item.itemType, player)
		end)
	end)
end

function Carry.start()
	for _, p in Map.interact("Items"):GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("ItemType") then
			wire(p)
		end
	end
	for _, d in Map.root():WaitForChild("Interact"):GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Accepts") then
			Carry.wireSocket(d)
		end
	end
	Crew.incapacitated:Connect(Carry.drop)
	Players.PlayerRemoving:Connect(Carry.drop)
end

return Carry
