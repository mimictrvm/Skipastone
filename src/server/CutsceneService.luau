--[[
	CutsceneService (server): decides which cutscene a catch gets and who
	hears about it. The scene itself plays on the finder's client.

	Call it from the loot code at the moment a catch is rolled, BEFORE the
	item is added to the player's Index (so "first find" is still true):

	    local CutsceneService = require(ServerScriptService.CutsceneService)
	    CutsceneService.onCatch(player, itemId, {
	        landing = landingPosition,   -- Vector3, where the stone landed
	        oneIn = 756000000,           -- optional, for the "1 in N" line
	        firstFind = not index:has(itemId), -- optional, see below
	    })

	Returns true when the item has a cutscene. The client then shows the
	normal loot reveal itself when the scene ends (Hooks.showLootReveal),
	so the loot code should skip its own reveal for these items. Granting
	the item can happen straight away; the scene is presentation only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Cutscenes"):WaitForChild("Config"))

local CutsceneService = {}

local remotes = Instance.new("Folder")
remotes.Name = "CutsceneRemotes"
local playRemote = Instance.new("RemoteEvent")
playRemote.Name = "Play"
playRemote.Parent = remotes
local announceRemote = Instance.new("RemoteEvent")
announceRemote.Name = "Announce"
announceRemote.Parent = remotes
remotes.Parent = ReplicatedStorage

-- WIRE UP: fallback "has this player caught this item before?" check, used
-- when onCatch isn't given firstFind. The default only remembers the current
-- server session, so every rejoin would replay the full scene.
local seenThisSession: { [Player]: { [string]: boolean } } = {}
function CutsceneService.hasFoundBefore(player: Player, itemId: string): boolean
	local seen = seenThisSession[player]
	return seen ~= nil and seen[itemId] == true
end

-- WIRE UP: point this at the existing legendary-find broadcast. The default
-- sends a plain system chat line to everyone except the finder.
function CutsceneService.broadcast(finder: Player, itemId: string, oneIn: number?)
	local entry = Config.items[itemId]
	for _, other in Players:GetPlayers() do
		if other ~= finder then
			announceRemote:FireClient(other, finder.DisplayName, entry.displayName, oneIn)
		end
	end
end

type CatchInfo = {
	landing: Vector3,
	oneIn: number?,
	firstFind: boolean?,
}

function CutsceneService.onCatch(player: Player, itemId: string, info: CatchInfo): boolean
	if not Config.items[itemId] then
		return false
	end

	local firstFind = info.firstFind
	if firstFind == nil then
		firstFind = not CutsceneService.hasFoundBefore(player, itemId)
	end
	seenThisSession[player] = seenThisSession[player] or {}
	seenThisSession[player][itemId] = true

	playRemote:FireClient(player, itemId, {
		full = firstFind,
		landing = info.landing,
		oneIn = info.oneIn,
	})
	CutsceneService.broadcast(player, itemId, info.oneIn)
	return true
end

Players.PlayerRemoving:Connect(function(player)
	seenThisSession[player] = nil
end)

return CutsceneService
