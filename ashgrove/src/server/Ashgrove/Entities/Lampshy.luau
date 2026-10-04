--[[
	The Lamp-shy (servants' wing). Killable. Lot 203, the hollow lantern.

	PLACEHOLDER for open decision #1 in docs/ASHGROVE_DIRECTION.md: Story 1
	needs a second, cheaper killable entity with a different approach from
	the Dullahan. Swap the rig and the name when the team picks one; keep
	a one-sentence rule.

	RULE: it only moves while it's out of the light.

	- Hunts by sound: walking carries a short way, sprinting a long way,
	  crouching not at all.
	- In any light (a torch beam, a lamp, a glow, a lightning flash) it
	  freezes completely. Reloading turns your torch off, so a lone player
	  can't light it and reload at the same time. Two players can.
	- Kill: one shot while it's lit. In the dark the shot finds nothing.
	- Death: it collapses into a pale glowing shape, a light source that
	  lasts a few minutes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))

local Ashgrove = script.Parent.Parent
local Crew = require(Ashgrove.Crew)
local Light = require(Ashgrove.Light)
local Map = require(Ashgrove.Map)
local Say = require(Ashgrove.Say)
local Rigs = require(script.Parent.Rigs)

local cfg = Config.entities.Lampshy

local Lampshy = {}

local function isLit(e): boolean
	return Light.isLit(e.root.Position + Vector3.new(0, 0.5, 0), { e.model })
end

local function hunt(e, player: Player)
	e.data.target = player
	e.data.lastHeard = os.clock()
	if e.state ~= "Hunt" then
		Audio.play("lampshyChitter", e.root, 0.8)
		e:setState("Hunt")
	end
end

-- The route marker furthest from a point, that isn't lit.
local function darkestRetreat(e, from: Vector3): Vector3
	local best, bestDistance = e.root.Position, -1
	for _, m in e.data.route do
		local d = (m.Position - from).Magnitude
		if d > bestDistance and not Light.isLit(m.Position, { e.model }) then
			best, bestDistance = m.Position, d
		end
	end
	return best
end

function Lampshy.build(e)
	local model, root, humanoid = Rigs.lampshy()
	e.data.route = Map.markers("Lampshy_Route_")
	e.data.nextTrace = os.clock() + 10
	e.data.nextWanderRoll = os.clock() + 10
	return model, root, humanoid
end

function Lampshy.onSpawn(e)
	e:setState("Feed")
end

function Lampshy.step(e, _dt: number)
	local d = e.data
	local now = os.clock()
	local root: BasePart = e.root

	-- A light on it tells it exactly where the light came from.
	local beamPlayer = Light.beamOn(root.Position + Vector3.new(0, 0.5, 0), nil, { e.model })
	if beamPlayer and e:canTarget(beamPlayer) and e.state ~= "Hunt" then
		hunt(e, beamPlayer)
	end

	if isLit(e) then
		if not d.frozen then
			d.frozen = true
			if e.state == "Hunt" or e.state == "Retreat" then
				Say.near(root.Position, 40, "[It stops dead in the light]", 2, "sound")
			end
		end
		e:stop()
		return
	end
	d.frozen = false

	-- Anyone close enough to touch, it knows about.
	for _, player in e:targets() do
		if e:distanceTo(player) <= cfg.touchRange then
			hunt(e, player)
			break
		end
	end

	local state = e.state
	if state == "Feed" or state == "Idle" then
		e:stop()
		if now >= d.nextTrace then
			d.nextTrace = now + 18 + math.random() * 14
			Audio.play("lampshyChitter", root, 0.4)
			Say.near(root.Position, 35, "[Wet chewing, somewhere in the dark]", 3, "sound")
		end
		if now >= d.nextWanderRoll then
			d.nextWanderRoll = now + 10
			if math.random() < cfg.idleWanderChance and #d.route > 0 then
				d.wanderTo = d.route[math.random(1, #d.route)].Position
				e:setState("Wander")
			end
		end
	elseif state == "Wander" then
		local goal: Vector3 = d.wanderTo or root.Position
		if (Vector3.new(goal.X - root.Position.X, 0, goal.Z - root.Position.Z)).Magnitude < 3 or e:inState() > 25 then
			e:setState("Feed")
		else
			e:moveTo(goal, cfg.wanderSpeed)
		end
	elseif state == "Hunt" then
		local target: Player? = d.target
		if not e:canTarget(target) or now - (d.lastHeard or 0) > cfg.loseTargetAfter then
			d.target = nil
			d.wanderTo = Map.marker("Lampshy_Spawn").Position
			e:setState("Wander")
			return
		end
		local targetRoot = Crew.root(target :: Player) :: BasePart
		if e:distanceTo(target :: Player) <= cfg.lungeRange then
			e:action("attack")
			Audio.play("lampshyLunge", root, 1)
			Say.near(root.Position, 40, "[It lunges]", 2, "sound")
			Crew.hit(target :: Player, 1)
			d.retreatTo = darkestRetreat(e, targetRoot.Position)
			e:setState("Retreat")
		else
			e:moveTo(targetRoot.Position, cfg.speed)
		end
	elseif state == "Retreat" then
		e:moveTo(d.retreatTo or root.Position, cfg.speed)
		if e:inState() >= cfg.retreatTime then
			if e:canTarget(d.target) then
				d.lastHeard = now
				e:setState("Hunt")
			else
				e:setState("Feed")
			end
		end
	end
end

function Lampshy.onShot(e, _part: BasePart, shooter: Player, _position: Vector3)
	if isLit(e) then
		e:banish(shooter)
	else
		Say.to(shooter, "Nothing. It isn't there in the dark. Get a light on it.", 3, "hint")
		if e:canTarget(shooter) then
			hunt(e, shooter)
		end
	end
end

function Lampshy.onNoise(e, noise, sameWing: boolean)
	if not sameWing then
		return
	end
	local source: Player? = noise.source
	if source and e:canTarget(source) then
		if e.state == "Hunt" and e.data.target ~= source then
			-- Keeps the nearer quarry.
			local current = e.data.target
			if current and e:canTarget(current) and e:distanceTo(current) < e:distanceTo(source) then
				e.data.lastHeard = os.clock()
				return
			end
		end
		hunt(e, source)
	end
end

function Lampshy.onAgitate(e, _position: Vector3)
	local nearest = e:nearestTarget()
	if nearest then
		hunt(e, nearest)
	end
end

function Lampshy.onBanish(e, model: Model, _killer: Player?)
	local position = model:GetPivot().Position
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			if p.Name ~= "HumanoidRootPart" then
				p.Material = Enum.Material.Neon
				p.Color = Color3.fromRGB(226, 222, 206)
				p.Transparency = 0.3
			end
		end
	end
	local pale = Color3.fromRGB(230, 226, 210)
	Map.addGlow(position, cfg.glowRadius, cfg.glowTime, pale)
	task.delay(cfg.glowTime - 4, function()
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				TweenService:Create(p, TweenInfo.new(4), { Transparency = 1 }):Play()
			end
		end
		task.delay(4, function()
			model:Destroy()
		end)
	end)
	for _, player in Players:GetPlayers() do
		local r = Crew.root(player)
		if r and (r.Position - position).Magnitude < 80 then
			Say.to(player, "[It folds up on itself and glows, pale, where it fell]", 4, "sound")
		end
	end
end

return Lampshy
