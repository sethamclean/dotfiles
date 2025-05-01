-- Initialize and register native MCP servers
local M = {}

function M.setup()
	-- Load all MCP servers in the mcp directory
	local mcp_servers = {}

	-- Add GitHub Actions MCP Server
	local ok, github_actions = pcall(require, "seth.mcp.github_actions")
	if ok and github_actions and github_actions.server then
		mcp_servers.github_actions = github_actions.server
	else
		vim.notify("Failed to load GitHub Actions MCP server", vim.log.levels.WARN)
	end

	-- Add Terraform Cloud MCP Server
	local ok, terraform_cloud = pcall(require, "seth.mcp.terraform_cloud")
	if ok and terraform_cloud and terraform_cloud.server then
		mcp_servers.terraform_cloud = terraform_cloud.server
	else
		vim.notify("Failed to load Terraform Cloud MCP server", vim.log.levels.WARN)
	end

	-- Register native servers with mcphub
	local mcphub = require("mcphub")
	for name, server in pairs(mcp_servers) do
		mcphub.add_server(name, server)
	end
end

return M
