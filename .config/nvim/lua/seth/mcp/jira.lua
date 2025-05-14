-- Jira MCP server
local M = { is_registered = false }

-- Debug mode flag
M.debug_mode = false

-- This flag will be set to true when the server is successfully registered
M.is_registered = false

-- Response object creator
local function create_mcphub_response()
	local response = {}
	response.text = function(self, content, mime_type)
		self.body = content
		self.mime_type = mime_type or "text/plain"
		return self
	end
	response.json = function(self, content)
		self.body = vim.fn.json_encode(content)
		self.mime_type = "application/json"
		return self
	end
	response.error = function(self, msg)
		self.body = msg
		self.mime_type = "text/plain"
		self.is_error = true
		return self:send()
	end
	response.send = function(self)
		return {
			body = self.body,
			mime_type = self.mime_type,
			is_error = self.is_error,
		}
	end
	return response
end

-- Debug logging function
function M.debug_log(msg, level)
	if not M.debug_mode then
		return
	end
	level = level or vim.log.levels.INFO
	vim.notify("[Jira MCP] " .. msg, level)
end

-- Helper function to create MCPHub-style response objects for testing
function M.create_default_response()
	local response = {}
	response.text = function(self, content, mime_type)
		self.body = content
		self.mime_type = mime_type or "text/plain"
		return self
	end
	response.json = function(self, content)
		self.body = vim.fn.json_encode(content)
		self.mime_type = "application/json"
		return self
	end
	response.error = function(self, msg)
		self.body = msg
		self.mime_type = "text/plain"
		self.is_error = true
		return self:send()
	end
	response.send = function(self)
		return {
			body = self.body,
			mime_type = self.mime_type,
			is_error = self.is_error,
		}
	end
	return response
end

-- Initialize function that will be called from init.lua
function M.init()
	M.debug_log("Jira MCP server initialization started")

	-- Allow the server to be auto-discovered by LLMs
	M.server.metadata = {
		priority = "high",
		keywords = {
			"jira",
			"issue",
			"ticket",
			"project",
			"task",
			"bug",
			"story",
			"epic",
			"sprint",
			"agile",
		},
		description = "Jira server for issue tracking and project management",
		suggested_invocation = "When users ask about Jira issues, tickets, or projects, automatically consider using the Jira tools to interact with their Jira instance.",
	}

	-- Concise LLM guidance to encourage automatic discovery
	M.server.llm_hints = {
		auto_detect_patterns = {
			"jira",
			"issue",
			"ticket",
			"project",
			"sprint",
			"board",
			"backlog",
		},
		use_cases = {
			"Managing Jira issues and tickets",
			"Searching through Jira projects",
			"Creating and updating Jira issues",
			"Project management tasks in Jira",
		},
		preferred_tools = {
			primary = "search_issues",
			create = "create_issue",
			view = "get_issue",
		},
		integration_strategy = "Combine Jira context with workspace information when relevant",
	}

	M.debug_log("Jira MCP server initialized with metadata and LLM guide")
	return true
end

-- Basic server configuration
M.server = {
	name = "jira",
	displayName = "Jira",
	capabilities = {
		tools = {},
		resources = {},
		resourceTemplates = {},
	},
}

-- Configuration variables
local config = {
	domain = nil,
}

-- Load API token from environment variable
local function get_api_token()
	local token = os.getenv("JIRA_TOKEN")
	if not token or token == "" then
		error("JIRA_TOKEN environment variable not set or is empty")
	end
	return token
end

-- Get full base URL from domain
local function get_base_url()
	if not config.domain then
		error("Jira domain not configured. Please set via set_config endpoint.")
	end
	-- Start with the domain
	local base_url = config.domain
	if not base_url then
		error("Base URL is nil")
	end

	-- If it already has a protocol, use it as is, otherwise prepend https://
	if type(base_url) == "string" and not base_url:match("^https?://") then
		base_url = "https://" .. base_url
	end

	-- Remove any trailing slashes if base_url is a string
	if type(base_url) == "string" then
		base_url = base_url:gsub("/+$", "")
		-- Remove any whitespace
		base_url = base_url:gsub("%s+", "")

		-- Additional URL validation
		if not base_url:match("^https?://[%w%.%-]+%.%w+") then
			error("Invalid base URL format: " .. base_url)
		end
	end

	return base_url
