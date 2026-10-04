--[[
	Director: Story 1, start to finish. Chapters, objectives, checkpoints,
	story beats and party wipes. Everything else reacts to the systems; this
	is the only file that knows the story's order.

	  I    The Second Crew      van -> hall. Find the camp and the manifest.
	  II   The Portrait Gallery the Dullahan. Secure the spine whip.
	                            First distant keen.
	  III  The Servants' Wing   the Lamp-shy. She mourns in the kitchen;
	                            the first keen. Secure the hollow lantern.
	                            The storm cuts the hall's power.
	  IV   The Cellar Vault     the opened box. Her keen with nothing to
	                            kill. Back to the van; she keeps keening.

	Checkpoints are the chapter starts. A wipe puts everyone back at the
	last one with the ammo they had there.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Ashgrove")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Ashgrove = script.Parent
local Banshee = require(Ashgrove.Banshee)
local BellBoard = require(Ashgrove.BellBoard)
local Crew = require(Ashgrove.Crew)
local Doors = require(Ashgrove.Doors)
local Gun = require(Ashgrove.Gun)
local Map = require(Ashgrove.Map)
local Pickups = require(Ashgrove.Pickups)
local Reading = require(Ashgrove.Reading)
local Retrieval = require(Ashgrove.Retrieval)
local Rites = require(Ashgrove.Rites)
local Say = require(Ashgrove.Say)
local Storm = require(Ashgrove.Storm)
local Entity = require(Ashgrove.Entities.Entity)
local Registry = require(Ashgrove.Entities.Registry)
local DullahanBehaviour = require(Ashgrove.Entities.Dullahan)
local LampshyBehaviour = require(Ashgrove.Entities.Lampshy)

local Director = {}

type Objective = { text: string, done: boolean? }

local chapter = 0
local chapterStartedAt = 0
local checkpointName = "Spawn_Van"
local objectives: { Objective } = {}
local flags: { [string]: any } = {}
local wiping = false

local dullahan
local lampshy

local function anyoneIn(wing: string): boolean
	return #Crew.playersInWing(wing) > 0
end

local function anyoneInRoom(room: string): boolean
	for _, player in Crew.activePlayers() do
		local root = Crew.root(player)
		if root and Map.roomAt(root.Position) == room then
			return true
		end
	end
	return false
end

local function setObjectives(list: { Objective })
	objectives = list
	Net.event("Objectives"):FireAllClients(objectives)
end

local function tick(index: number)
	if objectives[index] and not objectives[index].done then
		objectives[index].done = true
		Net.event("Objectives"):FireAllClients(objectives)
	end
end

local function setCheckpoint(name: string)
	checkpointName = name
	Gun.saveAll()
end

local function card(title: string, subtitle: string)
	Net.event("Chapter"):FireAllClients(title, subtitle)
end

------------------------------------------------------------------ chapters

local enterChapter: (number) -> ()

local function chapterOne()
	setCheckpoint("Spawn_Van")
	card("I. The Second Crew", "Ashgrove House. One night. A storm off the sea.")
	setObjectives({
		{ text = "Go into Ashgrove House" },
		{ text = "Find the first crew's camp in the hall" },
	})
	task.delay(4, function()
		Say.all("WASD move, Shift sprint, C crouch, F torch, Click shoot, R reload, E interact. H for help.", 10, "hint")
	end)
end

local function chapterTwo()
	setCheckpoint("Spawn_HallCamp")
	Pickups.roll()
	dullahan:activate()
	card("II. The Portrait Gallery", "Lot 114. The spine whip.")
	setObjectives({
		{ text = "Secure Lot 114, the spine whip (far end of the portrait gallery)" },
		{ text = "Optional: take Cornelius's gold sovereign (case in the hall)" },
	})
end

local function chapterThree()
	setCheckpoint("Spawn_HallCamp")
	Doors.setLocked("ServantsDoor", false)
	Say.all("Okafor's keys were in the tack case. The servants' door is open.", 5, "story")
	lampshy:activate()
	card("III. The Servants' Wing", "Lot 203. The hollow lantern.")
	setObjectives({
		{ text = "Secure Lot 203, the hollow lantern (scullery, servants' wing)" },
		{ text = "Lot 077, the silver comb, is missing. Leave it." },
	})
end

local function chapterFour()
	setCheckpoint("Spawn_Stairwell")
	Doors.setLocked("VaultGate", false)
	Banshee.setNatural(false)
	Say.all("The chain on the cellar gate has rusted through. The way down is open.", 5, "story")
	card("IV. The Cellar Vault", "Lot 001. The sealed box.")
	setObjectives({
		{ text = "Find Lot 001, the sealed box (cellar vault)" },
	})
end

local CHAPTERS = { chapterOne, chapterTwo, chapterThree, chapterFour }

enterChapter = function(n: number)
	if n <= chapter or not CHAPTERS[n] then
		return
	end
	chapter = n
	chapterStartedAt = os.clock()
	CHAPTERS[n]()
end

local function ending()
	if flags.ended then
		return
	end
	flags.ended = true
	setObjectives({ { text = "You got out.", done = true } })
	for _, e in Registry.all() do
		e:retire()
	end
	local door = CFrame.lookAt(Vector3.new(-64, 0, 0), Vector3.new(-130, 0, 0))
	Banshee.ending(door)
	Say.all("[The keening doesn't stop]", 4, "sound")
	task.wait(4)
	Say.all("You're out in the rain, and she's still keening.", 5, "story")
	task.wait(5)
	Say.all("It wasn't about you.", 5, "story")
	task.wait(5)
	Net.event("Screen"):FireAllClients("end", "END OF STORY 1\n\nThe box was empty.\nSomebody is wearing what was in it.")
end

------------------------------------------------------------------ story beats

local function onSecured(objectId: string)
	if objectId == "SpineWhip" then
		tick(1)
		Storm.escalate()
		enterChapter(3)
	elseif objectId == "HollowLantern" then
		tick(1)
		Storm.escalate()
		enterChapter(4)
	end
end

local function onInspected(objectId: string, player: Player)
	if objectId ~= "DybbukBox" then
		return
	end
	tick(1)
	Say.all("The seal is broken. The box is empty.", 5, "story")
	task.wait(Config.story.ruleBreakDelay)
	if flags.ended then
		return
	end
	-- The rule-break: she keens with nothing here to kill. It's for one of you.
	local target = if table.find(Crew.playersInWing("Vault"), player) then player else nil
	if Banshee.keen("Vault", { forced = true, target = target }) then
		flags.ruleBreak = true
		setObjectives({ { text = "Nothing down here can die in your place. Keep the custom, or get out." } })
	else
		flags.finale = true
		setObjectives({ { text = "Get everyone back to the van" } })
	end
end

local function onKeenEnded(wing: string, _outcome: string)
	if chapter == 3 and wing == "ServantsWing" and not flags.naturalOn then
		flags.naturalOn = true
		Banshee.setNatural(true)
	end
	if flags.ruleBreak and wing == "Vault" and not flags.finale then
		flags.finale = true
		setObjectives({ { text = "Get everyone back to the van" } })
	end
end

local function storyLoop()
	while not flags.ended do
		task.wait(0.5)
		local now = os.clock()
		if chapter == 1 then
			if anyoneIn("Hall") then
				tick(1)
			end
			if anyoneIn("Gallery") then
				enterChapter(2)
			end
		elseif chapter == 2 then
			if not flags.distant and now - chapterStartedAt >= Config.story.firstDistantDelay then
				flags.distant = true
				Banshee.enableDistant()
				Banshee.distantNow()
			end
		elseif chapter == 3 then
			if not flags.distant then
				flags.distant = true
				Banshee.enableDistant()
			end
			if not flags.kitchenMourning and anyoneInRoom("Kitchen") then
				flags.kitchenMourning = true
				task.delay(Config.story.kitchenMourningDelay, function()
					if not Banshee.mourn(Map.marker("Body_Kitchen").Position, { noteId = "Memo_Kitchen", key = "Kitchen", grace = 6 }) then
						Reading.reveal("Memo_Kitchen")
						flags.firstKeenAt = os.clock() + Config.story.firstKeenDelay
					end
				end)
			end
			if flags.firstKeenAt and not flags.firstKeen and now >= flags.firstKeenAt and anyoneIn("ServantsWing") then
				if Banshee.keen("ServantsWing", { forced = true }) then
					flags.firstKeen = true
				end
			end
		elseif chapter == 4 then
			if flags.finale then
				local everyone = true
				local anyone = false
				for _, player in Players:GetPlayers() do
					local s = Crew.state(player)
					if s and not s.taken then
						anyone = true
						local root = Crew.root(player)
						if not Crew.isActive(player) or not root or Map.wingAt(root.Position) ~= "Van" then
							everyone = false
						end
					end
				end
				if anyone and everyone then
					task.spawn(ending)
				end
			end
		end
	end
end

------------------------------------------------------------------ wipes

local function onWipe()
	if wiping or flags.ended then
		return
	end
	wiping = true
	Net.event("Screen"):FireAllClients("wipe", "The house keeps you.")
	task.wait(3)
	Banshee.reset()
	for _, e in Registry.all() do
		e:reset()
	end
	Doors.clearLockouts()
	Crew.resetAll(Map.marker(checkpointName).CFrame)
	Gun.restoreAll()
	if flags.ruleBreak and not flags.finale then
		-- The vault keen is lost with the wipe; go straight to the escape.
		flags.finale = true
		setObjectives({ { text = "Get everyone back to the van" } })
	end
	Net.event("Screen"):FireAllClients("clear", "")
	Say.all("Back to the last safe place.", 4, "story")
	wiping = false
end

------------------------------------------------------------------ debug

local function onDebug(player: Player, command: any)
	if not RunService:IsStudio() or not Config.debug.studioKeys then
		return
	end
	if command == "next" then
		if chapter == 1 then
			enterChapter(2)
		elseif chapter == 2 then
			Retrieval.forceSecure("SpineWhip")
		elseif chapter == 3 then
			Retrieval.forceSecure("HollowLantern")
		end
		Say.to(player, `[debug] chapter {chapter}`, 3, "hint")
	elseif command == "keen" then
		local root = Crew.root(player)
		local wing = root and Map.wingAt(root.Position)
		if not wing or not Banshee.keen(wing, { forced = true, target = player }) then
			Say.to(player, "[debug] can't keen here (hall, van and grounds never keen)", 3, "hint")
		end
	elseif command == "refill" then
		Gun.refill(player)
		Crew.addBattery(player, Config.flashlight.maxBattery)
		Say.to(player, "[debug] refilled", 2, "hint")
	end
end

------------------------------------------------------------------ start

function Director.start()
	Map.root()
	Storm.start()
	Doors.setup()
	Rites.setup()
	Reading.setup()
	Retrieval.setup()
	for _, objectId in { "SpineWhip", "HollowLantern", "DybbukBox" } do
		Retrieval.setEnabled(objectId, true)
	end

	Crew.spawnCFrame = function()
		return Map.marker(checkpointName).CFrame
	end
	Gun.start()
	Crew.start()
	Pickups.setup()

	dullahan = Entity.new("Dullahan", Config.entities.Dullahan, DullahanBehaviour)
	lampshy = Entity.new("Lampshy", Config.entities.Lampshy, LampshyBehaviour)
	Entity.startLoop()
	Banshee.setup()
	BellBoard.start()

	Retrieval.secured:Connect(onSecured)
	Retrieval.inspected:Connect(onInspected)
	Banshee.keenEnded:Connect(onKeenEnded)
	Banshee.keenStarted:Connect(function(wing: string)
		if chapter == 3 and wing == "ServantsWing" then
			flags.firstKeen = true
		end
	end)
	Banshee.mourningEnded:Connect(function(key: string?, disturbed: boolean)
		if key == "Kitchen" and not disturbed and not flags.firstKeenAt then
			flags.firstKeenAt = os.clock() + Config.story.firstKeenDelay
		end
	end)
	Reading.read:Connect(function(noteId: string)
		if noteId == "Manifest" and chapter == 1 then
			tick(2)
		end
	end)
	Crew.wiped:Connect(onWipe)
	Net.event("Debug").OnServerEvent:Connect(onDebug)

	Players.PlayerAdded:Connect(function(player)
		task.delay(2, function()
			Net.event("Objectives"):FireClient(player, objectives)
		end)
	end)

	enterChapter(1)
	task.spawn(storyLoop)
end

return Director
