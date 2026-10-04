# Ashgrove House: Creative Direction

**Status:** directive, v1 (4 Oct 2026). The team builds to this document. To change a rule, edit it here; don't route around it.

**Built from:** *Horror Direction Analysis* (the comparative research) and *Ashgrove House: Art & Model Brief* (setting, premise, Story 1 beats, technical specs).

**How to read it.** Statements are decisions. Numbers are **starting values to tune in playtests**, not final. Where the two inputs disagreed, section 2 records which one won and why. Undecided items are listed in section 15. Nothing outside that section is open.

---

## 1. What this game is

**Pitch.** *A co-op horror game about retrieving a dead collector's haunted collection: you can shoot what comes for you, but the Banshee in the servants' wing can't be killed, and when she keens, something in the house has to die.*

**Identity.** *Hunt what you can see. Fear what's been foretold.*

**Core horror fantasy.** *"I can kill what I see coming. I can't stop what's been foretold."*

**Player fantasy.** You're hired retrievers, the second crew sent into Ashgrove House. You're armed because the first crew didn't come back. You're **capable, not safe**: the pistol can kill most things in the house if you see them in time, aim well and don't miss.

**Pillars, in priority order.** When two pillars conflict, the higher one wins.

1. **Exploration is reading.** Every room holds traces of the entities, of the first crew and of Cornelius. Understanding is how you get stronger.
2. **Doubt, not helplessness.** The player can usually win and should never be sure. Doubt comes from the situation (distance, light, ammo, noise, the Banshee), never from enemy health bars.
3. **Every death matters.** Every kill changes the house, every body tells part of the story, and the Banshee remembers both.
4. **Occasional, decisive danger.** Encounters are rare, short and sharp. Safe rooms really are safe.

**Emotional arc across a story.** Curiosity → unease → competence (first kills) → dread (the Banshee) → doubt (rules bend) → grief (what happened to the first crew) → resolve.

---

## 2. Reconciling the two inputs

The research assumed a rural, outdoor, folk setting with a long gun. The brief commits to a cliff-top manor with a pistol. **The brief's setting and premise are canon.** The research's principles still apply, translated into the manor as follows.

| Topic | Research said | Brief says | **Direction** |
|---|---|---|---|
| Setting | Rural and outdoor: bogs, causeways, villages. No interior mazes | Cliff-top manor at night in a storm | **Manor.** Make it grand and readable, never a maze. Use long rooms, sight lines, and the grounds and cliff path as open exterior. The storm does the job the tide did in the research: it changes the house over the night (section 10) |
| Where death sits in the world | "A place where death is everyday": wake houses, parishes | A collector's house of haunted objects, and a missing first crew | **The collection is the death-culture.** Every object has a dead owner and a catalogue card. The first crew are the recent dead |
| Weapon | One slow, loud long gun | A pistol that's "deliberately hard to aim" | **Pistol**, built to the research's limits: low capacity, slow uninterruptible reload, loud, sway that settles only when you stand still (section 7) |
| Enemies | Creatures with habitats, natural to the world | Entities bound to collection objects | **The object's room is the habitat.** Killing a manifestation banishes it back into its object. Securing the object ends that entity's threat (section 6) |
| Objectives | Progress through knowledge and access. No "find N keys" | Retrieval crew cataloguing a collection | **Retrieval is the objective grammar.** You locate an object by reading its traces and secure it at its habitat. No keys-and-codes chains |
| Party | Party of 4 or fewer. Punish separation | Co-op for 1–4 players | **1–4, playable solo.** Entities prefer isolated players (section 12) |
| Banshee | An omen that never chases | Met in the servants' wing in Story 1 | **The servants' wing is her home ground.** The Keen system is the game's signature (section 9) |
| Tone | Grief, dread and folklore | Grounded, modern, physical. Folklore, not zombies | Compatible. Keep both |

---

## 3. Non-negotiables

These ten rules apply to every design. A feature that breaks one doesn't ship.

