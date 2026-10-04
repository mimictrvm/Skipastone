--[[
	Every tuning number in the game, in one place.

	Values are the starting values from docs/ASHGROVE_DIRECTION.md. They are
	meant to be tuned in playtests; change them here, not in the systems.

	Sound ids are left empty on purpose: paste Creator Store ids in
	(e.g. "rbxassetid://123"). Empty ids are skipped silently, and every
	sound that carries gameplay information also shows an on-screen
	caption, so the game is fully playable before any audio exists.
]]

local Config = {}

-- Distances are in studs (1 stud = 0.28 m). Times are in seconds.

Config.player = {
	walkSpeed = 12,
	sprintSpeed = 19,
	crouchSpeed = 6,
	downedSpeed = 2,
	jumpPower = 40,

	hitsToDown = 3,
	hitInvulnerability = 1.2, -- after a hit, so one swing can't land twice
	sanctuaryRegenEvery = 20, -- one hit healed per this many seconds, sanctuaries only

	-- How far footsteps carry. Entities hear anything inside the radius.
	noise = {
		walk = 12,
		sprint = 38,
		crouch = 0,
		sampleEvery = 0.5,
	},

	-- Where a player taken by the Banshee is held until they come back.
	takenHoldPosition = Vector3.new(0, -300, 0),
}

-- YOUR GUN. Ashgrove doesn't have a gun of its own: it watches yours.
-- See ServerScriptService.Ashgrove.Shots (how hits are noticed) and
-- .Hooks (the three calls your gun can make for exact results).
Config.integration = {
	-- How a hit on a monster is noticed:
	--   "auto"   watch monster Humanoids for damage from your gun (the
	--            body part is worked out from where the shooter aimed). If
	--            your gun turns out never to damage Humanoids, switch to
	--            "click" by itself after a few shots, with a warning.
	--   "damage" damage only.   "click" every click is a hit along the aim.
	--   "hooks"  only Hooks.reportHit (most exact; wire it into your gun).
	hitDetection = "auto",
	gunshotNoise = 220, -- how far a shot is heard; carries through a wing
	clickRange = 400,
	-- Reloading needs both hands: the torch goes off for this long when the
	-- player presses the reload key with a tool out. 0 to turn it off.
	reloadKey = Enum.KeyCode.R,
	reloadTorchOff = 2.5,
}

-- YOUR MODELS. For each monster, Ashgrove looks for a Model with one of
-- these names (case and spaces ignored) in ServerStorage.AshgroveModels,
-- then ReplicatedStorage.AshgroveModels, then anywhere in Workspace or
-- ServerStorage. Found: it's used. Not found: the greybox body is used.
-- Animation ids are optional ("rbxassetid://..."); empty ones are skipped.
Config.models = {
	Dullahan = {
		names = { "Dullahan", "AH_Ent_Dullahan" },
		-- The part he carries and sees through. Falls back to any part
		-- whose name contains "head".
		headPart = "CarriedHead",
		animations = { idle = "", walk = "", run = "", attack = "", blind = "" },
	},
	Lampshy = {
		names = { "Lampshy", "Lamp-shy", "AH_Ent_Lampshy" },
		animations = { idle = "", walk = "", run = "", attack = "" },
	},
	Banshee = {
		names = { "Banshee", "AH_Ent_Banshee" },
		kneelDrop = 0.8, -- how far she sinks to "kneel" when mourning (greybox: 2.4)
		animations = { idle = "", keen = "", mourn = "" },
	},
}

Config.flashlight = {
	battery = 300, -- seconds of on-time
	maxBattery = 300,
	angle = 45, -- SpotLight cone, visual
	range = 60,
	brightness = 3,
	-- Gameplay cone: what counts as "in your light" for entities.
	beamHalfAngle = 20,
	litRange = 60,
}

Config.ward = {
	raiseTime = 2,
	cooldown = 10,
	range = 45,
}

-- Committed actions: once started you can't cancel them, and a hit
-- interrupts them. The player is rooted and can't shoot meanwhile.
Config.commit = {
	secure = 4,
	secureWhileEntityActive = 7,
	rite = 1.5,
	revive = 4,
}