end

-- Helper function to create a default response object

-- Set configuration values
table.insert(M.server.capabilities.tools, {
	name = "set_config",
	description = "Set Jira configuration values",
	inputSchema = {
		type = "object",
		properties = {
			domain = {
				type = "string",
				description = "Full Jira domain (must be 'jira.idexx.com')",
			},
		},
		required = { "domain" },
	},
	handler = function(req, res)
		-- Ensure req is properly initialized
		if not req then
			req = {}
		end
		if not req.params then
			req.params = {}
		end

		-- Validate error function exists before trying to use it
		local function send_error(msg)
			if res.error then
				return res:error(msg)
			else
				-- Fallback to text response if error() not available
				return res:text(msg):send()
			end
		end

		-- Validate domain parameter
		if not req.params.domain then
			return send_error("Domain parameter is required")
		end

		if type(req.params.domain) ~= "string" then
			return send_error("Domain must be a string")
		end

		-- Enforce jira.idexx.com domain
		if req.params.domain ~= "jira.idexx.com" then
			return send_error("Invalid domain. Only 'jira.idexx.com' is allowed.")
		end

		config.domain = req.params.domain
		M.debug_log("Updated Jira domain to: " .. config.domain)

		local data = {
			status = "Configuration updated successfully",
			config = {
				domain = config.domain,
				base_url = get_base_url(),
			},
		}
		M.debug_log("set_config response: " .. vim.inspect(data))

		-- Check if json method is available, otherwise fallback to text
		if res.json then
			return res:json(data):send()
		else
			-- Fallback to text response with manually encoded JSON
			return res:text(vim.fn.json_encode(data)):send()
		end
	end,
})

-- Get current configuration (excluding sensitive data)
table.insert(M.server.capabilities.tools, {
	name = "get_config",
	description = "Get current Jira configuration (excluding sensitive data)",
	inputSchema = {
		type = "object",
		properties = {},
	},
	handler = function(_, res)
		-- Create response data with explicit nil handling
		local response_data = {}
		-- Only include domain and base_url if they are actually set
		if config.domain then
			response_data.domain = config.domain
			response_data.base_url = get_base_url()
		end
		response_data.has_api_token = os.getenv("JIRA_TOKEN") ~= nil

		-- Check if json method is available, otherwise fallback to text
		if res.json then
			M.debug_log("get_config response (json): " .. vim.inspect(response_data))
			return res:json(response_data):send()
		else
			-- Fallback to text response with manually encoded JSON
			M.debug_log("get_config response (text): " .. vim.inspect(response_data))
			return res:text(vim.fn.json_encode(response_data)):send()
		end
	end,
})

-- Clear configuration
table.insert(M.server.capabilities.tools, {
	name = "clear_config",
	description = "Clear all Jira configuration values",
	inputSchema = {
		type = "object",
		properties = {},
	},
	handler = function(_, res)
		config.domain = nil
		M.debug_log("Cleared all configuration values")
		-- Check if json method is available, otherwise fallback to text
		if res.json then
			return res:json({ status = "Configuration cleared successfully" }):send()
		else
			-- Fallback to text response with manually encoded JSON
			return res:text(vim.fn.json_encode({ status = "Configuration cleared successfully" })):send()
		end
	end,
})

local curl_utils = require("seth.mcp.curl_utils")

-- Helper function to make HTTP requests to Jira API
local function make_jira_request(method, endpoint, data)
	local api_token = get_api_token()
	local url = string.format("%s/rest/api/latest/%s", get_base_url(), endpoint)

	M.debug_log("Making request to: " .. endpoint)

	local options = {
		headers = {
			["Authorization"] = "Bearer " .. api_token,
			["Accept"] = "application/json",
			["Content-Type"] = "application/json",
			["X-Atlassian-Token"] = "no-check",
		},
	}

	if data then
		options.data = data -- curl_utils will handle JSON encoding
	end

	local response, error_or_headers = curl_utils.make_request(method, url, options)
	if not response then
		M.debug_log("Request failed: " .. tostring(error_or_headers), vim.log.levels.ERROR)
		error(error_or_headers)
	end

	return response, error_or_headers
