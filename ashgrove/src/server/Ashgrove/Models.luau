--[[
	Models: uses your monster models when they exist, the greybox bodies
	when they don't.

	WHERE TO PUT YOUR MODELS. Any of these work (checked in this order):
	  ServerStorage.AshgroveModels.<name>
	  ReplicatedStorage.AshgroveModels.<name>
	  anywhere in Workspace or ServerStorage
	with <name> one of Config.models[id].names (case, spaces, "_" and "-"
	ignored), e.g. "Dullahan", "AH_Ent_Dullahan", "Banshee". A model left
	standing in the Workspace is moved to ServerStorage.AshgroveModels when
	the game starts, so it doesn't stand in the level in a T-pose.

	WHAT A MODEL NEEDS
	  - Rigged (Humanoid + HumanoidRootPart): used as it is. Its front must
	    be the root's -Z (the usual Roblox export).
	  - Not rigged (just meshes): it's carried on an invisible root and
	    Humanoid that Ashgrove adds. Its front must face -Z.
	  - The Dullahan's carried head: a part named Config.models.Dullahan.
	    headPart ("CarriedHead"), or failing that any part with "head" in
	    its name. It's what he sees through and his weak point.
	  - Hit parts: anything with "head" in its name counts as a head hit,
	    everything else as body, unless you set a Hitbox attribute
	    ("Head" / "Body") yourself.
	  - Animations: optional ids in Config.models[id].animations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Config"))

local Models = {}

local cache: { [string]: Model | false } = {}

local function normal(name: string): string
	return string.lower((string.gsub(name, "[%s_%-]", "")))
end

local function storageFolder(): Folder
	local f = ServerStorage:FindFirstChild("AshgroveModels")
	if not f then
		f = Instance.new("Folder")
		f.Name = "AshgroveModels"
		f.Parent = ServerStorage
	end
	return f :: Folder
end

local function isExcluded(inst: Instance): boolean
	local house = workspace:FindFirstChild("AshgroveHouse")
	if house and inst:IsDescendantOf(house) then
		return true
	end
	for _, player in game:GetService("Players"):GetPlayers() do
		if player.Character and inst:IsDescendantOf(player.Character) then
			return true
		end
	end
	return false
end

-- The template model for an entity id, or nil.
function Models.find(id: string): Model?
	local cached = cache[id]
	if cached ~= nil then
		return if cached then cached else nil
	end
	local cfg = (Config.models :: any)[id]
	if not cfg then
		cache[id] = false
		return nil
	end
	local wanted: { [string]: boolean } = {}
	for _, name in cfg.names do
		wanted[normal(name)] = true
	end
	local function search(list: { Instance }): Model?
		for _, inst in list do
			if inst:IsA("Model") and wanted[normal(inst.Name)] and not isExcluded(inst) then
				return inst
			end
		end
		return nil
	end
	local found: Model? = nil
	for _, holder in { ServerStorage, ReplicatedStorage } do
		local folder = holder:FindFirstChild("AshgroveModels")
		if folder and not found then
			found = search(folder:GetChildren())
		end
	end
	found = found or search(workspace:GetDescendants()) or search(ServerStorage:GetDescendants())
	if found and found:IsDescendantOf(workspace) then
		found.Parent = storageFolder()
	end
	cache[id] = found or false
	return found
end

-- Look for every configured model now (moves any out of the Workspace).
function Models.collect()
	for id in Config.models :: any do
		local found = Models.find(id)
		if found then
			print(`[Ashgrove] Using your model "{found.Name}" for {id}.`)
		end
	end
end

function Models.configureHumanoid(humanoid: Humanoid)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.MaxHealth = 1e6
	humanoid.Health = 1e6
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.WalkSpeed = 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

local function isHeadName(name: string): boolean
	return string.find(string.lower(name), "head", 1, true) ~= nil
end

local function findHead(model: Model, preferred: string?): BasePart?
	if preferred then
		local exact = model:FindFirstChild(preferred, true)
		if exact and exact:IsA("BasePart") then
			return exact
		end
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and isHeadName(p.Name) then
			return p
		end
	end
	return nil
end

-- A spawnable copy of your creature model, ready for the AI. Returns nil
-- when there's no model for this id.
function Models.creature(id: string): (Model?, BasePart?, Humanoid?, BasePart?)
	local template = Models.find(id)
	if not template then
		return nil, nil, nil, nil
	end
	local cfg = (Config.models :: any)[id]
	local model = template:Clone()
	model.Name = id
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart) :: BasePart?

	if humanoid and root then
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = false
			end
		end
	else
		-- Not rigged: carry the meshes on a root and a Humanoid of our own.
		local box, size = model:GetBoundingBox()
		local newRoot = Instance.new("Part")
		newRoot.Name = "HumanoidRootPart"
		newRoot.Size = Vector3.new(2, 2, 1)
		newRoot.Transparency = 1
		newRoot.CanCollide = true
		newRoot.CFrame = CFrame.new(box.Position) * model:GetPivot().Rotation
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = false
				p.CanCollide = false
				p.Massless = true
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = newRoot
				weld.Part1 = p
				weld.Parent = p
			end
		end
		newRoot.Parent = model
		model.PrimaryPart = newRoot
		local newHumanoid = Instance.new("Humanoid")
		newHumanoid.RigType = Enum.HumanoidRigType.R15
		newHumanoid.HipHeight = math.max(0.2, size.Y / 2 - newRoot.Size.Y / 2)
		newHumanoid.Parent = model
		humanoid, root = newHumanoid, newRoot
	end
	local finalRoot = root :: BasePart
	model.PrimaryPart = finalRoot
	finalRoot:SetAttribute("Hitbox", "Body")
	Models.configureHumanoid(humanoid :: Humanoid)

	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("Hitbox") == nil then
			p:SetAttribute("Hitbox", if isHeadName(p.Name) then "Head" else "Body")
		end
	end
	return model, finalRoot, humanoid, findHead(model, cfg and cfg.headPart)
end

-- The joint that holds a part, made turnable and detachable. Converts a
-- WeldConstraint into a Weld; makes one to the root if there's none.
function Models.jointFor(model: Model, root: BasePart, part: BasePart): JointInstance
	for _, d in model:GetDescendants() do
		if d:IsA("JointInstance") and (d.Part1 == part or d.Part0 == part) then
			return d
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("WeldConstraint") and (d.Part0 == part or d.Part1 == part) then
			local other = if d.Part0 == part then d.Part1 else d.Part0
			if other then
				local weld = Instance.new("Weld")
				weld.Part0 = other
				weld.Part1 = part
				weld.C0 = other.CFrame:Inverse() * part.CFrame
				d:Destroy()
				weld.Parent = part
				return weld
			end
		end
	end
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = part
	weld.C0 = root.CFrame:Inverse() * part.CFrame
	weld.Parent = part
	return weld
end

-- Your Banshee, prepared to be shown and hidden: an invisible "Root" at
-- her feet as the pivot. Returns the model, the part used as her face
-- (torch-on-face check) and the part her keen and light come from.
function Models.banshee(): (Model?, BasePart?, BasePart?)
	local template = Models.find("Banshee")
	if not template then
		return nil, nil, nil
	end
	local model = template:Clone()
	model.Name = "Banshee"
	local box, size = model:GetBoundingBox()
	local rotation = model:GetPivot().Rotation
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local jointed = (model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("AnimationController")) ~= nil
		and model:FindFirstChildWhichIsA("Motor6D", true) ~= nil

	local face, chest, highest = nil, nil, nil
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Anchored = not jointed or p == hrp
			p:SetAttribute("BaseTransparency", p.Transparency)
			local lower = string.lower(p.Name)
			if not face and (string.find(lower, "face", 1, true) or string.find(lower, "head", 1, true)) then
				face = p
			end
			if not chest and (lower == "chest" or lower == "uppertorso" or lower == "torso") then
				chest = p
			end
			if not highest or p.Position.Y > highest.Position.Y then
				highest = p
			end
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	end

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Transparency = 1
	root.Size = Vector3.one * 0.5
	root.CFrame = CFrame.new(box.X, box.Y - size.Y / 2, box.Z) * rotation
	root.Parent = model
	model.PrimaryPart = root
	return model, face or highest, chest or root
end

------------------------------------------------------------------ animation

export type Animations = {
	loop: (name: string) -> (),
	action: (name: string) -> (),
}

local FALLBACK = {
	run = "walk",
	blind = "idle",
	keen = "idle",
	mourn = "idle",
}

local NO_ANIMATIONS: Animations = {
	loop = function() end,
	action = function() end,
}

-- Plays the ids in Config.models[id].animations on a model. `loop` keeps
-- one looping animation going (idle, walk, run, keen...); `action` plays
-- a one-off on top (attack). Missing ids are ignored.
function Models.animations(model: Model, id: string): Animations
	local cfg = (Config.models :: any)[id]
	local ids = cfg and cfg.animations
	local controller = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("AnimationController")
	if not ids or not controller then
		return NO_ANIMATIONS
	end
	local animator = controller:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end
	local tracks: { [string]: AnimationTrack } = {}
	local function track(name: string): AnimationTrack?
		if tracks[name] then
			return tracks[name]
		end
		local animId = ids[name]
		if not animId or animId == "" then
			return nil
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = animId
		local ok, loaded = pcall(function()
			return (animator :: Animator):LoadAnimation(animation)
		end)
		if ok and loaded then
			tracks[name] = loaded
			return loaded
		end
		return nil
	end
	local current: string? = nil
	return {
		loop = function(wanted: string)
			-- A missing animation falls back to a close one (run -> walk).
			local name = wanted
			if not track(name) and FALLBACK[name] then
				name = FALLBACK[name]
			end
			if current == name then
				return
			end
			local nextTrack = track(name)
			if not nextTrack then
				return
			end
			if current and tracks[current] then
				tracks[current]:Stop(0.25)
			end
			current = name
			nextTrack.Looped = true
			nextTrack:Play(0.25)
		end,
		action = function(name: string)
			local t = track(name)
			if t then
				t.Looped = false
				t:Play(0.1)
			end
		end,
	}
end

return Models
