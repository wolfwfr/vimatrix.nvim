local chances = require("vimatrix.config").options.chances
local droplet_props = require("vimatrix.config").options.droplet
local colourscheme = require("vimatrix.colours.provider")
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

---@class glitch
---@field cell cell
---@field frame integer
---@field is_bright boolean

---@class lane
---@field props lane_props
---@field timeout_counter integer
---@field frame integer
---@field head cell
---@field tail cell
---@field glitches glitch[]
---@field cleared boolean --works only as long as a lane can contain no more than one droplet at a time
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
	return not self:has_tail() and not self:has_head() and self.cleared -- TODO: consider making configurable
end

---@return boolean
function lane:has_glitch()
	return self.glitches ~= nil and #self.glitches > 0
end

local function as_array(obj)
	return { obj }
end

---@param pos integer
---@return glitch
local function new_glitch(pos)
	local br = colourscheme.get_colour("glitch_bright")
	local is_bright = not br[2]

	return {
		cell = {
			pos = pos,
			char = alph.get_char(),
			hl_group = br[1],
		},
		frame = 0,
		is_bright = is_bright,
	}
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
		if chances.head_to_tail > 0 and math.random(chances.head_to_tail) == 1 then
			lane.tail = {
				pos = lane.head.pos,
				char = char,
				hl_group = colourscheme.get_colour("tail")[1],
			}
			return as_array({
				pos = lane.tail.pos,
				char = lane.tail.char,
				hl_group = lane.tail.hl_group,
			})
		end
	end

	if chances.head_to_glitch > 0 and math.random(chances.head_to_glitch) == 1 then
		local gl = new_glitch(lane.head.pos)
		local ar = lane.glitches or {}
		table.insert(ar, gl)
		lane.glitches = ar
		return as_array(gl.cell)
	end
	return as_array({
		pos = lane.head.pos,
		char = char,
		hl_group = colourscheme.get_colour("body")[1],
	})
end

---@param lane lane
---@return event[]?
local function advance_head_cell(lane)
	lane.head.pos = lane.head.pos + 1
	if lane.head.pos > lane.props.height then
		lane.head = nil
		return
	end

	lane.head.char = alph.get_char()
	lane.head.hl_group = colourscheme.get_colour("head")[1]

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
	for i, gl in ipairs(lane.glitches or {}) do
		if gl.cell.pos == m.pos then
			table.remove(lane.glitches, i)
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
    lane.cleared = true
		return nil
	end

	lane.tail.hl_group = colourscheme.get_colour("tail")[1]

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
		droplet_props.max_size_offset > 0 and lane:has_head() and lane.head.pos >= lane.props.height - droplet_props.max_size_offset
		or chances.body_to_tail > 0 and math.random(chances.body_to_tail) == 1
	then
		lane.tail = {
			pos = 1,
			char = alph.get_char(),
			hl_group = colourscheme.get_colour("tail")[1],
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
	if chances.empty_stay_empty > 0 and math.random(chances.empty_stay_empty) == 1 then
		return
	end
	lane.head = {
		pos = 1,
		char = alph.get_char(),
		hl_group = colourscheme.get_colour("head")[1],
	}
  lane.cleared = false
	return as_array({
		pos = lane.head.pos,
		char = lane.head.char,
		hl_group = lane.head.hl_group,
	})
end

---@param lane lane
---@return event[]?
local function replace_glitch_cells(lane)
	local mutations = {}

	for i, gl in ipairs(lane.glitches or {}) do
		local refresh_eligible = (gl.frame + 1) % lane.props.fpu_glitch == 0

		if refresh_eligible then
			local gln = new_glitch(gl.cell.pos)
			lane.glitches[i] = gln
			table.insert(mutations, gln.cell)
			goto continue
		end

		if gl.is_bright then
			lane.glitches[i].cell.hl_group = colourscheme.get_colour("glitch")[1]
			lane.glitches[i].is_bright = false

			table.insert(mutations, {
				pos = lane.glitches[i].cell.pos,
				hl_group = lane.glitches[i].cell.hl_group,
			})
		end

		lane.glitches[i].frame = lane.glitches[i].frame + 1

		::continue::
	end

	return mutations
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

	-- FIXME:harmless but unintended side-effect from should_skip
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
  l.cleared = true
	return l
end

return M
