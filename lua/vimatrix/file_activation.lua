local config = require("vimatrix.config").options.auto_activation

local M = {}

---@class vx.file_activation.props
---@field callback function

---@param props vx.file_activation.props
function M.activate_on_file(props)
	vim.defer_fn(function()
		local buf = vim.api.nvim_get_current_buf()
		if vim.tbl_contains(config.on_filetype or {}, vim.bo[buf].filetype) then
			props.callback()
		end
	end, 100)
end

return M
