local config = require("vimatrix.config").options.window
local colours = require("vimatrix.colours.provider")

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

local function set_cursor_blend(i)
	local def = vim.api.nvim_get_hl(0, { name = "Cursor" })
	vim.api.nvim_set_hl(0, "Cursor", vim.tbl_extend("force", def, { blend = i }))
	vim.opt.guicursor:append("a:Cursor")
end

local function hide_cursor()
	set_cursor_blend(100)
end

local function reveal_cursor()
	set_cursor_blend(0)
end

---@return boolean
function M.open_overlay()
	M.old_buffer = vim.api.nvim_get_current_buf()
	local filetype = vim.bo[M.old_buffer].filetype
	local blend = (config.by_filetype[filetype] or config.general).blend
	local background = (config.by_filetype[filetype] or config.general).background
	local zindex = (config.by_filetype[filetype] or config.general).zindex

	local id = vim.api.nvim_get_hl_id_by_name("NormalFloat")
	M.old_fl_hl = vim.api.nvim_get_hl(0, { id = id })

	M.bufid = vim.api.nvim_create_buf(false, true)
	local ok = pcall(vim.api.nvim_buf_set_name, M.bufid, "vimatrix")
	if not ok then
		-- vimatrix already running (e.g. due to both screensaver & filetype instigation)
		return false
	end

	M.winid = vim.api.nvim_open_win(M.bufid, false, {
		relative = "editor",
		row = 0,
		col = 0,
		width = vim.go.columns,
		height = vim.go.lines,
		focusable = false,
		zindex = zindex,
		style = "minimal",
		noautocmd = true,
	})
	vim.api.nvim_win_set_hl_ns(M.winid, colours.ns_id)
	vim.api.nvim_set_hl(colours.ns_id, "NormalFloat", { bg = background })
	vim.wo[M.winid].winblend = blend
	hide_cursor()

	M.bo(M.bufid, bufopts)
	M.wo(M.winid, winopts)

	M.ignore_cells = (config.by_filetype[filetype] or config.general).ignore_cells

	return true
end

function M.undo()
	reveal_cursor()
	pcall(vim.api.nvim_win_close, M.winid, true)
	vim.api.nvim_set_hl(colours.ns_id, "NormalFloat", {
		bg = M.old_fl_hl.bg,
		fg = M.old_fl_hl.fg,
		sp = M.old_fl_hl.sp,
		default = M.old_fl_hl.default,
		link = M.old_fl_hl.link,
		blend = M.old_fl_hl.blend,
		ctermbg = M.old_fl_hl.cterm and M.old_fl_hl.cterm.background,
		ctermfg = M.old_fl_hl.cterm and M.old_fl_hl.cterm.foreground,
	})
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
