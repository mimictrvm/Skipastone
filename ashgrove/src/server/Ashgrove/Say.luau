--[[
	Say: on-screen captions. Every sound that carries information has one,
	so the game reads correctly with no audio and for deaf players.

	Styles: "sound" for [bracketed sound captions], "story" for lines the
	player should notice, "hint" for teaching text.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Net"))

local captionRemote = Net.event("Caption")

local Say = {}

function Say.to(player: Player, text: string, seconds: number?, style: string?)
	captionRemote:FireClient(player, text, seconds or 4, style or "story")
end

function Say.all(text: string, seconds: number?, style: string?)
	captionRemote:FireAllClients(text, seconds or 4, style or "story")
end

-- Everyone whose character is within `radius` of `position`.
function Say.near(position: Vector3, radius: number, text: string, seconds: number?, style: string?)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and ((root :: BasePart).Position - position).Magnitude <= radius then
			Say.to(player, text, seconds, style)
		end
	end
end

function Say.except(skip: Player, text: string, seconds: number?, style: string?)
	for _, player in Players:GetPlayers() do
		if player ~= skip then
			Say.to(player, text, seconds, style)
		end
	end
end

return Say
