local M = {}

---@class vx.auto_activation
---@field screensaver_setup_deferral integer seconds to wait prior to activating screensaver timers (this helps if you automatically open multiple neovim sessions and screensavers are needlessly activated)
---@field screensaver_timeout integer seconds after which to automatically display vimatrix
---@field on_filetype string[] filetypes for which to automatically display vimatrix

---@class vx.lane_timings
---@field max_fps integer frames per second for the fastest lane
---@field fps_variance integer the number of different speeds to assign to the various lanes; each speed is equal to 'fps/random(1,fps_variance)'
---@field glitch_fps_divider integer glitch symbols update at a slower pace than the droplet's progression; lane_glitch_fps_divider defines the ratio; glitch updates equal 'lane_fps/lane_glitch_fps_divider';
---@field max_timeout integer maximum number of seconds that any lane can idle prior to printing its first droplet; timeout is randomized to random(1, max_timeout)
---@field local_glitch_frame_sharing boolean
---@field global_glitch_frame_sharing boolean overrules local_glitch_frame_sharing
---
---@class vx.window_props
---@field background string hex-code colour for window background; empty string will not set a custom background
---@field blend integer
---
---@class vx.window
---@field general vx.window_props
---@field by_filetype table<string, vx.window_props>
---
---@class vx.random
---@field body_to_tail integer
---@field head_to_glitch integer
---@field head_to_tail integer
---@field kill_head integer determines the chance or a head being killed on-screen
---@field new_head integer determines the chance of a new head forming when the lane is empty
---
---@class vx.droplet
---@field max_size_offset integer a positive value will force tail creation on a droplet when it has reached length == window_height - max_size_offset
---@field timings vx.lane_timings
---@field random vx.random the chances of random events; each is a chance of 1 in x

---@class vx.config
---@field auto_activation vx.auto_activation
---@field window vx.window
---@field droplet vx.droplet --settings that relate to the droplet lanes
---@field colourscheme vimatrix.colour_scheme | string
---@field alphabet vx.alphabet_props
---@field logging vx.log.props error logging settings; BEWARE: errors can ammass quickly if something goes wrong
local defaults = {
	auto_activation = {
		screensaver_setup_deferral = 10,
		screensaver_timeout = 0,
		on_filetype = {},
	},
	window = {
		general = {
			background = "#000000", --black
			blend = 0,
		},
		by_filetype = {
			-- e.g:
			-- snacks_dashboard = {
			-- 	background = "",
			-- 	blend = 100,
			-- },
		},
	},
	droplet = {
		max_size_offset = 5,
		timings = {
			max_fps = 25,
			fps_variance = 2,
			glitch_fps_divider = 5,
			max_timeout = 200,
			local_glitch_frame_sharing = false,
			global_glitch_frame_sharing = false, -- true to the source material
		},
		random = {
			body_to_tail = 50,
			head_to_glitch = 150,
			head_to_tail = 50,
			kill_head = 150,
			new_head = 30,
		},
	},
	colourscheme = "green",
	alphabet = {
		built_in = { "katakana", "decimal", "symbols" },
		randomize_on_init = true,
		randomize_on_pick = false,
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
	if M.options.droplet.timings.glitch_fps_divider == 1 then
		M.options.droplet.timings.glitch_fps_divider = 2
	end
end

---@param opts vx.config
function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", defaults, opts or {})
	validate_and_fix()
end

return M
