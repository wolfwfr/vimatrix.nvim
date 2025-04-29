local M = {}

---@class vx.screensaver
---@field setup_deferral integer seconds to wait prior to activating screensaver timers (this helps if you automatically open multiple neovim sessions and screensavers are needlessly activated)
---@field timeout integer seconds after which to automatically display vimatrix
---@field ignore_focus boolean allows screensaver to activate on neovim instances that are out-of-focus (e.g. background)
---@field block_on_term boolean prevents screensaver from activating when terminal window is open
---@field block_on_cmd_line boolean prevents screensaver from activating when command-line window is open

---@class vx.auto_activation
---@field screensaver vx.screensaver screensaver specific settings
---@field on_filetype string[] filetypes for which to automatically display vimatrix

---@class vx.lane_timings
---@field max_fps integer frames per second for the fastest lane
---@field fps_variance integer the number of different speeds to assign to the various lanes; each speed is equal to 'fps/random(1,fps_variance)'
---@field glitch_fps_divider integer glitch symbols update at a slower pace than the droplet's progression; lane_glitch_fps_divider defines the ratio; glitch updates equal 'lane_fps/lane_glitch_fps_divider'
---@field max_timeout integer maximum number of seconds that any lane can idle prior to printing its first droplet; timeout is randomized to random(1, max_timeout)
---@field local_glitch_frame_sharing boolean determines whether glitch cells within one lane synchronise their timings
---@field global_glitch_frame_sharing boolean determines whether all glitch cells on screen synchronise their timings; overrules local_glitch_frame_sharing when true

---@class vx.window_props
---@field background string hex-code colour for window background; empty string will not set a custom background
---@field blend integer determines the blend (i.e.) transparency property of the window; see vim.api.keyset.win_config
---@field zindex integer zindex of the floating vimatrix window; see vim.api.keyset.win_config; 1000 seems to hide every other window underneath it but this includes messages and terminal applications from which vimatrix is not canceled.
---@field ignore_cells? function(integer, integer, integer) callback function that accepts parameters (old_buffer_id, line, column) and returns a boolean that determines if printing to that cell is allowed.
---
---@class vx.window
---@field general vx.window_props window settings that apply when no filetype match is found
---@field by_filetype table<string, vx.window_props> window settings that appy to the configured filetype

---@class vx.random
---@field body_to_tail integer determines the chance of a body cell at the top row changing into a tail cell
---@field head_to_glitch integer determines the chance of a head cell to leave behind a glitch cell
---@field head_to_tail integer determines the chance of a head cell to immediately be followed by a tail cell (nano-droplet)
---@field kill_head integer determines the chance or a head cell being killed on-screen
---@field new_head integer determines the chance of a new head cell forming when the lane is empty

---@class vx.droplet
---@field max_size_offset integer a positive value will force tail creation on a droplet when it has reached length == window_height - max_size_offset
---@field timings vx.lane_timings the timings of changes on screen
---@field random vx.random the chances of random events; each is a chance of 1 in x

---@class vx.config
---@field auto_activation vx.auto_activation --settings that relate to automatic activation of vimatrix.nvim
---@field window vx.window settings that relate to the window that vimatrix.nvim opens
---@field droplet vx.droplet settings that relate to the droplet lanes
---@field colourscheme vimatrix.colour_scheme | string
---@field highlight_props? vim.api.keyset.highlight Highlight definition to apply to rendered cells, accepts the following keys:
--- - bg: color name or "#RRGGBB"
--- - blend: integer between 0 and 100
--- - bold: boolean
--- - standout: boolean
--- - underline: boolean
--- - undercurl: boolean
--- - underdouble: boolean
--- - underdotted: boolean
--- - underdashed: boolean
--- - strikethrough: boolean
--- - italic: boolean
--- - reverse: boolean
---@field alphabet vx.alphabet_props
---@field logging vx.log.props error logging settings; BEWARE: errors can ammass quickly if something goes wrong
local defaults = {
	auto_activation = {
		screensaver = {
			setup_deferral = 10,
			timeout = 0,
			ignore_focus = false,
			block_on_term = true,
			block_on_cmd_line = true,
		},
		on_filetype = {},
	},
	window = {
		general = {
			background = "#000000", --black
			blend = 0,
			zindex = 10,
			ignore_cells = nil,
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
			fps_variance = 3,
			glitch_fps_divider = 12,
			max_timeout = 200,
			local_glitch_frame_sharing = false,
			global_glitch_frame_sharing = true,
		},
		random = {
			body_to_tail = 50,
			head_to_glitch = 20,
			head_to_tail = 50,
			kill_head = 150,
			new_head = 30,
		},
	},
	colourscheme = "matrix",
	highlight_props = {
		bold = true,
		blend = 1, -- quickfix for loss of highlight contrast with window blend;
		-- might be removed if it causes unwanted effects
	},
	alphabet = {
		built_in = { "katakana", "decimal", "symbols" },
		custom = {},
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
