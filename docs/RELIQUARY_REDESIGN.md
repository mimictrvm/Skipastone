# The Reliquary: Redesign Around One Monster

**Status:** directive, v1 (5 Oct 2026). This document **overrides** the earlier design documents wherever they disagree (section 10 lists exactly what changes). Whoever builds the game, person or AI, builds to this.

**The decision.** *The Reliquary* is built around **one monster: the Dybbuk.** Every map is a different place where a dybbuk has taken hold. The lobby works like Demonology's: a party line-up, a leader who picks the job and difficulty, a shop for equipment and perks, everyone readies up, and the party teleports into the map.

**Assumption to confirm.** "One monster" is read as **the Dybbuk**, because Map 1 (Ebbmoor Junction) is already built around it. If you meant a different monster, the structure of this document still holds; only sections 3 and 4 change.

**How to read it.** Statements are decisions. Numbers are starting values to tune in playtests. Open questions are in section 12. Nothing outside that section is open.

---

## 0. Instructions for the AI building this

- **Read sections 1–3 first.** They are the game. Sections 4–9 are the parts; section 11 is the build order.
- **Map 1's own rules stay in `docs/SUBWAY_DIRECTION.md`.** This document only changes what section 4.3 lists. Don't redesign Map 1 from here.
- **The lobby's look stays in `docs/LOBBY_DIRECTION.md`** (walls, lighting values, materials, storm, sound). This document replaces its layout, cases and menus (section 10).
- **The server decides everything that matters:** money, levels, unlocks, purchases, who is in a party, who is ready, the teleport. Clients only show it.
- **Never trust the client with currency or unlocks.** Every purchase is checked on the server against saved data.
- **Every tunable number goes in `Config`.**
- **Fair monetisation only** (section 7.5): no paid random rewards, nothing that only Robux can buy which changes how well you play.
- **Report honestly** what you tested in Studio, with how many players, and what you only checked offline.

---

## 1. How Demonology does its lobby (the research)

The Demonology wiki and guide sites are blocked from the environment this was written in. Everything below comes from **search-result summaries of those pages, not from reading them directly**, so check the details in-game before relying on them.

| Feature | How Demonology does it |
|---|---|
| **The line-up** | When you load in, your avatar stands **first on the left**. Next to it are **silhouettes with "+"**. Click one to invite a player. Parties are solo or up to 6 players |
| **Tutorial** | First-time players get a pop-up offering a tutorial from a character called **The Boss**. It can be skipped ("No Thanks") and replayed from Settings |
| **The leader decides** | The **party leader** chooses the **job site**, the **difficulty** (Easy to Nightmare, plus **custom difficulty** that changes the reward multiplier, reported as 0x to 4.07x), and adds **equipment** and **perks** before starting |
| **Ready and start** | Everyone presses **Ready Up**. Then the leader presses **Start** and the whole party is **teleported** into the job |
| **Equipment** | An **Equipment** page in the lobby. Starter equipment is free every job; stronger items are bought. **Anyone in the party can buy equipment for the job**, and the cost comes out of their balance once the job starts |
| **Perks** | Bought before a job: **Tarot cards** that give boosts like stamina, speed, carrying capacity or protection. Each has a level requirement |
| **Levels** | Levels unlock **job sites, equipment and perks** |
| **Job sites** | Reported as 4 small, 4 medium and 3 large |
| **Store** | Separate from equipment. Mostly **Robux cosmetics and gamepasses**, described as optional to the game. One reported item instantly unlocks a locked job site |
| **Journal** | Opened with **J**, including inside a job. Covers equipment and evidence |
| **The job** | Find the ghost's room, collect three evidence types, mark them in the journal, identify the ghost, and get back to the van alive |
| **Optional objectives** | A rotating set of bonus objectives (provoking it, measuring it, photographing it) that pay extra |
| **Pay** | A **paycheck** after each job, scaling with whether the identification was correct, how long it took, and whether you survived |
| **Servers** | Reported as 30 players per lobby server and free private servers. Public lobbies were planned but not yet added |

**What we copy:** the line-up with "+" slots; the leader choosing the job and difficulty; ready-then-start; equipment and perks bought before a job and level-locked; the journal; the paycheck and levels; optional objectives.

