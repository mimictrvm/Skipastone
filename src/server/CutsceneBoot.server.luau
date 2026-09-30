-- Loads CutsceneService at server start so its remotes exist before any
-- client looks for them, even if the loot code requires it lazily.
require(script.Parent:WaitForChild("CutsceneService"))
