local M = {}

M.ns_id = vim.api.nvim_create_namespace("Vimatrix")

local hl_group_prefix = "VimatrixDroplet"
local hl_group_head_segment = "Head"
local hl_group_body_segment = "Body"
local hl_group_tail_segment = "Tail"
local hl_group_glitch_segment = "Glitch"
local hl_group_glitch_bright_segment = "GlitchBright"

---@class vimatrix.colour_scheme
---@field head string hex colourcode for head cell
---@field body string[] hex colourcodes for body cells, no particular order
---@field tail string hex colourcode for the tail cell
---@field glitch_bright? string|string[] hex colourcode for glitch cells upon character change, after which they change colour once more
---@field glitch? string[] hex colourcodes for glitch cells

---@param scheme_props vimatrix.colour_scheme | string
function M.Init(scheme_props)
	local scheme = scheme_props
	if type(scheme_props) == "string" then
		scheme = require("vimatrix.colours.schemes")[scheme_props]
		if not scheme then
			local default = "green"
			vim.notify("colour_scheme '" .. scheme_props .. "' not found; defaulting to '" .. default .. "'")
			scheme = require("vimatrix.colours.schemes")[default]
		end
	end

	M.scheme = scheme

	local hl_groups = {
		Head = { fg = scheme.head },
		Tail = { fg = scheme.tail },
	}
	for i = 1, #scheme.body do
		hl_groups[hl_group_body_segment .. i] = { fg = scheme.body[i] }
	end
	for i = 1, #(scheme.glitch or {}) do
		hl_groups[hl_group_glitch_segment .. i] = { fg = scheme.glitch[i] }
	end

	local brights = scheme.glitch_bright and type(scheme.glitch_bright) == "string" and { scheme.glitch_bright }
		or scheme.glitch_bright

	for i = 1, #(brights or {}) do
		hl_groups[hl_group_glitch_bright_segment .. i] = { fg = brights[i] }
	end

	for hl_group, hl in pairs(hl_groups) do
		hl_group = hl_group_prefix .. hl_group
		vim.api.nvim_set_hl(M.ns_id, hl_group, hl)
	end

	vim.api.nvim_set_hl_ns(M.ns_id)
end

---@enum (key) droplet_segment
local segments = {
	head = "head",
	body = "body",
	tail = "tail",
	glitch = "glitch",
	glitch_bright = "glitch_bright",
}

M.segments = segments

---@return string
function M.get_next_body()
	M.body_idx = M.body_idx or 0

	M.body_idx = M.body_idx + 1

	if M.body_idx > #M.scheme.body then
		M.body_idx = 1
	end

	return hl_group_prefix .. hl_group_body_segment .. M.body_idx
end

---@class highlight_group_response
---@field hlg string
---@field fallback boolean

---@return highlight_group_response
function M.get_next_glitch()
	if #(M.scheme.glitch or {}) == 0 then
		return { M.get_next_body(), true }
	end

	M.glitch_idx = M.glitch_ix or 0

	M.glitch_idx = M.glitch_idx + 1

	if M.glitch_idx > #M.scheme.glitch then
		M.glitch_idx = 1
	end

	return { hl_group_prefix .. hl_group_glitch_segment .. M.glitch_idx, false }
end

---@return highlight_group_response
function M.get_glitch_bright()
	if not M.scheme.glitch_bright then
		return M.get_next_glitch()
	end

	M.glitch_bright_idx = M.glitch_bright_ix or 0

	M.glitch_bright_idx = M.glitch_bright_idx + 1

	if M.glitch_bright_idx > #M.scheme.glitch_bright then
		M.glitch_bright_idx = 1
	end

	return { hl_group_prefix .. hl_group_glitch_bright_segment .. M.glitch_bright_idx, false }
end

---@param seg droplet_segment
---@return highlight_group_response
function M.get_colour(seg)
	if seg == segments.body then
		return { M.get_next_body(), false }
	end
	if seg == segments.head then
		return { hl_group_prefix .. hl_group_head_segment, false }
	end
	if seg == segments.tail then
		return { hl_group_prefix .. hl_group_tail_segment, false }
	end
	if seg == segments.glitch then
		return M.get_next_glitch()
	end
	if seg == segments.glitch_bright then
		return M.get_glitch_bright()
	end
end

return M
