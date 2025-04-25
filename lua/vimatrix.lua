local lanes = require("droplet_lane.droplet_lane")
local coloursets = require("colours.coloursets")

local M = {}

local state = {
	lanes = {},
	bufid = 0,
	extmarks = {},
}

math.randomseed(os.time())

--- @param n integer number of spaces
local space = function(n)
	local line_chars = ""
	for i = 1, n + 1 do
		line_chars = line_chars .. " "
	end
	return line_chars
end

---@param num_rows integer number of rows to fill
---@param num_cols integer number of cols to fill
local function setup_buffer_virt(num_rows, num_cols)
	for i = 1, num_rows do
		for j = 1, num_cols do
			local id = vim.api.nvim_buf_set_extmark(state.bufid, coloursets.ns_id, i - 1, j, {
				end_line = i - 1,
				end_col = j + 1,
				virt_text = { { " ", "VimatrixDropletBody1" } },
				virt_text_win_col = j,
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
	-- num_cols = 2
	for i = 1, num_cols - 1 do
		state.lanes[i] = lanes.new_lane({
			height = num_rows,
			fpu = math.random(2), -- TODO: configure fpu
			fpu_glitch = 10, -- TODO: configure fpu_glitch
			timeout = math.random(1, 200), -- TODO: configure timeout
		})
	end
end

local function print_event_virt(lane_nr, evt)
	local pos = evt.pos
	local char = evt.char
	local hl_group = evt.hl_group
	local extmark_id = state.extmarks[pos][lane_nr]

	local extmark = {}
	if not char or not hl_group then
		extmark = vim.api.nvim_buf_get_extmark_by_id(state.bufid, coloursets.ns_id, extmark_id, { details = true })[3]
	end

	if not char then
		char = extmark.virt_text[1][1]
	end

	if not hl_group then
		hl_group = extmark.virt_text[1][2]
	end

	if char == "" then
		char = " " -- replace character with space
	end

	vim.api.nvim_buf_del_extmark(state.bufid, coloursets.ns_id, extmark_id)

	vim.api.nvim_buf_set_extmark(state.bufid, coloursets.ns_id, pos - 1, lane_nr, {
		end_line = pos - 1,
		end_col = lane_nr + 1,
		virt_text = { { char, hl_group } },
		virt_text_win_col = lane_nr,
		id = extmark_id,
	})
end

local function update_lanes()
	for i, lane in ipairs(state.lanes) do
		local evts = lane:advance()
		for _, evt in pairs(evts or {}) do
			print_event_virt(i, evt)
		end
	end
end

---@param bufid integer id of the buffer to write to
M.insert = function(bufid)
	local num_cols = vim.fn.winwidth(0)
	local num_rows = vim.fn.winheight(0)
	state.bufid = bufid

	setup_buffer(num_rows, num_cols)
	setup_buffer_virt(num_rows, num_cols)
	setup_lanes(num_rows, num_cols)

	require("ticker.ticker").start(50, vim.schedule_wrap(update_lanes))
end

return M
