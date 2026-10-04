--[[
	Checks the paste-in installer against Rojo, outside Studio, with Lune:

	    rojo build default.project.json -o build/scripts.rbxlx
	    lune run tools/check_installer.luau AshgroveInstaller.lua build/scripts.rbxlx
	    lune run tools/check_installer.luau installer-parts/*.lua build/scripts.rbxlx

	Runs the installer against an empty DataModel and compares the tree it
	makes (names, classes, source sizes) with the one Rojo builds.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local game = roblox.Instance.new("DataModel")
local workspace = game:GetService("Workspace")
local sp = game:GetService("StarterPlayer")
local sps = roblox.Instance.new("StarterPlayerScripts"); sps.Name = "StarterPlayerScripts"; sps.Parent = sp
local bp = roblox.Instance.new("Part"); bp.Name = "Baseplate"; bp.Parent = workspace

local env = { game = game, workspace = workspace, print = print, assert = assert, pcall = pcall, error = error, typeof = typeof, math = math, table = table, string = string, ipairs = ipairs, pairs = pairs, next = next, tostring = tostring, setmetatable = setmetatable, type = type, select = select }
for k, v in roblox do env[k] = v end
-- Studio's require: run a ModuleScript's Source once, with `script` set.
local loaded = {}
env.require = function(module)
	if loaded[module] == nil then
		local menv = table.clone(env)
		menv.script = module
		loaded[module] = luau.load(module.Source, { debugName = module.Name, environment = menv })()
	end
	return loaded[module]
end

-- Every argument but the last is an installer file, run in order (the
-- split parts can be checked this way too).
for i = 1, #process.args - 1 do
	luau.load(fs.readFile(process.args[i]), { debugName = process.args[i], environment = env })()
end

local function tree(root, prefix, out)
	for _, c in root:GetChildren() do
		local line = prefix .. c.Name .. " (" .. c.ClassName .. ")"
		if c:IsA("LuaSourceContainer") then line ..= " " .. #c.Source end
		table.insert(out, line)
		tree(c, prefix .. c.Name .. "/", out)
	end
end
local mine = {}
tree(game:GetService("ReplicatedStorage"), "RS/", mine)
tree(game:GetService("ServerScriptService"), "SSS/", mine)
tree(sps, "SPS/", mine)
table.sort(mine)

local place = roblox.deserializePlace(fs.readFile(process.args[#process.args]))
local theirs = {}
tree(place:GetService("ReplicatedStorage"), "RS/", theirs)
tree(place:GetService("ServerScriptService"), "SSS/", theirs)
tree(place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"), "SPS/", theirs)
table.sort(theirs)
local a, b = table.concat(mine, "\n"), table.concat(theirs, "\n")
print(#mine, "instances from installer;", #theirs, "from rojo;", if a == b then "IDENTICAL" else "DIFFERENT")
if a ~= b then print(a) print("----") print(b) end
print("Baseplate removed:", workspace:FindFirstChild("Baseplate") == nil, " house built:", workspace:FindFirstChild("AshgroveHouse") ~= nil)
