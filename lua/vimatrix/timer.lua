local uv = vim.uv or vim.loop

---@class vx.timer
local M = {}

M.timer = uv.new_timer()

local state = {
	stopped = false,
}

function M.stop()
	state.stopped = true
	M.timer:stop()
	M.timer:close()
	M.timer = uv.new_timer()
end

function M.has_stopped()
	return state.stopped
end

---@param timeout integer milliseconds
---@param cb function callback function
function M.start(timeout, cb)
	state.stopped = false
	M.timer:start(timeout, 0, cb)
end

function M.reset(timeout, cb)
	if M.timer:is_active() then
		M.stop()
	end
	M.start(timeout, cb)
end

return M
