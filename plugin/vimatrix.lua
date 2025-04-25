local vimatrix = function()
	local conf = require("config").Defaults

	local alphs = ""
	for _, a in pairs(conf.alphabet) do
		for _, l in pairs(a) do
			alphs = alphs .. l
		end
	end

	require("colours.coloursets").Init(conf.colourset)
	require("chances.chances").init(conf.chances)
	require("alphabet.provider").init({ alphabet = alphs, randomize_on_init = true, randomize_on_pick = false }) --TODO: make configurable

	local bufid = require("buffer").Open()
	require("insert_vimatrix").insert(bufid)
end

local reset = function()
	package.loaded["insert_vimatrix"] = nil
	package.loaded["buffer"] = nil
	package.loaded["config"] = nil
	package.loaded["colours.coloursets"] = nil
	package.loaded["ticker.ticker"] = nil
	package.loaded["chances.chances"] = nil
end

local function stop_ticker()
	require("ticker.ticker").stop()
end

vim.api.nvim_create_user_command("VimatrixOpen", function(cmd)
	reset()
	vimatrix()
end, {
	nargs = "*",
})

vim.api.nvim_create_user_command("VimatrixStop", function(cmd)
	stop_ticker()
end, {
	nargs = "*",
})

vim.api.nvim_create_autocmd({ "BufWinLeave", "BufDelete" }, {
	pattern = "vimatrix",
	callback = stop_ticker,
})

vim.keymap.set("n", "<leader>R", reset, {})
vim.keymap.set("n", "<leader>M", vimatrix, {})
vim.keymap.set("n", "<leader>T", stop_ticker, {})
