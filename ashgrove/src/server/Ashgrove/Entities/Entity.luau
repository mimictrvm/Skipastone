--[[
	Entity: what every killable entity shares. A behaviour module (Dullahan,
	Lampshy) supplies the rule; this supplies the body, the binding and
	the movement.

	The binding (direction doc, section 6):
	  - killing a manifestation BANISHES it back into its object. It
	    re-forms at its spawn after Config.entities.reformMin..Max seconds
	  - securing the object (Retrieval) removes it for the rest of the story
	  - every banish fires Registry.died, which the Banshee counts as a death

	status: "dormant" (not in the story yet) | "active" | "banished" | "secured"

	Entities never leave their wing, and never target players who are in a
	sanctuary or outside the wing.

	A behaviour module provides:
	  build(e) -> (Model, root: BasePart, Humanoid)   e.data is fresh
	  step(e, dt)
	  onShot(e, part, shooter, position)
	  onNoise(e, noise)?   onAgitate(e, position)?   onBanish(e, model, killer)?
]]

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Config"))

local Ashgrove = script.Parent.Parent
local Crew = require(Ashgrove.Crew)
local Map = require(Ashgrove.Map)
local Models = require(Ashgrove.Models)
local Noise = require(Ashgrove.Noise)
local Shots = require(Ashgrove.Shots)
local Registry = require(script.Parent.Registry)

local Entity = {}
Entity.__index = Entity

local entityFolder: Folder? = nil
local function folder(): Folder
	if not entityFolder or not entityFolder.Parent then
		local f = Instance.new("Folder")
		f.Name = "Entities"
		f.Parent = Map.root()
		entityFolder = f
	end
	return entityFolder :: Folder
end

function Entity.new(id: string, cfg: { [string]: any }, behaviour: { [string]: any })
	local self = setmetatable({
		id = id,
		cfg = cfg,
		wing = cfg.wing,
		behaviour = behaviour,
		status = "dormant",
		model = nil :: Model?,
		root = nil :: BasePart?,
		humanoid = nil :: Humanoid?,
		state = "Idle",
		stateAt = 0,
		data = {} :: { [string]: any },
		reformAt = 0,
		waypoints = nil :: { PathWaypoint }?,
		waypointIndex = 0,
		pathGoal = Vector3.zero,
		pathAt = 0,
		pathBusy = false,
		anim = nil :: Models.Animations?,
		animOverride = nil :: string?,
	}, Entity)
	Registry.add(self)
	return self
end

function Entity:setState(name: string)
	if self.state ~= name then
		self.state = name
		self.stateAt = os.clock()
	end
end

function Entity:inState(): number
	return os.clock() - self.stateAt
end

function Entity:position(): Vector3?
	return if self.root then self.root.Position else nil
end

-- Brings a dormant entity into the story.
function Entity:activate()
	if self.status == "dormant" then
		self:spawn()
	end
end

function Entity:spawn()
	local marker = Map.marker(self.id .. "_Spawn")
	self.data = {}
	self.waypoints = nil
	local model, root, humanoid = self.behaviour.build(self)
	model:SetAttribute("EntityId", self.id)
	model:PivotTo(marker.CFrame)
	-- Stand it on the floor whatever its size (your model may be taller
	-- or shorter than the greybox).
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model }
	local floor = workspace:Raycast(marker.Position + Vector3.new(0, 2, 0), Vector3.new(0, -30, 0), params)
	if floor then
		local box, size = model:GetBoundingBox()
		local bottom = box.Position.Y - size.Y / 2
		model:PivotTo(model:GetPivot() + Vector3.new(0, floor.Position.Y + 0.05 - bottom, 0))
	end
	model.Parent = folder()
	root:SetNetworkOwner(nil)
	self.model, self.root, self.humanoid = model, root, humanoid
	self.anim = Models.animations(model, self.id)
	self.animOverride = nil

	-- Your gun's damage is the confirmed hit (see Shots). Health is topped
	-- straight back up: Ashgrove's monsters die by their rules, not by HP.
	local lastHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		if health < lastHealth - 0.01 and self.humanoid == humanoid then
			humanoid.Health = humanoid.MaxHealth
			lastHealth = humanoid.MaxHealth
			Shots.onDamaged(self)
		else
			lastHealth = health
		end
	end)
	self.status = "active"
	self.state = ""
	self:setState("Idle")
	if self.behaviour.onSpawn then
		self.behaviour.onSpawn(self)
	end
	Registry.formed:Fire(self)
