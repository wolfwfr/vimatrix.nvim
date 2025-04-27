--TODO: cleanup this code
local config = require("vimatrix.config")

local M = {}

function M.setup(opts)
	require("vimatrix.config").setup(opts)

	M.create_user_commands()
	M.auto_activate_on_filetype()
	M.auto_activate_after_timeout()
end

local function stop_ticker()
	require("vimatrix.ticker").stop()
end

---@class vx.vimatrix_runner_props
---@field focus_listener boolean?

---@param props vx.vimatrix_runner_props?
local rain = function(props)
	local events = { "CursorMoved", "CursorMovedI", "ModeChanged", "InsertCharPre" }
	if props and props.focus_listener then
		table.insert(events, "FocusLost")
	end

	vim.api.nvim_create_autocmd(events, {
		callback = function()
			stop_ticker()
			require("vimatrix.window").undo()
		end,
	})

	require("vimatrix.orchestrator").rain()
end

function M.auto_activate_after_timeout()
	local cb = vim.schedule_wrap(function()
		rain({
			focus_listener = true,
		})
	end)
	require("vimatrix.screensaver").setup({ callback = cb })
end

function M.auto_activate_on_filetype()
	local cb = rain
	require("vimatrix.file_activation").activate_on_file({ callback = cb })
end

function M.create_user_commands()
	vim.api.nvim_create_user_command("VimatrixOpen", function()
		rain()
	end, {})

	vim.api.nvim_create_user_command("VimatrixStop", function()
		stop_ticker()
	end, {})
end

return M
