local coloursets = require("colours.coloursets")

local M = {}

--- @param line string single line to flip to a column
local flip_single = function(line)
	local lines = {}
	for i = 1, #line do
		lines[i] = line:sub(i, i)
	end
	return lines
end

--- @param n integer number of spaces
local space = function(n)
	local line_chars = ""
	for i = 1, n do
		line_chars = line_chars .. " "
	end
	return line_chars
end

-- something interesting I found in the CodeCompanion logic
-- local width = window.width > 1 and window.width or math.floor(vim.o.columns * window.width)
-- local height = window.height > 1 and window.height or math.floor(vim.o.lines * window.height)

--- @param column_chars string characters to write from top to bottom
M.insert_column = function(column_chars)
	-- assuming middle column
	local columnN = vim.fn.winwidth(0)
	-- local columnN = 226
	-- print(columnN)

	local middle_col = math.floor(columnN / 2)

	local col = flip_single(column_chars)
	local lines = {}
	for i = 1, #col do
		lines[i] = space(middle_col - 1) .. col[i]
	end

	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

	local clr = coloursets.get_colour("body")

	vim.api.nvim_buf_set_extmark(0, coloursets.ns_id, 0, 0, {
		end_line = 2,
		end_col = middle_col,
		hl_group = clr,
	})
	-- vim.api.nvim_create_namespace(name)
end

return M
