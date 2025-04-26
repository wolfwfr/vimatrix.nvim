local ch = require("vimatrix.chances")
local coloursets = require("vimatrix.colours.provider")
local alph = require("vimatrix.alphabet.provider")

local M = {}

---@class lane_props
---@field height integer the number of display cells in the window column
---@field fpu integer the number of frames per update, essentially, the interval between updates of the droplets in this lane
---@field fpu_glitch integer the number of frames per update for glitch characters, must be greater or equal to fpu
---@field timeout integer the number of updates to skip upon first run

---@class cell
---@field pos integer --the display cell that contains the droplet-character; 1-indexed
---@field char string --single character
---@field hl_group string

---@class lane
---@field props lane_props
---@field timeout_counter integer
---@field frame integer
---@field head cell
---@field tail cell
---@field glitch cell[]
local lane = {}

-- a droplet-event signifies a buffer change
---@class event
---@field pos integer position in the lane; 1-indexed
---@field char string single character to print to buffer
---@field hl_group string

---@return boolean
function lane:has_head()
	return self.head ~= nil
end

---@return boolean
function lane:has_tail()
	return self.tail ~= nil
end

---@return boolean
function lane:is_head_and_tail_only()
	return self:has_tail() and self.tail.pos == self.head.pos - 1
end

---@return boolean
function lane:has_body_at_top()
	return self:has_head() and self.head.pos ~= 1 and not self:has_tail()
end

---@return boolean
function lane:has_head_at_top()
	return self:has_head() and self.head.pos == 1
end

---@return boolean
function lane:ready_for_head()
	return not self:has_tail() and not self:has_head() -- TODO: consider making configurable
end

---@return boolean
function lane:has_glitch()
	return self.glitch ~= nil and #self.glitch > 0
end

local function as_array(obj)
	return { obj }
end

