--[[
	Builds a ready-to-open Studio place with the greybox already in the
	Workspace (so level designers can see and move it before pressing Play).
	Needs Rojo and Lune:

	    rojo build default.project.json -o build/scripts.rbxlx
	    lune run tools/build_place.luau build/scripts.rbxlx build/Ashgrove.rbxl
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local input, output = process.args[1], process.args[2]
assert(input and output, "usage: lune run tools/build_place.luau <in.rbxlx> <out.rbxl>")

local game = roblox.deserializePlace(fs.readFile(input))
local workspace = game:GetService("Workspace")

local env: { [string]: any } = {
	game = game,
	workspace = workspace,
	math = math,
	table = table,
	string = string,
	typeof = typeof,
	type = type,
	pairs = pairs,
	ipairs = ipairs,
	next = next,
	print = print,
	error = error,
	assert = assert,
	tostring = tostring,
	tonumber = tonumber,
	setmetatable = setmetatable,
	select = select,
}
for key, value in roblox :: any do
	env[key] = value
end

local greybox = game:GetService("ServerScriptService").Ashgrove.Greybox
luau.load(greybox.Source, { debugName = "Greybox", environment = env })().build()

fs.writeFile(output, roblox.serializePlace(game))
print("wrote " .. output)
