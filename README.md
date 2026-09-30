# Skipastone

Catch cutscenes for the zones' headline Mythic items (Pirate Doubloon,
Koi Spirit, Siren's Lyre, Fallen Star, The Mothership, Frost Wyrm and
Crystal Golem), plus the 3-second replay used after a player's first find.

- Design, sound brief and integration guide: [docs/CUTSCENES.md](docs/CUTSCENES.md)
- Each scene's second-by-second timeline: the header of its file in
  `src/shared/Cutscenes/Scenes/`

The layout follows `default.project.json` (Rojo). Without Rojo, copy
`src/shared/Cutscenes` into ReplicatedStorage, `src/server/*` into
ServerScriptService and `src/client/*` into StarterPlayerScripts.
