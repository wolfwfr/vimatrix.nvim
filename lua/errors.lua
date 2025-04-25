local M = {}

---@class log_props
---@field print_errors boolean
---@field log_level vim.log.levels

function M.init(props)
	M.print_errors = props.print_errors or false
	M.log_level = props.log_level or vim.log.levels.DEBUG
end

---@param error string
function M.print(error)
	if M.print_errors then
		vim.notify("encountered an error:" .. error, M.log_level)
	end
end

return M
