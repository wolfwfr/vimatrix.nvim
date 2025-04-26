local M = {}

function M.setup(opts)
	require("vimatrix.config").setup(opts)

	M.create_user_commands()
	M.create_auto_commands()
end

local reset = function()
	package.loaded["vimatrix"] = nil
	package.loaded["buffer"] = nil
	package.loaded["config"] = nil
	package.loaded["colours.colourscheme"] = nil
	package.loaded["ticker"] = nil
	package.loaded["chances"] = nil
	package.loaded["errors"] = nil
	package.loaded["orchestrator"] = nil
end

local function stop_ticker()
	require("vimatrix.ticker").stop()
end

local vimatrix = function()
	math.randomseed(os.time())

	local conf = require("vimatrix.config").options

	require("vimatrix.colours.provider").Init(conf.colourscheme)
	require("vimatrix.chances").init(conf.chances)
	require("vimatrix.alphabet.provider").init(conf.alphabet)
	require("vimatrix.errors").init(conf.logging)

	local bufid = require("vimatrix.buffer").Open()
	require("vimatrix.orchestrator").insert(bufid)
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

function M.create_auto_commands()
	vim.api.nvim_create_autocmd({ "BufWinLeave", "BufDelete" }, {
		pattern = "vimatrix",
		callback = stop_ticker,
	})
end

return M
