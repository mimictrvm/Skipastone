# The Reliquary: Lobby Direction

**Status:** directive, v1 (4 Oct 2026). Whoever builds or dresses the lobby, person or AI, builds to this document. To change a rule, edit it here first.

**What it is:** the lobby of *The Reliquary*. It's Cornelius Ashgrove's private collection room, where every relic belongs to one of the game's maps. Players arrive here, party up, read the books and choose where to go.

**Starting point:** the current lobby screenshot (4 Oct 2026): a long dark gallery with brass-framed glass cases down both sides, a runner down the middle, a lectern with an open book and candles in the foreground, two orange-lit windows and a dark doorway on the far wall, and one candle lit on a chandelier.

**How to read it.** Statements are decisions. Numbers are **starting values to tune by eye in Studio**. Open questions are in section 15.

---

## 0. Instructions for the AI building this

- **Keep what works:** the symmetry, the runner leading the eye, and the lectern in the foreground. Everything here builds on that composition. Don't replace it.
- **Build in the order in section 14.** Each step should look finished on its own.
- **Keep the user's own parts.** If the room already has a part that does a job in this document (the lectern, the cases, the chandelier), improve it in place rather than rebuilding it.
- **Every tunable number goes in one `LobbyConfig` module:** light values, timings, sizes.
- **The lobby is the first thing anyone sees.** It has to load fast and run smoothly on phones (section 13).
- **No real brands or logos.** *Pellam & Sloane* is our invented auction house.
- **Flashing:** lightning stays at 3 flashes a second or fewer, with a "reduce flashing" setting that softens it.
- **Report honestly** what you checked in Studio, at which screen sizes, and what you couldn't test.

---

## 1. The idea

**One line.** *You're standing in a dead collector's reliquary, choosing which of his haunted relics to go after.*

