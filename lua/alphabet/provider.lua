---@class alphabet_provider
local M = {}

---@class props
---@field alphabet string[] all characters available for printing
---@field randomize_on_init boolean randomizes the given alphabet on initialization; possible performance hit on init
---@field randomize_on_pick boolean randomizes the chosen character on pick

math.randomseed(os.time())

---@param props props
function M.init(props)
	M.alphabet = props.alphabet

	if props.randomize_on_init then
		local rem = props.alphabet
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
