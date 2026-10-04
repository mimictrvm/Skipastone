--[[
	Minimal signal used between server systems so they don't have to
	require each other in a circle. Handlers run in their own thread.
]]

export type Connection = { Disconnect: () -> () }

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ handlers = {} :: { (...any) -> () } }, Signal)
end

function Signal:Connect(fn: (...any) -> ()): Connection
	table.insert(self.handlers, fn)
	return {
		Disconnect = function()
			local i = table.find(self.handlers, fn)
			if i then
				table.remove(self.handlers, i)
			end
		end,
	}
end

function Signal:Fire(...: any)
	for _, fn in table.clone(self.handlers) do
		task.spawn(fn, ...)
	end
end

return Signal
