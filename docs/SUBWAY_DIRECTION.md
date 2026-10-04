# Map 1: Ebbmoor Junction (the Dybbuk)

**Status:** directive, v1 (4 Oct 2026). Whoever builds this map, person or AI, builds to this document. To change a rule, edit it here first; don't route around it.

**What it is:** a standalone map with no link to Ashgrove House. One dark, disused subway junction. One Dybbuk. Trains that never stop. Five pieces of a code that isn't a code.

**How to read it.** Statements are decisions. Numbers are **starting values to tune in playtests**, and every one of them lives in `Config`. Open questions are in section 19. Nothing outside that section is open.

---

## 0. Instructions for the AI building this

Read this section first and follow it for the whole build.

**Your job.** Build Map 1 as a Roblox experience the user can paste into Roblox Studio, milestone by milestone (section 17). Each milestone has to work on its own before you start the next.

**Read in this order:**
1. Sections 1–3: what the map is and its hard rules.
2. Section 16: the architecture and file layout.
3. The milestone you're on in section 17, plus every section it links to.

**Rules for you:**
- **Don't invent mechanics.** If something isn't covered here and you need a decision, pick the simplest option that keeps sections 2 and 3 true, write it into section 19 as "decided by builder", and tell the user.
- **The server decides everything that matters:** who is caught, who stared, train hits, pickups and shots. Clients only render, animate and report input.
- **Every number goes in `Config`.** No magic numbers in behaviour code.
- **Don't touch the user's own gun or wobble system.** The Solution (section 9) is a separate tool. Hook into their viewmodel sway only through an adapter (section 16.6).
- **Use the user's models by name** (section 16.5). If one is missing, build a clearly labelled grey placeholder and keep going. Never block on art.
- **Paste-in delivery.** Ship the same way as `ashgrove/`: a Rojo project, plus a generated Command Bar installer split into parts of 40 KB or less, plus copy-and-paste instructions. Reuse `ashgrove/tools/build_installer.py`; don't rewrite it.
- **Verify before you hand anything over.** Typecheck (`luau-lsp analyze` with Roblox types), run the offline map checks (section 17, M1), and confirm the installer rebuilds exactly what's in the Rojo project. Report honestly what you tested in Studio and what you only checked offline.
- **Keep it Roblox-safe.** No gore: train impacts are a flash, sparks and a cut, never blood or body parts. Jumpscares stay at a sane volume. Train-window strobing stays at 3 flashes a second or fewer (section 13.4).
- **Invent everything.** No real transit names, roundels, maps, logos or fonts. The station, the line and the memorial name are made up (section 4).
- **Treat the folklore with respect.** A dybbuk comes from Jewish folklore. The memorial is sincere and the dead man is a person, not a joke. No caricature anywhere.

---

## 1. The map in one breath

**Pitch.** *You're shut inside a dead subway junction with something tall that never steps on the rails. Find the five pieces of the code, find out what the code really is, and put the thing in front of a train.*

**The rule the player learns.** *Don't stare at it. Don't let it reach you off the rails. Use the trains.*

**Length.** 20–35 minutes for a first clear. Around 12 minutes once you know the map. Pieces move each run, so it stays fresh.

**Players.** It works the same for 1 or 20 players, following MONOCHROME's approach: one entity, one set of pieces and one gun per server; progress is shared; nothing scales with player count (section 12).

**Seven clip moments.** Every system in this document exists to deliver at least one of them.

| # | Moment | Comes from |
|---|---|---|
| 1 | **The head turn.** You stare too long; its head unscrews slowly round to face you, past where a neck should stop, then the roar and the charge | Stare (6.4) |
| 2 | **The bridge run.** You drop onto the rails; it can't follow, so it sprints the full length of the platform to the bridge and back down your side | Never on the rails (6.2) |
| 3 | **The train-light reveal.** An express goes past and its windows strobe light across the far platform: it's standing there, still, watching | Trains (7) + darkness (13) |
| 4 | **SOLUTION.** The fifth piece goes into the pile, the slips swirl round your hand, spell out S-O-L-U-T-I-O-N, and fold into a gun | The twist (8–9) |
| 5 | **The kill.** It's stunned on the rails, the board says APPROACHING, and the train hits | The kill (10) |
| 6 | **The wake-up.** Your timing was off: it wakes up on the rails and climbs out screaming | The kill (10.4) |
| 7 | **The thrown body.** You're safe on the rails, so it picks up a body and throws it at you | Corpses (6.7) |

---

## 2. Pillars

In priority order: when two conflict, the higher one wins.

1. **Readable rules, scary execution.** Every danger is explained in the world before it can hurt you, and warned about every time. A death should always feel like *"I knew that"*, never *"that's cheap"*.
2. **The trains are the level.** They're the hazard, the safe zone's price, the clock and the only weapon that actually kills. Every area is designed around where the rails are.
3. **One monster, always somewhere.** The Dybbuk is the only entity. It's always on the map and always doing something, and players can track it through its traces (6.6).
4. **Funny once, then scary again.** The SOLUTION joke lands once, and the Dybbuk's roar pulls the tension straight back (8.4).

---

## 3. Non-negotiables

A feature that breaks one of these doesn't ship.

