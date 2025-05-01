-- Terraform Cloud MCP Server for mcphub.nvim
-- This server provides tools to interact with Terraform Cloud API directly
-- Since the Terraform CLI doesn't directly work with Terraform Cloud without proper setup

local M = {}

-- Helper function to execute TFC API calls via curl
local function tfc_api_call(url_path, token_var)
	-- We use TFC_TOKEN environment variable by default
	local token = vim.fn.getenv(token_var or "TFC_TOKEN")
	if token == vim.NIL or token == "" then
		return nil, "Terraform Cloud API token not found. Set TFC_TOKEN environment variable."
	end

	local base_url = "https://app.terraform.io/api/v2"
	local full_url = base_url .. url_path

	-- Build the curl command with proper headers
	local cmd = string.format(
		'curl -s -H "Authorization: Bearer %s" -H "Content-Type: application/vnd.api+json" %s',
		token,
		full_url
	)

	local output = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return nil, "API request failed: " .. output
	end

	return output, nil
end

-- Define the Terraform Cloud MCP server schema
M.server = {
	name = "terraform_cloud",
	displayName = "Terraform Cloud",
	capabilities = {
		tools = {
			{
				name = "list_workspaces",
				description = "List all Terraform Cloud workspaces for the current organization",
				inputSchema = {
					type = "object",
					properties = {
						organization = {
							type = "string",
							description = "Terraform Cloud organization name",
						},
					},
					required = { "organization" },
				},
				handler = function(req, res)
					local org = req.params.organization
					local url_path = string.format("/organizations/%s/workspaces", org)

					local result, err = tfc_api_call(url_path)
					if err then
						return res:error(err)
					end

					-- Attempt to parse the JSON and format a nicer response
					local ok, json = pcall(vim.fn.json_decode, result)
					if not ok then
						return res:text("Workspaces for " .. org .. ":\n\n" .. result):send()
					end

					local formatted = "Workspaces for " .. org .. ":\n\n"
					if json.data then
						for _, workspace in ipairs(json.data) do
							formatted = formatted
								.. string.format(
									"- %s\n  ID: %s\n  Created: %s\n  Terraform Version: %s\n\n",
									workspace.attributes.name or "unknown",
									workspace.id or "unknown",
									workspace.attributes["created-at"] or "unknown",
									workspace.attributes["terraform-version"] or "unknown"
								)
						end
					else
						formatted = formatted .. "No workspaces found or unexpected API response format."
					end

					return res:text(formatted):send()
				end,
			},
			{
				name = "show_workspace",
				description = "Show details of a specific Terraform Cloud workspace",
				inputSchema = {
					type = "object",
					properties = {
						organization = {
							type = "string",
							description = "Terraform Cloud organization name",
						},
						workspace = {
							type = "string",
							description = "Terraform Cloud workspace name",
						},
					},
					required = { "organization", "workspace" },
				},
				handler = function(req, res)
					local org = req.params.organization
					local workspace = req.params.workspace
					local url_path = string.format("/organizations/%s/workspaces/%s", org, workspace)

					local result, err = tfc_api_call(url_path)
					if err then
						return res:error(err)
					end

					-- Attempt to parse the JSON and format a nicer response
					local ok, json = pcall(vim.fn.json_decode, result)
					if not ok then
						return res:text("Workspace Details for " .. workspace .. ":\n\n" .. result):send()
					end

					local formatted = string.format("Workspace: %s/%s\n\n", org, workspace)
					if json.data and json.data.attributes then
						local attrs = json.data.attributes
						formatted = formatted
							.. string.format(
								"ID: %s\nCreated: %s\nTerraform Version: %s\nAuto Apply: %s\n"
									.. "VCS Repo: %s\nResource count: %s\nUpdated At: %s\n",
								json.data.id or "unknown",
								attrs["created-at"] or "unknown",
								attrs["terraform-version"] or "unknown",
								attrs["auto-apply"] and "Enabled" or "Disabled",
								attrs["vcs-repo"] and attrs["vcs-repo"].identifier or "None",
								attrs["resource-count"] or "unknown",
								attrs["updated-at"] or "unknown"
							)
					else
						formatted = formatted .. "Workspace not found or unexpected API response format."
					end

					return res:text(formatted):send()
				end,
			},
			{
				name = "run_plan",
				description = "Run a Terraform plan in the current directory",
				handler = function(_, res)
					local result = vim.fn.system("terraform plan")
					if vim.v.shell_error ~= 0 then
						return res:error("Failed to run Terraform plan. Check Terraform configuration.")
					end
					return res:text(result):send()
				end,
			},
			{
				name = "show_state",
				description = "Show the current Terraform state",
				handler = function(_, res)
					local result = vim.fn.system("terraform state list")
					if vim.v.shell_error ~= 0 then
						return res:error("Failed to show Terraform state. Make sure you're in a Terraform directory.")
					end
					return res:text(result):send()
				end,
			},
			{
				name = "show_runs",
				description = "Show recent Terraform Cloud runs for a workspace",
				inputSchema = {
					type = "object",
					properties = {
						organization = {
							type = "string",
							description = "Terraform Cloud organization name",
						},
						workspace = {
							type = "string",
							description = "Terraform Cloud workspace name",
						},
						limit = {
							type = "number",
							description = "Maximum number of runs to show (default: 5)",
						},
					},
					required = { "organization", "workspace" },
				},
				handler = function(req, res)
					local org = req.params.organization
					local workspace = req.params.workspace
					local limit = req.params.limit or 5

					-- First, get the workspace ID
					local ws_url = string.format("/organizations/%s/workspaces/%s", org, workspace)
					local ws_result, ws_err = tfc_api_call(ws_url)
					if ws_err then
						return res:error(ws_err)
					end

					local ws_ok, ws_json = pcall(vim.fn.json_decode, ws_result)
					if not ws_ok or not ws_json.data or not ws_json.data.id then
						return res:error("Failed to find workspace or parse workspace data.")
					end

					local workspace_id = ws_json.data.id
					local runs_url = string.format("/workspaces/%s/runs?page[size]=%d", workspace_id, limit)

					local result, err = tfc_api_call(runs_url)
					if err then
						return res:error(err)
					end

					-- Attempt to parse the JSON and format a nicer response
					local ok, json = pcall(vim.fn.json_decode, result)
					if not ok then
						return res:text("Recent runs for " .. org .. "/" .. workspace .. ":\n\n" .. result):send()
					end

					local formatted = string.format("Recent runs for %s/%s:\n\n", org, workspace)
					if json.data then
						for _, run in ipairs(json.data) do
							local attrs = run.attributes or {}
							formatted = formatted
								.. string.format(
									"ID: %s\nStatus: %s\nCreated: %s\nMessage: %s\n\n",
									run.id or "unknown",
									attrs.status or "unknown",
									attrs["created-at"] or "unknown",
									attrs.message or "No message"
								)
						end
					else
						formatted = formatted .. "No runs found or unexpected API response format."
					end

					return res:text(formatted):send()
				end,
			},
		},
		resources = {
			{
				name = "terraform_version",
				uri = "terraform://version",
				description = "Get the current Terraform CLI version",
				handler = function(_, res)
					local result = vim.fn.system("terraform version")
					if vim.v.shell_error ~= 0 then
						return res:error("Failed to get Terraform version. Make sure Terraform CLI is installed.")
					end
					return res:text(result):send()
				end,
			},
		},
		resourceTemplates = {
			{
				name = "workspace_info",
				uriTemplate = "terraform://organizations/{organization}/workspaces/{workspace}",
				description = "Get information about a specific workspace",
				handler = function(req, res)
					local org = req.params.organization
					local workspace = req.params.workspace
					local url_path = string.format("/organizations/%s/workspaces/%s", org, workspace)

					local result, err = tfc_api_call(url_path)
					if err then
						return res:error(err)
					end

					-- Attempt to parse the JSON and format a nicer response
					local ok, json = pcall(vim.fn.json_decode, result)
					if not ok then
						return res:text("Workspace Details for " .. workspace .. ":\n\n" .. result):send()
					end

					local formatted = string.format("Workspace: %s/%s\n\n", org, workspace)
					if json.data and json.data.attributes then
						local attrs = json.data.attributes
						formatted = formatted
							.. string.format(
								"ID: %s\nCreated: %s\nTerraform Version: %s\nAuto Apply: %s\n"
									.. "VCS Repo: %s\nResource count: %s\nUpdated At: %s\n",
								json.data.id or "unknown",
								attrs["created-at"] or "unknown",
								attrs["terraform-version"] or "unknown",
								attrs["auto-apply"] and "Enabled" or "Disabled",
								attrs["vcs-repo"] and attrs["vcs-repo"].identifier or "None",
								attrs["resource-count"] or "unknown",
								attrs["updated-at"] or "unknown"
							)
					else
						formatted = formatted .. "Workspace not found or unexpected API response format."
					end

					return res:text(formatted):send()
				end,
			},
		},
	},
}

return M
