# Catch cutscenes

Seven new scenes, one per zone's headline Mythic:

| Zone | Item | Caption | Length |
|---|---|---|---|
| Starter Beach | Pirate Doubloon | THE DEAD MAN'S COIN | 7.3 s |
| Lily Pad Zone | Koi Spirit | THE KOI SPIRIT AWAKENS | 6.9 s |
| Pebble Cove | Siren's Lyre | THE SIREN SINGS | 7.5 s |
| Meteor Fall | Fallen Star | A STAR HAS FALLEN | 7.6 s |
| UFO Deep | The Mothership | THEY HAVE ARRIVED | 7.8 s |
| Frozen Rift | Frost Wyrm | THE FROST WYRM STIRS | 7.8 s |
| Crystal Caverns | Crystal Golem | THE GOLEM WAKES | 10.0 s |

Every find after the first plays a 3-second version instead.

Each scene's full timeline, second by second, is written at the top of its
file in `src/shared/Cutscenes/Scenes/`. This document covers why the scenes
are built this way, how they fit together, and what's still needed.

---

## What we took from the reference video

The reference was an abstract sequence: colour fields, streaks, a pixel
cursor and a driving track. It had no characters and no story. It still
worked because of a few structural decisions. Each one became a concrete
rule here.

**1. One focal object the eye can follow.** In the video it's the cursor. In
Skipastone it's already there: **the stone**. Every scene opens on the stone
hitting the water and sending out a ripple (the "stone tap"). Every scene
closes on the same tap sound as the picture fades back. In the Golem scene
the stone becomes the golem's heart. Within each scene there's also one
small light that stands in for the cursor: the lantern in the fog, the star
in the sky, three lights in the black, two eyes in the snow.

**2. Rest makes the next burst hit harder.** The video drops to black
before its big white flash. Here, every scene has a **held breath** just
before its reveal: music drops out, the image darkens or stills, and
nothing moves. It lasts 0.15 s (Fallen Star) to 0.8 s (Crystal Golem).
This beat does more to sell the hit than anything else.

**3. Save the highest contrast for one beat.** Each scene allows itself
**one** full-intensity moment. Only two scenes use a full-strength white
flash: Fallen Star and Crystal Golem. The Golem's decays slowest and is
followed by the biggest shake. The 3-second replay is capped at half
strength, so full flashes stay special to first finds.

**4. Important actions must be audible.** Every visible action that
matters has a sound on the same frame: each lily pad ring (a chime), each
ice crack, each crystal pulse, and each golem shard snapping into place.

**5. Land several cues on one frame.** The reveal is one call,
`ctx:hit(time, {...})`. It fires the flash, the strike sound, the camera
shake, the music's return and the scene's own change on the same frame.
One clock drives the whole timeline (`Context:step`), so cues that share a
timestamp can't drift apart.

**6. End with intention.** Scenes don't cut off. The Return beat fades to
black, puts the world back, then fades up on the same stone-tap sound
the scene opened with. The loot reveal follows immediately.

**7. A coherent visual vocabulary.** Each scene is held to a three-colour
palette in `Config.luau` (`base`, `glow`, `accent`). The accent colour
appears only at the reveal and in the caption.

---

## The shared grammar

All seven scenes share the same five beats. The Director owns the three
that are identical everywhere; the scene owns the middle.

| Beat | Owner | What happens |
|---|---|---|
| Freeze (0.5 s) | Director | Bars slide in, HUD hides, game music ducks, controls lock. Scene moves the camera onto the stone; stone tap at 0.35 s |
| Build-up (2–3 s) | Scene | The zone reacts: light, water, sky. A rising cue and camera move; the focal light appears |
| Held breath | Scene | Sound drops out, image stills or darkens |
| Reveal (1–2 s) | Scene, via `ctx:hit` | Flash, strike, shake and the creature, on one frame |
| Title (~2 s) | Director | Caption slams in (scale 1.6 → 1 with overshoot) and drifts; item name, "1 in N", then the Golem's extra line |
| Return (~1 s) | Director | Fade to black, world restored, bars out, stone tap, loot reveal |

## How the seven differ

