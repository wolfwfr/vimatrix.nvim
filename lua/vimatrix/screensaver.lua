local config = require("vimatrix.config").options.auto_activation

local M = {}

---@class vx.screensaver.props
---@field callback function
---
---@param props vx.screensaver.props
function M.setup(props)
	local timeout = config.screensaver_timeout
	if not timeout or timeout < 1 then
		return
	end

	local timer = require("vimatrix.timer")

	vim.defer_fn(function()
		vim.api.nvim_create_autocmd({ "FocusLost" }, {
			callback = function()
				timer.stop()
				package.loaded["timer"] = nil
				timer = require("vimatrix.timer")
			end,
		})
		vim.api.nvim_create_autocmd({ "FocusGained" }, {
			callback = function()
				timer.start(timeout * 1000, props.callback)
			end,
		})
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged", "InsertCharPre" }, {
			callback = function()
				timer.reset(timeout * 1000, props.callback)
			end,
		})
	end, config.screensaver_setup_deferral * 1000)
end

return M
