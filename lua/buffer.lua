local M = {}

local bufopts = {
	bufhidden = "wipe",
	buftype = "nofile",
	buflisted = false,
	swapfile = false,
	undofile = false,
}

local winopts = {
	colorcolumn = "",
	cursorcolumn = false,
	cursorline = false,
	foldmethod = "manual",
	list = false,
	number = false,
	relativenumber = false,
	sidescrolloff = 0,
	signcolumn = "no",
	spell = false,
	statuscolumn = "",
	statusline = "",
	winbar = "",
	wrap = false,
}

---@return integer buffer_id
function M.Open()
	--vim.cmd("botright vsplit")
	-- vim.api.nvim_open_win(buffer, enter, config)
	-- require("insert_middle").insert_middle("B")
	local bufid = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(bufid, "vimatrix")
	vim.api.nvim_set_current_buf(bufid)
	local winid = vim.api.nvim_get_current_win()
	M.bo(bufid, bufopts)
	M.wo(winid, winopts)
	return bufid
end

-- NOTE: thanks Folke, your code is awesome

--- Set buffer-local options.
---@private
---@param buf number
---@param bo vim.bo|{}
function M.bo(buf, bo)
	for k, v in pairs(bo or {}) do
		vim.api.nvim_set_option_value(k, v, { buf = buf })
	end
end

--- Set window-local options.
---@private
---@param win number
---@param wo vim.wo|{}|{winhighlight: string|table<string, string>}
function M.wo(win, wo)
	for k, v in pairs(wo or {}) do
		if k == "winhighlight" and type(v) == "table" then
			local parts = {} ---@type string[]
			for kk, vv in pairs(v) do
				if vv ~= "" then
					parts[#parts + 1] = ("%s:%s"):format(kk, vv)
				end
			end
			v = table.concat(parts, ",")
		end
		vim.api.nvim_set_option_value(k, v, { scope = "local", win = win })
	end
end

return M
