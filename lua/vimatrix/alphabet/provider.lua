local built_in = require("vimatrix.alphabet.symbols")

---@class alphabet_provider
local M = {}

---@class vx.alphabet_props
---@field built_in string[]?
---@field custom string[]?
---@field randomize_on_init boolean randomizes the given alphabet on initialization; possible performance hit on init
---@field randomize_on_pick boolean randomizes the chosen character on pick

---@param props vx.alphabet_props
local function validate_and_fix(props)
	if (not props.built_in or #props.built_in == 0) and (not props.custom or #props.custom == 0) then
		vim.notify("vimatrix was configured with an empty alphabet, defaulting to 'latin'", vim.log.levels.WARN)
		props.custom = built_in.latin_lower
	end
end

---@param props vx.alphabet_props
function M.init(props)
	validate_and_fix(props)

	local chars = {}
	for _, b in pairs(props.built_in) do
		for _, s in pairs(built_in[b] or {}) do
			table.insert(chars, s)
		end
	end
	for _, s in pairs(props.custom or {}) do
		table.insert(chars, s)
	end

	M.alphabet = chars

	if props.randomize_on_init then
		local rem = chars
		local rpl = {}
		while #rem > 0 do
			local i = math.random(#rem)
			rpl = table.move(rem, i, i, #rpl + 1, rpl)
			table.remove(rem, i)
		end
		M.alphabet = rpl
	end

	M.randomize_on_pick = props.randomize_on_pick
end

local idx = 1

---@return string
function M.get_char()
	if not M.randomize_on_pick then
		idx = idx + 1
		if idx > #M.alphabet then
			idx = 1
		end
		return M.alphabet[idx]
	end
	local rd = math.random(#M.alphabet)
	return M.alphabet[rd]
end

return M
