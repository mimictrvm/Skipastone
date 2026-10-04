--[[
	Doors: story locks and the Banshee's lockout.

	A door part has DoorId, Wing (the wing it leads into), StartsLocked and
	LockedText. Locked doors are solid with a prompt that explains why.

	Lockout: fleeing a keen "costs you the wing for now". The wing's doors
	are hung with black cloth and won't open for a while.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Ashgrove"):WaitForChild("Config"))

local Map = require(script.Parent.Map)
local Say = require(script.Parent.Say)

local Doors = {}

type Door = {
	part: BasePart,
	wing: string,
	locked: boolean,
	lockoutUntil: number,
	text: string,
	colour: Color3,
	material: Enum.Material,
	prompt: ProximityPrompt,
}

local doors: { [string]: Door } = {}

local function apply(door: Door)
	local lockedOut = os.clock() < door.lockoutUntil
	local closed = door.locked or lockedOut
	door.part.CanCollide = closed
	door.part.CanQuery = closed
	door.part.Transparency = if closed then 0 else 1
	if lockedOut and not door.locked then
		door.part.Color = Color3.fromRGB(12, 12, 14)
		door.part.Material = Enum.Material.Fabric
		door.prompt.ObjectText = "Black cloth hangs across the doorway"
	else
		door.part.Color = door.colour
		door.part.Material = door.material
		door.prompt.ObjectText = door.text
	end
	door.prompt.Enabled = closed
end

function Doors.setLocked(doorId: string, locked: boolean)
	local door = doors[doorId]
	if door then
		door.locked = locked
		apply(door)
	end
end

function Doors.lockout(wing: string, seconds: number?)
	local duration = seconds or Config.banshee.leaveLockout
	for _, door in doors do
		if door.wing == wing and not door.locked then
			door.lockoutUntil = os.clock() + duration
			apply(door)
			task.delay(duration + 0.1, apply, door)
		end
	end
end

function Doors.clearLockouts()
	for _, door in doors do
		door.lockoutUntil = 0
		apply(door)
	end
end

function Doors.setup()
	for _, p in Map.interact("Doors"):GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("DoorId") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Try the door"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Parent = p
			local door: Door = {
				part = p,
				wing = p:GetAttribute("Wing") or "",
				locked = p:GetAttribute("StartsLocked") == true,
				lockoutUntil = 0,
				text = p:GetAttribute("LockedText") or "Locked.",
				colour = p.Color,
				material = p.Material,
				prompt = prompt,
			}
			prompt.Triggered:Connect(function(player)
				if door.locked then
					Say.to(player, door.text, 3, "hint")
				elseif os.clock() < door.lockoutUntil then
					Say.to(player, "Black cloth over the doorway. It won't let you back in yet.", 3, "hint")
				end
			end)
			doors[p:GetAttribute("DoorId")] = door
			apply(door)
		end
	end
end

return Doors
