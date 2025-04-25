local uv = vim.uv or vim.loop

---@class ticker
local M = {}
--
-- local pp = {
-- 	i = 0,
-- }
-- function pp.print()
-- 	print(pp.i)
-- 	pp.i = pp.i + 1
-- end

local state = {
	stop_timer = false,
	counter = 0,
}
M.timer = uv.new_timer()

function M.stop()
	state.stop_timer = true
end

---@return boolean
local function should_stop(max)
	if not max or max < 1 then
		return state.stop_timer
	end

	state.counter = state.counter + 1
	if max and state.counter > max then
		print("stopped")
		state.stop_timer = true
	end

	return state.stop_timer
end

---@param interval integer milliseconds
---@param cb function callback function
---@param max integer? stops timer after this many cycles [optional]
function M.start(interval, cb, max)
	state.stop_timer = false
	M.timer:start(0, interval, function()
		if should_stop(max) then
			M.timer:stop()
			return
		end
		cb()
	end)
end

-- M.start(1000, pp.print, 12)

return M
