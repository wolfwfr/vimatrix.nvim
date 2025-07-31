local config = require("vimatrix.config")

local M = {}

---@class vx.vimatrix_runner_props
---@field focus_listener? boolean

---@param props? vx.vimatrix_runner_props
local rain = function(props)
	local events = { "CursorMoved", "CursorMovedI", "ModeChanged", "InsertCharPre" }
	local _ = props and props.focus_listener and table.insert(events, "FocusLost") or nil

	require("vimatrix.orchestrator").rain(events, config.options.keys.cancellation)
end

local function auto_activate_after_timeout()
	local cb = function()
		rain({ focus_listener = true })
	end
	require("vimatrix.screensaver").setup({ callback = cb })
end

local function auto_activate_on_filetype()
	require("vimatrix.file_activation").activate_on_file({ callback = rain })
end

local function create_user_commands()
	vim.api.nvim_create_user_command("VimatrixOpen", rain, {})

	vim.api.nvim_create_user_command("VimatrixStop", require("vimatrix.ticker").stop, {})

	vim.api.nvim_create_user_command("VimatrixClose", function()
		require("vimatrix.ticker").stop()
		require("vimatrix.window").undo()
	end, {})

	vim.api.nvim_create_user_command("VimatrixScreenSaverStop", require("vimatrix.screensaver").stop, {})
	vim.api.nvim_create_user_command("VimatrixScreenSaverRestart", auto_activate_after_timeout, {})
end

function M.setup(opts)
	config.setup(opts)

	create_user_commands()
	auto_activate_on_filetype()
	auto_activate_after_timeout()
end

return M
