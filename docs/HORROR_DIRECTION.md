# Horror Direction Analysis

Research, comparison and a recommended direction for an exploration-first horror game with occasional combat, killable regular creatures and one creature that can't be killed: the Banshee.

The document follows the order you asked for: **research → analyse → compare → find patterns → find white space → challenge the concept → design options → recommend.** Our game doesn't come up until Part 7.

---

## Part 0: Scope, sources and how far to trust this

### Which games these are

Search results for the four names all pointed to **2021–2026 Roblox horror experiences**. That fits this repository, which is a Roblox (Rojo/Luau) project. I analysed:

| Name you gave | Game I analysed | Confidence |
|---|---|---|
| Monochrome | **MONOCHROME** by paramodal (Roblox, released 3 Aug 2026) | High |
| Locaust | **[BOILED ONE] House of The Locust** by NULLWORKS STUDIOS (Roblox, released 19 Jul 2026) | **Medium.** I found no game spelled "Locaust". Other candidates: a "Locust" survive-the-killer round game and "The Locust Survival" (also Roblox). Tell me if you meant one of those. |
| Mimic | **The Mimic** by MUCDICH (Roblox, Books I–III plus modes) | High |
| Threshold | **THRESHOLD [HORROR]** by Reskioat (Roblox, beta, Episode 1 "DESPAIR") | High. Two other games share the name: *Threshold* (2024, Steam), a short oxygen-rationing train game by an ex-Arkane developer, and *Paranormal Activity: Threshold*. Neither fits the comparison as well. |

### Evidence labels

Every factual claim about a game carries one of these labels:

- **[C] Confirmed.** Stated in an official description, or consistently by several walkthrough/guide sources.
- **[P] Player/community consensus.** Reported by players, guides or videos, and not official.
- **[I] My interpretation.** A design reading I'm making.
- **[S] Speculation.** Plausible but unverified.
- **[U] Unverified.** I couldn't confirm it. Treat as unknown.

### Research limits

- **My web fetch was blocked for Roblox.com, Steam, the fandom wikis and most guide sites.** I worked from search-engine extracts of those pages, not the full pages. **I couldn't watch gameplay footage.** Detailed behaviour (for example exact monster speeds) is therefore marked [P] or [U].
- Many 2026 Roblox "wiki" sites are SEO guide farms, and some are probably AI-written. Where they agree with each other and with official text I used them. Where they're the only source I marked the claim [P].
- The four Roblox games are **live and updated weekly**. Two are labelled pre-alpha or beta, so behaviour can change after this snapshot (early October 2026).
- For the established comparison games (Part 1B) I relied on well-documented, long-standing knowledge of those titles and not on fresh fetches.

### Assumption about your game

Your comparison set is all Roblox, so I assume **Roblox is the likely platform**. That matters in several places: session length, server size, voice-chat availability, audience age and discoverability. I call it out wherever it changes a recommendation. If you're on PC/Steam instead, the design conclusions mostly still hold and the market notes don't.

---

## Part 1: The games

### 1A. The four named games

---

#### MONOCHROME (paramodal, Roblox, 2026)

**Core design**

| Field | Finding |
|---|---|
| Genre | Escape-room horror ("find the items, reach the exit"). Roblox lists it as Puzzle / Escape Room [C] |
| Inspiration | The *Boisvert* surreal web series by Parker Boisvert [C] |
| Camera | First-person [U]. This is typical for the format but I couldn't verify it from footage |
| Movement | Walk, sprint (Shift), interact (E: pry planks, open drawers, hide), torch (F) [C] |
| Exploration structure | A sealed grayscale house connected to a maze of basement corridors [C] |
| Linear vs nonlinear | Nonlinear collection inside one small map. Single fixed exit (an elevator) [C] |
| Level structure | One map. Hub (the house) plus maze (the corridors) [C/I] |
| Encounter frequency | One monster patrols constantly, so contact risk is continuous: roughly every 1–3 minutes in the corridors [I] |
| Combat | None [C/I]. No guide mentions any way to fight |
| Puzzles | Light. Four keys sit in dresser drawers in the basement corridors, and a four-digit elevator code is printed on a slip in the maze [C] |
| Stealth | Closets break line of sight. Hold still while hidden [C] |
| Resources | Torch. Its battery isn't mentioned anywhere [U] |
| Save/checkpoint | None needed: the whole run is 4–20 minutes [C/I] |
| Death | Contact with the monster kills you [C] |
| Progression | None outside the run [I] |
| Length | 10–20 minutes while learning. About 4.5 minutes in solo speedruns [P] |
| Players | Up to 20 per server, fully playable solo [C]. A "Pt. 2" place exists and Part Two is confirmed in progress [C] |

**Horror design**

- **Fear** comes from a **tall black horned silhouette with two white eyes** that kills on contact [C]. It's designed as "presence over anatomy" [C, from guide description]. In a grayscale world, the brightest, highest-contrast thing on screen is the monster's eyes [I].
- **Tension** comes from searching drawers while listening for footsteps [I].
- **Anticipation** is audio first: footsteps, plus a ukulele-like music cue that players report as it approaches [P]. An incongruous, almost cheerful cue is a smart choice: the music sounds wrong for what it announces [I].
- **Vulnerability** is total. There's no counterplay except hiding and distance [C].
- **How often you see the monster:** often. It's a patroller, so you see it many times per run [I].
- **Safe exploration:** the house is relatively safe and the corridors aren't [I/U].
- **Darkness:** lights go out and the torch "keeps you moving once the lights are gone" [C]. The torch doesn't affect the monster [C].
- **Silence and sound:** footsteps are the main alert [C]. Silence means you're safe, so silence is reassuring and not frightening [I].
- **Environmental storytelling:** minimal. The world is mostly mood (grayscale, surreal) [I].
- **Uncertainty:** low. The rules (hear it, hide) are learned in the first encounter [I].
- **Rule-breaking:** one strong instance. The monster sometimes **stops in front of your closet and stares in** before leaving, and players who bolt at that moment get caught [C/P]. That one beat creates doubt about whether it knows you're there.
- **What it relies on:** anticipation and helplessness first, atmosphere second, jump scares on death [I]. No combat and very little psychological horror.

**The monster**

| Question | Answer |
|---|---|
| What is it | Unnamed tall horned black figure with white eyes [C] |
| What the player knows | Nothing about its nature. Everything about its rules after one encounter [I] |
| Trigger and detection | Patrols. Reacts to line of sight. Exact sound detection isn't documented [C/U] |
| Kill, avoid, escape, disable | Kill: no. Avoid: yes. Escape: yes, by hiding. Disable: no [C/I] |
| Predictability | High. A single behaviour set [I] |
| Warning | Strong: footsteps and a music cue [C/P] |
| Speed | Not documented [U] |
| Danger | Instant death [C] |
| Repeated exposure | Becomes less frightening quickly. Speedrunners route around it [I/P] |
| Optimal response | Listen, hide in a closet, stay still through the stare, move on [C] |
| Interesting decisions | Few. The only real choice is "search one more drawer, or hide now?" [I] |

**Philosophy.** *"You know exactly what is hunting you and exactly what you need. The fear lives in the gap between the drawer and the closet."* [I]

**Emotional ranking** [I]: 1) Anticipation 2) Anxiety 3) Vulnerability 4) Disorientation (grayscale maze) 5) Paranoia (the stare) 6) Surprise 7) Isolation (only when solo) 8) Curiosity (surreal visuals, little payoff) 9) Dread (low, because the threat is known and cyclical). Anticipation ranks first because the whole game is the space between hearing it and seeing it. Dread ranks low because nothing unknown builds up.

**Assessment**

- **Five strongest decisions**
  1. Grayscale as a legibility system. With colour removed as information, the white eyes become the loudest thing on screen. The art direction is doing the gameplay work [I].
  2. A silhouette monster. It never looks like a cheap model, because it never shows you a model [I].
  3. The closet stare. It rewards stillness and punishes panic, and it breaks the rule "hiding = safe" for just long enough [I].
  4. A brutally clear objective (four keys plus a code). It's perfect for short Roblox sessions and for streamers explaining it in five seconds [I].
  5. Audio-first warnings using an incongruous music cue [I].
- **Five weakest decisions**
  1. A fixed code (5343) and fixed key locations. Guides spoil them immediately and replay collapses into a 4.5-minute route [C/I].
  2. One monster with one behaviour. Mastered by the second run [I].
  3. Closets as the universal answer, the genre's most worn mechanic [I].
  4. Instant death on contact, with nothing between safe and dead [I].
  5. 20-player servers. Group play turns isolation into chaos [I].
- **Most memorable mechanic:** the stare while you're hidden.
- **Most memorable horror concept:** white eyes in a world without colour.
- **Biggest source of tension:** searching while you can hear footsteps.
- **Biggest frustration:** maze disorientation plus one-touch death [P/I].
- **What players remember:** the eyes and the closet.
- **Boring if copied:** keys plus code plus closet plus patrolling monster.
- **Don't imitate:** fixed solutions, hiding as the universal answer, a map that's only a maze.

---

#### HOUSE OF THE LOCUST (NULLWORKS STUDIOS, Roblox, 2026), assumed to be "Locaust"

**Core design**

| Field | Finding |
|---|---|
| Genre | Escape/survival horror, pre-alpha [C]. Rated Moderate (13+) [C] |
| Creature | The Locust, designed by analog-horror creator Doctor Nowhere [C, per community wikis]. The title tag "[BOILED ONE]" points to that creator ecosystem [C] |
| Movement | Walk, sprint, crouch, **slide (Shift+C)** into narrow passages the Locust can't follow, crawl through vents [C] |
| Exploration structure | The Locust's "nest": a maze of green-wallpapered hallways, chandeliers, a library, a dark room and hidden crawl spaces [C] |
| Linear vs nonlinear | Fixed objective chain, nonlinear order within it [C] |
| Objectives | Find three coloured boxes, drag them to the matching red/blue/yellow floor pads to get **wirecutters**, find a **key**, and take a **keycard that the Locust carries** [C] |
| Encounter frequency | Constant patrol pressure. Average session about 6 minutes [P] |
| Combat | None at all [C] |
| Puzzles | Physical: carrying boxes under threat [C] |
| Stealth | Noise-based. Sprinting attracts it. Wall text reads "KEEP A LOW PROFILE OR HE SHALL COME" [C] |
| Death | Touching the Locust is instant death [C] |
| Win rate | The "Escaped" badge has about an 11% community-reported win rate. World record is about 1:10 [P] |
| Players | Up to 50 per server [C] |

