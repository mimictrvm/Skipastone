--[[
	Ashgrove House (client entry). Starts the HUD, controls, aiming and
	effects, and routes the server's one-off messages to the HUD.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Net"))

local Aim = require(script.Aim)
local Controls = require(script.Controls)
local Effects = require(script.Effects)
local Hud = require(script.Hud)

Hud.start()
Controls.start(Hud)
Aim.start(Hud)
Effects.start(Hud)

Net.event("Caption").OnClientEvent:Connect(Hud.caption)
Net.event("Note").OnClientEvent:Connect(Hud.showNote)
Net.event("Objectives").OnClientEvent:Connect(Hud.setObjectives)
Net.event("Chapter").OnClientEvent:Connect(Hud.chapter)
Net.event("Screen").OnClientEvent:Connect(Hud.screen)
