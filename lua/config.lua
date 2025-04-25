local alph = require("alphabets")

---@class vimatrix.Config
---@field colourset vimatrix.Colourset
---@field alphabet string[][]
local defaults = {
	colourset = {
		head = "#f2fff2", -- greenish white
		body = { "#27b427", "#1b671b", "#138c13" }, -- various green
		tail = "#425842", -- greenish gray
	},
	logging = {
		print_errors = false,
		log_level = vim.log.levels.DEBUG,
	},
	alphabet = { alph.katakana, alph.decimal, alph.symbols },
	fps = 5,
	chances = {
		body_to_tail = 150,
		head_to_glitch = 100,
		head_to_tail = -1,
		empty_ignore_head = -1,
		empty_stay_empty = 2,
	},
}

local M = {}

M.Defaults = defaults

return M