**Horror design**

- **Fear:** a tall, slender, pale, red-lit face, heard before seen through heavy footsteps and breathing [C/P].
- **Tension:** you have to approach the monster to take the keycard, by sneaking up behind it or grabbing it through a wall gap [C]. **This is the most interesting idea in the comparison set.**
- **Detection:** players describe three states: roam, investigate sprint noise, and pursue on line of sight [P]. It speeds up during chases [P].
- **Darkness:** one dark room needs the flashlight. Guides advise turning the light off when the Locust is near [P]. Whether light actually affects detection is [U].
- **Rules:** clear and stated diegetically on the wall [C].
- **What it relies on:** pursuit, helplessness and noise discipline. Jump scares on death [I].

**The monster**

| Question | Answer |
|---|---|
| Kill / avoid / escape / disable | No / yes / yes (slide spaces, breaking line of sight) / no [C] |
| Detection | Sound (sprinting) and line of sight [P] |
| Predictability | Medium. It patrols but investigates noise [P] |
| Warning | Footsteps and breathing [C] |
| Speed | Faster than walking and accelerates in chase [P] |
| What's scary | You have to go to it [I] |
| Optimal response | Short movement bursts, crouch, use geometry, take the card from behind, then run a pre-planned route [C/P] |
| Interesting decisions | **Yes, because of the keycard.** It turns "avoid the monster" into "study the monster" [I] |

**Philosophy.** *"The thing you need is on the thing that kills you."* [I]

**Emotional ranking** [I]: 1) Anxiety 2) Vulnerability 3) Anticipation 4) Helplessness 5) Paranoia 6) Surprise 7) Disorientation (maze) 8) Dread 9) Curiosity (low). With a 50-player server, isolation is barely present.

**Assessment**

- **Five strongest decisions**
  1. The keycard on the monster. Approach becomes mandatory and the creature turns from obstacle into objective.
  2. Diegetic rule text ("KEEP A LOW PROFILE…") teaches the system without a tutorial.
  3. Slide-only spaces give the player spatial counterplay without combat.
  4. A creature people already recognise brings instant audience recognition.
  5. Physical box-carrying makes the player slow and visible while doing a task.
- **Five weakest decisions**
  1. Borrowed creature IP, so the game's identity belongs to someone else.
  2. An 11% win rate [P] with one-touch death. Mastery is enjoyable for a few and churn-inducing for most [I].
  3. 50-player servers. The monster becomes a crowd event [I].
  4. A fixed objective chain. Once learned it's a 70-second route [P/I].
  5. Pre-alpha behaviour drift. Spawns and AI change between updates [C].
- **Most memorable mechanic:** the keycard pickpocket.
- **Most memorable horror concept:** being forced to walk toward it.
- **Biggest source of tension:** the approach for the keycard.
- **Biggest frustration:** instant death, low win rate, and slide timing [P/I].
- **What players remember:** "you have to steal from it."
- **Boring if copied:** coloured blocks on pads, key, keycard, door.
- **Don't imitate:** borrowed creature identity, a fixed chain, mass servers.

---

#### THE MIMIC (MUCDICH, Roblox, episodic since about 2021 [U on exact date])

**Core design**

| Field | Finding |
|---|---|
| Genre | Chapter-based story horror based on Japanese folklore (yokai, onryō, oni) [C] |
| Structure | Books: **Control's Book** (I), **Jealousy's Book** (II), **Rage's Book** (III). **Rebirth's Book** (IV) is announced. Plus *The Witch Trials* (prequel mode) and **Nightmare Mode** [C] |
| Players | Up to 5 per chapter [C] |
| Movement | First-person walk, sprint, interact [I/U on details] |
| Exploration structure | Authored chapters. Book I is **maze-heavy** (collect keys or "butterfly spirits" to open paths). Book II "lacks mazes", focuses more on exploration and puzzles, and runs about 40 minutes longer [C, per wiki] |
| Linear vs nonlinear | Linear chapter order. Local nonlinearity inside mazes [C/I] |
| Encounters | Scripted chases, roaming antagonists, arena encounters (for example Saigomo in a sakura arena, which players single out for difficulty) [P] |
| Combat | Essentially none. The player escapes and solves [C/I] |
| Puzzles | Frequent: riddles, keys, item puzzles [C] |
| Stealth | Avoidance and hiding inside mazes [C/I] |
| Death | Lives. Nightmare Mode gives **one life (more can be bought with Robux)**, faster monsters, better monster vision and darker mazes [C] |
| Progression | Narrative progression across books [C] |
| Length | Multiple hours across books. Individual chapters run from tens of minutes to (in Nightmare) reports of hours [P] |

**Horror design**

- **Fear** comes from authored yokai designs, chases and jump scares [C].
- **Tension** comes from chases through mazes and arena survival [C/P].
- **Anticipation and dread** come from folklore framing, a single flashlight, slow corridors, and the "face-stealing" premise [C, guide descriptions].
- **Environmental storytelling:** strong set dressing (shrines, villages), with deep lore around "Four Beasts" [C]. Much of the lore is understood through community wikis [I/P].
- **Rules:** chapter-specific. Each chapter introduces new antagonists [C].
- **What it relies on:** chase plus atmosphere plus jump scares plus lore [I].

**Monsters** (general pattern across the cast: Kintoru, Enzukai, Netamo, Yūma, and others such as Shinigami, Hyakume and Kishin [C names])

| Question | Answer |
|---|---|
| Kill | Generally no. Antagonists are escaped, not killed [I] |
| Avoid / escape | Yes, by navigating mazes and chases [C] |
| Predictability | Medium to high once a chapter is learned [I] |
| Danger | High in Nightmare Mode [C] |
| Repeated exposure | Becomes trial-and-error routing [P/I] |
| Interesting decisions | Mostly routing. Chases test execution more than judgement [I] |

**Philosophy.** *"Folklore made physical: each chapter is a haunted tale you have to get out of."* [I]

**Emotional ranking** [I]: 1) Dread 2) Curiosity (lore) 3) Anxiety (chases) 4) Surprise (jump scares) 5) Disorientation (mazes) 6) Helplessness 7) Vulnerability 8) Isolation (diluted by a team of 5).

**Assessment**

- **Five strongest decisions**
  1. A coherent cultural identity. Yokai give every monster a reason to look the way it does.
  2. Episodic books build a long-running lore community.
  3. Authored variety: every chapter is a new place with new rules.
  4. Atmosphere and art direction above the Roblox average [C, consistent praise].
  5. Co-op capped at 5, which keeps the friend-group appeal without crowd chaos.
- **Five weakest decisions**
  1. Maze padding. The game's own wiki credits Book II with having "eliminated monotonous gameplay" [C].
  2. Trial-and-error chases and arenas. Reports of a single Nightmare chapter taking up to four hours [P].
  3. **Lives sold for Robux** in Nightmare, which turns death into a purchase prompt [C/I].
  4. Lore lives in wikis more than in play [I].
  5. Unkillable chasers on repeat: after the third death, fear becomes chore [I].
- **Most memorable mechanic:** chapter-specific antagonists with set-piece chases.
- **Most memorable horror concept:** familiar faces worn by something else (the "mimic").
- **Biggest source of tension:** a chase in an unfamiliar maze.
- **Biggest frustration:** dying to the same chase repeatedly [P].
- **What players remember:** the creature designs and the lore.
- **Boring if copied:** "maze plus collect N items plus chase plus jump scare."
- **Don't imitate:** mazes as padding, monetised lives, lore that only exists on a wiki.

---

#### THRESHOLD (Reskioat, Roblox, beta 2026)

**Core design**

| Field | Finding |
|---|---|
| Genre | Story horror (Episode 1 "DESPAIR") plus a replayable Chase Mode [C] |
| Story structure | **One night in 25 chapters**, from a phone call at 1 a.m. to a ladder at sunrise. Became Episode 1 on 20 Sep 2026 [C] |
| Story activities | Investigation, **camera objectives**, quick-time escapes, defensive scenes, tasks, **Sanity** [C] |
| Creature | "A tall, pale thing that is **afraid of light and gets bigger in the dark**." Called the Entity in Story and **Eli** in Chase [C] |
| Light as a tool | The **camera flash blinds** the entity, for example in the car park and the bedroom [C] |
| Chase Mode | Underground tunnel maze. Eli hunts you, **listens to your microphone and talks back**. Lives, revives, a radar, and maintenance keys deposited at the exits [C] |
| Social twist | At the mall an NPC, **Scrow**, tells you the mall is safe and that all you need is the password, then calls the monster on you [P, widely shared clip] |
| Players | Story up to 4, Chase up to 10 [C] |
| Death | Lives and revives [C] |
| Length | A full Story run appears in single-video walkthroughs (roughly 1 hour or more) [U] |

**Horror design**

- **Fear:** a pale giant that grows when it's dark [C], and an enemy that hears you, the real person [C].
- **Tension:** light management (darkness literally feeds the threat) plus self-censorship on the mic [I].
- **Uncertainty:** "Repeating a phrase from a recording does not promise the same reaction in your round" [C, wiki]. That's deliberate opacity.
- **Psychological horror:** sanity, betrayal by an NPC, and your own voice as a liability [C/I].
- **What it relies on:** paranoia, pursuit, QTEs, novelty [I].

**The monster (Entity / Eli)**

| Question | Answer |
|---|---|
| Kill | No [C/I] |
| Disable | Temporarily, by blinding it with the camera flash [C] |
| Detection | Sight, plus voice in Chase [C] |
| Environmental scaling | Grows in darkness [C] |
| Warning | Radar in Chase [C] |
| Interesting decisions | **Yes:** when to flash, whether to speak, where light is [I] |
| Repeated exposure | The voice gimmick wears off once players simply mute [I] |

**Philosophy.** *Story:* "Light is safety and you are running out of night." *Chase:* "You are the noise." [I]

**Emotional ranking** [I]: 1) Paranoia 2) Anxiety 3) Vulnerability 4) Surprise 5) Anticipation 6) Dread 7) Helplessness 8) Curiosity 9) Disorientation (tunnels).

