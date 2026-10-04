--[[
	Reading: notes, catalogue cards and voice memos. A part with a NoteId
	attribute gets a "Read" prompt that opens the note on that player's
	screen (text in ReplicatedStorage.Ashgrove.Notes).

	RequiresMourning notes can only be read while the Banshee grieves over
	them (Banshee calls Reading.reveal); once revealed they stay readable.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Net = require(Shared:WaitForChild("Net"))
local Notes = require(Shared:WaitForChild("Notes"))
local Signal = require(Shared:WaitForChild("Signal"))

local Map = require(script.Parent.Map)

local Reading = {}

Reading.read = Signal.new() -- (noteId, player)

local prompts: { [string]: ProximityPrompt } = {}
local readBy: { [string]: { [Player]: boolean } } = {}

function Reading.reveal(noteId: string)
	local prompt = prompts[noteId]
	if prompt then
		prompt.Enabled = true
	end
end

function Reading.hasBeenRead(noteId: string): boolean
	return readBy[noteId] ~= nil and next(readBy[noteId]) ~= nil
end

function Reading.setup()
	for _, p in Map.interact("Notes"):GetChildren() do
		local noteId = p:GetAttribute("NoteId")
		if p:IsA("BasePart") and noteId then
			local note = Notes[noteId]
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = if p.Size.Y > 0.2 then "Play" else "Read"
			prompt.ObjectText = if note then note.title else noteId
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 7
			prompt.RequiresLineOfSight = false
			prompt.Enabled = p:GetAttribute("RequiresMourning") ~= true
			prompt.Parent = p
			prompts[noteId] = prompt
			prompt.Triggered:Connect(function(player)
				Net.event("Note"):FireClient(player, noteId)
				readBy[noteId] = readBy[noteId] or {}
				readBy[noteId][player] = true
				Reading.read:Fire(noteId, player)
			end)
		end
	end
end

return Reading
