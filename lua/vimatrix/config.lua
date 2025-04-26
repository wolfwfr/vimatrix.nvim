local alph = require("vimatrix.alphabet.symbols")

local M = {}

---@class lane_timings
---@field max_fps integer frames per second for the fastest lane
---@field fps_variance integer the number of different speeds to assign to the various lanes; each speed is equal to 'fps/random(1,fps_variance)'
---@field glitch_fps_divider integer glitch symbols update at a slower pace than the droplet's progression; lane_glitch_fps_divider defines the ratio; glitch updates equal 'lane_fps/lane_glitch_fps_divider';
---@field max_timeout integer maximum number of seconds that any lane can idle prior to printing its first droplet; timeout is randomized to random(1, max_timeout)

---@class vx.chances
---@field body_to_tail integer
---@field head_to_glitch integer
---@field head_to_tail integer
---@field empty_stay_empty integer --TODO: naming
---
---@class vx.config
---@field colourscheme vimatrix.colour_scheme | string
---@field alphabet vx.alphabet_props
---@field chances vx.chances the chances of random events; each is a chance of 1 in x
---@field logging vx.log.props error logging settings; BEWARE: errors can ammass quickly if something goes wrong
local defaults = {
	timings = {
		max_fps = 25,
		fps_variance = 2,
		glitch_fps_divider = 5,
		max_timeout = 200,
	},
	colourscheme = "green",
	alphabet = {
		symbols = { alph.katakana, alph.decimal, alph.symbols },
		randomize_on_init = true,
		randomize_on_pick = false,
	},
	chances = {
		body_to_tail = -150,
		head_to_glitch = 150,
		head_to_tail = 50,
		empty_stay_empty = 2,
	},
	logging = {
		print_errors = false,
		log_level = vim.log.levels.DEBUG,
	},
}

---@type vx.config
M.options = defaults

local function validate_and_fix()
	-- glitches must update at least twice as slow as max-fps
	if M.options.timings.glitch_fps_divider == 1 then
		M.options.timings.glitch_fps_divider = 2
	end
end

---@param opts vx.config
function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", defaults, opts or {})
	validate_and_fix()
end

return M