**Assessment**

- **Five strongest decisions**
  1. **The player's real voice as a threat.** The horror is self-generated and the screams themselves are the danger.
  2. **A monster scaled by darkness.** Light becomes a non-lethal combat verb (the flash) [I].
  3. **A one-night time spine** (1 a.m. to sunrise): a structure players can feel progressing.
  4. **Betrayal by an NPC.** Social horror is rare on Roblox [I].
  5. Two modes: authored story plus a replayable chase.
- **Five weakest decisions**
  1. **The voice mechanic excludes many players.** Roblox voice chat requires age verification, so a large share of the audience never experiences the headline feature [I; voice-chat eligibility rules are Roblox policy, verify the current terms].
  2. **Opaque rules** ("no promise of the same reaction") feel random [I].
  3. **QTEs**: low agency, and the move from horror to execution test is jarring [I].
  4. **Lives, revives and radar** in Chase cut into vulnerability [I].
  5. 25 chapters in one night risks fragmentation and pacing whiplash [S].
- **Most memorable mechanic:** Eli talking back to what you said.
- **Most memorable horror concept:** a monster that grows in the dark.
- **Biggest source of tension:** deciding not to speak.
- **Biggest frustration:** unclear voice triggers, beta bugs [C: "bugs are expected"].
- **What players remember:** "it heard me."
- **Boring if copied:** "monster hears your mic." It's already copied from the *Lethal Company* lineage (see below).
- **Don't imitate:** QTEs and opaque rules.

---

### 1B. Additional comparison games: why these and not others

I chose each one for a **specific structural reason related to your concept**, not for fame.

| Game | Why it belongs here |
|---|---|
| **Resident Evil 2 (2019)** | The canonical **"killable regulars plus one unkillable stalker (Mr. X)"** structure. It's the closest existing analogue to your Banshee plan, and the clearest warning. |
| **Alien: Isolation (2014)** | An unkillable primary threat run by an **AI director**, with killable secondary enemies. It's the best study of how long an unkillable creature stays scary, and when it stops being scary. |
| **Amnesia: The Bunker (2023)** | **Exploration-first, semi-open, scarce revolver, one unkillable Beast drawn by noise.** The closest whole-game match to "exploration + occasional combat + unkillable thing". |
| **Signalis (2022)** | **Combat exists but is secondary**, enemies revive unless their bodies are dealt with, and inventory is tight. The best model for "each enemy has a death that matters". |
| **Lethal Company (2023)** | A **rule-based creature roster where some can be killed and others can't**, built on an exploration/scavenging loop. It's the ancestor of Threshold's voice mechanic and of the co-op "friendslop" wave on Roblox. |
| **DOORS (Roblox, 2022–)** | The **platform's dominant template**: each entity is a rule. It defines what Roblox players already expect, which is your cliché baseline. |

Brief references only: *SOMA* (exploration with rare monsters, plus a "safe mode"), *Silent Hill 2* (the radio as a warning system, and Pyramid Head as an untouchable symbol), **Phasmophobia** (it has a ghost type literally called *Banshee*, which matters for originality, see Part 12), *Darkwood* (a day/night preparation loop), *Pressure* (a Roblox DOORS-like).

These are long-established, widely documented games. Facts below are [C] unless marked.

---

#### Resident Evil 2 (Capcom, 2019)

- **Core:** third-person survival horror. A semi-open police station plus linear later areas. Scarce ammo, a grid inventory, save rooms with typewriters. Puzzles are frequent, combat is regular but costly, and the game runs 6–10 hours per campaign.
- **Enemies:** zombies take many headshots and can get up again. Lickers are blind and hear you, so you walk past them. **Mr. X (Tyrant)** is unkillable and stalks the station: audible heavy footsteps, follows noise and gunfire, can be staggered by damage but never killed, and won't enter save rooms.
- **Philosophy:** *"You can fight anything except the thing that matters, and every bullet you fire is a bullet you don't have later."* [I]
- **Emotions:** Anxiety > Vulnerability > Anticipation (footsteps) > Dread > Empowerment (brief) > Surprise.
- **Strongest:** footsteps as constant information. Save rooms as sanctuaries. Zombies that stay "dead" uncertainly. The Licker teaching "don't run". Mr. X breaking the safety of solved spaces.
- **Weakest:** Mr. X becomes **an annoyance after the first hour** for many players [P]. Optimal play is to kite him around a loop. Backtracking with him is tedious. Damage sponges. Ammo pinch spikes.
- **Lesson for you:** an unkillable stalker is terrifying for about 30–60 minutes and then becomes **traffic**. **Your Banshee must not be a Mr. X.**

#### Alien: Isolation (Creative Assembly, 2014)