Config.storm = {
	-- Lightning interval range per storm level. Each secured object raises
	-- the level by one.
	lightning = {
		[0] = { min = 14, max = 30 },
		[1] = { min = 10, max = 24 },
		[2] = { min = 8, max = 18 },
		[3] = { min = 6, max = 14 },
	},
	flashWindow = 0.35, -- how long a flash counts as "lit" for gameplay
	powerCutLevel = 2, -- at this level the hall's work lamp fails
	rainVolume = { [0] = 0.35, [1] = 0.45, [2] = 0.55, [3] = 0.65 },
}

Config.entities = {
	-- A banished entity re-forms at its object after this long, unless the
	-- object has been secured.
	reformMin = 360,
	reformMax = 600,
	reformClearRadius = 30, -- never re-form with a player this close
	stepInterval = 0.1,

	Dullahan = {
		displayName = "the Dullahan",
		wing = "Gallery",
		walkSpeed = 7,
		huntSpeed = 11,
		fieldOfView = 70, -- degrees, centred on where the carried head faces
		sightRange = 90,
		touchRange = 4, -- always notices a player this close
		whipRange = 12, -- the kill window closes here, not at contact
		windupTime = 0.7,
		recoverTime = 1.2,
		blindTime = 3, -- after the head is shot out of his hands
		bodyHitsToKillWhileBlind = 2,
		staggerTime = 0.4,
		repelTime = 4,
		loseTargetAfter = 4,
		searchTime = 6,
		headGlowTime = 120, -- the dropped head keeps glowing after death
		headGlowRadius = 10,
		idlePauseMin = 3,
		idlePauseMax = 6,
	},

	-- PLACEHOLDER: decision #1 in the direction doc is still open. This is
	-- the "freezes in light" minor entity used to make Story 1 playable.
	Lampshy = {
		displayName = "the Lamp-shy",
		wing = "ServantsWing",
		speed = 16,
		wanderSpeed = 8,
		hearingMultiplier = 1,
		touchRange = 8,
		lungeRange = 3.5,
		retreatTime = 3,
		loseTargetAfter = 6,
		glowRadius = 14, -- its body glows after death
		glowTime = 180,
		idleWanderChance = 0.25,
	},
}

Config.banshee = {
	-- Her colour. Reserved: no other asset or effect may use it.
	colour = Color3.fromRGB(150, 174, 158),

	doomWindowMin = 60,
	doomWindowMax = 90,
	minGapBetweenKeens = 240,
	naturalKeenMin = 15 * 60,
	naturalKeenMax = 25 * 60,
	distantMin = 120,
	distantMax = 240,
	mournTime = 45,
	-- Mourning is safe to approach quietly: crouched, you can get this
	-- close; walking or sprinting, she notices you much further out.
	disturbRadius = 15,
	disturbRadiusCrouched = 4,
	aftermathGrace = 10, -- after a death she's come to mourn, she ignores you this long
	disturbLightRange = 35,
	disturbShotRadius = 60,
	leaveLockout = 120, -- a wing you fled a keen from stays shut this long
	takeRevealTime = 2.5,
	agitateEvery = 10,
}

Config.story = {
	firstDistantDelay = 240, -- after the gallery chapter starts
	mournDullahanDeaths = true, -- she grieves the Dullahan's first death
	kitchenMourningDelay = 5,
	firstKeenDelay = 60, -- after the kitchen mourning ends
	ruleBreakDelay = 6, -- after the sealed box is inspected
}

Config.pickups = {
	ammoAmount = 6,
	batteryAmount = 120,
	-- How many candidates in each group are live per run (Always pickups
	-- are extra). Each extra player adds extraPerPlayer, rounded.
	groups = {
		Gallery = 1,
		ServantsWing = 2,
		Vault = 1,
		Batteries = 2,
	},
	extraPerPlayer = 0.5,
}

Config.bellBoard = {
	checkEvery = 2,
	ringChance = 0.35, -- imperfect on purpose
	hearRadius = 45,
}

Config.sounds = {
	rain = "",
	thunder = "",
	gunshot = "",
	reload = "",
	dryFire = "",
	hurt = "",
	keen = "", -- the game's signature sound
	keenDistant = "",
	bansheeTake = "",
	dullahanWhip = "",
	dullahanBreath = "",
	headDrop = "",
	lampshyChitter = "",
	lampshyLunge = "",
	bell = "",
	riteStep = "",
	secure = "",
	pickup = "",
	heartbeat = "",
}

Config.debug = {
	-- Studio only: F6 next chapter, F7 force a keen where you stand,
	-- F8 refill ammo and battery.
	studioKeys = true,
}

return Config
