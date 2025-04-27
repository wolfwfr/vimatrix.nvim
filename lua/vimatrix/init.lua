local M = {}

local function stop_ticker()
	require("vimatrix.ticker").stop()
end

---@class vx.vimatrix_runner_props
---@field focus_listener boolean?

---@param props vx.vimatrix_runner_props?
local rain = function(props)
	local events = { "CursorMoved", "CursorMovedI", "ModeChanged", "InsertCharPre" }
	local _ = props and props.focus_listener and table.insert(events, "FocusLost") or nil

	vim.api.nvim_create_autocmd(events, {
		callback = function()
			stop_ticker()
			require("vimatrix.window").undo()
		end,
	})

	require("vimatrix.orchestrator").rain()
end

local function auto_activate_after_timeout()
	local cb = vim.schedule_wrap(function()
		rain({
			focus_listener = true,
		})
	end)
	require("vimatrix.screensaver").setup({ callback = cb })
end

local function auto_activate_on_filetype()
	local cb = rain
	require("vimatrix.file_activation").activate_on_file({ callback = cb })
end

local function create_user_commands()
	vim.api.nvim_create_user_command("VimatrixOpen", function()
		rain()
	end, {})

	vim.api.nvim_create_user_command("VimatrixStop", function()
		stop_ticker()
	end, {})
end

function M.setup(opts)
	require("vimatrix.config").setup(opts)

	create_user_commands()
	auto_activate_on_filetype()
	auto_activate_after_timeout()
end

return M