- **Core:** first-person stealth survival on a space station. Linear-ish with backtracking. Crafting. Manual save stations (a tense save with a countdown). Long, around 15–20 hours.
- **Enemies:** the Xenomorph is unkillable. Two-layer AI: a "director" that always knows roughly where you are and keeps the Alien near you, and the Alien's own senses that have to actually find you. A flamethrower drives it off temporarily. Androids and humans can be killed.
- **Philosophy:** *"Something intelligent is hunting you and it is learning."* [I, based on the game's widely discussed AI behaviour]
- **Emotions:** Dread > Paranoia (the motion tracker) > Vulnerability > Anxiety > Helplessness.
- **Strongest:** the motion tracker as imperfect information. A drive-away tool that doesn't kill. Its learned resistance to your tactics. Hiding that isn't absolutely safe. Sound everywhere.
- **Weakest:** **far too long** for its single threat [P, a common criticism]. Saves are punishing. Late-game fatigue. Android sections are slow. Several "false endings".
- **Lesson for you:** an unkillable creature needs **a tool that pushes it away without killing it**, and **a limited screen time budget**.

#### Amnesia: The Bunker (Frictional Games, 2023)

- **Core:** first-person semi-open survival horror in a WWI bunker. **A revolver with very few bullets.** Grenades and traps. A generator whose fuel powers the lights (light is a resource). Some item and code locations are randomised. Saves only in a safe room. Around 4–6 hours.
- **Enemies:** **the Beast**, unkillable, moves through the walls and tunnels, **drawn by noise**, and can be driven back by gunfire. Rats (killable, dangerous in the dark).
- **Philosophy:** *"Every action you take is heard."* [I]
- **Emotions:** Anxiety > Dread > Vulnerability > Anticipation > Resourcefulness (an "Other" category: planning).
- **Strongest:** light as a fuel economy. Noise as a cost. Semi-open problem-solving with multiple solutions. A gun that solves a moment but not the monster. Randomisation that defeats guides.
- **Weakest:** the Beast's ubiquity becomes routine. Trial and error when plans fail. Fiddly item management [P/I].
- **Lesson for you:** **combat should create a new problem (noise) while solving the current one.**

#### Signalis (rose-engine, 2022)

- **Core:** top-down/third-person survival horror. Six inventory slots. Save rooms. Combat-secondary. Dreamlike narrative. Around 8–10 hours.
- **Enemies:** Replika units that **get back up unless their bodies are burned** (thermite/flares). Different variants (armoured, crawling, fast) each need a response.
- **Philosophy:** *"Killing is a cost, not a solution."* [I]
- **Emotions:** Dread > Melancholy (Other) > Disorientation > Anxiety > Curiosity.
- **Strongest:** **death is a state, not an ending**. A tight inventory forces decisions. Environmental storytelling. Radio frequencies as exploration. Enemies that block spaces you'll return to.
- **Weakest:** opaque narrative alienates some players. Inventory friction. Combat feels stiff [P].
- **Lesson for you:** **a creature's death can be a mechanic, not a cosmetic.**

#### Lethal Company (Zeekerss, 2023)

- **Core:** first-person co-op scavenging horror. Procedurally generated facilities. A quota loop. Proximity voice. Run-based.
- **Enemies, each a rule:** Coil-head (moves only when unobserved), Bracken (stalks and is angered by eye contact), Jester (winds up, then everyone has to leave), Eyeless Dogs (blind, **hunt by sound including voice**), Thumper (fast in straight lines). **Some can be killed with a shovel or shotgun, others can't.**
- **Philosophy:** *"Every creature is a puzzle with a lethal wrong answer."* [I]
- **Emotions:** Anxiety > Surprise > Paranoia > Comedy (Other) > Vulnerability.
- **Strongest:** a mix of killable and unkillable creatures. Rules discovered by dying. Voice as diegetic noise. Variety from combinations. Tension from greed (one more item).
- **Weakest:** horror decays into comedy with friends. Repetitive facilities. Rule mastery kills fear [P/I].
- **Lesson for you:** **"different rules per creature" is a strong framework, and with groups it turns into comedy.**

#### DOORS (LSPLASH, Roblox, 2022–)

- **Core:** first-person, 100 procedurally arranged rooms per floor (plus later floors). Items (lighter, crucifix, etc.). No combat. Revives. Runs of 20–40 minutes.
- **Enemies, each a rule:** Rush (lights flicker, so hide), Ambush (comes back several times), Seek (eyes on the walls, then a chase), Figure (blind, hears you), Screech (look at it), Eyes (don't look), Halt (reverse).
- **Philosophy:** *"Learn the rules, read the warnings, react correctly."* [I]
- **Emotions:** Anticipation > Surprise > Anxiety > Mastery (Other).
- **Strongest:** warning-then-rule clarity, procedural variety, short sessions, a recognisable cast, excellent Roblox fit.
- **Weakest:** horror becomes a reflex test, entity lists start to feel like flash cards, and the template is now copied everywhere on Roblox [I].
- **Lesson for you:** **on Roblox, "lights flicker so hide in a closet" is already a reflex.** Players will try it on your game in their first minute.

---

## Part 2: The core horror philosophy of each game

| Game | "What is this game actually trying to make the player feel?" | Fear source |
|---|---|---|
| **Monochrome** | "It's coming and I'm not done." | Known threat, known goal, not enough time |
| **House of the Locust** | "I have to go toward it." | Forced proximity |
| **The Mimic** | "I'm inside a cursed story that wants me." | Authored folklore and pursuit |
| **Threshold** | "My own light, and my own voice, decide whether I live." | Self-generated danger |
| **RE2** | "I can fight everything except the thing that matters." | Scarcity plus an unstoppable stalker |
| **Alien: Isolation** | "It is smarter than me and it is close." | Intelligent hunter |
| **Amnesia: The Bunker** | "Everything I do makes noise." | Consequence |
| **Signalis** | "Nothing stays dead, including the past." | Grief and futility |
| **Lethal Company** | "Every creature has a rule, and I don't know this one yet." | Unknown rules |
| **DOORS** | "Read the warning, do the right thing." | Reaction test |

**Pattern** [I]: the four Roblox games all aim for **anxiety and anticipation**, short and spiky. Only the premium games (RE2, Alien, Bunker, Signalis) build **dread**, the slow, long-term fear that something bad is coming. **Dread is underrepresented in your direct competitive set.** That's the first white-space signal.

Emotional rankings for each game appear in Part 1 alongside the game.

---

## Part 3: Summary of what works

Detailed strongest/weakest lists for each game are in Part 1. Distilled:

| | Steal the principle | Don't copy the implementation |
|---|---|---|
| Monochrome | Art direction as a legibility system. A silhouette monster. A beat that breaks the hiding rule. | Fixed codes, closets as the answer, one monster |
| Locust | The objective sits on the monster. Diegetic rule text. Spaces only the player can use. | Borrowed IP, mass servers, one-touch death |
| The Mimic | Cultural coherence. Chapter variety. Lore as long-term draw. | Maze padding, chase trial-and-error, paid lives |
| Threshold | The player's own behaviour is the danger. Light as a non-lethal weapon. A time spine. | QTEs, opaque rules, a feature locked behind voice eligibility |
| RE2 | Footsteps as information. Sanctuaries. | A stalker who becomes traffic |
| Alien: Isolation | A drive-away tool. A screen time budget. An AI director. | Running long beyond what the threat can support |
| Bunker | Combat creates noise. Light as fuel. | Ubiquitous threat |
| Signalis | Death as a state. Tight inventory. | Opacity for its own sake |
| Lethal Company | Different rules per creature, killable vs unkillable. | Comedy collapse |
| DOORS | Warning, then rule. | Flash-card entities |

---

## Part 4: Comparison matrix

Scores are 0–5 (0 = absent, 5 = defining feature). All scores are [I], my reading of the evidence above.

| Category | Mono-chrome | Locust | Mimic | Thres-hold | RE2 | Alien:I | Bunker | Signalis | Lethal Co. | DOORS |
|---|---|---|---|---|---|---|---|---|---|---|
| Exploration | 2 | 2 | 3 | 3 | 4 | 3 | 5 | 4 | 4 | 2 |
| Exploration freedom | 2 | 2 | 1 | 1 | 3 | 2 | 4 | 3 | 4 | 1 |
| Combat | 0 | 0 | 0 | 1 (flash) | 4 | 2 | 2 | 3 | 2 | 0 |
| Enemy frequency | 5 | 5 | 4 | 4 | 4 | 4 | 4 | 3 | 4 | 4 |
| Enemy variety | 1 | 1 | 4 | 1 | 3 | 2 | 2 | 3 | 5 | 5 |
| Enemy intelligence | 1 | 2 | 2 | 2 | 2 | 5 | 3 | 2 | 2 | 1 |
| Player vulnerability | 5 | 5 | 4 | 4 | 3 | 5 | 4 | 3 | 4 | 4 |
| Resource management | 0 | 0 | 1 | 2 | 5 | 3 | 5 | 5 | 3 | 2 |
| Environmental storytelling | 1 | 2 | 3 | 3 | 4 | 4 | 4 | 5 | 2 | 1 |
| Puzzles | 2 | 2 | 4 | 2 | 4 | 1 | 3 | 4 | 1 | 2 |
| Stealth | 3 | 4 | 3 | 2 | 2 | 5 | 4 | 1 | 3 | 3 |
| Atmosphere | 4 | 3 | 4 | 3 | 4 | 5 | 5 | 5 | 3 | 3 |
| Sound design (as gameplay) | 3 | 4 | 3 | 5 | 5 | 5 | 5 | 3 | 5 | 4 |
| Visual horror | 4 | 3 | 4 | 3 | 4 | 4 | 3 | 4 | 2 | 3 |
| Psychological horror | 2 | 1 | 2 | 4 | 1 | 2 | 2 | 5 | 1 | 1 |
| Jump scares | 3 | 3 | 4 | 4 | 2 | 2 | 2 | 1 | 3 | 4 |
| Dread (slow fear) | 1 | 1 | 3 | 2 | 3 | 4 | 4 | 5 | 2 | 1 |
| Pursuit/chase reliance | 3 | 4 | 5 | 4 | 3 | 3 | 3 | 1 | 3 | 3 |
| Rule clarity | 5 | 4 | 3 | 2 | 4 | 3 | 4 | 3 | 2* | 5 |
| Rule violation (deliberate) | 2 | 1 | 2 | 3 | 2 | 4 | 2 | 3 | 1 | 1 |
| Replayability | 2 | 2 | 2 | 3 | 3 | 2 | 4 | 2 | 5 | 5 |
| Tension | 4 | 4 | 4 | 4 | 4 | 5 | 5 | 4 | 4 | 4 |
| Creature encounters as decisions | 1 | 3 | 1 | 3 | 3 | 4 | 4 | 4 | 4 | 2 |
| Narrative | 1 | 1 | 4 | 4 | 3 | 3 | 3 | 5 | 1 | 2 |
| Safe spaces / sanctuaries | 1 | 0 | 1 | 1 | 5 | 2 | 4 | 5 | 3 | 1 |
| Session length fit for Roblox | 5 | 5 | 3 | 3 | n/a | n/a | n/a | n/a | n/a | 5 |
| Originality (in 2026) | 2 | 3 | 3 | 3 | 3 | 4 | 3 | 4 | 4 | 3 |

\*Lethal Company's rules are clear once learned but undiscoverable without dying.

**What the matrix says** [I]:

1. **In your direct competitors, combat is zero.** "Exploration horror with real but secondary combat" is uncontested in the Roblox set. That's an opportunity, and also a sign that the platform audience isn't trained for it.
2. **Your competitors have very low dread, safe spaces, resource management and environmental storytelling.** The premium games carry all four.
3. **Creature encounters as decisions** are weak in the Roblox set (Monochrome and Mimic score 1). The Locust's keycard and Threshold's flash are the exceptions, and they're the most-discussed features.

---

## Part 5: The common formula

### What these games have in common

- **A single, mostly unkillable primary threat** that patrols or chases. True in every Roblox title, and in RE2, Alien and Bunker for the "big" threat.
- **Audio-first warning:** footsteps, breathing, music cues, flickering lights.
- **Hiding as the universal counterplay:** closets, lockers, vents.
- **Keys/codes/items as the objective grammar.**
- **Instant or near-instant death on contact** (all four Roblox titles).
- **Tall, thin, pale or black humanoid monsters.** Monochrome, Locust and Threshold **all** use a tall, slender humanoid [C]. That's three of four.
- **Interior mazes:** houses, corridors, tunnels, malls.

### Repeated horror mechanics

Closets/lockers · sprinting makes noise · flashlight · lights going out before an entity arrives · chase sequences · notes and documents · "find N items" · jump scare on death · sanity meters · line-of-sight breaking.

### Repeated pacing structure

**Roblox:** constant mid-level pressure with spikes (the patroller is always somewhere). There's no true rest and no true build-up. Sessions run 5–20 minutes.

**Premium:** explore (low) → threat signs (rising) → encounter (peak) → sanctuary (rest) → reveal (reward). Over and over, on a 10–20 minute wave.

### Repeated enemy behaviours

Patrol paths · investigate noise · lock on with line of sight · chase · lose you if line of sight breaks · check hiding spots (the "stare") · instant kill.

### Repeated environments

Houses and mansions · basements · corridor mazes · tunnels · malls and parking garages · hospitals, schools, facilities · liminal/backrooms spaces. **Almost entirely interior, almost entirely urban or domestic.**

### Repeated player behaviours

Listen → crouch → peek → dash → hide → wait → sprint to the objective. Speedrunners and guide readers turn every game into a route.

### What creates tension across the set

1. Knowing the threat is near without knowing exactly where.
2. Being forced to do something slow (search, carry, read) while exposed.
3. Being forced toward the threat (the Locust keycard, a key in a monster's room).
4. Resources running out (light, ammo, lives).

### Genre clichés in 2026

| Cliché | Status |
|---|---|
| Hide in a closet/locker | **Exhausted** |
| Find N keys plus a code | **Exhausted** |
| Tall slender pale humanoid | **Exhausted on Roblox** |
| Lights flicker = entity coming | **Exhausted** (DOORS owns it) |
| Instant kill on touch | Overused |
| Corridor maze as the level | Overused |
| Scripted chase with a set route | Overused |
| Sanity meter | Overused, usually cosmetic |
| Notes as the only storytelling | Overused |
| Voice-chat detection | **Fresh in 2023, becoming a trend** (Lethal Company → Threshold and others) |

### Ideas that still feel fresh

- **The objective carried by the monster** (Locust).
- **Light as a non-lethal weapon that also changes the monster** (Threshold).
- **Death as a state that stays in the world** (Signalis).
- **Combat that causes a new problem** (Bunker's noise).
- **Threats that grade information** (Alien's motion tracker).
- **NPC betrayal** (Threshold's Scrow).
- **Art direction as a gameplay readout** (Monochrome).

### The genre formula

**Roblox horror formula (2026):**

> **Spawn sealed → receive item list → explore a maze → hear the monster → hide/run → collect → hear it again → exit.**

**Premium exploration horror formula:**

> **Explore → find something wrong → get a warning → encounter → escape/fight → rest in a safe room → learn something → unlock deeper → repeat with higher stakes.**

**Is it effective?** Yes. It works because it alternates threat and relief, and that's how tension is produced.

**Is it overused?** The **Roblox formula** is saturated. The **premium formula** is *familiar but not saturated on Roblox*, because almost no one on the platform has the scope or patience to build it.

**Can it be reinvented?** Yes, but not by removing steps. Change **what the encounter step means**: make it a decision instead of a reflex, and make its consequence carry into the next exploration step.

---

## Part 6: The white space

### Underrepresented horror experiences

1. **Dread over a long arc.** The Roblox set is all spikes. Nobody builds slow-burn fear over 60+ minutes.
2. **Grief and mourning.** Horror about loss, not about being chased. Signalis touches it. Nobody on Roblox does.
3. **Omens and prophecy.** Being *told* something bad will happen, and choosing how to meet it. Almost no game uses foretelling as a mechanic.
4. **Outdoor/rural dread.** Open space where you can see far and still feel unsafe.
5. **Agency horror:** fear of your own choices and their consequences, not fear of a monster.

### Rarely used enemy behaviours

- **Enemies reacting to each other** (a creature that feeds on another's corpse, a creature drawn to another's death cry).
- **Enemies that use the environment** (closing doors, putting out lights).
- **Enemies that are only dangerous in specific conditions** (water, darkness, silence, being watched).
- **Enemies with non-hostile states** (grazing, sleeping, mourning).
- **Threats that judge rather than hunt.**
- **An unkillable entity that isn't a chaser.** Almost every unkillable monster (Mr. X, Alien, Beast, Locust, Mimic) *pursues*. **An unkillable thing that does something other than chase is close to unexplored.**

### Underused exploration structures

- **Hub with expeditions** (Darkwood, Lethal Company). On Roblox this is mostly used for lobbies, not for diegetic home bases.
- **Knowledge-gated progression** (Outer Wilds): you progress by understanding, not by finding keys.
- **Environments that change between visits** because of what you did.
- **Time-gated spaces** (tides, daylight) that reshape the map.

### Underused environments

Bogs and marshes · tidal flats and causeways · quarries · lighthouses · funeral homes and wake houses · rural parishes · mills and weirs · ferry crossings · peat-cutting fields · farms at night. **Anything outdoor, rural, wet, or ritual.**

### Underused player decisions

- **Whether to fight at all** (when fighting has a cost).
- **Who or what to sacrifice** (lure a creature into another, let one die).
- **When to stop exploring** (greed vs safety).
- **Whether to follow or avoid the dangerous thing** (when it also leads to information).

### Underused forms of vulnerability

- **Informational vulnerability:** knowing something is wrong and not knowing what.
- **Positional vulnerability:** being low, in water, in the open.
- **Social vulnerability:** NPC betrayal, an unreliable companion.
- **Commitment vulnerability:** committing to a slow action (reloading, carrying, climbing) you can't cancel.

### Underused forms of combat

- **Range-and-timing duels:** one slow, decisive shot against an approaching thing (*"can I kill it before it reaches me?"*). Your premise is **exactly this white space.**
- **Environmental kills:** luring creatures into hazards.
- **Combat whose aftermath matters:** corpses as lures, light, noise, food for other creatures.
- **Non-lethal combat verbs:** stun, blind, repel, bind.

### Underused non-combat interaction

- **Observation as a verb:** watch creatures to learn them (a field journal).
- **Ritual actions:** cover mirrors, stop clocks, open windows for the dead. Folklore rules that *work*.
- **Mourning and acknowledgement:** interacting with the dead (bodies, graves) as a gameplay act.

### What makes a game feel different without becoming a gimmick

A mechanic stops being a gimmick when it does all three:

1. **It appears constantly**, not as a one-off.
2. **It interacts with the core loop.**
3. **It carries meaning** (theme), not only novelty.

Threshold's mic mechanic fails (1) and (2) for many players. The Locust's keycard passes (2) but appears once. **Your differentiator has to be in the loop every minute.**

---

## Part 7: Your concept as stated

- Primarily **exploration horror**.
- Combat exists but **isn't the central loop**.
- Most of the game: exploring, discovering, finding clues, understanding the world, navigating danger, occasional creatures.
- **Regular enemies, not bosses.**
- Combat tension: *"Can I kill this thing before it reaches me?"*
- Each monster has its own identity, behaviour, danger profile and death.
- **The Banshee can't be killed** and should create a fundamentally different kind of tension.
- Pillars: **exploration → discovery → atmosphere → occasional danger → survival**.

### My read

The concept is **well positioned**. It sits in the white space between the Roblox set (zero combat, all-spike tension) and premium survival horror (heavier combat, scarcity). Its two most promising pieces are:

1. **"Can I kill this thing before it reaches me?"** That's a range-and-timing duel, an underused form of combat (Part 6).
2. **An unkillable entity in a world where everything else can be killed.** This makes the Banshee *meaningful by contrast*, as long as it isn't another chaser.

There are serious risks, though. Part 8 covers them.

---

## Part 8: Challenging your design

### 1. "Can I kill this thing before it reaches me?" is an action question, not a horror question

That question is about **competence**. Once the player can answer "yes" reliably, the creature becomes a **target**. Horror depends on doubt about the answer. If the player's weapon and skill reliably win, every regular enemy is a shooting-gallery target by hour two.

**Risk: high.** This is the single biggest risk to your identity.

**Fix:** the answer should usually be *"probably, if I commit now, and committing costs me something."* Doubt has to come from the **situation** (distance, light, ammo, noise, the Banshee), not from enemy health bars.

### 2. "Regular enemies" vs "exploration is primary" is a tension

"Regular" implies frequency. Frequency is what destroys atmosphere. If creatures appear often enough to feel regular, exploration becomes "clearing rooms".

**Fix:** "regular" should mean **ordinary within the fiction** (they live here, they aren't bosses), **not frequent**.

### 3. "Every monster has a unique death" can become cosmetic and repetitive

A unique death per *species*, seen the 5th time, is an animation. Players stop watching.

**Fix:** deaths should be **functional**. Each death changes the space (it leaves light, noise, a lure, a hazard or a path) or feeds a system (the Banshee). Then players care about *where* and *when* they kill, not only *whether*.

### 4. The Banshee could feel like an arbitrary exception

"Everything dies except this one" reads as a designer's rule unless the **fiction** explains it. If it's just "the one you can't shoot", players will see it as a cheat, especially if it also chases.

**Fix:** the Banshee has to be unkillable *because of what it is*. A banshee in folklore doesn't kill: **it announces death**. That's your reason, and it's in Part 12.

### 5. The Banshee could become Mr. X (traffic)

If the Banshee patrols and chases, players will kite it, learn its loop and resent it within an hour. This is the RE2 and Alien: Isolation lesson [P].

**Fix:** the Banshee **doesn't chase**. It creates situations.

### 6. Players will memorise enemy behaviour

They will. That isn't a failure, it's the payoff of learning. The failure is when **memorising equals solving**.

**Fix:** combine creatures with situations (light, water, height, noise, the Banshee). Creature A is simple, but creature A in a flooded room during a keen is a new problem.

### 7. The game could become an action game

Triggers: a reload under 1.5 seconds, ammo above enough, enemies in groups, upgrades to damage, arena rooms.

**Fix:** Part 10 limits.

### 8. Exploration could become walking

Walking without decisions is a walking simulator, and on Roblox that's churn. Exploration needs to be **reading**: noticing signs, deciding routes, choosing what to risk.

**Fix:** traces (Part 9) and knowledge-gated progression (Part 11).

### 9. Could be too similar to existing indie horror

The baseline you might accidentally drift into is "a dark building, keys, a creature, a flashlight". That's literally the four reference games.

**Fix:** outdoor/rural/ritual environments (Part 13) and the Banshee's role (Part 12).

### 10. Visual repetition

Exploration-first games need **many visually distinct spaces**, and that's expensive. Roblox teams usually solve it with corridors, which produces the maze cliché.

**Fix:** fewer, denser, more distinct zones (Part 13).

### 11. The player could become too powerful

If combat and progression stack (upgrades, ammo surplus, health), the second half becomes empowering. That's fine for an action game and fatal for horror.

**Fix:** no damage upgrades. Progression is knowledge, tools and access (Part 11).

### 12. Roblox-specific risks

- **Group play.** Four friends with guns makes an action game regardless of design. Scale ammo per player, and consider keeping creatures *dangerous per player* (they pick off isolated players).
- **Short sessions.** A 60–90 minute exploration game needs **checkpointed chapters of 10–20 minutes**.
- **Audience expectations.** Roblox horror players will try closets first. Either support hiding as one option or teach clearly early that this world works differently.

---

## Part 9: Gameplay loop options

### Option A: classic

**Explore → discover → investigate → danger → combat → recover → continue**

A safe, known structure. Combat is the climax of each cycle, so the game risks becoming room clearing.

### Option B: expedition

**Hub → prepare → enter a dangerous area → encounter → return with what you found**

Darkwood/Lethal Company style. Strong pacing and a clear sanctuary. Can feel gamey and repetitive.

### Option C: knowledge-gated

**Explore → find environmental clues → encounter a creature → survive → use new knowledge to access deeper areas**

Outer Wilds plus horror. Exploration matters, but it's hard to design and risks walking.

### Option D: trace-read-commit (recommended)

**Trace → Read → Commit → Survive → Understand**

- **Trace:** explore and notice evidence (sounds, marks, bodies, disturbed objects).
- **Read:** infer what's here (which creature, where, what it does) and what the space hides.
- **Commit:** choose to fight, avoid, lure, or wait.
- **Survive:** a short, sharp encounter.
- **Understand:** the outcome (or the Banshee's reaction) reveals something (story, route, creature behaviour), and that opens the next space.

### Option E: omen-driven

**Explore → receive an omen (the Banshee) → decide how to meet it → consequence → explore what changed**

A strong identity, but it puts the Banshee at the centre of every cycle and risks overexposure.

### Option F: investigation case

**Arrive → question → gather clues → confrontation → answer → next question**

A detective structure. Strong narrative, weak on danger.

### Scoring (1–5)

| Criterion | A | B | C | **D** | E | F |
|---|---|---|---|---|---|---|
| Horror | 3 | 3 | 3 | **4** | 5 | 2 |
| Exploration | 3 | 3 | 5 | **5** | 3 | 4 |
| Pacing | 3 | 4 | 3 | **4** | 3 | 3 |
| Player agency | 3 | 4 | 4 | **5** | 4 | 3 |
| Enemy integration | 4 | 4 | 3 | **5** | 3 | 2 |
| Replayability | 2 | 4 | 2 | **3** | 3 | 1 |
| Narrative potential | 3 | 2 | 4 | **4** | 5 | 5 |
| Originality | 1 | 2 | 3 | **4** | 4 | 2 |
| Production feasibility | 5 | 4 | 2 | **3** | 3 | 4 |
| **Total** | 27 | 30 | 29 | **37** | 33 | 26 |

### Recommendation: Option D, with the Banshee from Option E as a **modifier**, not the core

**Trace → Read → Commit → Survive → Understand.** The Banshee isn't a step in every cycle. She's a **pressure modifier** that appears in about one cycle in three (Part 14).

**Why D wins:**
- It makes exploration **the place where combat is decided**. The player's knowledge of a creature (from traces) determines whether they win the kill window.
- It makes encounters **decisions** (Part 6 white space) instead of reflexes.
- The **Understand** step gives each encounter a consequence beyond survival, so combat feeds discovery instead of interrupting it.
- It fits your pillars directly.

**Secondary loop** (across a chapter): **Venture out from a sanctuary → reach a new zone → find what it's hiding → bring knowledge back → the world shifts (new routes, changed creatures, the Banshee closer).**

---

## Part 10: The role of combat

### Options

| Level | Description | Verdict |
|---|---|---|
| Low | Rare, dangerous, often avoidable | Close, but too rare to make "each monster has a death" matter |
| **Low-moderate** | **Regular threat contact, fights are deliberate and short, avoidance is often better** | **Recommended** |
| Moderate | Combat every room or two, still secondary in theory | Drifts into action |
| High | Survival/action horror | Contradicts your pillars |

### Design targets

These are **starting points to tune in playtests**, not rules.

| Metric | Target | Reasoning |
|---|---|---|
| Threat signal (hear/see a sign of a creature) | Every **2–4 min** in danger zones | Keeps dread alive without contact |
| Actual creature encounter | Every **5–8 min** in danger zones | Enough to stay credible, rare enough to stay scary |
| Fights (shots fired) | About **50–60% of encounters** | Fighting is the default but not mandatory |
| Avoided encounters | About **40–50%** | If avoidance is never optimal, the game is an action game |
| Encounters in sanctuaries | **0** | Safe has to mean safe |
| Encounter duration | **8–25 seconds** | "Can I kill it before it reaches me?" is a short question |
| Enemies per encounter | **1** (rarely 2) | Groups turn it into action |
| Ammo on hand | Enough for about **3–5 kills** at a time, refill at about **70–80% of encounter demand** | Every shot matters, and some creatures are better avoided |
| Shots to kill | **1–3** for most creatures, with weak points | A decisive, readable duel |
| Reload | **2–3.5 seconds**, uninterruptible | The committed moment is the fear |
| Player damage taken | **2–3 hits to die**, no regen outside sanctuaries | Mistakes are survivable but costly |
| Player power over time | **Flat to slightly rising** (tools, not damage) | Never grow out of fear |

### How powerful the player should feel

**Capable, not safe.** Like a hunter with a single-shot rifle at dusk: you can kill it, if you see it in time, if you aim well, if you don't miss. *"I can win this. I might not."*

### How difficult enemies should be

- **Easy to understand**, through clear traces and a distinct silhouette and sound.
- **Hard to execute against under pressure**, because they close distance in distinct ways.
- **Dangerous in combination** with the environment.

### How quickly encounters should end

Fast. The kill window is the encounter. If an encounter lasts more than about 30 seconds, it's become a fight scene, and you're in action territory.

### Weapon direction

One slow, loud primary weapon with a meaningful reload (for example a break-action shotgun, a bolt rifle, a flintlock, a crossbow; choose for your setting). Avoid automatic fire. **Gunshots should be loud and have consequences** (they attract creatures, alert the Banshee).

A secondary non-lethal tool (light, flare, a ritual object) that **repels or stalls** without killing gives the player something to do when a kill isn't possible, and it's the tool that interacts with the Banshee.

---

## Part 11: Enemy philosophy

### Principles

1. **Every creature is a question, not a wall.** The question is always some version of "can I kill this before it reaches me?", but each creature asks it differently.
2. **Traces before contact.** Every creature leaves readable evidence in the world before the player meets it.
3. **One rule each.** A creature should be explainable in one sentence.
4. **Death is functional.** Every death leaves something behind that changes the space.
5. **Ordinary within the world.** They live here. They have habits (feeding, sleeping, nesting) and aren't only aggressive.
6. **Approach is the identity.** How a creature closes the distance is what makes it recognisable and what makes the kill window different.

### Enemy design template

Use this for every creature:

```
CREATURE: [name]

1. ONE-SENTENCE RULE
   [e.g. "It only moves when you're not looking at it."]

2. WHAT IT TEACHES
   [The skill or idea the player learns: e.g. "light controls distance".]

3. EMOTION
   [The primary feeling: dread / anxiety / disgust / paranoia ...]

4. BEHAVIOUR IT FORCES
   [What the player does differently: e.g. "keep the torch on it while reloading".]

5. TRACES (before contact)
   - Sound: [distinctive, readable from a distance]
   - Visual: [marks, nests, carcasses, disturbed objects]
   - Environment: [what it changes: lights, water, doors]

6. RECOGNITION
   - Silhouette: [readable at 20+ m, in the dark]
   - Sound signature: [unique, never shared with another creature]
   - Movement signature: [how it moves: crawl, lurch, glide, stop-start]

7. NON-HOSTILE STATE
   [What it does when it hasn't noticed you: feeds, sleeps, mourns, wanders.]

8. DETECTION
   [Sight / sound / light / smell / vibration, and range for each.]

9. APPROACH (the kill window)
   - Pattern: [straight / zigzag / ceiling / burst-pause / flanking]
   - Speed: [walk / jog / sprint / variable]
   - Window: [how many seconds from detection to contact]
   - Weak point: [where, and how visible]

10. DANGER
    [Damage per hit; any special effect (knockdown, light-out, poison).]

11. COUNTERS
    - Kill: [shots needed; weak-point bonus]
    - Avoid: [how]
    - Repel/stall: [what non-lethal tool works]

12. WHAT MAKES FIGHTING IT SATISFYING
    [The skill moment: e.g. "waiting until it stops to aim".]

13. WHAT MAKES SURVIVING IT MEMORABLE
    [The story the player tells afterwards.]

14. DEATH (functional)
    - What happens: [animation, sound]
    - What it leaves: [light / noise / lure / hazard / path / food]
    - Banshee interaction: [does its death satisfy a keen? does she come to mourn it?]

15. ANTI-ANNOYANCE RULES
    - Max simultaneous: [usually 1]
    - Cooldown before respawn in a zone: [x min]
    - Never in sanctuaries
    - [Creature-specific limits]

16. COMBINATIONS
    [How it interacts with environments, other creatures and the Banshee.]
```

### Two illustrative examples (placeholders, not a story)

**Example 1: "the Wader"**
- **Rule:** it only hunts in water, and it's blind out of it.
- **Teaches:** routes matter. Choose dry paths or commit to wet ones.
- **Traces:** rings on still water, a wet drag line, a smell of rot.
- **Approach:** a fast underwater glide, then a lunge. **3 seconds** from the first ripple to contact.
- **Kill:** two shots at the head when it surfaces to lunge. Or step onto dry land and it gives up.
- **Death:** it floats and blocks a channel, creating a bridge (path) **and** drawing scavengers (a lure).

**Example 2: "the Lantern-shy"** (placeholder name)
- **Rule:** it freezes in light and moves in darkness.
- **Teaches:** the torch is a weapon *and* a resource.
- **Approach:** stop-start. It closes distance whenever the light leaves it, so you can't reload and light it at the same time.
- **Kill:** one shot to the chest **while lit**. If you shoot in the dark, you miss.
- **Death:** it collapses into a pale glowing shape, a **light source** that lasts a few minutes.

---

## Part 12: The Banshee

### Does the concept work?

**Yes, if she isn't a chaser.** As an "unkillable thing that hunts you" she's **Mr. X, the Alien, the Beast, the Locust and every Mimic antagonist again**, which is the most common unkillable-monster pattern in the research. She'd be the least original thing in your game.

Folklore gives you a better answer. **In Irish and Scottish tradition the banshee (*bean sídhe*) doesn't kill. She keens (wails) to announce that someone is about to die.** She's an **omen**, not a predator. That's both the reason she can't be killed (you can't kill an announcement) and the source of a different kind of tension.

### Originality warning

*Phasmophobia* has a ghost type called "Banshee" (a ghost that targets one player and has a distinctive scream), and banshees are generic in fantasy games. The name won't be distinctive on its own. **The omen mechanic is what makes your Banshee yours.**

### What she should represent

> **The regular creatures ask: "Can I kill this before it reaches me?"
> The Banshee asks: "Who is going to die here?"**

She stands for **the inevitability of death, and the obligation to acknowledge it**. Every creature you kill is a death. Every body you find is a death. She's the world's memory of those deaths. She makes **killing meaningful** (it isn't free) and **discovery meaningful** (she grieves where the story happened).

### Recommended design: "the Keen"

**The core rule:** *when the Banshee keens, someone nearby will die soon. If nothing else dies, you will.*

**Her states:**

| State | What happens | Danger | Player response |
|---|---|---|---|
| **Distant** | Faint keening across the landscape. An omen only | None | Dread. "She's somewhere." |
| **Mourning** | She appears at a **site of death** (a body, a grave, a creature you killed) and grieves | Safe, unless you disturb her (light, noise, getting too close) | Observe from a distance. **Mourning sites hold clues** |
| **Keening** | A loud wail; lights dim; creatures in the area are drawn; a **doom window** opens (about **60–90 s**) | Indirect, then lethal | **Resolve it:** let a death happen (kill a creature), leave the area (cross a threshold), or perform a ritual |
| **Taking** | The doom window closes and nobody else died | Lethal | Unavoidable at this point. The punishment for ignoring her |

**Resolving a keen (three ways, deliberately):**

1. **Fulfil it:** kill a creature inside the area. A death has occurred, and she goes quiet and comes to mourn it. **This binds the Banshee and combat together.** She makes you fight, and combat stays your choice.
2. **Leave:** cross a **threshold** (running water, an iron gate, a lit hearth). This is folklore-compatible and gives the player a non-combat way out.
3. **Ritual:** cover a mirror, stop a clock, open a window. These are wake customs, used as **rare, location-specific** options that make the environment part of the solution.

### Answers to your questions

| Question | Answer |
|---|---|
| **When should she appear?** | As **Distant** from about minute 15. First **Mourning** at about minute 25. First **Keen** at about minute 40 (Part 14) |
| **How frequently?** | Distant: ambient, every few minutes. Mourning: about once per zone. **Keen: about every 15–25 minutes, at most once per zone visit** |
| **Predictable or unpredictable?** | **Rules predictable, timing unpredictable.** Players should understand *what* she does, never *when* |
| **Heard before seen?** | **Always.** Her keening is the most recognisable sound in the game, and she's never a jump scare |
| **Environmental effects?** | Yes: lights dim, water stills, creatures go quiet then agitated, a cold tint. **Her effects are environmental, not violent** |
| **Should she chase?** | **No.** Never. That's the main thing that separates her from every other unkillable monster |
| **Should she patrol?** | No. She **appears**, at sites of death and at places the story needs |
| **Should she guard areas?** | Yes, by **mourning there**. Some story locations can only be investigated while she grieves, quietly, without disturbing her |
| **Should the player learn rules?** | Yes, and the rules are part of exploration (wake customs found in notes and from NPCs) |
| **Should the rules ever change?** | **Twice at most**, as narrative peaks: (1) she keens and there are no creatures nearby, so it must be you; (2) she keens for someone else (an NPC, a companion) and you can't save them, or can you? |
| **How do we stop her becoming annoying?** | She never chases. Her doom window is long enough to think. Never more than one keen per zone visit. Never in sanctuaries. Never during another keen's cooldown |
| **How do we stop the player simply running every time?** | Keens are tied to **areas that hold what you need**. Leaving resolves the keen but costs you the zone for now (you have to come back later, and the area may have changed) |
| **How does she become part of exploration?** | **Mourning sites are where the story is.** She leads the player to the dead, so following her keening is how you find what happened |

### Simpler fallback ("Omen-only Banshee")

If the keen system is too much scope: she **never kills**, she only **summons**. Her keen draws every creature in the area and kills the lights for 60 seconds. She's still unkillable and still not a chaser, with lower production cost and less identity.

---

## Part 13: Level design direction

### Direction

Your identity is **exploration, discovery, death and grief, with an omen in the landscape**. The environments should be places where **death is part of everyday life**, with rural folk customs, open landscapes and ritual interiors. That's the opposite of the corridor mazes that saturate the reference set.

Below is a recommended **palette of zone types**, chosen by function. The example dressing assumes a rural/folk setting because that fits the Banshee. Reskin as needed for your setting; the functions carry over.

| Zone | Why it works | Creatures that fit | Gameplay | Storytelling | Tension | Visual distinction |
|---|---|---|---|---|---|---|
| **The village at dusk** (hub/sanctuary edge) | A familiar, domestic place that's slightly wrong | Rare. Mostly traces | Safe exploration, NPCs, preparing | Homes, absent families, wake customs half-done | Low dread: "something happened here" | Warm windows against a blue dusk |
| **The bog/marsh** | Open but unsafe. Fog. Sound carries strangely. Bodies preserved in peat | Water creatures, ambushers | Route choice (wet vs dry), long sight lines for the kill window | Bog bodies as literal, ancient storytelling | Exposure: "I can see far and it can too" | Flat, low, desaturated, mist layers |
| **The tidal causeway & lighthouse** | **Time-gated space**: the tide reshapes the map | Shore/water creatures | Timing, vertical climbs, a lighthouse lamp as a tool | Shipwrecks, keepers' logs | Time pressure without a timer UI | Horizon, beam sweep, wet rock |
| **The wake house/parish** | **Ritual interiors**: mirrors, clocks, coffins | Few creatures. **The Banshee's home ground** | Ritual mechanics, investigation | Wake customs are the rules of the Banshee | Quiet dread, social uncertainty | Candlelight, covered mirrors, black cloth |
| **The mill & weir** | **Loud space**: machinery masks sound | A creature you can't hear coming | Turn machines off to hear and be heard. A trade-off | Industrial life, accidents | Sensory deprivation | Moving wheels, spray, iron |
| **The quarry/mine** | Vertical, dark, echoing | Ambushers, light-sensitive creatures | Light management, ropes, ledges | Workers who didn't come out | Claustrophobia, darkness | Cut stone, lamps, depth |
| **The keening ground** (strange space, rare) | Where the Banshee's grief becomes literal space | Banshee only | Story revelations, rule breaks | The truth | Disorientation, awe | Breaks the art rules: colour inverted, sound reversed |

### Level design principles

1. **Readable from distance.** Kill windows need sight lines. Outdoor and semi-open spaces make "can I kill it before it reaches me?" possible.
2. **Dense, not wide.** Fewer, richer zones beat big empty maps. Each zone gets **3–5 discoveries** and **1–3 creature habitats**.
3. **Habitats, not spawns.** Creatures live somewhere (nests, feeding grounds). Traces lead there.
4. **Sanctuaries are diegetic.** Hearths, churches, lit houses. The player can see them from danger zones.
5. **Return visits change.** Bodies stay, the Banshee has mourned, the tide is different.
6. **No pure mazes.** Complexity comes from verticality, water, light and sight lines, not corridors.

---

## Part 14: Pacing

### Pacing philosophy

**Long waves, not constant noise.** Each wave: calm exploration → traces build → commit → spike → release → discovery. The player should **feel completely safe often** (sanctuaries) so that unsafe means something.

### Targets

| Element | Target |
|---|---|
| Exploration section (between real encounters) | **5–8 min** |
| Threat signals (traces, sounds) | Every **2–4 min** in danger zones |
| Creature encounter | Every **5–8 min** in danger zones |
| Combat (shots fired) | Every **8–15 min** on average |
| Completely safe (sanctuary or safe zone) | Every **15–20 min**, for **2–5 min** |
| Important discovery (clue, route, revelation) | Every **4–7 min** |
| Banshee **Distant** | Ambient, a few times per 10 min, once introduced |
| Banshee **Mourning** | About once per zone |
| Banshee **Keen** | Every **15–25 min**, never twice in one zone visit |
| Major narrative revelation | Every **20–30 min** |
| Chapter/checkpoint | Every **10–20 min** (Roblox session fit) |

### Example: first 60–90 minutes (pacing only, no story)

| Minutes | Beat | Danger | Purpose |
|---|---|---|---|
| 0–5 | Arrival. Village at dusk. Something is wrong. No creature | None | Mood, controls, curiosity |
| 5–10 | First traces (a carcass, drag marks, a far sound) | Signal only | Teach "traces before contact" |
| 10–15 | **First encounter**: one slow, readable creature. A kill window with a long distance | Low–medium | Teach the core question: "can I kill it before it reaches me?" Should feel winnable |
| 15–17 | First **Distant** keening. Nothing else | Omen | Plant dread |
| 17–25 | Exploration. Discoveries. First sanctuary | Low | Release. Discovery reward |
| 25–28 | **First Mourning**: the Banshee grieving at a body, seen from a distance | Tension, no danger | Teach "she doesn't chase. She marks death." |
| 28–35 | New zone. Second creature type (different approach pattern). Optional avoidance | Medium | Teach "avoidance is valid" |
| 35–40 | Discovery from the mourning site (story clue) | Low | Payoff: following her leads to answers |
| 40–43 | **First Keen.** A creature nearby. The player learns to resolve the keen by fulfilling it (kill) | **High** | The signature mechanic |
| 43–50 | Aftermath. She mourns the creature you killed. Sanctuary | Release | Death acknowledged |
| 50–55 | **First major revelation** | None | Narrative peak |
| 55–65 | Larger zone. Creatures in combination (environment plus creature) | Medium | Escalation |
| 65–70 | Second keen, **no creature nearby**. The player has to leave (threshold) or perform a ritual | **High** | Teach the other resolutions |
| 70–80 | Return to a changed zone. New route opened | Medium | "The world remembers" |
| 80–90 | Chapter end. A **rule break**: she keens, and it's not about you, or it is | Peak | Cliffhanger |

---

## Part 15: Originality test

### Derivative

- A dark rural place with a monster: generic.
- Killable regulars plus an unkillable one: RE2/Alien/Bunker structure.
- A banshee by name: Phasmophobia and fantasy games.
- A flashlight and a gun: generic.

### Familiar (fine as a foundation)

- Traces before contact (Alien, Bunker).
- Sanctuaries (RE2, Signalis).
- Creature rules (Lethal Company, DOORS).
- Slow, loud weapon (Bunker, RE2).

### Distinctive

- **An unkillable entity that doesn't chase**: an omen, not a predator.
- **Combat as a response to prophecy**: kill to satisfy the keen.
- **Functional creature deaths.**
- **Rural/ritual environments** in a corridor-saturated market.
- **Real combat** in the Roblox exploration-horror space.

### Signature candidates

| # | Concept | Why it's different | Resembles | Push it further | Production difficulty | Gimmick risk |
|---|---|---|---|---|---|---|
| 1 | **The Keen** (someone will die here soon, you or something else) | Turns the unkillable monster into a **decision generator**, not a chaser | Phasmophobia's hunt warning, Silent Hill's radio | The keen's pitch/direction hints at the target. NPCs can be keened for | Medium (states, timer, area logic) | Low if it's in every chapter. High if used once |
| 2 | **Functional deaths** (every kill leaves light/noise/path/lure/food) | Makes *where* and *when* you kill matter | Signalis (bodies), Dead Space (dismemberment) | Creatures react to each other's corpses | Medium (per-creature) | Low |
| 3 | **Mourning sites as storytelling** (the Banshee leads you to the dead) | The monster is also the guide | Few direct precedents | Mourning reveals ghost re-enactments of how they died | Medium–high (content per site) | Low–medium |
| 4 | **The kill window** (creatures defined by how they close distance) | Combat as a **timing/reading duel**, not DPS | Darkwood, Hunt: Showdown, RE2 Lickers | Light, water and height change the window | Medium (AI per creature) | Low |
| 5 | **Knowledge as progression** (a field journal from observation, no damage upgrades) | Power grows through understanding, keeping fear intact | Phasmophobia journal, Outer Wilds, Monster Hunter | Observing non-hostile behaviour reveals weak points | Medium | Medium (busywork if manual) |
| 6 | **Wake customs as rules** (folk rituals that really work) | Environment as a toolkit, culturally coherent like The Mimic's yokai | The Mimic (folklore), Threshold (light rules) | Customs differ by household. Learning them is exploration | Low–medium | Medium if overused |

**Strongest combination:** 1 + 2 + 4. The Keen ties the Banshee to combat, functional deaths tie combat to exploration, and the kill window gives combat its own identity.

---

## Part 16: Creative direction: what is this game?

**One-sentence pitch**
*An exploration horror game where you hunt the creatures that hunt you, and a Banshee that can't be killed tells you when someone, or something, is about to die.*

**Core fantasy**
A lone (or small-party) investigator in a place where death is part of life, uncovering what happened by reading the land, the dead and the creatures.

**Core horror fantasy**
*"I can kill what I can see coming. I can't stop what's been foretold."*

**Primary gameplay loop**
**Trace → Read → Commit → Survive → Understand.**

**Secondary gameplay loop**
Venture out from a sanctuary → reach a new zone → uncover what it hides → bring the knowledge back → the world shifts.

**Exploration philosophy**
Exploration is **reading**. Every space holds traces (of creatures, of the dead, of the story) and knowledge is how you get stronger.

**Combat philosophy**
**Short, decisive, consequential.** One slow, loud weapon. Encounters end in seconds. Every kill changes something. Avoidance is often smarter.

**Enemy philosophy**
**Creatures, not monsters.** They live here, they have habits, they leave traces, and each closes distance in its own way. One rule each. Deaths that matter.

**Banshee philosophy**
**An omen, not a predator.** She never chases. She announces death and mourns it. Her keen forces a decision: let something die, leave, or be taken.

**Level design philosophy**
**Dense, readable, rural and ritual.** Sight lines for kill windows. Habitats instead of spawns. Sanctuaries you can see. Zones that remember.

**Narrative philosophy**
**The story is told by the dead**, through mourning sites, traces and wake customs. Lore lives in the world, not in a wiki.

**Pacing philosophy**
**Long waves.** Calm, signs, decision, spike, release, discovery. Safety is real and regular.

**Visual identity**
Dusk and fog, warm sanctuary light against cold landscapes. One high-contrast element per scene, a lesson from Monochrome. The Banshee alone gets a colour no other thing in the game uses.

**Audio identity**
**The keen is the game's signature sound.** Creature sounds are distinct and readable from a distance. Silence is used deliberately before keens. Gunshots are loud and carry far.

**Player emotion progression**
Curiosity → unease → competence (first kills) → dread (the Banshee) → doubt (rules bend) → grief (the story) → resolve.

---

## Part 17: The "do not become this game" test

| Failure identity | How you'd drift there | Rules that keep you away |
|---|---|---|
| **Action horror** (RE4-style) | Ammo surplus, fast reloads, groups, damage upgrades | Max 1–2 creatures per encounter. Reload ≥2 s. No damage upgrades. Ammo ≈ 70–80% of encounter demand |
| **Chase horror** (Mimic/DOORS-style) | The Banshee or creatures chasing scripted routes | **The Banshee never chases.** Creatures give up after line of sight breaks plus a short search. No scripted chase sequences outside rare set pieces |
| **Jump-scare game** | Scripted scares instead of systemic ones | Every scare must have a warning (traces, sound). No death screen screamers. The Banshee is always heard first |
| **Walking simulator** | Exploration without decisions | Every zone must contain decisions (routes, risk, creatures). Discoveries every 4–7 min |
| **Mr. X clone** | The Banshee as a patrolling stalker | She appears, she doesn't patrol. One keen per zone visit |
| **Key-hunt escape room** (Monochrome/Locust) | Progress through "find N keys" | Progress through knowledge and access. No more than one "find N items" objective per chapter |
| **DOORS-like rule list** | Creatures that are only a warning plus a reflex | Every creature must allow both fight and avoidance, and must have a non-hostile state |
| **Friendslop comedy** | Large servers, voice chaos, ragdolls | Party size ≤4. Creatures that punish separation. Tone that doesn't reward clowning |
| **Backrooms/liminal clone** | Empty corridors and fluorescent lights | Rural, ritual, outdoor zones. No pure mazes |
| **Lore-wiki game** | Story only in notes | The story is found in mourning sites and environments; notes are supplementary |
| **Soulslike horror** | High difficulty as the source of fear | Fear comes from doubt and dread, not from punishing execution. Checkpoints every 10–20 min |

---

## Part 18: Final recommendation

### THE RECOMMENDED DIRECTION

**Build a rural, ritual, exploration-first horror game where the player is a capable but fragile hunter, every creature is a readable kill-window duel whose death changes the world, and the Banshee is an omen that never chases: when she keens, something has to die.**

**1. Defining identity**
*Hunt what you can see. Fear what's been foretold.* Killable creatures test your nerve and the Banshee tests your choices.

**2. Ideal gameplay loop**
**Trace → Read → Commit → Survive → Understand**, inside a sanctuary-to-zone expedition structure.

**3. Ideal combat frequency**
**Low-moderate.** Shots fired about every **8–15 minutes**. Encounters of **8–25 seconds**. About **half of encounters** fought and the rest avoided.

**4. Ideal enemy frequency**
Threat signals every **2–4 minutes** in danger zones, real encounters every **5–8 minutes**, **zero** in sanctuaries.

**5. Role of exploration**
**The core of the game and where fights are won.** Reading traces tells you what's ahead and how to beat it. Knowledge is the main progression.

**6. Role of the Banshee**
**An omen, not a predator.** She mourns where the story is, and her keen forces a decision about death. She never chases. She's the game's signature.

**7. Most important level-design principle**
**Readable distance.** Build spaces where the player can see creatures coming, so the kill window is a real decision. That rules out corridor mazes and points toward semi-open, rural, vertical spaces.

**8. Most important horror principle**
**Doubt, not helplessness.** The player can usually win, but should never be sure. Doubt comes from the situation (distance, light, ammo, noise, the Banshee), not from enemy health.

**9. Biggest originality opportunity**
**An unkillable entity that doesn't chase.** Almost every unkillable monster in the research pursues the player. A Banshee that foretells death, ties into combat through the keen and leads the player to the story is clear white space.

**10. Biggest design mistake to avoid**
**Making the Banshee a stalker.** If she chases, patrols or hunts, she becomes Mr. X, players will route around her within an hour, and your most distinctive idea becomes your most derivative one.

---

## Sources

Gathered October 2026. Full pages for Roblox, the fandom wikis, Steam and most guide sites couldn't be fetched (blocked by the research environment), so the facts below come from search-engine extracts of these pages.

**MONOCHROME**
- [MONOCHROME Roblox Wiki](https://monochrome.wiki/) · [Game guide](https://monochrome.wiki/roblox/monochrome-roblox-game)
- [What Is MONOCHROME?](https://monochromegame.org/guides/monochrome-game/) · [Monster guide](https://monochromegame.org/guides/monochrome-monster/)
- [Official overview & guide](https://monochrome.robloxgameswiki.com/guide/what-is-monochrome) · [Monster survival guide](https://monochrome.robloxgameswiki.com/guide/monochrome-monster-guide)
- [allthings.how: full escape guide](https://allthings.how/how-to-play-monochrome-in-roblox-full-escape-guide/)
- [aprasi: walkthrough](https://www.aprasi.com/blogs/trending-topics/monochrome-roblox-walkthrough)
- [Rolimons: Pt. 2 place](https://www.rolimons.com/game/134208374070897)
- [Boisvert (TV Tropes)](https://tvtropes.org/pmwiki/pmwiki.php/WebAnimation/Boisvert)

**House of The Locust**
- [The Locust monster guide](https://houseofthelocust-game.wiki/wiki/monsters/the-locust/) · [Wiki](https://houseofthelocust-game.wiki/wiki/)
- [allthings.how: full walkthrough](https://allthings.how/house-of-the-locust-full-walkthrough-and-escape-ending-roblox/)
- [bo3.gg walkthrough](https://bo3.gg/games/articles/house-of-the-locust-walkthrough)
- [Sportskeeda beginner's guide](https://www.sportskeeda.com/roblox-news/house-locust-a-beginner-s-guide)
- [roonby guide](https://roonby.com/2026/08/25/house-of-the-locust-roblox-guide-how-to-get-the-ending/)
- [nerdschalk escape guide](https://nerdschalk.com/house-of-the-locust-escape-guide-how-to-complete-the-full-escape-chain/)
- [The Locust (villains wiki)](https://villains.fandom.com/wiki/The_Locust)

**The Mimic**
- [The Mimic Wiki: game information](https://mimic.fandom.com/wiki/The_Mimic) · [Books](https://mimic.fandom.com/wiki/Books) · [Rage's Book](https://mimic.fandom.com/wiki/Rage's_Book) · [Nightmare Mode](https://mimic.fandom.com/wiki/Nightmare_Mode) · [The Witch Trials](https://mimic.fandom.com/wiki/The_Witch_Trials)
- [Roblox wiki: The Mimic](https://roblox.fandom.com/wiki/CTStudio/The_Mimic)
- [TV Tropes: The Mimic](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/TheMimic)
- [NamuWiki: The Mimic](https://en.namu.wiki/w/The%20Mimic)
- [endsights: folklore and fear design](https://endsights.com/the-mimic-lore)
- [Pocket Tactics](https://www.pockettactics.com/roblox/the-mimic)

**THRESHOLD**
- [Roblox page](https://www.roblox.com/games/78453398695059/THRESHOLD)
- [Threshold Roblox Horror Wiki](https://thresholdhorror.fandom.com/)
- [THRESHOLD Wiki & Guides](https://threshold.wiki/) · [Voice chat](https://threshold.wiki/mechanics/threshold-voice-chat/) · [Beginner guide](https://threshold.wiki/guides/threshold-beginner-guide/)
- [TikTok: Scrow clip](https://www.tiktok.com/@kirbyventz/video/7690941967366180110)
- Other games with the same name: [Threshold (2024)](https://en.wikipedia.org/wiki/Threshold_(2024_video_game)), [PCGamesN](https://www.pcgamesn.com/threshold/steam)

**Additional games:** facts on Resident Evil 2 (2019), Alien: Isolation, Amnesia: The Bunker, Signalis, Lethal Company, DOORS, Phasmophobia, SOMA, Silent Hill 2 and Darkwood come from well-documented knowledge of those games, not from fresh fetches. [DOORS (Wikipedia)](https://en.wikipedia.org/wiki/Doors_(game)).
