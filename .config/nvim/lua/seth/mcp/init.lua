-- Initialize and register native MCP servers
local M = {}

-- Debug mode flag
M.debug_mode = false

-- Debug function to log info only when debug mode is enabled
local function debug_log(msg, level)
	if not M.debug_mode then
		return
	end
	level = level or vim.log.levels.INFO
	vim.notify("[MCP] " .. msg, level)
end

-- Define the MCP server modules to load
M.server_modules = {
	github_actions = "seth.mcp.github_actions",
	terraform_cloud = "seth.mcp.terraform_cloud",
	knowledge_base = "seth.mcp.knowledge_base",
	code2prompt = "seth.mcp.code2prompt",
	-- Add new server modules here
}

-- Function to enable/disable debug mode across all servers
function M.set_debug_mode(enabled)
	M.debug_mode = enabled
	vim.notify("[MCP] Debug mode " .. (enabled and "enabled" or "disabled"))

	-- Update debug mode in individual MCP servers
	for _, module_path in pairs(M.server_modules) do
		pcall(function()
			local module = require(module_path)
			if module and module.set_debug_mode then
				module.set_debug_mode(enabled)
			end
		end)
	end
end

function M.setup()
	-- Load all MCP servers
	local mcp_servers = {}

	for name, module_path in pairs(M.server_modules) do
		local ok, module = pcall(require, module_path)
		if ok and module and module.server then
			mcp_servers[name] = module.server
			debug_log("Loaded " .. name .. " MCP server")
		else
			local error_msg = "Failed to load " .. name .. " MCP server"
			if type(module) == "string" then
				error_msg = error_msg .. ": " .. module
			end
			debug_log(error_msg, vim.log.levels.WARN)
		end
	end

	-- Register native servers with mcphub
	local ok_mcphub, mcphub = pcall(require, "mcphub")
	if not ok_mcphub then
		vim.notify("Failed to load mcphub: " .. tostring(mcphub), vim.log.levels.ERROR)
		return
	end

	debug_log("Registering MCP servers with mcphub")
	for name, server in pairs(mcp_servers) do
		local ok, err = pcall(function()
			mcphub.add_server(name, server)
			debug_log("Registered MCP server: " .. name)
		end)

		if not ok then
			vim.notify("Failed to register MCP server " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
		end
	end

	-- Diagnostic: show registered servers (only in debug mode)
	vim.defer_fn(function()
		if not M.debug_mode then
			return
		end

		-- Check if _G.MCP_SERVERS exists
		---@diagnostic disable-next-line: undefined-field
		if _G.MCP_SERVERS then
			local registered = {}
			---@diagnostic disable-next-line: undefined-field
			for name, _ in pairs(_G.MCP_SERVERS) do
				table.insert(registered, name)
			end
			if #registered > 0 then
				debug_log("Active MCP servers: " .. table.concat(registered, ", "))
			else
				debug_log("No active MCP servers found!", vim.log.levels.WARN)
			end
		else
			debug_log("_G.MCP_SERVERS is not initialized!", vim.log.levels.WARN)
		end
	end, 1000)
end

return M
