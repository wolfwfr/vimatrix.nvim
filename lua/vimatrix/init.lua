local config = require("vimatrix.config")

local M = {}

function M.setup(opts)
	config.setup(opts)

	M.create_user_commands()
	M.auto_activate_on_filetype()
	M.auto_activate_after_timeout()
end

local reset = function()
	package.loaded["vimatrix"] = nil
	package.loaded["buffer"] = nil
	package.loaded["config"] = nil
	package.loaded["colours.colourscheme"] = nil
	package.loaded["ticker"] = nil
	package.loaded["errors"] = nil
	package.loaded["orchestrator"] = nil
end

local function stop_ticker()
	require("vimatrix.ticker").stop()
end

local vimatrix = function()
	math.randomseed(os.time())

	local opts = config.options

	require("vimatrix.colours.provider").Init(opts.colourscheme)
	require("vimatrix.alphabet.provider").init(opts.alphabet)
	require("vimatrix.errors").init(opts.logging)

	require("vimatrix.buffer").open_overlay()
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged", "InsertCharPre" }, {
		callback = function()
			stop_ticker()
			require("vimatrix.buffer").undo()
		end,
	})
	require("vimatrix.orchestrator").rain()
end

function M.auto_activate_after_timeout()
	local timeout = config.options.auto_activation.screensaver_timeout
	if not timeout or timeout < 1 then
		return
	end

	local timer = require("vimatrix.timer")
	timer.start(timeout * 1000, vim.schedule_wrap(vimatrix))
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged", "InsertCharPre" }, {
		callback = function()
			timer.reset(timeout * 1000, vim.schedule_wrap(vimatrix))
		end,
	})
end

function M.auto_activate_on_filetype()
	vim.defer_fn(function()
		local buf = vim.api.nvim_get_current_buf()
		if vim.tbl_contains(config.options.auto_activation.on_filetype or {}, vim.bo[buf].filetype) then
			vimatrix()
		end
	end, 100)
end

function M.create_user_commands()
	vim.api.nvim_create_user_command("VimatrixOpen", function()
		reset()
		vimatrix()
	end, {})

	vim.api.nvim_create_user_command("VimatrixStop", function()
		stop_ticker()
	end, {})
end

return M