1. **The Banshee never chases, never patrols and is never a jump scare.** She is always heard before she is seen.
2. **Every entity leaves traces before contact.** That means sound, visual marks and an environmental change. No entity arrives unannounced.
3. **One rule per entity, explainable in one sentence.**
4. **Every entity allows both fighting and avoidance, and has a non-hostile state.**
5. **Every kill is functional:** it banishes the entity, opens a window to secure its object and feeds the Banshee system. A death that only plays an animation isn't finished.
6. **One entity per encounter** (two at most, rarely). Encounters last 8–25 seconds.
7. **No damage upgrades.** The player's power grows through knowledge, tools and access.
8. **Sanctuaries have zero encounters.** Safe means safe.
9. **No pure mazes.** Complexity comes from sight lines, light, verticality and the storm.
10. **No lives or revives sold for Robux.** Death is never a purchase prompt.

---

## 4. Core loops

### Primary loop: Trace → Read → Commit → Survive → Understand

This loop repeats every 5–8 minutes in danger zones.

| Step | What the player does | Ashgrove form |
|---|---|---|
| **Trace** | Notices evidence | An empty display case, a catalogue card, a first-crew voice memo, a servants' bell ringing in an empty room, scorch marks, a dust sheet pulled off a portrait |
| **Read** | Works out what's here, where it is and what it does | Cornelius's catalogue cards state the folklore. The first crew's notes record what went wrong. Players combine them into the entity's rule |
| **Commit** | Chooses to fight, avoid, repel or wait | Shoot it in its kill window, route around it, use a folklore ward, or wait out its non-hostile state |
| **Survive** | Plays out a short, sharp encounter | 8–25 seconds. Often a single shot decides it |
| **Understand** | Gets a consequence that opens the next space | The banished entity's object can now be secured. The Banshee comes to mourn. A route opens. A first-crew death is explained |

### Secondary loop: the retrieval run

**Van (sanctuary) → enter a wing → read it and find the object → secure it → return → the house changes.**

After each object is secured, the storm escalates. Some routes open and others flood or lose power, and the Banshee moves closer to the story's centre.

---

## 5. Objectives

- **Each story is a retrieval list.** The list comes from the auction house's manifest, cross-checked against Cornelius's catalogue. Each object sits in its entity's habitat.
- **Finding an object is a reading problem, not a search problem.** The catalogue card says *what* the object is. Traces say *where* it went and *what guards it*. No object hides in a random drawer.
- **Securing an object** means placing it in a warded retrieval crate. This is a slow, uninterruptible action of about 4 seconds, and it is the moment of commitment. It's quickest while the entity is banished.
- **At most one "collect N things" objective per chapter**, and never a numeric code. Codes get printed on guide sites the day a game launches.
- **Randomise inside authored rules.** Habitats are fixed. Within each habitat, the object's exact spot, the side room the entity starts in and the first crew's casualty sites vary between runs, so a route can't be memorised.

---

## 6. Entities

### Philosophy

**Entities, not monsters.** Each one is bound to an object Cornelius bought, belongs to the culture its folklore comes from, has habits in its room, and closes distance in a way no other entity does. **The approach is the identity:** how an entity reaches you defines its kill window.

### The binding (functional death, by design)

- **Kill** a manifestation and it dissipates back into its object. It **re-forms after a cooldown** (starting value 6–10 minutes) unless the object is secured.
- **Securing the object** removes that entity for the rest of the story.
- This is the Locust lesson made systemic: *the thing you need is where the thing that kills you lives.* Killing buys the window. Securing ends the threat.
- Every manifestation's death also counts as a death for the Banshee (section 9).

### Every entity is designed with this template

Fill this in before any art or code begins. The art team receives sections 1, 6, 7, 10 and 14.

```
ENTITY: [name]  ·  OBJECT: [what it's bound to]  ·  ORIGIN: [culture]
 1. One-sentence rule
 2. What it teaches the player
 3. Primary emotion
 4. Behaviour it forces
 5. Traces before contact: sound / visual / environment
 6. Recognition: silhouette (readable at 70+ studs in the dark), unique sound, movement signature
 7. Non-hostile state (what it does when it hasn't noticed you)
 8. Detection: senses and ranges
 9. Approach (the kill window): pattern, speed, seconds from detection to contact, weak point
10. Danger: damage per hit, special effects
11. Counters: kill (shots, weak point) / avoid / repel (folklore ward)
12. What makes fighting it satisfying
13. What makes surviving it memorable
14. Death: what happens, what it leaves, how the Banshee reacts
15. Anti-annoyance limits: max simultaneous, re-form cooldown, never in sanctuaries
16. Combinations with rooms, the storm, other entities and the Banshee
```

