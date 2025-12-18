local M = {}

local augroup_name = "vimatrix_screensaver"
local timer = require("vimatrix.timer")
local enabled = true

---@class vx.screensaver.props
---@field callback function
---
---@param props vx.screensaver.props
function M.setup(props)
	enabled = true

	local config = require("vimatrix.config").options.auto_activation.screensaver

	local function cb()
		-- NOTE: When Vim is in an 'unsafe' state, it awaits user input (see :h SafeState).
		-- In this state, autocommands do not execute, which can lead to unintentional
		-- execution of the vimatrix screensaver callback (e.g., in an unfocused window)
		-- due to missing 'timer.reset' from autocommands. To prevent this,
		-- the vimatrix screensaver aborts completely if the callback is triggered
		-- during an 'unsafe' state.
		if vim.fn.state("S") ~= "" then
			return
		end

		vim.schedule(function()
			props.callback()
		end)
	end

	local timeout = config.timeout
	if not timeout or timeout < 1 then
		return
	end

	vim.api.nvim_create_augroup(augroup_name, {})

	vim.defer_fn(function()
		if not enabled then
			return
		end

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
				group = augroup_name,
			})
		end

		if #start_events > 0 then
			vim.api.nvim_create_autocmd(start_events, {
				callback = reset,
				group = augroup_name,
			})
		end

		vim.api.nvim_create_autocmd("User", {
			pattern = "VimatrixUndo",
			callback = function()
				if not require("vimatrix.timer").has_stopped() then -- prevents unintended resets if event arrives while screensaver timer is not ticking
					reset()
				end
			end,
			group = augroup_name,
		})

		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged", "InsertCharPre" }, {
			callback = reset,
			group = augroup_name,
		})

		if config.ignore_focus then -- cannot start timer immediately and respect focus, because I cannot seem to obtain focus state outside of catching events
			reset()
		end
	end, config.setup_deferral * 1000)
end

function M.stop()
	vim.api.nvim_del_augroup_by_name(augroup_name)
	enabled = false
	timer.stop()
end

return M