**What we change:**
- **Our lobby is a place, not a screen.** Every menu page moves the camera to somewhere in Cornelius's room (section 6.4).
- **One monster means no "which ghost is it?" question.** Our investigation is **who the dybbuk was** and **how to lay it to rest** (section 3.3).
- **The tutorial is Cornelius's letters**, not a boss character (section 6.6).

---

## 2. The game in one page

**Pitch.** *Every dybbuk was somebody. Find out who, then send it on the way it died.*

**What a dybbuk is** (folklore, kept respectfully): the soul of a dead person that couldn't move on, held in the world by unfinished business. It clings to the place where it died.

**The fiction.** Cornelius Ashgrove collected the things dybbuks cling to. His reliquary, the lobby, is where those things end up. The auction house **Pellam & Sloane** is selling off his estate, and pays crews to go where a dybbuk has been sighted and lay it to rest. Each one laid to rest leaves a relic, and the relic goes into a case in his room.

**The loop.**
```
LOBBY  -> pick a sighting, difficulty, equipment, keepsakes -> everyone ready -> leader starts
  |                                                                                  |
  |                                                                           TELEPORT
  |                                                                                  v
RESULTS <- laid to rest, failed, or fled <- investigate, survive, set up the kill <- THE SIGHTING
  |
  +-> paycheck (sovereigns) + reputation (XP) -> level up -> new sightings, equipment, keepsakes
  +-> first time laid to rest: its relic appears in a case in the lobby
```

**Session length.** 15–35 minutes per sighting, sized like Demonology's small, medium and large job sites.

**Party.** Solo, or up to **6 players**, matching Demonology.

---

## 3. The one monster

### 3.1 What every dybbuk shares

These rules are true on every map. Players learn them once, and every new map tests them in a new place.

| Rule | Detail | Defined in |
|---|---|---|
| **Don't stare at it** | 3 s of staring at it while it's visible sets off the head turn, the roar and a charge at whoever stared | `SUBWAY_DIRECTION.md` 6.4 |
| **It won't touch where it died** | Each dybbuk has **forbidden ground**: the place or material tied to its death. It never steps on it and can't reach anyone on it | Section 3.2 |
| **It's bound to its place** | It never leaves the area it haunts. The spawn area is always safe | `SUBWAY_DIRECTION.md` 6.2 |
| **Only its own death finishes it** | Stuns don't kill it. It's laid to rest only by **recreating the way it died** | Section 3.2 |
| **Its traces** | **Freezing temps** (your breath fogs), **prints** (handprints along its route), **wither** (posters and flowers decay) | `SUBWAY_DIRECTION.md` 6.6 |
| **It throws bodies** | At players it can't reach | `SUBWAY_DIRECTION.md` 6.7 |
| **The music box** | The first time one is played, it's stunned | `SUBWAY_DIRECTION.md` 14 |
| **Its body** | Very tall, long legs, long arms, a dark grinning head: the user's Dybbuk model on every map | |

### 3.2 What each dybbuk has of its own

Every map defines these five things, and nothing else about the monster changes:

| Field | Ebbmoor Junction (Map 1) |
|---|---|
| **Who it was** | Ezra Halloran, night trackman |
| **How it died** | Struck on the rails, waiting for a last train home |
| **Forbidden ground** | The rails |
| **How it's laid to rest** | Stun it so it falls onto the rails, and let a train hit it |
| **The twist on that map** | The five-piece code that spells SOLUTION and becomes the stun gun |
| **Its relic** | Ezra's dented trackman's lamp |

**Rule for new maps:** the forbidden ground and the way it's laid to rest must both come from **how that person died**, so a player who learns who it was can work out how to finish it.

Map ideas that follow the rule (for the roadmap only; not designed yet):
- **A drowned ferry keeper.** Forbidden ground: water. Laid to rest by getting it into the flooded hold as the tide comes in.
- **A woman who died in a house fire.** Forbidden ground: anything burnt. Laid to rest by trapping it in a room as the fire is relit.
- **A miner lost in a collapse.** Forbidden ground: the old seam. Laid to rest by bringing the roof down on it.

