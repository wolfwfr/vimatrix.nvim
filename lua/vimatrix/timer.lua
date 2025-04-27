local uv = vim.uv or vim.loop

---@class vx.timer
local M = {}

local state = {
	stop_timer = false,
}
M.timer = uv.new_timer()

function M.stop()
	state.stop_timer = true
end

---@return boolean
local function should_stop()
	return state.stop_timer
end

---@param timeout integer milliseconds
---@param cb function callback function
function M.start(timeout, cb)
	state.stop_timer = false
	M.timer:start(timeout, 0, function()
		if should_stop() then
			M.timer:stop()
			return
		end
		cb()
	end)
end

function M.reset(timeout, cb)
	state.stop_timer = false
	if M.timer:is_active() then
		M.timer:stop()
	end
	M.timer:start(timeout, 0, function()
		if should_stop() then
			M.timer:stop()
			return
		end
		cb()
	end)
end

return M