end

-- Tools

-- Get issue details
table.insert(M.server.capabilities.tools, {
	name = "get_issue",
	description = "Get details of a Jira issue",
	inputSchema = {
		type = "object",
		properties = {
			issue_key = {
				type = "string",
				description = "The issue key (e.g., PROJECT-123)",
			},
		},
		required = { "issue_key" },
	},
	handler = function(req, res)
		M.debug_log("Getting issue details for " .. req.params.issue_key)
		local result = make_jira_request("GET", "issue/" .. req.params.issue_key)
		M.debug_log("get_issue response: " .. vim.inspect(result))

		-- Check if json method is available, otherwise fallback to text
		if res.json then
			return res:json(result):send()
		else
			-- Fallback to text response with manually encoded JSON
			return res:text(vim.fn.json_encode(result)):send()
		end
	end,
})

-- Create issue
table.insert(M.server.capabilities.tools, {
	name = "create_issue",
	description = "Create a new Jira issue",
	inputSchema = {
		type = "object",
		properties = {
			project_key = {
				type = "string",
				description = "Project key",
			},
			summary = {
				type = "string",
				description = "Issue summary",
			},
			description = {
				type = "string",
				description = "Issue description",
			},
			issue_type = {
				type = "string",
				description = "Type of issue (e.g., Bug, Task, Story)",
				default = "Task",
			},
		},
		required = { "project_key", "summary" },
	},
	handler = function(req, res)
		M.debug_log("Creating new issue in project " .. req.params.project_key)

		-- Build the issue data according to Jira API v3 format
		local issue_data = {
			fields = {
				project = { key = req.params.project_key },
				summary = req.params.summary,
				description = {
					type = "doc",
					version = 1,
					content = {
						{
							type = "paragraph",
							content = {
								{
									type = "text",
									text = req.params.description or "",
								},
							},
						},
					},
				},
				issuetype = { name = req.params.issue_type or "Task" },
			},
		}

		local result = make_jira_request("POST", "issue", issue_data)
		-- Check if json method is available, otherwise fallback to text
		if res.json then
			return res:json(result):send()
		else
			-- Fallback to text response with manually encoded JSON
			return res:text(vim.fn.json_encode(result)):send()
		end
	end,
})

-- Search issues
table.insert(M.server.capabilities.tools, {
	name = "search_issues",
	description = "Search for Jira issues using JQL",
	inputSchema = {
		type = "object",
		properties = {
			jql = {
				type = "string",
				description = "JQL search query",
			},
			max_results = {
				type = "number",
				description = "Maximum number of results to return",
				default = 50,
			},
		},
		required = { "jql" },
	},
	handler = function(req, res)
		M.debug_log("Searching issues with JQL: " .. req.params.jql)

		local search_data = {
			jql = req.params.jql,
			maxResults = req.params.max_results or 50,
			fields = { "summary", "description", "status", "priority", "issuetype" },
		}

		local result = make_jira_request("POST", "search/jql", search_data)
		-- Check if json method is available, otherwise fallback to text
		M.debug_log("search_issues response: " .. vim.inspect(result))
		if res.json then
			return res:json(result):send()
		else
			-- Fallback to text response with manually encoded JSON
			return res:text(vim.fn.json_encode(result)):send()
		end
	end,
})