---@param lane lane
---@return event[]?
local function replace_head_cell(lane)
	local char = lane.head.char

	if lane:is_head_and_tail_only() then
		return
	end

	-- convenience: only simple body cells at the top, no glitches
	if lane:has_head_at_top() then
		if ch.chances.head_to_tail > 0 and math.random(ch.chances.head_to_tail) == 1 then
			lane.tail = {
				pos = lane.head.pos,
				char = char,
				hl_group = coloursets.get_colour("tail"),
			}
			return as_array({
				pos = lane.tail.pos,
				char = lane.tail.char,
				hl_group = lane.tail.hl_group,
			})
		end
	end

	if ch.chances.head_to_glitch > 0 and math.random(ch.chances.head_to_glitch) == 1 then
		local gl = {
			pos = lane.head.pos,
			char = alph.get_char(),
			hl_group = coloursets.get_colour("glitch"),
		}
		local ar = lane.glitch or {}
		table.insert(ar, #ar, gl)
		lane.glitch = ar
		return as_array(gl)
	end
	return as_array({
		pos = lane.head.pos,
		char = char,
		hl_group = coloursets.get_colour("body"),
	})
end

---@param lane lane
---@return event[]?
local function advance_head_cell(lane)
	if ch.chances.empty_ignore_head > 0 and math.random(ch.chances.empty_ignore_head) == 1 then
		lane.head = nil
		return
	end

	lane.head.pos = lane.head.pos + 1
	if lane.head.pos > lane.props.height then
		lane.head = nil
		return
	end

	lane.head.char = alph.get_char()
	lane.head.hl_group = coloursets.get_colour("head")
	return as_array({
		pos = lane.head.pos,
		char = lane.head.char,
		hl_group = lane.head.hl_group,
	})
end

---@param lane lane
---@return event[]
local function replace_tail_cell(lane)
	local m = {
		pos = lane.tail.pos,
		char = "",
	}
	for i, gl in ipairs(lane.glitch or {}) do
		if gl.pos == m.pos then
			table.remove(lane.glitch, i)
			break
		end
	end
	return as_array(m)
end

---@param lane lane
---@return event[]?
local function advance_tail_cell(lane)
	lane.tail.pos = lane.tail.pos + 1
	if lane.tail.pos > lane.props.height then
		lane.tail = nil
		return nil
	end

	lane.tail.hl_group = coloursets.get_colour("tail")

	return as_array({
		pos = lane.tail.pos,
		-- nil char signals no change to char
		hl_group = lane.tail.hl_group,
	})
end

---@param lane lane
---@return event[]?
local function replace_body_cell(lane)
	if
		lane:has_head() and lane.head.pos >= lane.props.height - 5
		or ch.chances.body_to_tail > 0 and math.random(ch.chances.body_to_tail) == 1
	then
		lane.tail = {
			pos = 1,
			char = alph.get_char(),
			hl_group = coloursets.get_colour("tail"),
		}
		return as_array({
			pos = lane.tail.pos,
			char = lane.tail.char,
			hl_group = lane.tail.hl_group,
		})
	end
end

---@param lane lane
---@return event[]?
local function create_head_cell(lane)
	if ch.chances.empty_stay_empty > 0 and math.random(ch.chances.empty_stay_empty) == 1 then
		return
	end
	lane.head = {
		pos = 1,
		char = alph.get_char(),
		hl_group = coloursets.get_colour("head"),
	}
	return as_array({
		pos = lane.head.pos,
		char = lane.head.char,
		hl_group = lane.head.hl_group,
	})
end

--TODO: impl
---@param lane lane
---@return event[]?
local function replace_glitch_cells(lane)
	if not lane:has_head() and not lane:has_tail() then
		lane.glitch = {}
		return
	end
	local ms = {}
	for i, gl in ipairs(lane.glitch or {}) do
		local gln = {
			pos = gl.pos,
			char = alph.get_char(),
			hl_group = coloursets.get_colour("glitch"),
		}
		local tail_pos = -1
		local head_pos = lane.props.height + 1
		if lane:has_tail() then
			tail_pos = lane.tail.pos
		end
		if lane:has_head() then
			head_pos = lane.head.pos
		end
		if gln.pos > tail_pos and gln.pos < head_pos then
			lane.glitch[i] = gln
			table.insert(ms, gln)
		else
			lane.glitch[i] = nil
		end
	end
	return ms
end

-- TODO: implement
---@param lane lane
---@return boolean
local function should_skip_glitch(lane)
	lane.frame = lane.frame + 1 --side effect
	return lane.frame % lane.props.fpu ~= 0
end

---@param lane lane
---@return boolean
local function should_skip(lane)
	lane.frame = lane.frame + 1 --side effect
	return lane.frame % lane.props.fpu ~= 0
end

---@param lane lane
---@return boolean
local function await_timeout(lane)
	lane.timeout_counter = lane.timeout_counter or 0
	if lane.props.timeout <= 0 then
		return false
	end

	if lane.timeout_counter >= lane.props.timeout then
		return false
	end

	-- BUG:fix harmless but unintended side-effect from should_skip
	if not should_skip(lane) then
		lane.timeout_counter = lane.timeout_counter + 1
	end
	return true
end

---@return event[]
function lane:advance()
	if await_timeout(self) then
		return {}
	end

	if should_skip(self) then
		return {}
	end

	-- reset frames to keep num small and performant
	self.frame = 0

	local events = {}

	-- all functions that can return events
	local head_replacement = nil
	local head_advancement = nil
	local tail_replacement = nil
	local tail_advancement = nil
	local top_body_replacement = nil
	local top_empty_replacement = nil
	local glitch_replacement = nil

	-- assign functions

	if self:has_head() then
		head_replacement = replace_head_cell
		head_advancement = advance_head_cell
	end

	if self:has_tail() then
		tail_replacement = replace_tail_cell
		tail_advancement = advance_tail_cell
	end

	if self:has_body_at_top() then
		top_body_replacement = replace_body_cell
	end

	if self:ready_for_head() then
		top_empty_replacement = create_head_cell
	end

	glitch_replacement = replace_glitch_cells

	-- in order
	local mutations = {
		head_replacement,
		head_advancement,
		tail_replacement,
		tail_advancement,
		top_body_replacement,
		top_empty_replacement,
		glitch_replacement,
	}

	for _, func in pairs(mutations) do
		local mutation_events = func(self)
		for _, m in pairs(mutation_events or {}) do
			table.insert(events, m)
		end
	end

	return events
end

---@param props lane_props
---@return lane
function M.new_lane(props)
	local l = setmetatable({}, { __index = lane })
	l.props = props
	l.frame = 0
	return l
end

-------------------------------------------------
--- DELETE ME ---

-- local l = M.new_lane({
-- 	height = 12,
-- 	upf = 1,
-- })
--
-- l.head = {
-- 	pos = 12,
-- 	char = "A",
-- }
--
-- -- l.glitch = {
-- -- 	[1] = {
-- -- 		pos = 6,
-- -- 		char = "X",
-- -- 	},
-- -- }
-- --
-- l.tail = {
-- 	pos = 2,
-- 	char = "C",
-- }
-- --
-- alph.init({ alphabet = "ABC", randomize_on_init = false, randomize_on_pick = false })
-- local conf = require("config").Defaults
-- coloursets.Init(conf.colourset)
-- require("chances.chances").init({
-- 	body_to_tail = -1,
-- 	head_to_glitch = -1,
-- 	head_to_tail = -1,
-- 	glitch_to_glitch = -1,
-- 	glitch_to_tail = -1,
-- 	empty_ignore_head = -1,
-- })
--
-- local evts = l:advance()
-- P(evts)

--- DELETE ME ---
-------------------------------------------------

return M