**Whose room.** **Cornelius Ashgrove**, the collector whose catalogue cards are signed "C.A." The room says who he was without any text on screen:
- He **collected**: the cases, the card index, the ledgers.
- He's **being sold off**: Pellam & Sloane crates, half unpacked.
- The room is **in mourning**: the clock stopped, the mirrors covered, a window open (the housekeeper's customs from Ashgrove).
- **Something is still behind the strongroom door** (section 3).

Players who know the Ashgrove story will understand the details. Everyone else just feels the room is wrong.

**The rule of the room.** *Warm room, cold relics.* Candles and sconces are amber; the cases and the moonlight are cool blue-white. That contrast is the whole image.

---

## 2. Layout and camera

### 2.1 Room

```
                    [ PORTRAIT ]
               [ STRONGROOM VAULT DOOR ]           <- far wall, z = 90
   window                                      window
   [case 4]   |                         |   [case 8]   z = 70
   sconce     |                         |   sconce
   [case 3]   |         RUNNER          |   [case 7]   z = 55
   window     |                         |   window
   [case 2]   |                         |   [case 6]   z = 40
   sconce     |                         |   sconce
   [case 1]   |                         |   [case 5]   z = 25
              |                         |
                  [ PARTY UP / BOOKS ]                 (screen, not world)
                      [ LECTERN ]                      z = 6
                      ( camera )                       z = 0
```

| Element | Size and position (studs) |
|---|---|
| Room | 36 wide × 90 long × 20 high |
| Runner | 6 wide, from z = 8 (stopping short of the lectern) to z = 87 |
| Cases | 4 per side, centred at z = 25, 40, 55, 70, about 6 in from each side wall |
| Windows | on the **side walls** between cases, at z = 32 and z = 62, both sides |
| Strongroom door | centre of the far wall, 8 wide × 12 high |
| Portrait | above the door, 6 wide × 8 high |
| Lectern | centred, z = 6 |

**Fix from the current build:** the windows move off the far wall onto the side walls, so the far end of the room is the darkest and most important place.

### 2.2 Menu camera

- **Field of view 55.** The current wide angle bends the outer cases on wide screens.
- **Position:** z = 0, about 6 studs high (standing eye height), centred, tilted down about 5°.
  - The book and candles fill the bottom third of the screen.
  - The strongroom door sits just above the centre.
- **Idle drift:** about 0.2 studs of slow sway over 8 seconds.
- **Hover push-in:** while any button is hovered, the camera eases 1 stud forward over 0.6 seconds, and back when it's released.
- **Screen sizes:**
  - **Frame for 16:9.** On ultrawide screens a vignette fades the extra sides to black.
  - **On phones** the camera moves back about 2 studs so the lectern isn't cropped.
- **Avatars:** while the menu camera is active, hide the local player's avatar from the camera. Party members appear in the room as described in 9.2.

---

## 3. The far wall: strongroom and portrait

This is the room's focal point. It's currently missing.

**The strongroom door:**
- A heavy iron vault door with rivets around its edge, a large brass wheel handle in the middle and a chain hung across it.
- Set into a **brick surround**, as if it was cut into the house after it was built. This is the only brick in the room.
- A **thin line of cold light under the door**: a SurfaceLight or neon strip, colour around RGB 170, 190, 230, very low brightness. No other light on the door itself.
- **The knocks:** every 2–3 minutes (random), three slow knocks from behind it, with a tiny puff of dust from the frame on each one. Nothing else happens. Never explained.

**The portrait of Cornelius**, above the door:
- A heavy gilt frame. Portrait style: a Victorian gentleman in dark clothes with a gold watch chain.
- Lit from below by a single candle on a small shelf.
- Mostly in shadow. Only the eyes and the watch chain catch the light.

**The title** **THE RELIQUARY** sits small and centred above the portrait, as gold-leaf letters on the wall. It catches the light only in lightning flashes (section 8).

---

## 4. Walls, ceiling and floor

### 4.1 Walls

| Layer | Spec |
|---|---|
| Wainscot (lower panelling) | 4 high, very dark oak (around RGB 45, 30, 22), Wood material, with raised panels and a moulded rail on top |
| Wallpaper (above) | Deep bottle-green (around RGB 28, 42, 34) or oxblood (around RGB 60, 22, 24). Fabric material with a damask pattern decal at about 0.6 transparency, so the pattern only shows where light falls |
| Picture rail | A thin oak strip at 14 high |
| Cornice | Moulding where the walls meet the ceiling |

- **No pure black surfaces anywhere.** The darkest colour is about RGB 18, 16, 15, so shapes still separate in the dark.
- The thin rails and cornice matter: they catch faint light and show the room's shape even when it's mostly dark.

### 4.2 Ceiling

- **Coffered or beamed**, at 20 high, in the same dark oak. It must exist; at the moment it's a black void, which reads as unfinished.
- **The chandelier** hangs from a visible chain at the room's centre. **All its candles are lit, dimly** (at the moment only one is, which looks like a bug). The alternative is to leave it fully unlit with cobwebs, but don't leave it half lit.

### 4.3 Floor

- **Herringbone parquet:** WoodPlanks material, dark colour, Reflectance about 0.05. Candles and case lights leave long soft reflections, which is a big part of the depth.
- **The runner:**
  - deep red with a thin gold border
  - worn paler down the middle, where he walked
  - frayed at the far end where it meets the vault door
  - stops just short of the lectern (doesn't run under it)

---

## 5. The cases

The game is named after these. They have to be the stars of the room.

### 5.1 Construction

| Part | Spec |
|---|---|
| Plinth | Dark wood or black marble, 6 × 6, 3 high. The cases currently float; every case gets one |
| Glass box | On top of the plinth, 5 high. Transparency about 0.85, Reflectance about 0.15. **Make sure every glass panel exists**; at the moment you can see straight into some cases |
| Brass frame | Thin: about 0.15 thick. The current frames are thick enough to look like scaffolding |
| Cushion or stand | Velvet, deep red or black. The relic sits on it |
| Light | A SpotLight inside the top of the case, pointing down: Angle about 50, Range about 10, Brightness about 2, Color around RGB 200, 215, 255. Shadows off |
| Dust | A few motes drifting in the case's light (section 7.3) |
| Plaque | Brass, on the front of the plinth, actually readable: `No. 001 · THE SEALED BOX` |
| Catalogue card | A small handwritten card in a brass clip on the plinth, signed "C.A." |

### 5.2 What goes in them

| Case | Relic | Card (a line in his handwriting) |
|---|---|---|
| **No. 001** | The sealed box: a small wine cabinet, seal broken, lid open a crack. Empty | *"The only thing I have bought that I would sell back."* |
| **No. 077** | **Nothing.** Only the dent in the velvet where a comb once lay | *"Do not search for it."* |
| **No. 114** | The spine whip, coiled | *"The whip is a spine. He came with it."* |
| **No. 203** | The hollow lantern, unlit | *"Never trim the wick and look away."* |
| **Subway map** | A dented trackman's lamp, or the five torn SOLUTION slips pinned in a row | *"Ebbmoor. Acquired at no cost. The line keeps the rest."* (Optional. The subway has no story link; this only means he collected something from it) |
| **Unreleased maps** | Cases under **dust sheets** | No card. It reads as a collection still being added to |

The empty case (No. 077) is deliberately the creepiest.

### 5.3 Rhythm and fixes

- Four cases per side, evenly spaced, with a **wall sconce between each pair**, so the light falls in even pools down the room.
- **The tilted frame in the current left case:** fix it, or make it obviously deliberate by standing it on a small easel at an angle.

### 5.4 Interaction (optional, if the lobby is walkable: section 15, #1)

- Walking up to a case brightens its light and shows the plaque name.
- Cases only show a relic once **that player** has completed its map; until then they show the dust sheet. The room fills up as you play.

---

## 6. The lectern and set dressing

### 6.1 The lectern (the foreground anchor)

| Item | Spec |
|---|---|
| Lectern | A sloped reading lectern, or a desk with a green leather top and brass edging |
| The book | Thick, with handwritten-page decals, a red ribbon bookmark and worn edges. Every 6–10 s a page lifts slightly and settles, as if in a draught |
| Candles | Three, at different heights, with wax drips down the sides. **One has just gone out**, with a thin trail of smoke |
| Quill and inkwell | (The current white stick may already be the quill) |
| Magnifying glass | |
| Pocket watch | Open and stopped |
| The gold sovereign | Under a small glass dome |
| Letters | Two or three, sealed with red wax |

### 6.2 Cornelius's room

Spread along the walls and between the cases, all lit only by spill from the sconces:
- **A card-index cabinet:** dozens of small drawers, each with a brass label holder.
- **Bookshelves** between some of the cases, with ledgers and auction catalogues.
- **Pellam & Sloane crates**, stencilled `PELLAM & SLOANE · AUCTIONEERS`, half unpacked, with straw spilling out.
- **His coat and walking stick** on a stand by the vault door.

### 6.3 The mourning customs

From the housekeeper's book in Ashgrove. All three are in the room:
- **The clock is stopped.** A tall case clock against a wall, hands at a fixed time, **silent**.
- **The glass is covered.** A large wall mirror hung with black cloth.
- **A window is open.** One of the side windows is open a crack, with its curtain moving in the draught.

Players who know Ashgrove will realise someone died in this room. No other hint is given.

---

## 7. Lighting

### 7.1 Lighting service and post effects

| Setting | Value |
|---|---|
| `Lighting.Technology` | `Future` (use `ShadowMap` if phones struggle) |
| `Ambient` | 0, 0, 0 |
| `OutdoorAmbient` | 20, 22, 30 |
| `Brightness` | 0.5 |
| `ClockTime` | 0 |
| `EnvironmentDiffuseScale` | 0.2 |
| `EnvironmentSpecularScale` | 0.5 |
| **Atmosphere** | Density 0.35, Offset 0, Color 45, 40, 38, Decay 20, 18, 16, Glare 0, Haze 1.5 |
| **ColorCorrection** | Contrast 0.1, Saturation −0.15, TintColor 255, 240, 225 |
| **Bloom** | Intensity 0.6, Size 24, Threshold 1.6 (candles glow; nothing else should) |
| **DepthOfField** (menu camera only) | FocusDistance about 20, InFocusRadius about 25, FarIntensity 0.3. The vault door is softly blurred; the book is sharp |

### 7.2 Lights

| Light | Type and values | Shadows |
|---|---|---|
| Lectern candles | PointLight, Range 8, Brightness 1.5, Color 255, 170, 90. Flicker: Brightness varied ±15% at random every 0.05–0.15 s | **Yes**, on the tallest candle only |
| Chandelier | One PointLight at its centre (not one per candle), Range 18, Brightness 0.6, warm | Yes |
| Wall sconces | PointLight, Range 10, Brightness 0.8, warm, with the same flicker but slower | No |
| Cases | Section 5.1: cool, from inside the top | No |
| Windows (moonlight) | SpotLight angled in through each window, Color 140, 160, 200, Brightness 1, Range 40. **The same on both sides** (the current single orange window is the biggest distraction in the shot) | One window only |
| Light shafts | A Beam with a soft gradient texture through each window, very transparent | — |
| Portrait | A small PointLight from the candle below it, Range 6, warm | No |
| Strongroom door | The cold line under the door only (section 3) | No |

**Shadow budget: no more than 3 shadow-casting lights** (one lectern candle, the chandelier, one window).

### 7.3 Particles

- **Dust motes** in each case's light and in the window shafts: ParticleEmitter, Rate about 2, Size about 0.05, Speed about 0.2, Lifetime about 8, LightEmission 0.3, very slight random drift.
- **Smoke** from the snuffed candle: a thin, slow, curling wisp.

---

## 8. The storm

Ashgrove sits on a cliff in a storm. So does this room.
- **Rain** streaking down every window: a decal whose texture offset scrolls slowly downward.
- **Lightning every 25–50 s (random):**
  - The moonlight SpotLights and a large soft fill light ramp up over about 0.1 s, hold briefly, and fall over about 0.3 s, followed by a smaller second flicker.
  - Thunder follows 1–3 s later.
  - For that moment players see the **whole room**: the cases, the portrait, the vault door, the title. Then it's dark again. **This is how the room stays dark but readable.**
- **Safety:** never more than 3 flashes per second. With "reduce flashing" on, the flash is half as bright and ramps twice as slowly.

---

## 9. The interface

### 9.1 Layout

```
                     THE RELIQUARY            <- gold leaf on the wall, in the world
                 [ portrait / vault door ]

              ┌────────────────────────┐
              │        PARTY  UP        │      <- lower middle, over the runner
              └────────────────────────┘
              ┌────────────────────────┐
              │          BOOKS          │
              └────────────────────────┘
                 [ lectern, book, candles ]
```

- **Position:** lower middle of the screen, over the runner and just above the lectern. Both buttons stay inside the **central 60% of the screen**, clear of Roblox's top bar and of phone notches.
- **Size:** each about 22% of the screen width, with a gap of about 2% of the screen height between them. Use `UIAspectRatioConstraint` so they keep their shape on every screen.

### 9.2 Style and behaviour

| | Spec |
|---|---|
| Look | Engraved **brass plaques** matching the case plaques. Dark lettering pressed into the brass. A serif such as Garamond or Merriweather from Roblox's font list. **No default buttons, no rounded corners** |
| Hover | The plaque brightens slightly, the letter spacing widens a touch, a soft metal clink plays, and the camera pushes in (2.2) |
| Party Up hover | The lectern candles flare |
| Books hover | The book's pages flutter and it glows faintly |
| Party Up click | A deep bell |
| Books click | A page turn |

**Party Up:**
- Opens the party panel: invite friends, see who's in, choose a map.
- **One extra candle lights on the lectern for each friend in the party.** The party shows in the room itself, not just in a list.
- Party members' avatars can appear standing along the runner, facing the camera.

**Books:**
- Opens the journal, styled like the existing Dybbuk card: cream paper, handwritten font, sketch art and "Evidence" icons.
- Entities you haven't met are **blotted, unreadable pages** until you've seen them in a map.

---

## 10. Sound

| Sound | Detail |
|---|---|
| Base layer | Rain on the windows, wind pressing at the glass, a low room tone |
| Close to the camera | Candles crackling |
| The clock | **Silent.** No tick where one should be |
| The open window | A faint creak as the curtain moves |
| Thunder | After every lightning flash, 1–3 s behind |
| The vault knocks | Three slow knocks every 2–3 minutes |
| Rare | A very distant keening, once every few minutes |
| Interface | Brass clink on hover, a bell for Party Up, a page turn for Books |

Keep everything quiet. This is a menu people sit in for a while; nothing should startle except the knocks, and even those are soft.

---

## 11. Colour palette

| Use | Colour (RGB) |
|---|---|
| Candle light | 255, 170, 90 |
| Moonlight | 140, 160, 200 |
| Case light | 200, 215, 255 |
| Dark oak | 45, 30, 22 |
| Wallpaper (green option) | 28, 42, 34 |
| Wallpaper (oxblood option) | 60, 22, 24 |
| Runner red | 110, 24, 28 |
| Brass | 181, 140, 70 |
| Darkest allowed | 18, 16, 15 |

---

## 12. What players should notice, in order

1. **First second:** the candlelit book in front of them and the two buttons.
2. **First few seconds:** the glowing cases down both sides, and the dark door at the end.
3. **First lightning flash:** the whole room: the portrait, the title, the cases' contents.
4. **First minute:** the empty case, the stopped clock, the covered mirror.
5. **First few minutes:** the knocks behind the door.

If any of these can't be seen at the moment it's meant to be, fix that before adding anything else.

---

## 13. Performance

- **No more than 3 shadow-casting lights** (7.2).
- `CastShadow = false` on every small prop (candles, quills, cards, books on shelves).
- Use Decals or textures for patterns (wallpaper, parquet, rain) instead of extra parts.
- Keep part count low. Every relic is a single model, with no hidden geometry inside the cases.
- **Test on a phone-sized screen** at the lowest graphics setting. The cases, book and buttons must still read clearly.

---

## 14. Build order

| Step | What | Done when |
|---|---|---|
| 1 | Camera (2.2) | The shot matches the diagram in 2.1, with no bending at the edges on 16:9 or ultrawide |
| 2 | Cases lit and windows moved and evened out (5.1, 7.2) | Cases glow cool and the warm/cool contrast reads; no single bright spot pulls the eye off-centre |
| 3 | Strongroom door, portrait and title (3) | The far end is the clear focal point |
| 4 | Walls, ceiling and floor (4) | The room's shape reads in the dark; no void above |
| 5 | Relics, plaques and cards (5.2) | Every case has its contents or dust sheet; plaques are readable from the camera |
| 6 | Buttons (9) | Both work, hover and click feedback in place, readable on phone and ultrawide |
| 7 | Lectern and set dressing (6) | Every item in 6.1–6.3 is in place |
| 8 | Storm, sound and particles (7.3, 8, 10) | Lightning reveals the room, sounds per section 10, safety setting works |
| 9 | Performance pass (13) | Smooth on a phone at the lowest graphics setting |

---

## 15. Open questions

1. **Is the lobby walkable**, or is it menu-camera only? If walkable, add 5.4 (cases light up as you approach; relics appear as you beat maps).
2. **Wallpaper colour:** bottle-green or oxblood?
3. **The subway relic** (5.2): lamp, slips, or leave it out?
4. **Is there a Play button** separate from Party Up, and a Settings button? If so, where do they go? (Suggested: Settings as a small brass key icon in the bottom right corner.)
