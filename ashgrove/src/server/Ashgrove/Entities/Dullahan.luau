--[[
	The Dullahan (portrait gallery). Killable. Lot 114, the spine whip.

	RULE: it sees only what its carried head is facing.

	- Idle: walks the gallery, stopping to hold the head up to portraits
	  and windows. Stay out of the head's view and you can pass behind him.
	- The kill window closes at whip reach (about 12 studs), not contact.
	- Weak point: the head. Hit it and he drops it and gropes blind for
	  Config.blindTime seconds; body shots then kill him. Body shots while
	  he holds the head only stagger him.
	- Gold raised where the head can see it drives him back. No kill.
	- Death: the body falls apart, the head keeps glowing where it rolled
	  for a while (a light source), and the Banshee may come to mourn.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Audio = require(Shared:WaitForChild("Audio"))
local Config = require(Shared:WaitForChild("Config"))

local Ashgrove = script.Parent.Parent
local Crew = require(Ashgrove.Crew)
local Map = require(Ashgrove.Map)
local Noise = require(Ashgrove.Noise)
local Say = require(Ashgrove.Say)
local Rigs = require(script.Parent.Rigs)

local cfg = Config.entities.Dullahan

local Dullahan = {}

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-4 then f.Unit else Vector3.new(0, 0, -1)
end

local function hasHead(e): boolean
	return not e.data.blind and e.data.head ~= nil and e.data.headWeld ~= nil and e.data.headWeld.Parent ~= nil
end

local function headLook(e): Vector3
	return flat(e.data.head.CFrame.LookVector)
end

-- Turns the carried head towards a world direction, at `rate` radians/s.
local function turnHeadTowards(e, direction: Vector3, dt: number, rate: number)
	if not hasHead(e) then
		return
	end
	local rel = e.root.CFrame:VectorToObjectSpace(flat(direction))
	local target = math.clamp(math.atan2(-rel.X, -rel.Z), math.rad(-150), math.rad(150))
	local current = e.data.headYaw or 0
	local step = math.clamp(target - current, -rate * dt, rate * dt)
	e.data.headYaw = current + step
	e.data.headWeld.C0 = CFrame.new(Rigs.DULLAHAN_HEAD_OFFSET) * CFrame.Angles(0, e.data.headYaw, 0)
end

local function headSees(e, player: Player, range: number): boolean
	if not hasHead(e) then
		return false
	end
	local head = Crew.head(player)
	if not head then
		return false
	end
	local from = e.data.head.Position
	local offset = head.Position - from
	if offset.Magnitude > range then
		return false
	end
	local inCone = headLook(e):Dot(flat(offset)) >= math.cos(math.rad(cfg.fieldOfView / 2))
	return inCone and e:canSee(from, player, range)
end

local function findTarget(e): Player?
	local best, bestDistance = nil, math.huge
	for _, player in e:targets() do
		local d = e:distanceTo(player)
		if d < bestDistance and (d <= cfg.touchRange or headSees(e, player, cfg.sightRange)) then
			best, bestDistance = player, d
		end
	end
	return best
end

local function startHunt(e, player: Player)
	local d = e.data
	local wasHunting = e.state == "Hunt" or e.state == "Windup" or e.state == "Recover"
	d.target = player
	d.lastSeen = os.clock()
	local root = Crew.root(player)
	d.lastSeenPos = if root then root.Position else e.root.Position
	if not wasHunting then
		Say.to(player, "[The head turns towards you]", 3, "sound")
		Audio.play("dullahanBreath", e.root, 0.8)
	end
	e:setState("Hunt")
end

local function alert(e, position: Vector3)
	e.data.alertPos = position
	e:setState("Alert")
end

local function dropHead(e)
	local d = e.data
	if not hasHead(e) then
		return
	end
	d.headWeld:Destroy()
	d.headWeld = nil
	d.blind = true
	d.bodyHits = 0
	local head: BasePart = d.head
	head.Massless = false
	head.CanCollide = true
	head.AssemblyLinearVelocity = flat(e.root.CFrame.LookVector) * 6 + Vector3.new(0, 8, 0)
	pcall(function()
		head:SetNetworkOwner(nil)
	end)
	Audio.play("headDrop", head, 0.8)
	Noise.emit(head.Position, 25, "impact")
	e:setState("Blind")
end

local function returnHead(e)
	local d = e.data
	local head: BasePart = d.head
	if not head or not head.Parent or not e.root then
		return
	end
	head.CanCollide = false
	head.Massless = true
	head.AssemblyLinearVelocity = Vector3.zero
	d.headYaw = 0
	local weld = Instance.new("Weld")
	weld.Name = "HeadWeld"
	weld.Part0 = e.root
	weld.Part1 = head
	weld.C0 = CFrame.new(Rigs.DULLAHAN_HEAD_OFFSET)
	weld.Parent = head
	d.headWeld = weld
	d.blind = false
	Say.near(e.root.Position, 60, "[He finds his head]", 3, "sound")
end

local function repel(e, from: Vector3)
	e.data.repelFrom = from
	e:setState("Repelled")
	Say.near(e.root.Position, 50, "[He recoils from the gold]", 3, "sound")
end

------------------------------------------------------------------ behaviour

function Dullahan.build(e)
	local model, root, humanoid, parts = Rigs.dullahan()
	e.data.head = parts.head
	e.data.headWeld = parts.headWeld
	e.data.headYaw = 0
	e.data.route = Map.markers("Dullahan_Route_")
	e.data.routeIndex = 1
	e.data.routeDir = 1
	e.data.pauseUntil = 0
	e.data.nextTrace = os.clock() + 15
	return model, root, humanoid
end

function Dullahan.step(e, dt: number)
	local d = e.data
	local now = os.clock()
	local root: BasePart = e.root

	-- Traces before contact: a whip-crack that carries out of the gallery.
	if now >= d.nextTrace and (e.state == "Idle" or e.state == "Alert") then
		d.nextTrace = now + 20 + math.random() * 20
		Audio.play("dullahanWhip", root, 0.5, 200)
		Say.near(root.Position, 160, "[A whip-crack, somewhere down the gallery]", 3, "sound")
	end

	-- Gold he can see drives him back.
	if hasHead(e) and e.state ~= "Repelled" then
		for _, player in Crew.activePlayers() do
			if Crew.isWardRaised(player) and headSees(e, player, Config.ward.range) then
				local r = Crew.root(player)
				if r then
					repel(e, r.Position)
				end
				break
			end
		end
	end

	local state = e.state
	if state == "Idle" then
		local seen = findTarget(e)
		if seen then
			startHunt(e, seen)
			return
		end
		local route = d.route
		if #route == 0 then
			e:stop()
			return
		end
		local stop: BasePart = route[d.routeIndex]
		local offset = stop.Position - root.Position
		if Vector3.new(offset.X, 0, offset.Z).Magnitude < 3 then
			e:stop()
			if d.pauseUntil == 0 then
				d.pauseUntil = now + cfg.idlePauseMin + math.random() * (cfg.idlePauseMax - cfg.idlePauseMin)
			end
			local look = stop:GetAttribute("Look")
			if typeof(look) == "Vector3" then
				turnHeadTowards(e, look - root.Position, dt, 1.5)
			end
			if now >= d.pauseUntil then
				d.pauseUntil = 0
				local nextIndex = d.routeIndex + d.routeDir
				if nextIndex < 1 or nextIndex > #route then
					d.routeDir = -d.routeDir
					nextIndex = d.routeIndex + d.routeDir
				end
				d.routeIndex = math.clamp(nextIndex, 1, #route)
			end
		else
			e:moveTo(stop.Position, cfg.walkSpeed)
			-- The head sweeps slowly while he walks.
			local sweep = math.sin(now * 0.6) * 0.9
			turnHeadTowards(e, root.CFrame:VectorToWorldSpace(CFrame.Angles(0, sweep, 0).LookVector), dt, 1.2)
		end
	elseif state == "Alert" then
		local seen = findTarget(e)
		if seen then
			startHunt(e, seen)
			return
		end
		local goal: Vector3 = d.alertPos or root.Position
		turnHeadTowards(e, goal - root.Position, dt, 2.5)
		if (Vector3.new(goal.X - root.Position.X, 0, goal.Z - root.Position.Z)).Magnitude > 4 then
			e:moveTo(goal, cfg.walkSpeed)
		else
			e:stop()
		end
		if e:inState() > cfg.searchTime then
			e:setState("Idle")
		end
	elseif state == "Hunt" then
		local target: Player? = d.target
		if not e:canTarget(target) then
			alert(e, d.lastSeenPos or root.Position)
			return
		end
		local targetRoot = Crew.root(target :: Player) :: BasePart
		if headSees(e, target :: Player, cfg.sightRange) or e:distanceTo(target :: Player) <= cfg.touchRange then
			d.lastSeen = now
			d.lastSeenPos = targetRoot.Position
		elseif now - (d.lastSeen or 0) > cfg.loseTargetAfter then
			alert(e, d.lastSeenPos)
			return
		end
		turnHeadTowards(e, targetRoot.Position - root.Position, dt, 5)
		local distance = e:distanceTo(target :: Player)
		if distance <= cfg.whipRange and e:canSee(root.Position, target :: Player, cfg.whipRange + 2) then
			e:stop()
			e:face(targetRoot.Position)
			Say.to(target :: Player, "[The whip draws back]", 2, "sound")
			e:setState("Windup")
		else
			e:moveTo(targetRoot.Position, cfg.huntSpeed)
		end
	elseif state == "Windup" then
		local target: Player? = d.target
		if target and Crew.root(target) then
			e:face((Crew.root(target) :: BasePart).Position)
		end
		if e:inState() >= cfg.windupTime then
			Audio.play("dullahanWhip", root, 1, 200)
			Say.near(root.Position, 80, "[CRACK]", 2, "sound")
			if target and e:canTarget(target) and e:distanceTo(target) <= cfg.whipRange + 1.5 and e:canSee(root.Position, target, cfg.whipRange + 3) then
				Crew.hit(target, 1)
			end
			e:setState("Recover")
		end
	elseif state == "Recover" then
		e:stop()
		if e:inState() >= cfg.recoverTime then
			if e:canTarget(d.target) then
				e:setState("Hunt")
			else
				alert(e, d.lastSeenPos or root.Position)
			end
		end
	elseif state == "Stagger" then
		e:stop()
		if e:inState() >= cfg.staggerTime then
			if e:canTarget(d.target) then
				startHunt(e, d.target)
			else
				alert(e, d.lastSeenPos or root.Position)
			end
		end
	elseif state == "Blind" then
		-- Groping towards the last thing he heard.
		local goal: Vector3? = d.gropeTo
		if goal and (Vector3.new(goal.X - root.Position.X, 0, goal.Z - root.Position.Z)).Magnitude > 3 then
			e:moveTo(goal, 5)
		else
			e:stop()
		end
		if e:inState() >= cfg.blindTime then
			returnHead(e)
			local seen = findTarget(e)
			if seen then
				startHunt(e, seen)
			else
				alert(e, d.lastSeenPos or root.Position)
			end
		end
	elseif state == "Repelled" then
		local from: Vector3 = d.repelFrom or root.Position
		turnHeadTowards(e, from - root.Position, dt, 4)
		local away = flat(root.Position - from)
		e:moveTo(root.Position + away * 10, cfg.huntSpeed)
		if e:inState() >= cfg.repelTime then
			if e:canTarget(d.target) then
				e:setState("Hunt")
			else
				e:setState("Idle")
			end
		end
	end
end

function Dullahan.onShot(e, part: BasePart, shooter: Player, _position: Vector3)
	local d = e.data
	local hitbox = part:GetAttribute("Hitbox")
	if hitbox == "Head" and hasHead(e) then
		d.target = shooter
		d.lastSeen = os.clock()
		dropHead(e)
		Say.to(shooter, "Hit the head. He's blind. Now.", 3, "hint")
		Say.near(e.root.Position, 80, "[The head hits the floor and rolls]", 3, "sound")
		return
	end
	if d.blind then
		d.bodyHits = (d.bodyHits or 0) + 1
		if d.bodyHits >= cfg.bodyHitsToKillWhileBlind then
			e:banish(shooter)
		else
			Say.near(e.root.Position, 60, "[He staggers]", 2, "sound")
		end
		return
	end
	if not d.taughtBody then
		d.taughtBody = true
		Say.to(shooter, "Body shots don't stop him.", 3, "hint")
	end
	d.target = shooter
	d.lastSeen = os.clock()
	local r = Crew.root(shooter)
	d.lastSeenPos = if r then r.Position else e.root.Position
	e:setState("Stagger")
end

function Dullahan.onNoise(e, noise, sameWing: boolean)
	local d = e.data
	if e.state == "Blind" then
		if sameWing then
			d.gropeTo = noise.position
		end
		return
	end
	if e.state == "Idle" or e.state == "Alert" then
		if sameWing then
			alert(e, noise.position)
		end
	end
end

function Dullahan.onAgitate(e, position: Vector3)
	if e.state == "Idle" then
		alert(e, position)
	end
end

function Dullahan.onBanish(e, model: Model, _killer: Player?)
	local d = e.data
	local head: BasePart? = d.head
	local position = model:GetPivot().Position
	-- The head stays, still glowing, where it rolled.
	if head then
		if d.headWeld then
			d.headWeld:Destroy()
		end
		head.Massless = false
		head.CanCollide = true
		head.CanQuery = false
		head:SetAttribute("LightRadius", cfg.headGlowRadius)
		head.Parent = Map.interact("Glows")
		pcall(function()
			head:SetNetworkOwner(nil)
		end)
		Debris:AddItem(head, cfg.headGlowTime)
	end
	-- The body comes apart.
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.Anchored = true
		root.CanCollide = false
	end
	for _, p in model:GetDescendants() do
		if p:IsA("WeldConstraint") then
			p:Destroy()
		elseif p:IsA("BasePart") and p ~= root then
			p.CanCollide = true
			p.CanQuery = false
		end
	end
	task.delay(5, function()
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				TweenService:Create(p, TweenInfo.new(3), { Transparency = 1 }):Play()
			end
		end
		task.delay(3, function()
			model:Destroy()
		end)
	end)
	for _, player in Players:GetPlayers() do
		local r = Crew.root(player)
		if r and (r.Position - position).Magnitude < 120 then
			Say.to(player, "[He comes apart. The head keeps glowing.]", 4, "sound")
		end
	end
end

return Dullahan