-- List project issues
table.insert(M.server.capabilities.tools, {
	name = "list_project_issues",
	description = "List all issues in a Jira project",
	inputSchema = {
		type = "object",
		properties = {
			project_key = {
				type = "string",
				description = "The project key (e.g., PROJ)",
			},
			status = {
				type = "string",
				description = "Filter by status (e.g., 'Open', 'In Progress', 'Done'). Leave empty for all statuses.",
			},
			max_results = {
				type = "number",
				description = "Maximum number of results to return",
				default = 50,
			},
			order_by = {
				type = "string",
				description = "Field to order results by (e.g., 'created', 'updated', 'priority', 'status')",
				default = "created",
			},
			order_direction = {
				type = "string",
				description = "Order direction ('ASC' or 'DESC')",
				default = "DESC",
			},
		},
		required = { "project_key" },
	},
	handler = function(req, res)
		M.debug_log("Listing issues for project " .. req.params.project_key)

		-- Construct JQL query
		local jql_parts = {
			string.format("project = %s", req.params.project_key),
		}

		-- Add status filter if provided
		if req.params.status then
			table.insert(jql_parts, string.format("status = '%s'", req.params.status))
		end

		-- Add ordering
		local order_by = req.params.order_by or "created"
		local direction = req.params.order_direction or "DESC"
		local jql = table.concat(jql_parts, " AND ") .. string.format(" ORDER BY %s %s", order_by, direction)

		local search_data = {
			jql = jql,
			maxResults = req.params.max_results or 50,
			fields = {
				"summary",
				"status",
				"priority",
				"issuetype",
				"created",
				"updated",
				"assignee",
				"reporter",
			},
		}

		local result = make_jira_request("POST", "search/jql", search_data)
		M.debug_log("list_project_issues response: " .. vim.inspect(result))

		-- Check if json method is available, otherwise fallback to text
		if res.json then
			return res:json(result):send()
		else
			-- Fallback to text response with manually encoded JSON
			return res:text(vim.fn.json_encode(result)):send()
		end
	end,
})

-- Resources

-- Current user info
table.insert(M.server.capabilities.resources, {
	name = "current_user",
	uri = "jira://user/current",
	description = "Get information about the current Jira user",
	handler = function(req, res)
		M.debug_log("Getting current user information")
		local result = make_jira_request("GET", "myself")
		-- Check if json method is available, otherwise fallback to text
		if res.json then
			return res:json(result):send()
		else
			-- Fallback to text response with manually encoded JSON
			return res:text(vim.fn.json_encode(result)):send()
		end
	end,
})

-- Resource Templates

-- Issue details template
table.insert(M.server.capabilities.resourceTemplates, {
	name = "issue",
	uriTemplate = "jira://issue/{issue_key}",
	description = "Get detailed information about a specific issue",
	handler = function(req, res)
		M.debug_log("Getting detailed information for issue " .. req.params.issue_key)
		local result =
			make_jira_request("GET", string.format("issue/%s?expand=renderedFields,names,schema", req.params.issue_key))
		return res:json(result):send()
	end,
})

-- Project details template
table.insert(M.server.capabilities.resourceTemplates, {
	name = "project",
	uriTemplate = "jira://project/{project_key}",
	description = "Get detailed information about a specific project",
	handler = function(req, res)
		M.debug_log("Getting detailed information for project " .. req.params.project_key)
		local result = make_jira_request("GET", string.format("project/%s", req.params.project_key))
		return res:json(result):send()
	end,
})

-- Set debug mode
function M.set_debug_mode(enabled)
	M.debug_mode = enabled
	M.debug_log("Debug mode " .. (enabled and "enabled" or "disabled"))
end

-- Test function to directly invoke tools/resources
-- Test function to directly invoke tools/resources
function M.test(tool_name, params)
	-- Enable debug mode for testing
	M.set_debug_mode(true)
	M.debug_log("Testing tool: " .. tool_name)

	-- Initialize server if not already done
	if not M.is_registered then
		M.init()
	end

	-- Find the requested tool
	local tool
	for _, t in ipairs(M.server.capabilities.tools) do
		if t.name == tool_name then
			tool = t
			break
		end
	end

	if not tool then
		error("Tool not found: " .. tool_name)
	end

	-- Create mock request and response objects like MCPHub would
	local req = {
		params = params or {},
	}
	local res = create_mcphub_response()

	-- Execute the tool handler as MCPHub would
	local result = tool.handler(req, res)
	M.debug_log("Tool execution result: " .. vim.inspect(result))

	-- Check for error response
	if result and result.is_error then
		error(result.body)
	end

	return result
end

return M
