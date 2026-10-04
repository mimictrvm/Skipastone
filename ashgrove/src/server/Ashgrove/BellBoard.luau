--[[
	BellBoard: the servants' bells ring for the room an entity is in.

	Imperfect on purpose (Config.bellBoard.ringChance per check), and only
	heard by players near the board: a diegetic tracker you have to go and
	stand by, like Alien: Isolation's motion tracker.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))

local Map = require(script.Parent.Map)
local Registry = require(script.Parent.Entities.Registry)
local Say = require(script.Parent.Say)

local BellBoard = {}

local NAMES = {
	Gallery = "GALLERY",
	Kitchen = "KITCHEN",
	Corridor = "PASSAGE",
	Scullery = "SCULLERY",
	Housekeeper = "HOUSEKEEPER",
	ServantsHall = "SERVANTS' HALL",
	Vault = "CELLAR",
}

local function ring(bell: BasePart, room: string)
	local base = bell.CFrame
	local swing = TweenService:Create(bell, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 5, true), {
		CFrame = base * CFrame.Angles(0, 0, math.rad(25)),
	})
	swing:Play()
	swing.Completed:Once(function()
		bell.CFrame = base
	end)
	Audio.play("bell", bell, 0.6, 60)
	Say.near(bell.Position, Config.bellBoard.hearRadius, `[A bell rings on the board: {NAMES[room] or room}]`, 3, "sound")
end

function BellBoard.start()
	local board = Map.root():WaitForChild("Interact"):FindFirstChild("BellBoard")
	if not board then
		return
	end
	local bells: { [string]: BasePart } = {}
	for _, p in board:GetChildren() do
		local room = p:GetAttribute("Room")
		if p:IsA("BasePart") and room then
			bells[room] = p
		end
	end
	task.spawn(function()
		while true do
			task.wait(Config.bellBoard.checkEvery)
			for _, e in Registry.all() do
				local position = e:position()
				if e.status == "active" and position then
					local room = Map.roomAt(position)
					local bell = room and bells[room]
					if bell and math.random() < Config.bellBoard.ringChance then
						ring(bell, room :: string)
					end
				end
			end
		end
	end)
end

return BellBoard