A set of seven scenes built on one template risks feeling like one scene
seven times. Each scene therefore gets a different contrast device, i.e.
a different way to get from "rest" to "hit":

| Scene | Contrast device | Held breath | Flash | Shake |
|---|---|---|---|---|
| Koi Spirit | calm to bloom: ascending chimes, a soft breach | music thins, 0.35 s | 0.55, tinted | 0.25 |
| Pirate Doubloon | fog to fire: a lone lantern, then a cannon | music drops, 0.5 s | 0.85, warm | 0.8 |
| Siren's Lyre | **sound to silence**: no music at all until after the hit | total silence, 0.4 s | 0.6, violet | **none** |
| Fallen Star | dark to white | black dip, 0.15 s | **1.0 white** | 1.2 |
| The Mothership | **instant blackout** to every light at once | total dark, 0.3 s | 0.8, lime | 0.9, low rumble |
| Frost Wyrm | **whiteout** to clear (the inverse of the others) | silence in the white, 0.2 s | 0.5, cyan | 1.1 |
| Crystal Golem | all of the above, longest | dark and silent, **0.8 s** | **1.0 white, 1.2 s decay** | **1.5** |

Siren and Wyrm deliberately break the pattern the others set. After a few
scenes, players expect "gets dark, then flashes". The Siren gets quieter
instead of louder, and the Wyrm's pause is white instead of black.

### Crystal Golem, the rarest item

The Golem gets the most of everything, and each of its beats is a larger
version of a device used elsewhere:

- **Rhythm:** sixteen crystal pulses circle the cavern. Each is a little
  sooner (×0.86 interval) and higher in pitch (0.8 → 1.6) than the last,
  like a heartbeat speeding up. The camera orbits with them.
- **Convergence:** every crystal fires a beam at one point. The stone
  floats up into it and becomes the core.
- **Assembly:** shards fly in and snap together from the feet up, each
  with a heavy clack. If the Index model has at least six parts, **its own
  parts** fly together. Otherwise crystal shards assemble, and the real
  model is swapped in under the white flash, which hides the cut.
- **The longest silence in the game (0.8 s),** then the only white flash
  with a 1.2-second decay.
- **Ending:** the golem bows and its core pulses once with the stone-tap
  sound: the stone the player threw.

---

## Sound brief

Nothing is uploaded yet. Every slot in `Config.luau` is an empty string,
and empty slots are skipped, so the scenes run silently until IDs are
pasted in. Each scene needs a music bed plus `stir`, `rise` and `strike`.
Two cues are shared by all scenes.

Several scenes replay `stir` at different pitches to make a rhythm. Those
`stir` sounds should be **short, dry one-shots with a clear pitch**, not
long or reverb-heavy.

| Scene | music | stir | rise | strike |
|---|---|---|---|---|
| Pirate Doubloon | eerie sea shanty, sparse | ship's bell, single toll | wood creak + low swell, ~2 s | cannon boom |
| Koi Spirit | koto / flute, calm | **water chime / bell** (pitched ×3) | rising shimmer, ~2 s | splash with a bright bloom |
| Siren's Lyre | harp, soft (starts *after* the hit) | low hush / drone, ~3 s | **a lone female voice, wordless**, ~2.2 s, must cut cleanly | one lyre pluck, long reverb |
| Fallen Star | sparse synth pad | deep cosmic whoom | falling whistle, rising pitch, ~1.5 s | big impact boom |
| The Mothership | pulsing synth (starts at the hit) | electrical power-down "chunk" | low alien hum, ~3 s | BRAAAM horn |
| Frost Wyrm | low cold strings | **ice crack, short** (pitched ×7) | blizzard wind, ~2.5 s | roar + ice shatter |
| Crystal Golem | choir / epic bed (starts at the hit) | **crystal ping, short** (pitched ×16, and down for shard clacks) | cavern rumble, ~2.6 s | awakening boom + choir hit |

| Shared | |
|---|---|
| `stoneTap` | a small "plip" of a stone on water. Opens and closes every scene |
| `titleSlam` | a punchy whoosh-thud for the caption |

---

## Wiring it into the game

