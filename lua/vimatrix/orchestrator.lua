local lanes = require("vimatrix.droplet_lane")
local coloursets = require("vimatrix.colours.provider")
local logger = require("vimatrix.errors")
local ticker = require("vimatrix.ticker")
local config = require("vimatrix.config").options
local buffer = require("vimatrix.window")

local M = {}

local state = {
	lanes = {},
	bufid = 0,
	extmarks = {},
}

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
local function setup_buffer_virt(num_rows, num_cols)
	for i = 1, num_rows do
		for j = 1, num_cols do
			local id = vim.api.nvim_buf_set_extmark(state.bufid, coloursets.ns_id, i - 1, j - 1, {
				virt_text_win_col = j - 1,
				virt_text_pos = "overlay",
			})
			local row = state.extmarks[i] or {}
			row[j] = id
			state.extmarks[i] = row
		end
	end
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
	local char = evt.char
	local hl_group = evt.hl_group
	local extmark_id = state.extmarks[pos][lane_nr]

	local extmark = {}
	if not char or not hl_group then
		local ok, res =
			pcall(vim.api.nvim_buf_get_extmark_by_id, state.bufid, coloursets.ns_id, extmark_id, { details = true })
		if ok then
			extmark = res[3]
		else
			print_error_and_stop(res)
			return
		end
	end

	local vt = extmark and extmark.virt_text or { { " ", "" } }
	char = char or vt[1][1]
	hl_group = hl_group or vt[1][2]

	local ok, err = pcall(vim.api.nvim_buf_del_extmark, state.bufid, coloursets.ns_id, extmark_id)
	if not ok then
		print_error_and_stop(err)
		return
	end

	local ok, err = pcall(vim.api.nvim_buf_set_extmark, state.bufid, coloursets.ns_id, pos - 1, lane_nr - 1, {
		virt_text = { { char, hl_group } },
		virt_text_win_col = lane_nr - 1,
		id = extmark_id,
	})
	if not ok then
		print_error_and_stop(err)
		return
	end
end

local function update_lanes()
	for i, lane in ipairs(state.lanes) do
		local evts = lane:advance()
		for _, evt in pairs(evts or {}) do
			print_event_virt(i, evt)
		end
	end
end

M.rain = function()
	math.randomseed(os.time())

	require("vimatrix.colours.provider").Init(config.colourscheme, config.highlight_props)
	require("vimatrix.alphabet.provider").init(config.alphabet)
	require("vimatrix.errors").init(config.logging)

	local ok = require("vimatrix.window").open_overlay()
	if not ok then
		-- could not open window
		return
	end

	local num_cols = vim.fn.winwidth(buffer.winid)
	local num_rows = vim.fn.winheight(buffer.winid)
	state.bufid = buffer.bufid

	setup_buffer(num_rows, num_cols)
	setup_buffer_virt(num_rows, num_cols)
	setup_lanes(num_rows, num_cols)

	ticker.start(1000 / config.droplet.timings.max_fps, vim.schedule_wrap(update_lanes))
end

return M