1. **The Dybbuk never sets foot on the rails.** Not when chasing, not when pathing, not ever. The only exceptions are being knocked down there by a stun (10) and climbing straight back out after one (10.4). Back this up with a hard guard in code (16.3), not just pathfinding.
2. **It can't touch you while you're on the rails.** Its reach stops at the platform edge. On the rails, its only ways to hurt you are thrown bodies (6.7) and luring you into a train.
3. **Every train is warned about, every time** (7.3). A train that arrives without warning is a bug.
4. **The departure boards never lie.** Every board shows the real timetable.
5. **Only a train kills it.** The gun and the music box only stun. Your normal guns do nothing to it (section 19, #1).
6. **Staring has to be a choice.** It only counts when the Dybbuk is actually visible, near the middle of your view, and in line of sight (6.4). You can't trigger it by accident in pitch darkness.
7. **Dying costs time, never the run.** Pieces found stay found. The gun drops where its holder fell.
8. **The respawn landing is completely safe.** The Dybbuk is bound to the line and never crosses the ticket barriers (6.2).

---

## 4. Setting and backstory

**Ebbmoor Junction** on **the Night Line**: an invented, disused deep-level interchange that's been closed to passengers for years. Express trains still run through it at full speed, through the night, and never stop. Nobody knows why they still run.

**Look.** Cracked cream-and-oxblood tiles, enamel signs with made-up names, dead escalators, vaulted brick over the platforms, puddles and cables. Emergency power only: sodium-orange pools of light with long black stretches between them.

**The dead man.** A brass memorial plaque on the island platform, next to a vase of withered flowers:

> **IN MEMORY OF EZRA HALLORAN**
> **NIGHT TRACKMAN, THE NIGHT LINE**
> **Lost on this line. He never caught his last train home.**

(The name is invented. If it ever matches a real person, change it.)

**Why it behaves the way it does.** A dybbuk is a soul that couldn't move on, clinging to the world because of unfinished business. Ezra died on these rails, waiting for a last train home that never stopped for him. So:
- **It won't touch the rails**: that's where it died.
- **It won't leave the line**: the ticket barriers are as far as it goes.
- **Only a train can finish it**: that's how it gets its last train.
- **The ending**: once it's gone, the last train stops for the first time (10.5).

The player never needs this spelled out. Every piece of it is shown in the world: the plaque, the graffiti, the trackman's notes (section 11).

---

## 5. The map

Units are studs. Characters are about 5 studs tall; the Dybbuk is about 14. Player jump height with the current JumpPower of 40 is about 4 studs, so **platforms stand 3.2 studs above the rail bed**: low enough to jump back up anywhere, which keeps the rails a real option.

### 5.1 Layout

```
                     STREET STAIRS (out of bounds: the shutter is down)
                              |
          +-------- RESPAWN LANDING (safe: outside the line) --------+
          |   exit shutter + decoy keypad #1, ticket hall board       |
          +================ TICKET BARRIERS ==========================+   <- the Dybbuk never crosses
          |                 TICKET HALL (paid side)                   |
          +---- ESCALATOR HALL (3 dead escalators) ---- staff stair (low) ----+
                              |                                      |
          +--------------- LOWER CONCOURSE (tiled passages) ---------------+
          | staff mess | lockers | LOST PROPERTY | cleaners | toilets     |
          | signal box stair | concourse board | service lift (keypad #2) |
          +------+-----------------------+---------------------+---------+
                 |                       |                     |
            north stairs           low underpass          south stairs
                 |              (under all four tracks)        |
  ===============|=======================|=====================|===============
  N tunnel  |  NORTH BRIDGE                                  SOUTH BRIDGE  |  S tunnel
            |  (spans A-B-C)                                 (spans A-B-C) |
  PLATFORM A  ---------------------------------------------------------------
  TRACK 1  ========================= northbound =============================>
  TRACK 2  <======================== southbound ==============================
  ISLAND B  ------------------ MEMORIAL (pillar 5) --------------------------
  TRACK 3  ========================= northbound =============================>
  TRACK 4  <======================== southbound ==============================
  PLATFORM C  ---------------------------------------------------------------
                         SIGNAL BOX (glass, high on the south wall)
  Track 4's north tunnel -> GHOST PLATFORM (old station, reachable ONLY along the rails)
```

### 5.2 Areas

| Area | Size | Purpose |
|---|---|---|
| **Respawn landing** | 40 × 20 | Spawn and respawn. Completely safe. The exit shutter is here with **decoy keypad #1**, plus a departure board repeater |
| **Ticket hall** | 80 × 50, ceiling 14 | First taste of darkness. Ticket barriers along one side mark the line's boundary. The Dybbuk can reach the barriers and stand behind them, which is a good scare, but can't cross them |
| **Escalator hall** | three escalators, 120 long, dropping 60 | A long, exposed walk. A **low staff stair** beside it (ceiling 8) is the slow-for-it route (6.3) |
| **Lower concourse** | tiled passage maze, 10 wide, ceiling 11 | Most of the searching happens here: rooms off the passages, corners, dead ends. MONOCHROME-style maze feel, but with landmarks: every passage has a coloured tile band and an enamel direction sign |
| **The junction** | 360 long × 110 wide, vault 40 high | The centrepiece: three platforms, four tracks, two bridges, one underpass. Built for sight lines and the bridge run |
| **North and south bridges** | at z = ±165, 8 wide, ~14 above platforms | The **only** way across the tracks for the Dybbuk, apart from the underpass. Their distance apart is what makes clip #2 |
| **Low underpass** | under all four tracks at mid-length, ceiling 8 | The players' fast way across. The Dybbuk can use it but has to stoop, so it's slow there |
| **Signal box** | 20 × 10, glass front, high on the south wall | Overlooks the whole junction. A great spot to see the Dybbuk, which makes it a great spot to stare by accident. Holds the master board showing all four tracks (11) |
| **Tunnels** | each track runs 500 into a tunnel at each end | Train-only danger. **Refuge alcoves** (3 deep, 4 wide) every 40 studs: stand in one and a train misses you |
| **Ghost platform** | old 1930s platform, 80 long, 300 up track 4's north tunnel | Reachable **only by walking the rails**. Its stairs are bricked up, so the Dybbuk can never get there. Totally safe from it, but you have to walk a live tunnel both ways |

### 5.3 Geometry rules

- **Rails zone.** Each track's bed is a `Rails` zone part with a `TrackId` attribute, from wall to platform face, rail bed up to 10 studs high, running into the tunnels. Everything that asks "is this on the rails?" reads these parts.
- **Edge strips.** Each platform edge has an invisible `EdgeStrip` part, 6 wide (measured from the platform face inward) and running the full platform length, with the `TrackId` of the track it overlooks. They drive the kill (10.2) and where the Dybbuk waits at the edge (6.5).
- **Yellow line.** Painted 2 studs from every platform edge. Decoration only, but players read it as "danger beyond here".
- **Climb-out.** Players can jump up anywhere. Every platform end also has a sloped ramp down to the rails.
- **Low passages.** Every route with a ceiling under 10 gets a `Low` attribute. That's where the Dybbuk stoops (6.3).
- **Sight lines.** From the middle of each platform you can see both bridges. Clip #2 depends on it.
- **Darkness budget.** No more than 30 emergency light pools in the junction, with gaps of at least 25 studs between pools along a platform.

---

## 6. The Dybbuk

### 6.1 Body and presence

- **About 14 studs tall.** Very long legs and long arms with hooked fingers, a narrow torso, and a dark, grinning head. Use the user's Dybbuk model (16.5).
- **Movement.** Long, slow, deliberate strides when calm. Fast and loping in a chase. It stoops right down in low passages.
- **Sound.** Footsteps are a heavy, slow tap with a long gap between, so players learn its gait. A wet clicking breath. The roar is reserved for clip #1.

### 6.2 Where it can go

- **Anywhere on the paid side of the barriers, except the rails** (Rails zones) **and the ghost platform.**
- It crosses the tracks only by the **north bridge, south bridge or underpass.**
- It **never crosses the ticket barriers.** The respawn landing is completely safe. Players who are waiting there see it come up to the barriers sometimes and just stand.

### 6.3 Speeds

Player speeds are walk 12, sprint 19 and crouch 6.

| State | Speed | Note |
|---|---|---|
| Wander | 8 | Patrol pace |
| Investigate | 14 | Heading for a noise |
| Chase (open) | 26 | **Faster than a sprint.** You can't outrun it in the open; you have to break line of sight, get onto the rails or get into a low passage |
| Chase (low passage) | 9 | Stooping. Low passages are where you get away from it |
| Bridges and stairs | 0.85 × | It slows a little on stairs |

### 6.4 The stare (clip #1)

**What counts as staring.** Checked on the server 10 times a second, per player, with every condition true:
1. The Dybbuk's head or torso is within **12°** of the player's camera direction.
2. It's within **140 studs** with a clear line of sight (server raycast, head to head).
3. **It's actually visible**, meaning at least one of these:
   - any player's torch cone is on it (within 60 studs)
   - it's standing in an emergency light pool
   - a train is passing on a track next to where it stands
   - it's within 15 studs of the player

**Building it up.** Each player has their own stare meter. It fills over **3 seconds** of staring and drains at twice that speed when you look away. Feedback on that player's client:
- **from 1.5 s**: a thin tinnitus ring that rises
- **from 2.5 s**: the edges of the screen tighten slightly

No HUD meter. Players learn the sound.

**Trigger.** At 3 s:
1. **The turn.** Its body stops dead. The head rotates on the neck towards the player at **70° a second**, up to 180° relative to the body, so it can face the player over its own back. The rotation is slow and smooth. This **can't be cancelled** once it starts.
2. **The unscrew.** The body twists round to line up with the head in 0.4 s.
3. **The roar.** 1 second. Loud, and it carries across the map (players far away hear it too).
4. **The chase.** At full speed towards that player and only them (6.5).

The turn plus the roar give the player about 3 to 4 seconds to start running. That's enough to run and not enough to feel safe.

**Rules:**
- While it's chasing, nobody else's stare counts. **One chase at a time.**
- After a chase ends, there's a **12 s cooldown** before stares count again.
- A player who triggers it never learns that someone else's meter was also filling.

### 6.5 States

```
WANDER --noise--> INVESTIGATE --nothing--> WANDER
   |                    |
   +------- stare reaches 3 s (any state) ------> TURN -> ROAR -> CHASE
                                                                 |
   CHASE --target unseen 6 s--> SEARCH (10 s at last seen point) --> WANDER
   CHASE --target on the rails--> EDGE WAIT --> (throw a body) / bridge / give up
   CHASE --target past the barriers--> SEARCH
   any state --stunned--> STUNNED (30 s) --> WANDER or ON THE RAILS (10.2)
   ON THE RAILS --train--> DEAD          ON THE RAILS --stun ends--> PANIC CLIMB --> CHASE the shooter
```

| State | Behaviour |
|---|---|
| **Wander** | Walks a random route on its waypoint graph (16.3) and leaves prints (6.6). It favours areas near players, but not their exact positions, so it feels like it's hunting without cheating |
| **Investigate** | Hears a noise and goes to where it came from: sprinting players within 40, walking within 15, crouching within 4, a dropped object within 30, keypad beeps within 25. Looks around for 5 s, then goes back to Wander |
| **Catch** (any state except Stunned) | **A player off the rails within 5 studs is caught** (6.8). In Wander and Investigate this still happens: walking into it is deadly, and only the full charge needs a stare |
| **Chase** | Paths to its one target and catches on contact. Line-of-sight memory lasts 6 s |
| **Edge wait** | The target is on the rails. If the target is on the rails right beside the platform it's on, it **goes to the nearest point of the edge strip and stands there**, leaning over, screaming, clawing at the air above the rails. Every 15 s it tries to throw a body (6.7). After 20 s it gives up and goes to Search. **This is where the kill comes from** (10.1) |
| **Cross** | The target is on the far platform, or on rails reached from there: it takes the shortest bridge or underpass route and comes round (clip #2). It always commits to the crossing once it starts |
| **Search** | Walks to the last place it saw the target and looks around for 10 s |
| **Stunned** | Collapses where it stands and lies there for 30 s. Harmless, and it can be walked past (10.2) |
| **On the rails / panic climb** | Only after being stunned on an edge strip (10.2, 10.4) |

### 6.6 Its traces (from the Dybbuk card's evidence)

These are how players track it in the dark. They're all diegetic, with no HUD markers.

| Evidence | In the game |
|---|---|
| **Freezing temps** | Within **35 studs** of it, even through walls, your breath fogs on your camera every 2 s. Within **15 studs** a frost vignette creeps in from the edges of the screen. This is the main way to tell how close it is |
| **Prints** | While it moves, it leaves a pale handprint on the nearest wall or pillar (within 6 studs) every 8 s. Prints fade over 90 s, so a trail of fresh prints shows where it went |
| **Wither** | Paper posters it passes curl and darken. The memorial flowers are always withered. Lower priority, so build it last |

### 6.7 Throwing bodies (clip #7)

The Dybbuk card says it can throw corpses, so it does.
- **Bodies on the map.** 6 placed bodies at the start: night workers in grey overalls and hi-vis, face down and non-graphic. **A caught player's character also leaves a body** (6.8), up to 12 bodies on the map at once; the oldest fades out first.
- **When it throws.** In Edge Wait or Cross, if its target is on the rails or across the tracks within 60 studs, and there's a body within 25 studs of the Dybbuk, it walks over, picks the body up (1.2 s windup with a loud strain sound) and throws it in an arc aimed at where the target is heading.
- **On a hit**, the player is knocked flat for 2 s (no damage). That's deadly only if a train is due, and that's the point.
- One throw per 15 s. Thrown bodies stay on the rails; the next train **removes** them (a thump and the body is gone, no gore).

### 6.8 Being caught

- The victim's camera snaps to its face for **1.2 s**, at a sane volume, then fades to black.
- Everyone else sees it lift the victim with both hands, hold them up and drop them. The victim's character is left as a **body**.
- The victim **loses a life** and respawns at the respawn landing after 4 s (section 12).
- If the victim was holding the gun or the music box, it drops where they were caught (9.5).

---

## 7. Trains

### 7.1 The timetable

- **Four tracks.** Tracks 1 and 3 run northbound; 2 and 4 southbound.
- Each track has a train every **70–140 s**, randomised per run. The **server owns the timetable** as a list of pass times per track, generated at run start, extended as the run goes, and sent to clients (16.4).
- **Never two trains passing the same point on adjacent tracks within 4 s of each other.** That keeps the strobe readable and the sound legible.
- At the very start, the first train passes 25 s after the first player arrives, while everyone is still in the ticket hall. It's heard and felt, not seen (13.2).

### 7.2 The train

- **8 cars, 160 studs long, at 230 studs/s.** It's past a point in about 0.7 s.
- **Lights on inside**, but no passengers. Lit windows throw moving light across the platforms (clip #3).
- **Anything in its Rails zone when it passes is hit:** a player loses a life; the Dybbuk dies (only possible when stunned on the rails); a body is removed. Being in a tunnel refuge alcove or on a platform is safe.

### 7.3 Warnings: every train, every time

| Time to arrival | Warning (in the tunnel mouth it's coming from and on its track) |
|---|---|
| **−10 s** | A low rumble rising from that tunnel |
| **−6 s** | Wind: dust and litter blow out of the tunnel mouth and along the track; the rails start to hum (a sound plus a slight shimmer on the rail tops) |
| **−4 s** | Headlight glow in the tunnel, getting brighter |
| **−2 s** | Horn |
| **0** | It's past in less than a second: a blast of sound, wind, light and camera shake |

### 7.4 Departure boards

- **Dot-matrix style**, amber on black, with an invented font. One board over each platform (showing the two tracks next to it), plus one each on the concourse, in the signal box (all four tracks) and on the respawn landing.
- Each line shows `TRACK 2   NON-STOPPING   2 min`, counting down in minutes, then `APPROACHING` under 30 s, then `STAND BACK` under 6 s.
- **Clients render the boards from the timetable.** They never need a server tick.

---

## 8. The code: SO · LU · TI · O · N

### 8.1 What players think is going on

From the first minute, everything says *"there's a code and it opens the exit"*:
- **Decoy keypad #1** sits on the exit shutter's control box on the respawn landing: `ENTER ACCESS CODE`.
- **Decoy keypad #2** is on the service lift in the concourse.
- Graffiti and trackman's notes talk about "the code" (section 11).
- The pieces look like torn pieces of an access card.

Both keypads accept any input and answer `INVALID` with a harsh beep. The beep is a noise the Dybbuk can hear (6.5), which is a nice punishment for button mashing.

### 8.2 The pieces

- **Five slips of torn card.** Each has a fragment of a printed header and big stencilled letters:

  | Slip | Header fragment | Letters |
  |---|---|---|
  | 1 | `ACC` | **SO** |
  | 2 | `ESS` | **LU** |
  | 3 | ` CO` | **TI** |
  | 4 | `DE` | **O** |
  | 5 | `:` | **N** |

- **Where they are.** Each slip has 3–4 candidate spots in its own area. One spot per slip is chosen at random each run:

  | Slip | Area | Why it's there |
  |---|---|---|
  | 1 | Lower concourse (staff mess, lockers) | Easy, early, teaches searching |
  | 2 | **Ghost platform** | Only reachable along the rails: train risk with no Dybbuk risk |
  | 3 | **Signal box** | The best view in the station, so the highest stare risk |
  | 4 | Island B, near the memorial | Puts players beside the plaque that explains everything |
  | 5 | Platform C or the far end of Platform A | Makes players cross the tracks or a bridge |

- **Shared.** A slip that's picked up counts for the whole server. On the HUD, top left, the slots read `SO · __ · TI · __ · __` as they fill. The slots are in order, so the word builds up in front of everyone and the realisation arrives at a different moment for each player. That's fine, and funny.

### 8.3 Collecting the fifth piece

The player who picks up the fifth slip gets **"The Code"**: a little fan of five slips in their hand, with a prompt to **unfold it** (click or tap). Everyone else gets a caption: `<Name> has the whole code.`

### 8.4 The unfold (clip #4)

Everything happens on the holder's client in first person, with a matching world-space version for anyone watching.

| t (s) | First person |
|---|---|
| 0.0 | The fan of slips in hand. Click |
| 0.2 | The slips lift off one by one and start orbiting the hand, rising (radius 1.2, a trail behind each) |
| 1.0 | They speed up. The letters start to glow faintly |
| 1.4 | They snap into a line in front of the camera, in order: **S O L U T I O N** |
| 2.2 | A beat of silence. Hold |
| 2.4 | They spiral inward fast and fold together with a paper-crackle sound |
| 2.8 | A flash, and **the Solution** is in your hand, with a heavy mechanical click as it's loaded |
| 3.4 | Far away in the station, **the Dybbuk roars** (server-triggered, heard everywhere), whether it's mid-chase or not |

- **Everyone else** sees the five slips orbit round the holder's hand, the word hang in the air for a second, and the gun appear.
- The roar is the joke's punchline. Don't cut it, don't shorten it, and don't play music under it.
- The decoy keypads change to `NO CODE REQUIRED`. A quiet second joke for anyone who goes back to look.

---

## 9. The Solution (the gun)

### 9.1 What it does

- **One gun per server.** One shot, then a **reload of 180 s**.
- **A hit anywhere on the Dybbuk stuns it for 30 s.** A miss still spends the shot.
- It does nothing to players.
- It's hitscan with a range of 200. The client reports the shot direction; the server checks it against the player's last reported aim (within 15°) and raycasts from the player's head.

### 9.2 How it looks and feels

- The model is the user's call (section 19, #3). Until then, use a placeholder: an old, heavy, brass-and-paper pistol, with faint stencilled letters still visible on it.
- **Reloading is shown on the gun.** While it reloads, paper visibly folds back into the barrel over the 180 s, and a soft paper rustle plays when it's ready. HUD shows: `THE SOLUTION · ready` or `THE SOLUTION · 2:14`.

### 9.3 Its relationship to the user's gun

- **The Solution is a separate tool and doesn't use the user's gun code.**
- If the user's system exposes a viewmodel sway ("wobble") API, apply it to the Solution through `WobbleAdapter` (16.6). If not, a simple bob is enough.

### 9.4 Passing it

- Holder presses **G** to drop it. Anyone can pick it up with **E**.
- It's a single shared object, so whoever has it is the one everyone protects. Expect friends to shout over it.

### 9.5 If the holder falls

- Caught, hit by a train or leaving the server: the gun **drops where they were**, with a faint paper-white glow so it can be found in the dark.
- If it fell onto the rails, it stays there. Trains don't remove it (they only remove bodies).
- The reload keeps counting while it's on the floor.

---

## 10. The kill

### 10.1 The intended play

The game never says this out loud, but every rule above points to it:
1. **Read a board.** Pick a track with a train due in under 30 s.
2. **Get on those rails**, below a platform the Dybbuk can reach.
3. **Stare at it on purpose** from the rails. It turns, roars and charges, but it can't come down, so it stops on the edge strip above you and leans over you (Edge Wait, 6.5). The stare that was the danger is now the lure.
4. **Shoot it.** It's stunned and collapses forward **onto the rails, right next to you.**
5. **Get out.** Climb up the other side or run for a ramp before the train arrives.
6. **The train hits it.**

### 10.2 Stun on an edge strip

- If the Dybbuk is stunned (by gun or music box) while its root is inside an `EdgeStrip`, it **falls onto that strip's track**, onto the rail bed at the nearest point, and lies there for the rest of the stun.
- Anywhere else, it collapses where it stands.
- The fall itself takes 1 s and has heavy weight to it: arms flailing out, a crash onto the ballast.

### 10.3 The hit (clip #5)

If a train passes its track while it's lying on the rails:
- The horn becomes a long scream that cuts off.
- A white flash and sparks. The camera shakes for everyone within 60 studs. **No gore.**
- When the train has gone, there's nothing left on the rails but frost melting.

### 10.4 Waking up on the rails (clip #6)

If the stun ends before a train comes:
- It wakes **screaming** and **panic-climbs** out at the nearest point of the nearest platform (this is the one time it moves on the rails, and it goes straight out by the shortest route).
- Then it goes straight into a Chase of whoever shot it, with no stare needed.

### 10.5 The ending

1. **Silence.** A beat. Then every light in the station flickers on, properly, for the first time. Real light everywhere.
2. **The memorial flowers are fresh.**
3. **Every board changes:** `LAST TRAIN · ISLAND PLATFORM · STOPPING SERVICE`.
4. **45 s later**, a train arrives slowly on track 3 and **stops** at Island B. The doors open. Warm light inside.
5. Players board. The doors close when every living player is aboard, or after **120 s**, whichever comes first.
6. The train pulls out. Fade to black. End card: **"He caught his last train home."**
7. Players still on the platform when the doors close are left behind in the lit, empty station. Their end card reads: **"You missed the last train."**

---

## 11. Teaching: everything in the world

Every rule has to be learnable before it kills you. No tutorial pop-ups apart from the controls.

| What | Where | Wording (or near it) |
|---|---|---|
| **Don't stare** | Graffiti, big, on the ticket hall wall facing the barriers | `DON'T LOOK AT IT` with `LOOK AWAY` scratched underneath |
| **It won't go on the rails** | Trackman's notebook on the concourse | *"It won't come down onto the rails. Stood right over me on the edge, it did, and didn't come down. Like the rails burn it."* |
| **The trains don't stop** | Platform poster | *"Ebbmoor Junction is closed. Trains will not stop. Stand behind the yellow line."* |
| **Refuges** | Enamel signs at tunnel mouths | `REFUGES AHEAD · STAND CLEAR OF TRAINS`, plus refuge alcoves marked with a white painted square |
| **The cold** | Trackman's notebook | *"Your breath goes white before you see it. Every time."* |
| **The music box** | Lost property ledger | *"Item 113. Music box. Hand-written note attached: it doesn't like this the first time it hears it."* |
| **The code** | Graffiti near keypad #1 and the trackman's notebook | `THE CODE IS IN PIECES` · *"Found part of the code. Still makes no sense."* |
| **Who he was** | The memorial plaque (section 4) | |
| **The timetable** | Master board in the signal box | All four tracks at once, so players can plan the kill there |

---

## 12. Players, lives and dying

Modelled on MONOCHROME: up to 20 players per server, shared progress, nothing scales.

- **Lives: 3 per player per run.** Shown as three small train-ticket icons on the HUD.
- **Caught by the Dybbuk or hit by a train**: lose a life and respawn at the respawn landing after 4 s. Train deaths get no jumpscare: just a cut to black and the horn.
- **Out of lives**: you spectate, cycling through living players with left and right. You still see your own HUD and the boards.
- **Everyone out of lives**: the run fails. End card: **"The line keeps you."** The run resets (new piece spots, new timetable) after 10 s.
- **Joining mid-run**: you spawn on the landing with 3 lives, into the run as it stands.
- **Progress kept across deaths:** pieces found, whether the code has been unfolded, where the gun and the music box are, and whether the music box has been used.

---

## 13. Darkness, light and sound

### 13.1 Light

- **Emergency light only:** sodium-orange pools (no more than 30 in the junction), plus the flicker of dying fluorescents on the concourse.
- **The player torch** never runs out on this map. It's a narrow cone (about 60 studs range). The torch cone is one of the things that makes the Dybbuk visible (6.4), so **your torch is how you find it and how you get caught by it**.
- **Trains are the brightest thing on the map**: headlights in the tunnel, then lit windows sweeping along the platforms.
- Lighting tech: `ShadowMap` or `Future`, whichever the user's place already uses. `Atmosphere` density about 0.4, colour near-black brown. Fog end about 180 studs.

### 13.2 The first train

The very first train passes beneath the ticket hall 25 s in. The floor shakes, dust falls, the boards flicker and the sound comes up through the escalators. It teaches the trains before they can hurt anyone.

### 13.3 Sound

| Sound | Note |
|---|---|
| Distant trains | Always somewhere: muffled rumbles through the walls between real passes |
| The train pass | Doppler sweep, a wall of noise, then a long rail ringing afterwards |
| Dybbuk footsteps | Heavy, slow, long gaps. Positional, audible to 80 studs |
| Dybbuk breath | Wet clicking within 20 studs |
| The stare ring | Client-only, rising from 1.5 s |
| The roar | Heard everywhere on the map, louder near it |
| The music box | **An original melody.** No existing songs or lullabies that might be copyrighted |
| Keypad `INVALID` | Harsh, loud, and a noise the Dybbuk hears |

### 13.4 Safety

- Lit train windows strobing across a platform: **no more than 3 flashes per second.** Use spaced window gaps or soften the light's edges until this is true at 230 studs/s.
- The jumpscare stays within normal game audio levels; no clipping or sudden peak at full scale.
- Add a "reduce flashing" setting that dims train-window light.

---

## 14. The music box

- **One per run**, at one of 3 random spots: Lost Property (most likely), the staff mess or the ghost platform.
- It's carried like the gun (one carried item per player: the gun or the music box, not both).
- **To play it:** hold E for 2 s to wind it (you can't move while winding). It plays the melody for 20 s.
- **The first time it's played, the Dybbuk is stunned for 30 s, wherever it is on the map.** Exactly the same stun as the gun, including falling onto the rails if it's on an edge strip (10.2).
- **After that** it just plays music. It's still a noise the Dybbuk hears.
- So it's either a one-time escape from a chase, or a second chance at the kill if the gun is reloading. Clever players will carry it to the edge.

---

## 15. HUD and controls

**HUD** (minimal; diegetic first):
- Top left: the code slots `SO · __ · TI · __ · __`
- Bottom left: three ticket icons for lives
- Bottom right, only for the holder: `THE SOLUTION · ready` or the reload countdown; or `MUSIC BOX · unused` or `· used`
- Captions for story lines and pickups, in the Ashgrove caption style
- **No** Dybbuk marker, stare meter, map or train timer outside the in-world boards

**Controls:**

| Key | Action |
|---|---|
| WASD, Shift, C | Move, sprint, crouch (using the user's existing movement) |
| F | Torch |
| E | Interact, pick up, wind the music box (hold) |
| Mouse 1 | Fire the Solution, or unfold the code |
| G | Drop what you're carrying |
| Left / right | Cycle spectate target |

---

## 16. Architecture

### 16.1 File layout

A new Rojo project next to `ashgrove/`, with the same conventions (`init.server.luau` → Script, `init.client.luau` → LocalScript, `init.luau` → ModuleScript with children):

```
subway/
  default.project.json
  README.md                         install, controls, what's built
  src/shared/Subway/
    Config.luau                     every number in this document
    Net.luau                        all remotes, named in one place
    Signal.luau                     copy from ashgrove
    Notes.luau                      every readable text (section 11)
  src/server/Subway/
    init.server.luau                builds the map, starts the Director
    Layout.luau                     builds the greybox map (section 5)
    Dressing.luau                   tiles, signs, lights, boards, props
    Map.luau                        zones, markers, rails, edge strips, waypoints
    Timetable.luau                  generates and shares the trains (7.1)
    Trains.luau                     server-side hit tests (16.4)
    Dybbuk.luau                     the state machine (6.5)
    Nav.luau                        waypoint graph and A* (16.3)
    Stare.luau                      server stare meters (6.4)
    Bodies.luau                     placed and new bodies, throwing (6.7)
    Evidence.luau                   prints and wither (6.6)
    Pieces.luau                     the five slips, random spots (8.2)
    Keypads.luau                    decoy keypads (8.1)
    Solution.luau                   the gun: shots, stun, reload, drop (9)
    MusicBox.luau                   (14)
    Carry.luau                      one carried item per player (gun, music box)
    Lives.luau                      lives, respawn, spectate, wipes (12)
    Ending.luau                     the last train (10.5)
    Director.luau                   run start, first train, run reset
    Models.luau                     user models by name (16.5)
  src/client/SubwayClient/
    init.client.luau
    TrainsView.luau                 renders trains and warnings locally (16.4)
    Boards.luau                     renders every departure board (7.4)
    Hud.luau                        (15)
    Cold.luau                       breath fog and frost vignette (6.6)
    StareFeedback.luau              the tinnitus ring and screen squeeze (6.4)
    Unfold.luau                     the SOLUTION animation (8.4)
    Jumpscare.luau                  (6.8)
    Spectate.luau                   (12)
    Aim.luau                        camera direction to the server at 10 Hz
  tools/
    check_map.luau                  offline map checks (17, M1)
    (installer: reuse ashgrove/tools/build_installer.py with a subway config)
```

### 16.2 Map contract

Systems never search for geometry by guesswork. They read:
- `Zones/` boxes with `Area`, `Rails` (true or false), `TrackId`, `Low`, `Safe` (respawn landing), `Paid` (inside the barriers)
- `EdgeStrips/` with `TrackId`
- `Markers/`: respawn points, piece candidates (`PieceSpot_<n>_<k>`), music box candidates, body spots, bridge ends, the stopping position for the last train
- `Nav/`: waypoint nodes (parts), each with a `Links` attribute (comma-separated node names) and an optional `Low` attribute
- `Tracks/`: one part per track along its centreline, with `TrackId`, `Direction` (+1 or −1 along its length) and `Length`

The art pass can replace any geometry as long as it keeps these parts and attributes.

### 16.3 Navigation and the rails guard

- **Use a hand-authored waypoint graph, not raw PathfindingService.** The map is designed, so the graph is reliable, and it guarantees non-negotiable #1: **no node sits on the rails, and the only edges that cross a track are the two bridges and the underpass.** It also makes stooping easy: edges between `Low` nodes use the low speed.
- **Within line of sight** (raycast clear, and the straight line doesn't cross a Rails zone), move straight at the target. Otherwise run A* on the graph to the node nearest the target, then go straight.
- **Movement:** a server-owned `Humanoid` (`SetNetworkOwner(nil)`) with `MoveTo`, re-issued every 0.25 s.
- **The hard guard.** Every Heartbeat, unless the state is Stunned or Panic Climb: if the root is inside a Rails zone, put it straight back at the last position where it wasn't, and log a warning in Studio. If you ever see the warning, fix the graph.
- **Its reach stops at the edge.** The catch check (5 studs) ignores players inside Rails zones.

### 16.4 Trains: the server keeps time, clients draw

A 230 studs/s train can't be replicated smoothly as a moving server part. So:
- **Timetable** (server): for each track, a list of `{ passStart = serverTime }` entries, where `passStart` is when the train's nose enters the track at its start end. Sent to clients on join and whenever it's extended or changed (`Net.Timetable`).
- **Position:** `nose(t) = (t - passStart) * speed` along the track; the train covers `[nose - 160, nose]`.
- **Server hit test** (every Heartbeat, for each train currently on a track): for each player, the Dybbuk and each body, project its position onto the track; it's hit if it's inside that track's Rails zone and its projection lies within `[nose - 160 + 2, nose - 2]`. The 2-stud margin forgives small client/server timing differences.
- **Client:** creates the train model locally 12 s before `passStart`, moves it on `RenderStepped` using `workspace:GetServerTimeNow()`, and plays every warning in 7.3 from the same clock. Boards read the same timetable.

### 16.5 The user's models

Look models up by name in `ReplicatedStorage`, `ServerStorage` and `workspace`, in that order, the same way `ashgrove/src/server/Ashgrove/Models.luau` does:

| Model | Names to look for | Needs |
|---|---|---|
| Dybbuk | `Dybbuk`, `SUB_Ent_Dybbuk` | Humanoid, HumanoidRootPart, Head, a neck Motor6D (find it by its `Part1 == Head`, whatever it's called), and ideally Walk, Run, Stoop, Throw, Grab, Stunned, Roar animations as Animation children |
| Train car | `TrainCar`, `SUB_TrainCar` | A model about 20 long; the client chains 8 |
| Body | `WorkerBody`, `SUB_Body` | A posed, non-graphic model |
| The Solution | `TheSolution`, `SUB_Gun_Solution` | A Tool or model with a `Handle` |
| Music box | `MusicBox`, `SUB_MusicBox` | Any model |

Every model has a grey, labelled placeholder that's built automatically if the real one is missing. **The head turn (6.4) drives the neck Motor6D's `C0` directly**, so it works on any rig that has one.

**Card art.** Use only the user's own Dybbuk card art and text in game. If the card shown in planning came from another game, rewrite it in our own words and art.

### 16.6 Wobble adapter

`Solution.luau` calls `WobbleAdapter.attach(tool)` and `WobbleAdapter.detach(tool)`. By default it does nothing. The user can fill it in to plug the Solution into their own wobble or sway system. Don't guess their API.

### 16.7 Remotes (`Net`)

| Direction | Remote |
|---|---|
| Client → server | `Aim(direction)` (unreliable, 10 Hz), `Fire(direction)`, `Unfold()`, `Drop()`, `Spectate(dir)` |
| Server → client | `Timetable(list)`, `Caption(text, seconds, style)`, `Note(id)`, `Pieces(slots)`, `Stare(level)` (only to that player), `Jumpscare()`, `Roar(position)`, `Unfolded(player)`, `Lives(n)`, `Screen(kind, text)`, `Ending(stage)` |

---

## 17. Build order

Build and verify each milestone before starting the next. **Done means** every check listed passes, it typechecks clean, and you've said what you tested.

### M1. The greybox map
- `Layout.luau` builds section 5: every area, the tracks, platforms at 3.2, bridges, underpass, tunnels with refuges, the ghost platform, the signal box, barriers and the respawn landing. All zones, edge strips, tracks, markers and nav nodes (16.2).
- `tools/check_map.luau` (Lune, like `ashgrove/tools/check_greybox.luau`) checks:
  - no NaN CFrames
  - every piece, music box and body spot can be reached on foot from the respawn landing
  - **no nav node is inside a Rails zone**
  - **the only nav edges crossing a track are the bridges and the underpass**
  - every platform edge is covered by an edge strip with the right TrackId
  - refuges are no more than 45 apart in every tunnel
  - the ghost platform is reachable only via the rails (no nav path)
  - platform height is 3.4 or less above the rail bed
  - both bridges are visible from the middle of each platform

### M2. Trains
- `Timetable`, `Trains` (server hit test), `TrainsView` (client) and `Boards`. Every warning in 7.3. The first train in 13.2.
- **Test:** stand on the rails and get hit; stand in a refuge and survive; boards match arrivals to the second.

### M3. The Dybbuk walks
- `Nav`, `Dybbuk` (Wander, Investigate, Catch), noise and the rails guard, using a placeholder rig if needed.
- **Test:** it patrols, crosses only by bridges and the underpass, never steps on the rails in 10 minutes of wandering (the guard's warning never fires), stops at the barriers, and stoops in low passages.

### M4. The stare and the chase
- `Stare`, `StareFeedback`, the turn/unscrew/roar, Chase, Edge Wait, Cross and Search.
- **Test:** 2.9 s of staring does nothing; 3 s triggers the turn; staring in total darkness never fills the meter; standing on the rails below it gets an Edge Wait; standing on the far platform gets the bridge run.

### M5. Lives
- `Lives`, `Jumpscare`, `Spectate`, the run failing and resetting.
- **Test:** being caught or hit costs a life; respawn is at the landing; the third death leads to spectating; everyone out resets the run.

### M6. The code
- `Pieces`, `Keypads`, the HUD slots, `Notes` (section 11 texts).
- **Test:** each run picks different spots; a slip counts for everyone; keypads always say INVALID and the Dybbuk hears it.

### M7. SOLUTION and the gun
- `Unfold`, `Solution`, `Carry`, `WobbleAdapter`.
- **Test:** the unfold plays to the timings in 8.4 for the holder and others; the roar follows; one shot stuns for 30 s; the reload is 180 s; drops on death; can be passed.

### M8. The kill and the ending
- Stun-on-edge-strip falls (10.2), train kill (10.3), panic climb (10.4), `Ending` (10.5).
- **Test:** the full intended play in 10.1 works start to finish; a stun with no train coming gives the panic climb; the ending train stops, waits and leaves.

### M9. Bodies, evidence and the music box
- `Bodies` (placed bodies, caught players leaving bodies, throws), `Evidence`, `Cold` and `MusicBox`.
- **Test:** throws only happen from Edge Wait or Cross with a body nearby; a hit knocks you flat for 2 s; the first music box play stuns from anywhere and the second does nothing.

### M10. Dressing, light and sound
- `Dressing`: tiles, signs, posters, the memorial, lights within the budget, boards, the art pass. All sounds from 13.3. The safety rules in 13.4.

### M11. Delivery
- The installer and its parts, `subway/README.md` (install, controls, which models it looks for, what's built), and an offline check that the installer is identical to the Rojo project.

---

## 18. Config: starting values

```
player   = { lives = 3, respawnDelay = 4 }
dybbuk   = { height = 14, speedWander = 8, speedInvestigate = 14, speedChase = 26,
             speedLow = 9, stairFactor = 0.85, catchRadius = 5,
             losMemory = 6, searchTime = 10, chaseCooldown = 12,
             hearing = { sprint = 40, walk = 15, crouch = 4, drop = 30, keypad = 25 } }
stare    = { coneDegrees = 12, range = 140, fill = 3, drainRate = 2,
             ringFrom = 1.5, squeezeFrom = 2.5, nearVisible = 15, torchRange = 60,
             turnSpeed = 70, maxTurn = 180, unscrew = 0.4, roar = 1 }
edge     = { waitTime = 20, stripWidth = 6 }
bodies   = { placed = 6, max = 12, pickupRange = 25, throwRange = 60,
             throwEvery = 15, windup = 1.2, knockdown = 2 }
trains   = { cars = 8, length = 160, speed = 230, gapMin = 70, gapMax = 140,
             adjacentSeparation = 4, firstTrain = 25, hitMargin = 2,
             warn = { rumble = 10, wind = 6, light = 4, horn = 2 } }
solution = { reload = 180, stun = 30, range = 200, aimTolerance = 15 }
music    = { stun = 30, windTime = 2, playTime = 20 }
cold     = { breath = 35, frost = 15, breathEvery = 2 }
prints   = { every = 8, wallRange = 6, fade = 90 }
ending   = { trainDelay = 45, doorsOpen = 120 }
light    = { maxPoolsJunction = 30, fogEnd = 180, maxStrobeHz = 3 }
```

---

## 19. Open questions and decisions

1. **Your normal guns on this map?** Recommended: **no.** The Solution is the only weapon, so the twist matters and the Dybbuk stays scary. Building it with a `Config.allowTeamGuns = false` switch means either works.
2. **Keys.** The first pitch had keys to find. This document replaces them with the five code pieces. Say if you want both (for example, keys to reach the signal box and the ghost platform).
3. **The Solution's look.** Placeholder until you supply a model.
4. **The station's name.** Ebbmoor Junction and the Night Line are working names.
5. **Monetisation and badges.** Not covered here. Natural badges: *Stared Too Long* (first head turn), *SOLUTION* (unfold the code), *Last Train Home* (the ending), *Missed It* (left behind).

*Decided by builder:* (none yet)