### Story 1 roster

#### The Dullahan (portrait gallery). Killable, and the first real encounter.

- **Rule:** *it sees only what its carried head is facing.*
- **Origin:** Irish folklore. A headless rider who carries his head and a whip made from a human spine. Gold repels him.
- **Traces:** a dry whip-crack echo from far down the gallery, the head's low glow sweeping like a lantern, portrait dust sheets torn away at head height, and a first-crew body lying with its face turned away.
- **Non-hostile state:** he walks the gallery holding the head up to the portraits, studying faces. If you stay out of the head's view, you can pass behind him.
- **Approach:** a slow, deliberate stalk with the head held forward. The kill window closes at **whip reach (about 12 studs), not at contact**, so "before it reaches me" means "before I'm inside the whip's reach." Starting value: about **6 seconds** from detection to whip range in an open gallery.
- **Weak point:** the head. Hitting it makes him drop it, and he gropes blind toward sound for about 3 seconds. That's the opening for the kill shot. Body shots only stagger him.
- **Counters:** kill (head hit, then 1–2 body shots), avoid (stay outside the head's facing), repel (raise a gold collection object into his view and he recoils, buying distance but not a kill).
- **Death:** the body falls and **the head keeps glowing** for about 2 minutes, a light source that still faces wherever it rolled. Then both return to the object. The Banshee comes to mourn him: two Irish death-omens meeting is Story 1's best quiet image.
- **What players remember:** shooting the head out of his hands and watching him search for it.
- **Bound object:** proposed to be the spine whip itself, stored in a locked tack case. The story team confirms (section 15).

#### The Banshee (servants' wing). Unkillable. See section 9.

#### The Dybbuk (cellar vault). The Story 1 finale and the Story 2 seed.

- In Story 1 the crew **finds the box already opened**. The Dybbuk is loose, and Story 1 doesn't resolve it.
- It isn't a combat entity in Story 1. Its role is to give the finale its rule-break (section 11): the Banshee keens in the vault with no entity present.
- **Proposal for the story team:** the Dybbuk has possessed a surviving member of the first crew. That gives Story 2 the social horror the research found almost absent on Roblox (an NPC who isn't what they say).
- **Care rule:** the dybbuk comes from Jewish folklore and the "dybbuk box" is a modern internet legend. Follow the brief: no Hebrew script or religious symbols as decoration. Research the folklore properly and treat it as a person's displaced soul, not a demon.

#### Gap: Story 1 needs one more killable entity

Story 1 runs 60–80 minutes. With only the Dullahan to fight, players will master him by the second encounter, which is the main way Monochrome fails. **Add one minor killable entity** to the entrance hall and servants' wing. It must have a different approach pattern from the Dullahan (fast and low, or stop-start) and a cheap rig. It is also the creature whose death resolves the first keen. The recommendation is in section 15.

### Later stories: starting rules

Each of these is a seed. Each entity still gets the full template before production.

| Entity | Origin | Starting rule | Why it's ours |
|---|---|---|---|
| **Siren** | Greek | *Its song pulls you toward it. Covering your ears stops the pull and stops you aiming.* | Each encounter is a choice: hear it and aim, or go deaf and safe. It belongs in the flooded sea-cave under the cliff |
| **Aswang** | Filipino | *Its call is loud when it's far away and quiet when it's close.* | This comes from tik-tik folklore and inverts the "footsteps mean danger" habit every Roblox player has |
| **Nightmare** (the Mare) | Germanic and Norse | *It only moves while you're still.* | It punishes hiding and holding still, the two most learned Roblox reflexes. It belongs in the bedrooms |
| **Demon** | **Undefined** | Not set | The weakest-defined entity, and the most exposed to the brief's rule against religious symbols. Before any art, pick a **specific** culture's entity and give it a rule. The recommended direction is a threat that bargains rather than hunts |

---

## 7. Combat

### Level: low to moderate

Fights are deliberate and short, and avoiding a fight is often the smarter move.

| Metric | Starting value |
|---|---|
| Threat signal (a trace, sound or bell) | Every 2–4 min in danger zones |
| Real encounter | Every 5–8 min in danger zones |
| Shots fired | Every 8–15 min on average |
| Encounters fought / avoided | About 50–60% / 40–50% |
| Encounter length | 8–25 s. Past 30 s it has become an action scene; fix the encounter |
| Entities per encounter | 1 (2 at most, rarely) |
| Shots to kill | 1–3, with a weak point |
| Hits to go down | 2–3. No regeneration outside sanctuaries |
| Player power over time | Flat to slightly rising (wards and knowledge, never damage) |

### The pistol

"Deliberately hard to aim" means hard to aim **in a hurry**, not randomly inaccurate. A player who stands still and commits should be able to hit.

- **Sway:** wide while moving, narrowing to near-steady after about **1.0–1.5 s standing still**. A shot re-opens it. Holding the flashlight in the same hand widens it.
- **Capacity:** small, starting at **6 rounds**. Carry cap per player: about **12 rounds** in reserve.
- **Reload:** **2.5–3.5 s, uninterruptible.** This is the moment the fear lives in.
- **Ammo supply:** enough on hand for about 3–5 kills. Pickups are tuned to **70–80% of what fighting every encounter would cost**, so avoiding fights has to be part of how you get through.
- **Noise:** gunshots are loud and carry through the wing. Entities in earshot investigate, and a shot during a keen draws the Banshee's attention.
- **Light:** lightning flashes are free, full-scene light. The best shot is often the one you wait for the lightning to give you.

### Non-lethal tools

- **Flashlight:** essential for reading traces and aiming in the dark. Battery runs down and spare batteries are found in the house.
- **Folklore wards** found in the collection: gold for the Dullahan, iron, salt, others per entity. A ward **repels or stalls but never kills.** Learning which ward works on which entity is knowledge progression. The catalogue cards hint at it.

---

## 8. Exploration and storytelling

- **Exploration is reading.** Each zone holds **3–5 discoveries** and **1–3 entity habitats**. An important discovery lands every **4–7 minutes**.
- **There are three layers of story:**
  1. **Cornelius:** catalogue cards, purchase receipts and correspondence. They tell you *what* each object is and *why* he wanted it.
  2. **The first crew:** voice memos, a half-done inventory, their bodies and their gear. They tell you *what went wrong*, which teaches the entity rules through someone else's mistake.
  3. **The dead the Banshee mourns.** Mourning sites are where the real story is (section 9).
- **The story lives in the house, not on a wiki.** Notes add detail. The core truths are found at sites and in the environment.
- **Rooms remember.** Bodies stay where they fell. A room the Banshee mourned in stays changed (stopped clocks, covered mirrors). Secured objects leave empty, dust-free outlines.

---

## 9. The Banshee

### What she is

> **The other entities ask: "Can I kill this before it reaches me?"**
> **The Banshee asks: "Who is going to die here?"**

In Irish folklore the banshee (*bean sí*) doesn't kill. **She keens to announce a death that's coming.** That's why she can't be killed (you can't kill an announcement), and it's why she isn't one more unkillable stalker. Every other unkillable monster in the research chases the player. She doesn't.

**Originality note:** *Phasmophobia* already has a ghost type called "Banshee", and the name is common in fantasy games. **The Keen mechanic is what makes her ours**, not the name.

### The core rule

**When the Banshee keens, someone nearby will die soon. If nothing else dies, one of you will.**

### Her states

| State | What happens | Danger | Player response |
|---|---|---|---|
| **Distant** | Faint keening through the walls, from somewhere in the house. An omen only | None | Dread. "She's somewhere" |
| **Mourning** | She appears at a site of death (a first-crew body, a banished entity) and grieves | Safe, unless you disturb her with light on her face, gunfire or getting within about 15 studs | Watch from a distance. **Mourning sites hold the story's clues** |
| **Keening** | **The storm goes silent.** Rain stops sounding and the lights dim. Entities nearby wake and become agitated. A **doom window** of about 60–90 s opens | Indirect at first, then lethal | Resolve it (below) |
| **Taking** | The window closes and nothing else died | Lethal | Unavoidable at this point. The penalty for ignoring her |

### Resolving a keen

There are three ways, by design:

1. **Fulfil it.** Kill an entity inside the keened area. A death has happened: she falls quiet and comes to mourn it. **This is what ties the Banshee to combat.** She makes a fight necessary, but the player still chooses which one.
2. **Leave.** Cross a threshold: a sanctuary doorway with a lit hearth or working light, or any exterior door into the rain. Leaving resolves the keen but **costs you the wing for now**. You come back later to a changed room.
3. **Perform the wake rite.** Stop the clock, cover the mirror, open the window. These are Irish wake customs, available only in **specific rooms**, mostly in the servants' wing, so the house becomes part of the answer. The servants left their customs written down for players to find.

### Rules

| Question | Answer |
|---|---|
| Does she chase? | **Never.** |
| Does she patrol? | **No.** She *appears*, at sites of death and where the story needs her |
| Predictable? | **Her rules are predictable and her timing isn't.** Players should always understand *what* she does and never know *when* |
| Is she heard first? | **Always.** The keen is the most recognisable sound in the game |
| How often? | Distant: ambient, a few times per 10 minutes once she's introduced. Mourning: about once per wing. **Keen: every 15–25 minutes, never twice in one wing visit, never in a sanctuary, never during another keen's cooldown** |
| Who is taken in co-op? | The player she faces. Before the window closes, her keen's direction and her gaze show who it is |
| Can players just run every time? | Keens trigger in wings that hold the object you need. Running out works and costs you the wing for that visit |
| Do her rules change? | **At most twice per story, as narrative peaks.** Story 1 uses one (section 11) |
| Her bound object | **Undecided** (section 15). The working rule is that her object can never be secured in Story 1 |

### Fallback if the Keen system is too much scope

She becomes **omen-only**: she never takes anyone, and her keen draws every entity in the wing and kills the lights for 60 seconds. She stays unkillable and still never chases. It's cheaper to build and gives her less identity. Use it only if Story 1's schedule demands it.

---

## 10. Level design

### Principles

1. **Readable distance.** Kill windows need sight lines. At least one sight line of **70+ studs** (about 20 m) in every combat space. The gallery gets the longest.
2. **Dense, not wide.** Fewer, richer rooms beat long empty corridors. Corridors connect spaces and are never the space.
3. **Habitats, not spawns.** Every entity lives in a specific room with its object, and traces lead there.
4. **Sanctuaries are diegetic and visible.** The van, and rooms the first crew powered and lit. Players should be able to see a sanctuary's light from a danger zone.
5. **The storm changes the house over the night.** As objects are secured, the storm builds: power fails room by room, water comes in at the cliff side, and windows blow in. Return visits differ.
6. **Lightning is gameplay light.** Tall windows in combat spaces. Flashes reveal silhouettes and give free aiming light. Flashes come at irregular intervals, and **never during a keen**: then the storm falls silent.
7. **The servants' bell board** in the servants' wing is a diegetic tracker. A bell rings for the room an entity is in. It gives imperfect, readable information, our version of Alien: Isolation's motion tracker.

### Story 1 zones

| Zone | Function | Entities | Gameplay | Story | Look |
|---|---|---|---|---|---|
| **Drive, grounds and the van** | Hub and sanctuary. Arrival and escape | None | Preparation, ammo, crating secured objects | The first crew's abandoned vehicle | Storm, cliff edge, the house's few lit windows |
| **Entrance hall** | First crew's base camp. Partial sanctuary at first, failing later | The minor entity, later | Teaching traces. First reads | Their lights, cases half-catalogued, the manifest | Dust sheets, crates, the grand stair, one working lamp |
| **Portrait gallery** | The first real kill-window encounter | **Dullahan** | Long sight lines, the head's facing, waiting for lightning | Cornelius's portraits of the objects' previous owners | Tall windows, lightning, rows of covered frames |
| **Servants' wing** | The Banshee's home ground. Ritual interiors | **Banshee**, the minor entity | Wake rites, the bell board, quiet investigation | The household that served Cornelius and what they knew | Narrow but legible: kitchens, the bell board, stopped clocks, covered mirrors |
| **Cellar vault** | The finale | Dybbuk (the opened box), Banshee | Darkness, flashlight management, the rule-break keen | The vault where the worst objects were kept | Stone, iron cages, the one empty plinth |

---

## 11. Pacing

### Philosophy

**Long waves, not constant noise.** Each wave runs calm → traces → decision → spike → release → discovery. Players should feel **completely safe** every 15–20 minutes, for 2–5 minutes at a time.

### Targets

| Element | Target |
|---|---|
| Exploration between real encounters | 5–8 min |
| Major narrative revelation | Every 20–30 min |
| Chapter checkpoint | Every 10–20 min (fits Roblox session length) |

### Story 1 beat sheet (about 75 minutes, four chapters)

This is pacing only. The story team owns the content.

| Min | Chapter | Beat | Danger | Purpose |
|---|---|---|---|---|
| 0–5 | 1 · Arrival | The drive in. The van. The first crew's empty vehicle. Into the hall | None | Mood, controls, curiosity |
| 5–12 | 1 | The first crew's camp: the manifest, voice memos, an empty display case | Traces only | Teach "traces before contact" |
| 12–15 | 1 | Gallery doors. The whip-crack far off. Checkpoint | Signal | Anticipation |
| 15–22 | 2 · Gallery | **First Dullahan encounter.** A long sight line, readable and winnable | Medium | Teach the core question and the head weak point |
| 20 | 2 | First **Distant** keen from the servants' wing | Omen | Plant dread |
| 22–32 | 2 | Secure the Dullahan's object in the banish window. A first-crew body in the gallery. Return to the van | Low | Release. First retrieval. Checkpoint |
| 32–38 | 3 · Servants' wing | The bell board. Wake customs written in the servants' hand. The minor entity's traces | Signal | Teach the bell board and the rites |
| 38–42 | 3 | **First Mourning**: the Banshee grieving over a first-crew body, seen from a distance | Tension, no danger | "She doesn't chase. She marks death" |
| 42–45 | 3 | Discovery at the mourning site | Low | Following her leads to answers |
| 45–50 | 3 | **First Keen.** The minor entity is nearby, and the player resolves the keen by killing it | **High** | The signature mechanic |
| 50–55 | 3 | She mourns the killed entity. Sanctuary. **First major revelation.** Checkpoint | Release | Death acknowledged |
| 55–65 | 4 · Vault | Down into the cellar. The storm has cut the power. The opened box | Medium | Escalation |
| 65–72 | 4 | **Rule-break:** she keens in the vault with **no entity present**. It's for one of you. Resolve by the wake rite (if the room has one) or by leaving | **Peak** | Teach the other resolutions under the most pressure |
| 72–75 | 4 | Out through the house to the van, crossing the threshold into the rain. **She keeps keening after you've crossed.** It wasn't about you | Release, then a hook | Cliffhanger into Story 2 |

---

## 12. Co-op and Roblox fit

- **Party of 1–4. Solo is fully supported.** Scale ammo pickups and keen pressure by party size.
- **Entities prefer the isolated player.** Splitting up should feel like a mistake the game punishes, not one it ignores.
- **Natural roles without classes.** One player holds the light while another aims. The pistol's flashlight sway makes this the smart choice, not a forced one.
- **Going down:** 2–3 hits downs a player. A crewmate revives them with a **4-second uninterruptible** action. Solo, or the whole party down, returns to the last checkpoint.
- **Taken by the Banshee:** you're out until the party reaches a sanctuary. A taken player can't be revived in place.
- **Not built on voice chat.** Voice chat is optional, and many Roblox players can't use it. No mechanic depends on the microphone.
- **Teach against Roblox reflexes early.** Players will hide in a wardrobe in their first minute. Let them. Hiding works sometimes against some entities, but it's never the universal answer, and the Nightmare (later) punishes it.
- **Tone doesn't reward clowning.** No ragdoll physics played for laughs, and no item that exists mainly for comedy.

---

## 13. Art and audio

These directions apply on top of the Art & Model Brief, which remains the technical source of truth (studs, triangle limits, PBR, naming).

### Visual

- **Seen by flashlight, lightning and the odd failing bulb.** Silhouette and value contrast matter more than surface detail.
- **One high-contrast element per scene**, the lesson from Monochrome: the Dullahan's glowing head, a lit hearth, a single uncovered portrait.
- **The Banshee alone gets a colour nothing else in the game uses.** The proposal is a pale grey-green, from the green dress and grey cloak of folk accounts. Art confirms the exact value, and no other asset or effect may use it.
- **Each entity reads as its culture first, then pushed toward horror.** No zombies, no mutants, no generic tall pale humanoid. That silhouette is worn out on Roblox.
- **Gore only where the folklore needs it** (the Dullahan's head and spine whip). No real-world religious symbols used decoratively.

### Audio

- **The keen is the game's signature sound.** No other sound may resemble it.
- **Silence is a signal.** When the storm goes quiet, a keen has begun. The storm's constant noise is what makes that silence readable.
- **Each entity has its own sound signature, readable from a distance and never shared.** The Dullahan's whip-crack, the bell board's bells, the Aswang's inverted call.
- **Gunshots are loud and carry**, and entities respond to them.
- **No death-screen screamer.** Every scare has a warning.

---

## 14. Failure modes to avoid

| If it drifts into… | The usual cause | The rule that prevents it |
|---|---|---|
| **Action horror** | Spare ammo, fast reloads, groups of enemies, upgrades | Max 1–2 per encounter. Reload of 2.5 s or more. No damage upgrades. Ammo at 70–80% of demand |
| **A Mr. X clone** | The Banshee patrolling or stalking | She appears and never patrols or chases. One keen per wing visit |
| **Chase horror** | Scripted chase routes | Entities give up after line of sight breaks and a short search. No scripted chases outside rare set pieces |
| **An escape-room key hunt** | "Find 4 keys and a code" | Retrieval by reading traces. At most one collect-N objective per chapter. No codes |
| **A jump-scare game** | Scripted screamers | Every scare is warned. The Banshee is always heard first |
| **A walking simulator** | Rooms without decisions | Every zone has a decision (route, risk, entity). A discovery every 4–7 min |
| **A DOORS-style rule list** | Entities that are just a warning plus a reflex | Every entity can be both fought and avoided, and has a non-hostile state |
| **A backrooms maze** | Corridors as content | No pure mazes. Corridors only connect |
| **A lore-wiki game** | Story only in notes | Core truths come from sites and the environment. Notes add detail |
| **A soulslike** | Punishing execution as the source of fear | Fear comes from doubt and dread. Checkpoints every 10–20 min |
| **Friendslop comedy** | Big servers, voice chaos, ragdolls | 4 players max, separation punished, tone that doesn't reward clowning |

---

## 15. Open decisions

Each item has an owner and a recommendation. Close them in this document.

| # | Decision | Recommendation | Owner |
|---|---|---|---|
| 1 | **Story 1's minor killable entity** (section 6) | Pick an Irish folk creature to match the Dullahan and the Banshee: small, fast, low to the ground, cheap to rig. It resolves the first keen. Alternative: move the **Nightmare** forward to the upper bedrooms, which teaches "don't just hide" early | Design and story |
| 2 | **What the Banshee is bound to, and why she can't be secured** | Use the folklore of the banshee's comb: catalogued but missing from its case. The story decides who has it | Story |
| 3 | **The Dullahan's bound object** | The spine whip, in a locked tack case | Story and art |
| 4 | **The Dybbuk's host** (section 6) | A surviving first-crew member, revealed in Story 2 | Story |
| 5 | **The Demon** | Choose a specific culture's entity before any art. Make it a threat that bargains rather than hunts | Design and story |
| 6 | **The Banshee's exact colour** | Pale grey-green, reserved for her | Art |
| 7 | **Keen scope** | Build the full Keen system for Story 1. Fall back to omen-only only if the schedule forces it | Production |
| 8 | **Revive and solo rules** (section 12) | As written. Validate in the first co-op playtest | Design |