The code has no dependency on the rest of the game. Everything it needs
from the game goes through two small files.

**`src/shared/Cutscenes/Hooks.luau`** (client). Every hook has a working
default; the `WIRE UP` ones matter most:

| Hook | Default | Point it at |
|---|---|---|
| `getItemModel(itemId)` | `ReplicatedStorage.ItemModels[itemId]` | the Index's 3D models |
| `freezeThrow(landing)` | nothing | the throw system: stop the stone, return its part |
| `releaseThrow()` | nothing | let the throw system clean up |
| `showLootReveal(itemId)` | nothing | the normal loot reveal UI |
| `duckMusic` / `restoreMusic` | SoundService `Music` SoundGroup | the game's music |
| `hideHud` / `showHud` | toggles every other ScreenGui | fine as is, usually |

**`src/server/CutsceneService.luau`** (server). Call it from the loot
code when the catch is rolled, **before** the item is added to the Index:

```lua
local handled = CutsceneService.onCatch(player, itemId, {
    landing = landingPosition,
    oneIn = odds,                        -- optional, drives "1 in N"
    firstFind = not index:has(itemId),   -- full scene vs 3-second replay
})
-- if handled, skip the usual reveal: the client shows it when the scene ends
```

- **First find:** pass `firstFind` from the player's saved Index. The
  fallback (`hasFoundBefore`) only remembers the current server session.
- **Broadcast:** `CutsceneService.broadcast` sends a system chat line to
  everyone else by default. Point it at the existing legendary-find
  broadcast.
- **Item IDs:** the keys in `Config.items` must match the game's item IDs.
- **Existing three scenes:** the 3-second replay is generic. To give
  Leviathan, Kraken and Banana their replay versions, add them to
  `Config.items` with a palette and call `onCatch` for them.

Granting the item doesn't wait for the scene; the scene is presentation
only. If a scene throws an error, the world is restored and the loot
reveal still happens.

## Files

```
src/shared/Cutscenes/     ReplicatedStorage.Cutscenes
  Config.luau             captions, palettes, sound ids
  Hooks.luau              the game-facing seams
  Director.luau           plays a scene: freeze, title, return, cleanup
  Context.luau            the timeline + camera, sound, world helpers
  Fx.luau                 rings, glows, beams, debris, trails, fades
  Ui.luau                 letterbox, flash, tint, fade, caption
  ShortScene.luau         the 3-second replay
  Scenes/*.luau           one file per item, timeline in the header
src/server/CutsceneService.luau   first-find + broadcast, fires the client
src/server/CutsceneBoot.server.luau
src/client/CutsceneClient.client.luau   plays scenes; Studio preview keys
```

## Previewing in Studio

In a Studio play-test, **Left Alt + 1–7** plays each full scene about 25
studs in front of the player, and **Left Alt + Shift + 1–7** plays the
replay. The order is Doubloon, Koi, Siren, Star, Mothership, Wyrm, Golem.
This works in any place, with or without Index models; missing models are
replaced by built-in placeholders.

## Verified so far, and what isn't

Verified outside Studio: every file compiles and type-checks against the
Roblox API. Every scene, full and replay, has been run frame by frame in
[Lune](https://lune-org.github.io/docs), which validates every property
name and value type. That was done with placeholders, with 1-part Index
models and with 8-part Index models, and with and without sound IDs.
After each run the harness checked that the world was fully put back:
lighting, camera, HUD, effects and UI.

Not yet verified: how it **looks and sounds**. That needs a Studio
play-test in the real zones. Expect to tune camera positions and distances
against each zone's terrain, particle densities, and timings once real
audio exists.

## Open questions

1. **Six or seven?** The plan's table marks seven items as *New*
   (Doubloon, Koi, Siren, Star, Mothership, Wyrm, Golem), but the text says
   "six new scenes". All seven are built here. Drop one by removing it from
   `Config.items`.
2. **Skipping.** First-find scenes can't be skipped, as specified. If
   players ask for it, allowing a skip after the Title beat starts would be
   a small change to the Director.
3. **Siren's Lyre timing.** Its build is quiet on purpose. It needs a
   real play-test to confirm it reads as tension and not as a stall.
