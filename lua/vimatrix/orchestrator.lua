local lanes = require("vimatrix.droplet_lane")
local coloursets = require("vimatrix.colours.provider")
local logger = require("vimatrix.errors")
local ticker = require("vimatrix.ticker")
local config = require("vimatrix.config").options
local window = require("vimatrix.window")

local M = {}

local state = {}

local function reset_state()
	state = {
		lanes = {},
		bufid = 0,
		-- cell_grid[pos][lane_nr] = { char, hl_group, extmark_id }
		-- is the Lua-side source of truth (the in-memory representation).
		-- It is populated lazily by get_cell() and updated atomically with
		-- every nvim_buf_set_extmark() call. Extmarks are derived state.
		cell_grid = {},
	}
end

reset_state()

---@class cell
---@field char string              -- current rendered character; defaults to " "
---@field hl_group string         -- current highlight group; defaults to ""
---@field extmark_id integer?     -- nil until the cell first needs to render

---Get (creating if necessary) the in-memory cell record for the
---given (row, lane) screen position. row/lane are 1-indexed.
---@param pos integer
---@param lane integer
---@return cell
local function get_cell(pos, lane)
	local row = state.cell_grid[pos]
	if not row then
		row = {}
		state.cell_grid[pos] = row
	end
	local cell = row[lane]
	if not cell then
		cell = { char = " ", hl_group = "", extmark_id = nil }
		row[lane] = cell
	end
	return cell
end

--- @param n integer number of spaces
local space = function(n)
	local line_chars = ""
	for i = 1, n do
		line_chars = line_chars .. " "
	end
	return line_chars
end

---@param num_rows integer number of rows to fill
---@param num_cols integer number of cols to fill
local function setup_buffer(num_rows, num_cols)
	local line = space(num_cols)
	local lines = {}
	for i = 1, num_rows do
		lines[i] = line
	end
	vim.api.nvim_buf_set_lines(state.bufid, 0, -1, false, lines)
end

---@param num_rows integer number of character cells in each lane
---@param num_cols integer number of lanes to setup
local function setup_lanes(num_rows, num_cols)
	-- num_cols = 1
	for i = 1, num_cols do
		state.lanes[i] = lanes.new_lane({
			height = num_rows,
			fpu = math.random(config.droplet.timings.fps_variance),
			fpu_glitch = config.droplet.timings.glitch_fps_divider,
			timeout = math.random(1, config.droplet.timings.max_timeout),
			local_glitch_sharing = config.droplet.timings.local_glitch_frame_sharing,
			global_glitch_sharing = config.droplet.timings.global_glitch_frame_sharing,
		})
	end
end

local function print_error_and_stop(err)
	-- TODO: print stack-trace
	logger.print(err)
	ticker.stop()
end

local function print_event_virt(lane_nr, evt)
	local pos = evt.pos
	local window = require("vimatrix.window")

	if window.ignore_cells and window.ignore_cells(window.old_buffer, pos, lane_nr) then
		return
	end

	local cell = get_cell(pos, lane_nr)

	-- Fill any missing fields from the in-memory grid.
	local new_char = evt.char or cell.char
	local new_hl_group = evt.hl_group or cell.hl_group

	-- No-op short-circuit: if nothing changed, don't pay for an API call.
	if new_char == cell.char and new_hl_group == cell.hl_group then
		return
	end

	-- Lazy extmark creation: the first non-default write allocates the
	-- mark; subsequent writes update it in place.
	local extmark_id = cell.extmark_id

	-- create or update extmark
	local ok, res = pcall(vim.api.nvim_buf_set_extmark, state.bufid, coloursets.ns_id, pos - 1, lane_nr - 1, {
		virt_text = { { new_char, new_hl_group } },
		virt_text_win_col = lane_nr - 1,
		virt_text_pos = "overlay",
		id = extmark_id,
	})
	if not ok then -- res == err
		print_error_and_stop(res)
		return
	end

	-- call to nvim_buf_set_extmark created new extmark (& associated ID) if
	-- extmark_id was nil
	if extmark_id == nil then
		if not res or res == 0 then -- res == id
			print_error_and_stop("nvim_buf_set_extmark returned invalid id")
			return
		end
		cell.extmark_id = res
	end

	cell.char = new_char
	cell.hl_group = new_hl_group
end

local function update_lanes()
	for i, lane in ipairs(state.lanes) do
		local evts = lane:advance()
		for _, evt in pairs(evts or {}) do
			print_event_virt(i, evt)
		end
	end
end

-- setup_cancellation sets up cancellation events and -keys.
-- These events and keys will call the cancellation function.
-- Temporary, buffer-local keymaps are created for the cancellation keys.
-- These could override existing buffer-local keymaps. Therefore, the setup makes a local
-- copy of the existing keymaps that will be overridden and restores them during
-- cancellation.

---@param cancel_events string[]
---@param cancel_keys string[]
local function setup_cancellation(cancel_events, cancel_keys)
	local utils = require("vimatrix.utils")
	local old_buffer = window.old_buffer

	local maps = utils.keymaps_list_buf(old_buffer, cancel_keys)

	local function undo()
		if not window.is_open() then
			return
		end
		ticker.stop()
		window.undo()
		utils.keymaps_restore_buf(old_buffer, maps)
		vim.api.nvim_exec_autocmds("User", { pattern = "VimatrixUndo" })
	end

	if cancel_events and #cancel_events > 0 then
		vim.api.nvim_create_autocmd(cancel_events, {
			once = true,
			callback = undo,
		})
	end

	utils.keymaps_set_all_buf(old_buffer, cancel_keys, undo)
end

---@param cancel_events string[]
---@param cancel_keys string[]
M.rain = function(cancel_events, cancel_keys)
	if window.is_open() then
		return
	end
	reset_state()

	math.randomseed(os.time())

	require("vimatrix.colours.provider").Init(config.colourscheme, config.highlight_props)
	require("vimatrix.alphabet.provider").init(config.alphabet)
	require("vimatrix.errors").init(config.logging)

	local ok = window.open_overlay()
	if not ok then
		-- could not open window
		return
	end

	local num_cols = vim.fn.winwidth(window.winid)
	local num_rows = vim.fn.winheight(window.winid)
	state.bufid = window.bufid

	setup_cancellation(cancel_events, cancel_keys)
	setup_buffer(num_rows, num_cols)
	setup_lanes(num_rows, num_cols)

	ticker.start(1000 / config.droplet.timings.max_fps, vim.schedule_wrap(update_lanes))
end

return M
