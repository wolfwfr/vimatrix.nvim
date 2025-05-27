local M = {}

local function keymaps_find(keymaps, key)
	for _, existing in ipairs(keymaps) do
		if existing.lhs == key then
			return existing
		end
	end
	return nil
end

---@class keymaps
---@field key string
---@field existing vim.api.keyset.get_keymap

---@param bufid integer buffer_id
---@param keys string[] keys for which to list keymaps
---@return keymaps[]
function M.keymaps_list_buf(bufid, keys)
	local keymaps = vim.api.nvim_buf_get_keymap(bufid, "n")
	local maps = {}
	for _, ck in ipairs(keys) do
		local match = keymaps_find(keymaps, ck)
		if match then
			table.insert(maps, { key = ck, existing = match })
		else
			table.insert(maps, { key = ck })
		end
	end
	return maps
end

--- currently assumes remap
---@param bufid integer buffer_id
---@param keys string[] keys to assign
---@param rhs function|string function or command to execute on keypress
function M.keymaps_set_all_buf(bufid, keys, rhs)
	for _, key in ipairs(keys) do
		vim.keymap.set("n", key, rhs, {
			buffer = bufid,
			remap = true,
		})
	end
end

---@param i integer
---@return boolean
local function int_to_bool(i)
	return i and i == 1 or false
end

---@param bufid integer buffer_id
---@param keymaps keymaps[]
function M.keymaps_restore_buf(bufid, keymaps)
	for _, map in ipairs(keymaps) do
		if map.existing ~= nil then
			vim.keymap.set("n", map.key, map.existing.rhs or "", {
				buffer = bufid,
				callback = map.existing.callback,
				desc = map.existing.desc,
				noremap = int_to_bool(map.existing.noremap),
				nowait = int_to_bool(map.existing.nowait),
				script = int_to_bool(map.existing.script),
				expr = int_to_bool(map.existing.expr),
				silent = int_to_bool(map.existing.silent),
			})
		else
			-- apply pcall for idempotent behaviour without errors
			pcall(vim.keymap.del, "n", map.key, { buffer = bufid })
		end
	end
end

return M
