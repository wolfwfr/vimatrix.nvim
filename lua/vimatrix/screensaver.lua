local M = {}

---@class vx.screensaver.props
---@field callback function
---
---@param props vx.screensaver.props
function M.setup(props)
	local config = require("vimatrix.config").options.auto_activation.screensaver
	local cb = vim.schedule_wrap(props.callback)
	local timeout = config.timeout
	if not timeout or timeout < 1 then
		return
	end

	local timer = require("vimatrix.timer")

	vim.defer_fn(function()
		local stop_events = {}
		local start_events = {}
		local ignore_modes = {}

		if not config.ignore_focus then
			table.insert(stop_events, "FocusLost")
			table.insert(start_events, "FocusGained")
		end

		if config.block_on_term then
			table.insert(stop_events, "TermEnter")
			table.insert(start_events, "TermLeave")
			table.insert(ignore_modes, "t")
			table.insert(ignore_modes, "nt")
		end

		if config.block_on_cmd_line then
			table.insert(stop_events, "CmdlineEnter")
			table.insert(stop_events, "CmdlineEnter")
			table.insert(start_events, "CmdwinLeave")
			table.insert(start_events, "CmdwinLeave")
			table.insert(ignore_modes, "c")
		end

		local reset = function()
			local m = vim.api.nvim_get_mode().mode
			if vim.tbl_contains(ignore_modes, m) then
				return
			end
			timer.reset(timeout * 1000, cb)
		end

		if #stop_events > 0 then
			vim.api.nvim_create_autocmd(stop_events, {
				callback = timer.stop,
			})
		end

		if #start_events > 0 then
			vim.api.nvim_create_autocmd(start_events, {
				callback = reset,
			})
		end

		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged", "InsertCharPre" }, {
			callback = reset,
		})

		if config.ignore_focus then -- cannot start timer immediately and respect focus, because I cannot seem to obtain focus state outside of catching events
			reset()
		end
	end, config.setup_deferral * 1000)
end

return M