end

local function fadeOut(model: Model, seconds: number)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			TweenService:Create(p, TweenInfo.new(seconds), { Transparency = 1 }):Play()
		end
	end
	task.delay(seconds, function()
		model:Destroy()
	end)
end

-- Killed: back into its object for a while.
function Entity:banish(killer: Player?)
	if self.status ~= "active" or not self.root or not self.model then
		return
	end
	local position = self.root.Position
	local model = self.model :: Model
	model:SetAttribute("EntityId", nil)
	self.status = "banished"
	self.model, self.root, self.humanoid = nil, nil, nil
	self.waypoints = nil
	local e = Config.entities
	self.reformAt = os.clock() + e.reformMin + math.random() * (e.reformMax - e.reformMin)
	if self.behaviour.onBanish then
		self.behaviour.onBanish(self, model, killer)
	else
		fadeOut(model, 1)
	end
	Registry.died:Fire(self, position, killer)
end

-- Its object is in a warded crate: gone for the rest of the story.
function Entity:secure()
	if self.model then
		local model = self.model :: Model
		model:SetAttribute("EntityId", nil)
		fadeOut(model, 1.5)
	end
	self.model, self.root, self.humanoid = nil, nil, nil
	self.status = "secured"
end

-- Checkpoint reset: back to its spawn, unaware.
function Entity:reset()
	if self.status == "active" then
		if self.model then
			self.model:Destroy()
		end
		self.model, self.root, self.humanoid = nil, nil, nil
		self:spawn()
	end
end

-- Despawn without killing (story end).
function Entity:retire()
	if self.model then
		fadeOut(self.model :: Model, 1.5)
	end
	self.model, self.root, self.humanoid = nil, nil, nil
	self.status = "secured"
end

------------------------------------------------------------------ senses

function Entity:ignoreList(): { Instance }
	local list: { Instance } = { Map.interact("Glows") }
	if self.model then
		table.insert(list, self.model)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	return list
end

-- Can a point see this player's head, with nothing in between?
function Entity:canSee(from: Vector3, player: Player, maxRange: number): boolean
	local head = Crew.head(player)
	local character = player.Character
	if not head or not character then
		return false
	end
	local offset = head.Position - from
	if offset.Magnitude > maxRange then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { Map.interact("Glows") }
	if self.model then
		table.insert(ignore, self.model)
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(from, offset, params)
	return hit == nil or hit.Instance:IsDescendantOf(character)
end

-- Players it may go after: targetable and inside its wing.
function Entity:targets(): { Player }
	local out = {}
	for _, player in Crew.playersInWing(self.wing) do
		if Crew.isTargetable(player) then
			table.insert(out, player)
		end
	end
	return out
end

function Entity:distanceTo(player: Player): number
	local root = Crew.root(player)
	if not root or not self.root then
		return math.huge
	end
	return (root.Position - self.root.Position).Magnitude
end

function Entity:nearestTarget(): Player?
	local best, bestDistance = nil, math.huge
	for _, player in self:targets() do
		local d = self:distanceTo(player)
		if d < bestDistance then
			best, bestDistance = player, d
		end
	end
	return best
end

function Entity:canTarget(player: Player?): boolean
	if not player or not Crew.isTargetable(player) then
		return false
	end
	local root = Crew.root(player)
	return root ~= nil and Map.wingAt(root.Position) == self.wing
end

------------------------------------------------------------------ movement