### 3.3 The investigation (our version of Demonology's identification)

On every map, the party fills in the **case file** in the journal:
1. **Who was it?** (a name, from the map: a plaque, a newspaper, a payslip)
2. **How did it die?** (chosen from 3–4 options written in the journal)
3. **Where won't it go?** (chosen from 3–4 options)

- **Not required to lay it to rest**, but every correct answer adds pay (section 5.2).
- Players who fill it in first will understand the map's kill before they find the twist.
- Correct answers are shown on the results screen, so wrong guesses teach as well.

---

## 4. Sightings (the maps)

### 4.1 Sizes

| Size | Time | Example | Unlocked at |
|---|---|---|---|
| Small | 12–18 min | (to design) | Level 1 |
| Medium | 18–28 min | **Ebbmoor Junction** | Level 1 (it's the launch map) |
| Large | 25–40 min | (to design) | Later levels |

At launch there's one map. That's fine: Demonology's draw is replay, and Ebbmoor already moves its pieces each run.

### 4.2 What changes per run on every map

Spawn spots of the twist's pieces, item spots, the music box spot, the dybbuk's starting area and timetable-style hazards (trains, tides, fires). The **who and how never change** on a map; the answers to the case file are fixed for that map.

### 4.3 Changes to Map 1 (`SUBWAY_DIRECTION.md`)

| Section there | Change |
|---|---|
| 1, 12 (players) | **Up to 6 players per run** (one party, a reserved server), instead of up to 20 on a shared server. Nothing in the map scales, so no other rule changes |
| 12 (joining mid-run) | **Removed.** Only the party that started the run is in it |
| 12 (everyone out of lives) | Instead of resetting the run, go to the **results screen** (section 6.7) and back to the lobby |
| 10.5 (the ending) | After the end card, show the **results screen** and teleport the party back to the lobby |
| 14 (music box) | Unchanged on the map. Equipment can add a second one (section 7.1) |
| 15 (HUD) | Add the journal on **J** with the case file (section 3.3) |
| New | **Difficulty** changes the values in section 7.3 |
| New | **Optional objectives** for this map (section 7.4) |

---

## 5. Progression

### 5.1 Currencies

| Name | What it is | Earned by | Spent on |
|---|---|---|---|
| **Sovereigns** | Pay from Pellam & Sloane (named after Cornelius's gold sovereign) | Every run | Equipment, keepsakes |
| **Reputation** | XP | Every run | Nothing. It sets your **level** |

### 5.2 The paycheck

```
pay = base(map size)
      × difficulty multiplier
      × (laid to rest ? 1.0 : 0.25)
      + case file bonus (per correct answer)
      + optional objective bonuses
      + survival bonus (per player, if they never ran out of lives)
```

| Item | Starting value |
|---|---|
| Base, small / medium / large | 60 / 100 / 150 sovereigns |
| Case file, per correct answer | +15 |
| Optional objective, each | +20 to +40 |
| Survival bonus | +20 |
| Reputation | Equal to pay before the difficulty multiplier, so higher difficulty pays more money but doesn't speed up levelling unfairly |

### 5.3 Levels

| Level | Unlocks |
|---|---|
| 1 | Ebbmoor Junction, starter equipment, Easy and Normal |
| 3 | Thermometer, first keepsake |
| 5 | Hard difficulty, UV lamp |
| 8 | Camera, second keepsake |
| 10 | Nightmare difficulty, Custom difficulty |
| 12+ | New sightings as they're released, more keepsakes |

---

## 6. The lobby

### 6.1 What it is

**The same room as `LOBBY_DIRECTION.md`:** Cornelius's reliquary, with its walls, lighting, storm, lectern and strongroom door. What changes is how the room is **used**.

### 6.2 The line-up

Copied from Demonology and placed in the room:

- **Six standing marks** in a row across the runner, about a third of the way down the room, facing the camera. Each mark is a small brass disc set into the floor with a **candle on a stand** beside it.
- **You** always stand on the **leftmost mark**, matching Demonology.
- **Empty marks** show a faint silhouette of dust and shadow, with a small brass **"+"** plaque at its feet. Click it to invite.
- **When someone joins**, their avatar steps out of the dark onto the mark and their candle lights.
- **The leader** has a small gold crown icon (or the brass key icon) above their name.
- **Ready:** the candle flame burns tall and bright. **Not ready:** a thin flame, guttering.
- Names appear on small brass plates on the floor in front of each mark.

### 6.3 Camera and screen layout

```
 ┌─────────────────────────────────────────────────────────────────────┐
 │  [ SIGHTINGS ] [ KIT ] [ KEEPSAKES ] [ JOURNAL ] [ STORE ] [ ⚙ ]    │  <- tabs, top
 │                                                                     │
 │   (you)  (+)   (+)   (+)   (+)   (+)         ┌──────────────────┐   │
 │    ▲     ┊     ┊     ┊     ┊     ┊           │  current page     │   │
 │   ▒▒▒   ▒▒▒   ▒▒▒   ▒▒▒   ▒▒▒   ▒▒▒          │  (job, difficulty │   │
 │   name  invite …                             │  or the shop)     │   │
 │                                              └──────────────────┘   │
 │   Sovereigns 340 · Level 4                [ READY ]   [ START ]     │  <- bottom
 └─────────────────────────────────────────────────────────────────────┘
```

- **The line-up fills the left 60%** of the screen; **the current page sits on the right 40%**, over the dark wall and bookshelves. This is Demonology's layout.
- The menu camera from `LOBBY_DIRECTION.md` 2.2 changes: it's placed slightly off-centre to the right and angled so the six marks sit on the left of the screen.
- **On phones:** the page panel slides up from the bottom and the line-up shrinks to the top half.

### 6.4 The pages: each one is a place in the room

Clicking a tab opens its panel **and** moves the camera (a 0.8 s ease) to the matching spot in the room. Closing the page brings the camera back to the line-up.

| Tab | Place in the room | Panel |
|---|---|---|
| **Sightings** (job sites) | A **corkboard** of newspaper clippings and a map with pins. Each pin is a sighting | The leader chooses the map and difficulty. Locked sightings show their level. Everyone else can see the choice but not change it |
| **Kit** (equipment) | A **travelling trunk** that opens, with tools in fitted slots | Buy equipment for this run (section 7.1). Anyone can buy; the party's combined kit is shown |
| **Keepsakes** (perks) | The **card-index cabinet**. A drawer slides out | Each player picks their own keepsakes (section 7.2) |
| **Journal** | The **lectern book** | Section 6.5 |
| **Store** | The **wardrobe and coat stand** | Robux cosmetics only (section 7.5) |
| **Settings** | No camera move | Audio, flashing, sensitivity, replay the tutorial |

**The cases** now hold **one relic for each dybbuk your party has laid to rest** (one per map), plus **Lot 001, the open dybbuk box**, on the central plinth behind the line-up: the one relic that explains the whole collection. Cases for sightings you haven't finished stay under dust sheets. This replaces the case list in `LOBBY_DIRECTION.md` 5.2.

### 6.5 The journal

Opened on the Journal tab in the lobby, or with **J** inside a map.

| Section | Contents |
|---|---|
| **The Dybbuk** | The user's Dybbuk card (its art, description and evidence) |
| **Traces** | One page per trace (freezing temps, prints, wither), explaining how each one shows on the map |
| **Case files** | One per sighting: the three case-file questions (section 3.3). Answers you got right stay filled in; unvisited sightings are blotted |
| **Kit** | One page per equipment item |
| **Keepsakes** | One page per keepsake |

### 6.6 The tutorial: letters from C.A.

Demonology uses The Boss. We use Cornelius's own hand.
- On a first visit, **a sealed letter lies on the lectern**. A prompt asks: "Read Mr Ashgrove's letter?" with **Read** and **Not now**.
- **Read** plays a short guided sequence: the camera moves to each place in 6.4 while the letter is shown, one paragraph per stop, in his voice. *"If you are reading this, the box is open."*
- **Not now** skips it. It can be replayed from Settings, the same as Demonology.

### 6.7 Ready, start and coming back

**Starting a run:**
1. The leader picks a sighting and difficulty.
2. Everyone buys kit and picks keepsakes (optional).
3. Each player presses **Ready**. Their candle burns tall.
4. When everyone is ready, the leader's **Start** button lights up. The leader presses it.
5. All candles flare; the strongroom door's line of light grows; fade to black over 1.5 s.
6. The party is **teleported** together to a **reserved server** for that map (section 8.2).

Any player can un-ready until the leader presses Start. If someone leaves, everyone's ready resets.

**Coming back (the results screen):**
- **Laid to rest, failed or fled.** Shown in the map, then the party is teleported back to the lobby.
- The results screen is a **paycheck in Pellam & Sloane's letterhead**, with each line from section 5.2 written out, plus case-file answers and the correct ones.
- **The first time a party lays a dybbuk to rest**, the camera moves to its case as the dust sheet is pulled off and the relic appears.
- The party stays together in the line-up for the next run.

---

## 7. Kit, keepsakes, difficulty, objectives and store

### 7.1 Kit (equipment)

Starter kit is free and comes with every run, like Demonology. Extra copies and other items cost sovereigns.

Each tool reads one of the dybbuk's traces, so equipment is how you track it:

| Item | Reads | Use | Cost | Level |
|---|---|---|---|---|
| **Torch** | | Light. Also what makes it visible, so what lets you stare (see the subway doc 6.4) | Free (1 each) | 1 |
| **Thermometer** | Freezing temps | Shows a temperature that drops as you get closer to it, even through walls | Free (1 per party); extra 25 | 1 |
| **UV lamp** | Prints | Makes its handprints glow, including old ones (up to 3 minutes old rather than 90 s) | 40 | 5 |
| **Pressed flower** | Wither | Held in the hand. Its petals curl when the dybbuk is within 25 studs | 30 | 3 |
| **Camera** | | Photos for optional objectives. The flash makes it visible, so photographing it also risks a stare | 50 | 8 |
| **Music box (extra)** | | A second music box. The "first play" stun counts **once per run**, whichever box plays first | 120 | 10 |

### 7.2 Keepsakes (perks)

Our version of Demonology's tarot cards: small objects from Cornelius's card-index cabinet. Each player brings **up to 2**. Bought **per run**; they're used up.

| Keepsake | Effect | Cost | Level |
|---|---|---|---|
| **Iron nail** | +20% sprint stamina (if the user's movement uses stamina; otherwise +5% sprint speed) | 30 | 3 |
| **Black ribbon** | Your stare meter fills 20% slower | 50 | 5 |
| **Grave soil** | Your footsteps are heard from 25% less far | 40 | 6 |
| **Return ticket** | +1 life (for you only) | 60 | 8 |
| **Steady hand** | The stun gun or music box, when you use it, stuns for 5 s longer | 50 | 10 |
| **Mourning veil** | The roar after a head turn lasts 0.5 s longer, giving you more time to run | 40 | 12 |

### 7.3 Difficulty

Chosen by the leader. Changes the shared dybbuk rules on every map.

| | Easy | Normal | Hard | Nightmare |
|---|---|---|---|---|
| Pay multiplier | ×0.75 | ×1 | ×1.5 | ×2.25 |
| Stare to trigger | 4 s | 3 s | 2.5 s | 2 s |
| Stare warning ring | from 1.5 s | from 1.5 s | from 1.5 s | **none** |
| Chase speed | 23 | 26 | 27 | 28 |
| Lives per player | 4 | 3 | 2 | 1 |
| Hazard warnings (trains on Map 1) | +2 s longer | as designed | as designed | as designed |
| Free thermometer | yes | yes | yes | no |

**Hazard warnings and the departure boards never get shorter or less honest on any difficulty.** Fair warning is a non-negotiable on every map.

**Custom** (level 10): the leader sets each row separately. The pay multiplier is worked out from the settings, from ×0 (everything made easier) to about ×4, the same as Demonology's reported range.

### 7.4 Optional objectives

Each run, **3** are picked at random from the map's list and shown on the Sightings page and in the journal. Each pays extra. Map 1's list:

| Objective | Pay |
|---|---|
| Photograph its head turning | +40 |
| Find all five code pieces within 10 minutes | +30 |
| Nobody triggers a head turn before the code is unfolded | +30 |
| Lay it to rest with the music box stun instead of the gun | +40 |
| Fill in the whole case file before laying it to rest | +20 |
| Nobody in the party loses a life | +40 |

### 7.5 Store (Robux)

**Cosmetics only:** avatar outfits in period styles (trench coats, flat caps, Victorian mourning wear), torch skins, lobby emotes, and candle colours for your mark in the line-up.

**Not sold:**
- Sovereigns, reputation or levels.
- Keepsakes, kit, or anything that changes play.
- Random rewards of any kind.
- **Sighting unlocks.** (Demonology reportedly sells these. We don't: levels are the only way in.)

A **private server** option uses Roblox's built-in private servers.

---

## 8. Technical

### 8.1 Places

One Roblox experience, several places:

| Place | Contents |
|---|---|
| **Lobby** (start place) | The reliquary, the line-up, all menus, party system, purchases |
| **Ebbmoor Junction** | Map 1 from `SUBWAY_DIRECTION.md` |
| (one place per future map) | |

Shared code (Config, Net, data and journal text) is a package used by every place.

### 8.2 Teleporting

- **To a map:** `TeleportService:TeleportAsync(mapPlaceId, partyPlayers, options)` with `TeleportOptions.ShouldReserveServer = true`, and teleport data carrying: party member user IDs, map, difficulty, each player's kit and keepsakes, and a run ID.
- **The map server validates the teleport data against saved data** before using it (players can edit teleport data). In practice: read each player's saved purchases for this run ID from the DataStore and ignore anything in the teleport data that doesn't match.
- **Back to the lobby:** teleport the party to the lobby place, with a `PartyId` in the teleport data so the lobby puts them back in the same line-up.
- **Failures:** retry a failed teleport up to 3 times with a short wait, then put the player back in the lobby with a message.

### 8.3 Saved data (DataStore)

Per player: sovereigns, reputation, level, case-file answers per map, maps laid to rest, cosmetics owned and equipped, settings, tutorial seen.

- **Use `UpdateAsync`**, never read-then-write.
- **Charging for kit and keepsakes:** deducted when the leader presses Start (matching Demonology), and recorded against the run ID. If the teleport fails, refund it.
- **Paying out:** the map server writes the paycheck before it teleports players back, using the run ID so a run can only be paid once.
- **Session locking:** stop the same player's data being written from two servers at once (the lobby and a map). Use a lock field with the server's job ID and a timeout.

### 8.4 The party system

- **In the lobby server:** a party is a leader plus up to 5 members. Players in the same lobby server can be invited directly from the "+" slot.
- **Friends in other servers:** the "+" slot also offers `SocialService:PromptGameInvite`. When they join, they're dropped straight into the inviter's party.
- **Each player sees only their own party** in the line-up. Other parties in the same lobby server aren't shown.
- **The leader leaving** passes leadership to the next player in the line-up.

### 8.5 Files

```
reliquary/
  default.project.json
  src/shared/Reliquary/      Config, Net, Signal, Data (schema), Journal (texts), Catalogue (kit, keepsakes, maps, objectives)
  src/lobby/server/          Party, Purchases, Teleport, Results, Tutorial
  src/lobby/client/          LineUp, Pages, CameraRig, Hud, ResultsScreen
  maps/ebbmoor/              Map 1, as in SUBWAY_DIRECTION.md 16.1, plus RunData (reads teleport data), Payout, CaseFile, Objectives
```

---

## 9. What carries across from the earlier documents

| Kept from | What |
|---|---|
| `SUBWAY_DIRECTION.md` | All of Map 1, with only the changes in 4.3 |
| `LOBBY_DIRECTION.md` | The room's look: walls, ceiling, floor, lectern, set dressing, mourning customs, strongroom door and knocks, lighting values, storm, sound, palette, performance |
| `ASHGROVE_STORY.md` | Cornelius Ashgrove, his catalogue cards, Pellam & Sloane, Lot 001 (the sealed box) |

---

## 10. What this replaces

| Document | Status now |
|---|---|
| `LOBBY_DIRECTION.md` 2 (layout and camera) | Replaced by 6.2–6.3 |
| `LOBBY_DIRECTION.md` 5.2 (what goes in the cases) | Replaced by 6.4 (relics of laid-to-rest dybbuks, plus Lot 001) |
| `LOBBY_DIRECTION.md` 9 (Party Up and Books buttons) | Replaced by 6.2–6.4. Party Up is now the "+" slots; Books is now the Journal tab |
| `ASHGROVE_DIRECTION.md` and the Ashgrove story's other monsters (Dullahan, Banshee, Lamp-shy and the rest) | **Parked.** Not part of *The Reliquary* while it's a one-monster game. Kept on file in case the house returns later as a map |
| The Ashgrove code in `ashgrove/` | Parked. Its tools (the installer builder, the offline map checks) are reused for the new projects |

---

## 11. Build order

| Step | What | Done when |
|---|---|---|
| R1 | **Map 1 playable** (`SUBWAY_DIRECTION.md` M1–M8) | Can be finished start to end in its own place |
| R2 | **Saved data** (8.3) | Sovereigns and reputation persist across sessions; session lock tested with two servers |
| R3 | **Lobby room and camera** (6.1, 6.3) | Room built to `LOBBY_DIRECTION.md` look; menu camera framing the line-up as in 6.3 |
| R4 | **Line-up and party** (6.2, 8.4) | Invite, join, leave and leader handover work with 2–6 players |
| R5 | **Sightings page, ready and start** (6.4, 6.7) | The party teleports together into a reserved Map 1 server |
| R6 | **Results and return** (6.7, 5.2) | Pay is correct, paid exactly once per run, party returns together |
| R7 | **Kit and keepsakes** (7.1, 7.2) | Bought in the lobby, present on the map, charged once, refunded if the teleport fails |
| R8 | **Difficulty** (7.3) | Every row changes the right values on the map |
| R9 | **Journal and case file** (6.5, 3.3) | Opens on J in the map; answers are scored on the results screen |
| R10 | **Optional objectives** (7.4) | 3 per run, tracked and paid |
| R11 | **Tutorial letters** (6.6) | Plays on first visit, skippable, replayable |
| R12 | **Relics in the cases** (6.4, 6.7) | The reveal plays the first time a dybbuk is laid to rest |
| R13 | **Store** (7.5) | Cosmetics only, bought with Robux, equipped in the lobby |

---

## 12. Open questions

1. **Is the one monster the Dybbuk?** (Assumed throughout.)
2. **Party size:** 6, like Demonology, or something else?
3. **Map 2:** which of the ideas in 3.2, if any, should be designed next?
4. **Does your movement system have stamina?** It changes the Iron Nail keepsake (7.2).
5. **Currency names:** keep sovereigns and reputation?

---

Sources (search results only; the pages themselves couldn't be opened from here):
- [Demonology Wiki (Fandom): Game](https://demonology.fandom.com/wiki/Demonology)
- [Demonology Wiki (Fandom): Guide](https://demonology.fandom.com/wiki/Guide)
- [Demonology Wiki (Fandom): Difficulty](https://demonology.fandom.com/wiki/Difficulty)
- [Demonology Wiki (Fandom): Levels](https://demonology.fandom.com/wiki/Levels)
- [Demonology Wiki (Fandom): Job Sites](https://demonology.fandom.com/wiki/Job_Sites)
- [Demonology Wiki (Fandom): Upcoming Content](https://demonology.fandom.com/wiki/Upcoming_Content)
- [Sportskeeda: Demonology, a beginner's guide](https://www.sportskeeda.com/roblox-news/demonology-a-beginners-guide)
- [Gamezebo: How to buy equipment in Demonology](https://www.gamezebo.com/walkthroughs/how-to-buy-equipment-in-demonology/)
- [TechWiser: Roblox Demonology all perks](https://techwiser.com/roblox-demonology-all-perks/)
- [Bloxodes: Demonology wiki](https://bloxodes.com/wiki/demonology)
- [allthings.how: Demonology beginner guide](https://allthings.how/demonology-on-roblox-beginner-guide-to-hunting-ghosts/)
