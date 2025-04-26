local M = {}

function M.setup(opts)
	require("vimatrix.config").setup(opts)

	M.namespace_id = vim.api.nvim_create_namespace("Vimatrix")

	M.create_user_commands()
	M.create_auto_commands()
	M.set_key_maps()
end

local reset = function()
	package.loaded["vimatrix"] = nil
	package.loaded["buffer"] = nil
	package.loaded["vx.config"] = nil
	package.loaded["colours.colourscheme"] = nil
	package.loaded["ticker"] = nil
	package.loaded["chances"] = nil
	package.loaded["errors"] = nil
end

local function stop_ticker()
	require("vimatrix.ticker").stop()
end

local vimatrix = function()
	local conf = require("vimatrix.config").options

	require("vimatrix.colours.provider").Init(conf.colourscheme)
	require("vimatrix.chances").init(conf.chances)
	require("vimatrix.alphabet.provider").init(conf.alphabet) --TODO: make configurable
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

function M.set_key_maps()
	vim.keymap.set("n", "<leader>R", reset, {})
	vim.keymap.set("n", "<leader>M", vimatrix, {})
	vim.keymap.set("n", "<leader>T", stop_ticker, {})
end

return M
