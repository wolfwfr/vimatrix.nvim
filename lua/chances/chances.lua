local M = {}

-- chances defines the random chance of non-default droplet position transitions
-- taking place. Chances are expressed as `x` in `chance = 1 in x`
--
-- The default transitions are:
-- - empty -> head (if head is incoming)
-- - head -> body
-- - body -> body
-- - glitch -> body
-- - tail -> empty
--
---@class chances
---@field body_to_tail integer
---@field head_to_glitch integer
---@field head_to_tail integer
---@field empty_ignore_head integer --TODO: naming
---@field empty_stay_empty integer --TODO: naming

---@param chances chances
function M.init(chances)
	M.initialised = true
	M.chances = chances
end

return M