local function clearTo(self, goal: Vector3): boolean
	local from = self.root.Position
	local to = Vector3.new(goal.X, from.Y, goal.Z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = self:ignoreList()
	return workspace:Raycast(from, to - from, params) == nil
end

function Entity:moveTo(goal: Vector3, speed: number)
	local humanoid, root = self.humanoid, self.root
	if not humanoid or not root then
		return
	end
	humanoid.WalkSpeed = speed
	if Map.wingAt(goal) ~= self.wing then
		self:stop()
		return
	end
	if clearTo(self, goal) then
		self.waypoints = nil
		humanoid:MoveTo(goal)
		return
	end
	local now = os.clock()
	if not self.pathBusy and (self.waypoints == nil or now - self.pathAt > 1 or (self.pathGoal - goal).Magnitude > 4) then
		self.pathBusy = true
		self.pathAt = now
		self.pathGoal = goal
		local from = root.Position
		task.spawn(function()
			local path = PathfindingService:CreatePath({
				AgentRadius = self.cfg.agentRadius or 2,
				AgentHeight = self.cfg.agentHeight or 6,
				AgentCanJump = false,
			})
			local ok = pcall(function()
				path:ComputeAsync(from, goal)
			end)
			if ok and path.Status == Enum.PathStatus.Success then
				self.waypoints = path:GetWaypoints()
				self.waypointIndex = 2
			else
				self.waypoints = nil
			end
			self.pathBusy = false
		end)
	end
	local waypoints = self.waypoints
	if waypoints and waypoints[self.waypointIndex] then
		local wp = waypoints[self.waypointIndex].Position
		local flat = Vector3.new(wp.X - root.Position.X, 0, wp.Z - root.Position.Z)
		if flat.Magnitude < 2.5 and self.waypointIndex < #waypoints then
			self.waypointIndex += 1
			wp = waypoints[self.waypointIndex].Position
		end
		humanoid:MoveTo(wp)
	end
end

function Entity:stop()
	if self.humanoid and self.root then
		self.humanoid.WalkSpeed = 0
		self.humanoid:MoveTo(self.root.Position)
	end
end

-- Turn the body to face a point (only while stopped).
function Entity:face(point: Vector3)
	local root = self.root
	if root then
		local flat = Vector3.new(point.X, root.Position.Y, point.Z)
		if (flat - root.Position).Magnitude > 0.1 then
			root.CFrame = CFrame.lookAt(root.Position, flat)
		end
	end
end

-- A one-off animation (Config.models[id].animations), e.g. "attack".
function Entity:action(name: string)
	if self.anim then
		self.anim.action(name)
	end
end

function Entity:shot(part: BasePart, shooter: Player, position: Vector3)
	if self.status == "active" then
		self.behaviour.onShot(self, part, shooter, position)
	end
end

function Entity:agitate(position: Vector3)
	if self.status == "active" and self.behaviour.onAgitate then
		self.behaviour.onAgitate(self, position)
	end
end

------------------------------------------------------------------ loop

local function playerNear(position: Vector3, radius: number): boolean
	for _, player in Players:GetPlayers() do
		local root = Crew.root(player)
		if root and (root.Position - position).Magnitude < radius then
			return true
		end
	end
	return false
end

function Entity.startLoop()
	Noise.emitted:Connect(function(noise: Noise.Noise)
		for _, e in Registry.all() do
			if e.status == "active" and e.root and e.behaviour.onNoise then
				local hearing = noise.radius * (e.cfg.hearingMultiplier or 1)
				local sameWing = Map.wingAt(noise.position) == e.wing
				if (sameWing or noise.kind == "gunshot") and (noise.position - e.root.Position).Magnitude <= hearing then
					e.behaviour.onNoise(e, noise, sameWing)
				end
			end
		end
	end)

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(Config.entities.stepInterval)
			local now = os.clock()
			local dt = now - last
			last = now
			for _, e in Registry.all() do
				if e.status == "active" then
					if not e.model or not e.model.Parent or not e.root then
						-- Lost its body (destroyed by something else): re-form later.
						e.status = "banished"
						e.model, e.root, e.humanoid = nil, nil, nil
						e.reformAt = now + Config.entities.reformMin
					else
						if Map.wingAt(e.root.Position) ~= e.wing then
							-- Strayed out of its wing: walk home.
							e.humanoid:MoveTo(Map.marker(e.id .. "_Spawn").Position)
						end
						local ok, err = pcall(e.behaviour.step, e, dt)
						if not ok then
							warn(`[Ashgrove] {e.id} step failed: {err}`)
						end
						if e.anim and e.root then
							local v = e.root.AssemblyLinearVelocity
							local speed = Vector3.new(v.X, 0, v.Z).Magnitude
							e.anim.loop(e.animOverride or (if speed > 10 then "run" elseif speed > 0.5 then "walk" else "idle"))
						end
					end
				elseif e.status == "banished" and now >= e.reformAt then
					local spawnAt = Map.marker(e.id .. "_Spawn").Position
					if playerNear(spawnAt, Config.entities.reformClearRadius) then
						e.reformAt = now + 10
					else
						e:spawn()
					end
				end
			end
		end
	end)
end

return Entity
