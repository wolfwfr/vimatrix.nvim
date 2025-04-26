---@alias hl table<string, string|vim.api.keyset.highlight>

--- Ensures the hl groups are always set, even after a colorscheme change.
---@param ns_id integer
---@param groups hl
---@param opts? { prefix?:string, default?:boolean, managed?:boolean }
local function set_hl(ns_id, groups, opts)
	opts = opts or {}
	for hl_group, hl in pairs(groups) do
		hl_group = opts.prefix and opts.prefix .. hl_group or hl_group
		hl = type(hl) == "string" and { link = hl } or hl --[[@as vim.api.keyset.highlight]]
		hl.default = opts.default
		vim.api.nvim_set_hl(ns_id, hl_group, hl)
	end
end

local M = {}

local ns_id = vim.api.nvim_create_namespace("Vimatrix")
M.ns_id = ns_id

---@class vimatrix.colour_scheme
---@field head string hex colourcode
---@field body string[] hex colourcodes for body characters, no particular order
---@field tail string hex colourcode for the tail character
---@field glitch? string[] hex colourcodes for glitching characters -- TODO: implement

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

	M.set = scheme

	local hl_groups = {
		Head = { fg = scheme.head },
		Tail = { fg = scheme.tail },
	}
	for i = 1, #scheme.body do
		local key = "Body" .. i
		hl_groups[key] = { fg = scheme.body[i] }
	end
	if scheme.glitch ~= nil then
		for i = 1, #scheme.glitch do
			local key = "Glitch" .. i
			hl_groups[key] = { fg = scheme.glitch[i] }
		end
	end

	set_hl(ns_id, hl_groups, { prefix = "VimatrixDroplet" })

	vim.api.nvim_set_hl_ns(ns_id)
end

---@enum (key) droplet_segment
local segments = {
	head = "head",
	body = "body",
	tail = "tail",
	glitch = "glitch",
}

M.segments = segments

---@return string
function M.get_next_body()
	M.body_idx = M.body_idx or 0

	M.body_idx = M.body_idx + 1

	if M.body_idx > #M.set.body then
		M.body_idx = 1
	end

	return "VimatrixDropletBody" .. M.body_idx
end

---@return string
function M.get_next_glitch()
	if #(M.set.glitch or {}) == 0 then
		return M.get_next_body()
	end

	M.glitch_idx = M.glitch_ix or 0

	M.glitch_idx = M.glitch_idx + 1

	if M.glitch_idx > #M.set.glitch then
		M.glitch_idx = 1
	end

	return "VimatrixDropletGlitch" .. M.body_idx
end

---@param seg droplet_segment
function M.get_colour(seg)
	if seg == segments.body then
		return M.get_next_body()
	end
	if seg == segments.head then
		return "VimatrixDropletHead"
	end
	if seg == segments.tail then
		return "VimatrixDropletTail"
	end
	if seg == segments.glitch then
		return M.get_next_glitch()
	end
end

return M
