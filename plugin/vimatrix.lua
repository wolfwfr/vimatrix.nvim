local name = "vimatrix"

local vimatrix = function()
	local conf = require("config").Defaults

	if #conf.alphabet == 0 then
		vim.notify(name .. " could not find alphabet, please check your config")
		return
	end

	local alphs = conf.alphabet[1]
	for i, a in pairs(conf.alphabet) do
		if i ~= 1 then
			for _, e in pairs(a) do
				table.insert(alphs, e)
			end
		end
	end

	require("colours.coloursets").Init(conf.colourset)
	require("chances.chances").init(conf.chances)
	require("alphabet.provider").init({ alphabet = alphs, randomize_on_init = true, randomize_on_pick = false }) --TODO: make configurable
	require("errors").init(conf.logging)

	local bufid = require("buffer").Open()
	require("vimatrix").insert(bufid)
end

local reset = function()
	package.loaded["insert_vimatrix"] = nil
	package.loaded["buffer"] = nil
	package.loaded["config"] = nil
	package.loaded["colours.coloursets"] = nil
	package.loaded["ticker"] = nil
	package.loaded["chances.chances"] = nil
end

local function stop_ticker()
	require("ticker").stop()
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
