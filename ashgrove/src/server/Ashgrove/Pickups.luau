--[[
	Pickups: ammo, batteries and the gold ward.

	Each pickup part has Kind ("ammo" | "battery" | "gold"), Group and
	Always. Always pickups are always there. For the rest, each group puts
	Config.pickups.groups[Group] of its candidates in the world per run
	(plus extra per extra player), chosen at random so routes can't be
	memorised. Supply is deliberately short of "fight everything".
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))

local Crew = require(script.Parent.Crew)
local Gun = require(script.Parent.Gun)
local Map = require(script.Parent.Map)
local Say = require(script.Parent.Say)

local Pickups = {}

local LABELS = {
	ammo = { action = "Take", object = "Pistol rounds" },
	battery = { action = "Take", object = "Torch batteries" },
	gold = { action = "Take", object = "Gold sovereign" },
}

local goldPart: BasePart? = nil

local function show(p: BasePart, visible: boolean)
	p.Transparency = if visible then 0 else 1
	p.CanQuery = false
	local prompt = p:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = visible
	end
	p:SetAttribute("Live", visible)
end

local function take(p: BasePart, player: Player)
	if not p:GetAttribute("Live") or not Crew.isActive(player) then
		return
	end
	local kind = p:GetAttribute("Kind")
	if kind == "ammo" then
		local taken = Gun.addAmmo(player, Config.pickups.ammoAmount)
		if taken <= 0 then
			Say.to(player, "Your pockets are full of rounds already.", 2, "hint")
			return
		end
		Say.to(player, `+{taken} rounds`, 2, "hint")
	elseif kind == "battery" then
		if not Crew.addBattery(player, Config.pickups.batteryAmount) then
			Say.to(player, "Your torch is already full.", 2, "hint")
			return
		end
		Say.to(player, "Fresh batteries.", 2, "hint")
	elseif kind == "gold" then
		Crew.giveGold(player)
	end
	Audio.play("pickup", p, 0.5)
	show(p, false)
end

-- Picks which candidates are live this run. Call once the party is in.
function Pickups.roll()
	local partySize = math.max(1, #Players:GetPlayers())
	local byGroup: { [string]: { BasePart } } = {}
	for _, p in Map.interact("Pickups"):GetChildren() do
		-- Always pickups were set out by setup (and may be taken already).
		if p:IsA("BasePart") and not p:GetAttribute("Always") then
			show(p, false)
			local group = p:GetAttribute("Group") or "Default"
			byGroup[group] = byGroup[group] or {}
			table.insert(byGroup[group], p)
		end
	end
	for group, candidates in byGroup do
		local base = Config.pickups.groups[group] or 1
		local count = math.min(#candidates, base + math.floor(Config.pickups.extraPerPlayer * (partySize - 1) + 0.5))
		for _ = 1, count do
			local i = math.random(1, #candidates)
			show(table.remove(candidates, i) :: BasePart, true)
		end
	end
end

function Pickups.setup()
	for _, p in Map.interact("Pickups"):GetChildren() do
		if p:IsA("BasePart") then
			local kind = p:GetAttribute("Kind")
			local labels = LABELS[kind] or LABELS.ammo
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = labels.action
			prompt.ObjectText = labels.object
			prompt.HoldDuration = 0.2
			prompt.MaxActivationDistance = 7
			prompt.RequiresLineOfSight = false
			prompt.Parent = p
			prompt.Triggered:Connect(function(player)
				take(p, player)
			end)
			if kind == "gold" then
				goldPart = p
			end
			-- Until the run's roll (Director, once the party is in), only the
			-- Always pickups are out.
			show(p, p:GetAttribute("Always") == true)
		end
	end
	-- If whoever had the gold leaves, it goes back in its case.
	Crew.goldLost:Connect(function()
		if goldPart then
			show(goldPart, true)
		end
	end)
end

return Pickups
