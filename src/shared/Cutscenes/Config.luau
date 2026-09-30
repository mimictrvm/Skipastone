--[[
	Per-item cutscene data. Keys must match the game's item ids.

	Sound ids are left empty on purpose: paste Creator Store ids in here.
	Empty slots are skipped silently, so scenes still run without audio.
	docs/CUTSCENES.md has a brief for every cue (what it should sound like).

	Palette roles (each scene keeps to these three):
	  base   - the dominant field colour of the scene
	  glow   - the creature / object's light
	  accent - reserved for the reveal hit and the caption text
]]

export type Sounds = {
	music: string,
	stir: string,
	rise: string,
	strike: string,
}

export type Entry = {
	displayName: string,
	caption: string,
	scene: string,
	palette: { base: Color3, glow: Color3, accent: Color3 },
	sounds: Sounds,
}

local Config = {}

-- Shared across every scene, so the whole set has one grammar:
-- stoneTap opens and closes each scene, titleSlam lands every caption.
Config.shared = {
	stoneTap = "",
	titleSlam = "",
}

Config.items = {
	PirateDoubloon = {
		displayName = "Pirate Doubloon",
		caption = "THE DEAD MAN'S COIN",
		scene = "PirateDoubloon",
		palette = {
			base = Color3.fromRGB(58, 72, 66),
			glow = Color3.fromRGB(110, 255, 170),
			accent = Color3.fromRGB(255, 196, 60),
		},
		sounds = { music = "", stir = "", rise = "", strike = "" },
	},
	KoiSpirit = {
		displayName = "Koi Spirit",
		caption = "THE KOI SPIRIT AWAKENS",
		scene = "KoiSpirit",
		palette = {
			base = Color3.fromRGB(16, 58, 70),
			glow = Color3.fromRGB(255, 244, 220),
			accent = Color3.fromRGB(255, 128, 160),
		},
		sounds = { music = "", stir = "", rise = "", strike = "" },
	},
	SirensLyre = {
		displayName = "Siren's Lyre",
		caption = "THE SIREN SINGS",
		scene = "SirensLyre",
		palette = {
			base = Color3.fromRGB(14, 20, 44),
			glow = Color3.fromRGB(200, 214, 255),
			accent = Color3.fromRGB(176, 120, 255),
		},
		sounds = { music = "", stir = "", rise = "", strike = "" },
	},
	FallenStar = {
		displayName = "Fallen Star",
		caption = "A STAR HAS FALLEN",
		scene = "FallenStar",
		palette = {
			base = Color3.fromRGB(18, 16, 52),
			glow = Color3.fromRGB(255, 246, 210),
			accent = Color3.fromRGB(255, 150, 60),
		},
		sounds = { music = "", stir = "", rise = "", strike = "" },
	},
	Mothership = {
		displayName = "The Mothership",
		caption = "THEY HAVE ARRIVED",
		scene = "Mothership",
		palette = {
			base = Color3.fromRGB(4, 8, 10),
			glow = Color3.fromRGB(120, 255, 200),
			accent = Color3.fromRGB(190, 255, 90),
		},
		sounds = { music = "", stir = "", rise = "", strike = "" },
	},
	FrostWyrm = {
		displayName = "Frost Wyrm",
		caption = "THE FROST WYRM STIRS",
		scene = "FrostWyrm",
		palette = {
			base = Color3.fromRGB(226, 240, 255),
			glow = Color3.fromRGB(90, 200, 255),
			accent = Color3.fromRGB(40, 110, 255),
		},
		sounds = { music = "", stir = "", rise = "", strike = "" },
	},
	CrystalGolem = {
		displayName = "Crystal Golem",
		caption = "THE GOLEM WAKES",
		scene = "CrystalGolem",
		palette = {
			base = Color3.fromRGB(14, 8, 26),
			glow = Color3.fromRGB(90, 230, 255),
			accent = Color3.fromRGB(255, 90, 220),
		},
		sounds = { music = "", stir = "", rise = "", strike = "" },
	},
} :: { [string]: Entry }

-- Length of the replay version, after the player's first find.
Config.shortDuration = 3

return Config
