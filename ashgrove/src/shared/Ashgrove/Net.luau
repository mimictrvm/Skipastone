--[[
	Every remote the game uses, created by the server on first require and
	looked up by the client. Names are listed here so both sides agree.

	Client -> server
	  Fire(origin, direction)   Reload()   Flashlight(on)   Move(mode)
	  Aim(direction)*           Ward()     Debug(command)
	Server -> client
	  ShotFx(shooter, origin, hit, kind)   Caption(text, seconds, style)
	  Note(noteId)   Objectives(list)   Chapter(title, subtitle)
	  Keen(state, info)   Lightning(strength)   Screen(kind, text)
	  Spectate(on)

	* unreliable: sent ten times a second, a lost packet doesn't matter.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RELIABLE = {
	"Fire",
	"Reload",
	"Flashlight",
	"Move",
	"Ward",
	"Debug",
	"ShotFx",
	"Caption",
	"Note",
	"Objectives",
	"Chapter",
	"Keen",
	"Lightning",
	"Screen",
	"Spectate",
}
local UNRELIABLE = { "Aim" }

local FOLDER_NAME = "AshgroveNet"

local Net = {}

local folder: Folder
if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, name in RELIABLE do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	for _, name in UNRELIABLE do
		local remote = Instance.new("UnreliableRemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Net.event(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

function Net.unreliable(name: string): UnreliableRemoteEvent
	return folder:WaitForChild(name) :: UnreliableRemoteEvent
end

return Net
