--[[
	Hooks: where Ashgrove meets the rest of your game.

	Nothing here is required: out of the box Ashgrove notices your gun on
	its own (see Shots). Wire these in when you want exact behaviour.

	----------------------------------------------------------------------
	YOUR GUN -> ASHGROVE. From your gun's SERVER code:

	    local Ashgrove = require(game.ServerScriptService.Ashgrove.Hooks)

	    -- a bullet hit something (call it for every hit; misses are fine
	    -- to skip). Ashgrove ignores parts that aren't its monsters.
	    Ashgrove.reportHit(player, hitPart, hitPosition)

	    -- a shot was fired, hit or miss: monsters hear it
	    Ashgrove.reportShot(player, muzzlePosition)

	    -- the player started reloading: their torch goes off meanwhile
	    Ashgrove.reportReload(player, reloadSeconds)

	    -- should this player be allowed to shoot right now? false while
	    -- they're down, taken by the Banshee, or busy (securing, reviving)
	    if not Ashgrove.canShoot(player) then return end

	----------------------------------------------------------------------
	ASHGROVE -> YOUR GAME. WIRE UP: replace the body of these.

	    Hooks.giveAmmo(player, rounds) -> boolean
	        Ammo pickups. Fill it in to give `rounds` to your gun and return
	        true, then set Hooks.ammoPickups = true below. Until then, ammo
	        pickups are left out of the map entirely.
]]

local Crew = require(script.Parent.Crew)
local Shots = require(script.Parent.Shots)

local Hooks = {}

-- Your gun calls these. ---------------------------------------------------

function Hooks.reportHit(player: Player, hitPart: BasePart, hitPosition: Vector3?)
	Shots.reportHit(player, hitPart, hitPosition)
end

function Hooks.reportShot(player: Player, muzzlePosition: Vector3?)
	Shots.reportShot(player, muzzlePosition)
end

function Hooks.reportReload(player: Player, reloadSeconds: number?)
	Shots.reportReload(player, reloadSeconds)
end

function Hooks.canShoot(player: Player): boolean
	return Crew.isActive(player) and not Crew.isCommitting(player)
end

-- WIRE UP. ----------------------------------------------------------------

-- WIRE UP: give `rounds` of ammo to your gun. Return true when you do.
function Hooks.giveAmmo(_player: Player, _rounds: number): boolean
	return false
end

-- WIRE UP: set to true once giveAmmo works, and ammo pickups appear.
Hooks.ammoPickups = false

return Hooks
