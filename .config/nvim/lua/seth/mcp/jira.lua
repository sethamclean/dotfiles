-- Jira MCP server
local M = {}

-- Debug mode flag
M.debug_mode = false

-- This flag will be set to true when the server is successfully registered
M.is_registered = false

-- Debug logging function
local function debug_log(msg, level)
	if not M.debug_mode then
		return
	end
	level = level or vim.log.levels.INFO
	vim.notify("[Jira MCP] " .. msg, level)
end

-- Helper function to create a default response object
local function create_default_response()
	-- Create base response object
	local response = {}

	-- Explicitly attach json method to response object
	response.json = function(_, data)
		-- Ensure data is not nil
		data = data or {}
		-- Return object with send method
		return {
			send = function()
				return data
			end,
		}
	end

	-- Create metatable to handle method calls
	local mt = {
		__index = response, -- This makes method calls work with : syntax
	}

	-- Set the metatable
	setmetatable(response, mt)

	-- Return the response object
	return response
end

-- Initialize function that will be called from init.lua
function M.init()
	debug_log("Jira MCP server initialization started")

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

	debug_log("Jira MCP server initialized with metadata and LLM guide")
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

-- Configuration variables with environment fallback
local config = {
	base_url = nil,
	email = nil,
	api_token = nil,
}

-- Load config from environment variables
local function load_env_config()
	config.base_url = config.base_url or os.getenv("JIRA_BASE_URL")
	config.email = config.email or os.getenv("JIRA_EMAIL")
	config.api_token = config.api_token or os.getenv("JIRA_TOKEN")
end

-- Set configuration values
table.insert(M.server.capabilities.tools, {
	name = "set_config",
	description = "Set Jira configuration values",
	inputSchema = {
		type = "object",
		properties = {
			base_url = {
				type = "string",
				description = "Jira base URL (e.g., https://your-domain.atlassian.net)",
			},
			email = {
				type = "string",
				description = "Jira account email",
			},
			api_token = {
				type = "string",
				description = "Jira API token",
			},
		},
	},
	handler = function(req, res)
		-- Ensure req and res are properly initialized
		req = req or {}
		req.params = req.params or {}

		if not res then
			res = create_default_response()
		end

		-- Initialize res.json if it doesn't exist (defensive programming)
		if not res.json then
			res.json = function(_, data)
				return {
					send = function()
						return data
					end,
				}
			end
		end

		if req.params.base_url then
			config.base_url = req.params.base_url
			debug_log("Updated base_url configuration")
		end
		if req.params.email then
			config.email = req.params.email
			debug_log("Updated email configuration")
		end
		if req.params.api_token then
			config.api_token = req.params.api_token
			debug_log("Updated api_token configuration")
		end

		-- Load environment variables as fallback after updating config
		load_env_config()

		return res:json({
			status = "Configuration updated successfully",
			config = {
				base_url = config.base_url or "",
				email = config.email or "",
				has_api_token = config.api_token ~= nil,
			},
		}):send()
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
		-- Ensure we have a valid response object
		if not res then
			res = create_default_response()
		end

		-- Load environment variables first
		load_env_config()

		-- Create response data
		local response_data = {
			base_url = config.base_url or "",
			email = config.email or "",
			has_api_token = config.api_token ~= nil,
		}

		return res:json(response_data):send()
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
	handler = function(req, res)
		if not res then
			res = create_default_response()
		end
		config.base_url = nil
		config.email = nil
		config.api_token = nil
		debug_log("Cleared all configuration values")
		return res:json({ status = "Configuration cleared successfully" }):send()
	end,
})

-- Helper function to make HTTP requests to Jira API
local function make_jira_request(method, endpoint, data)
	-- Load environment variables as fallback
	load_env_config()

	if not config.base_url or not config.email or not config.api_token then
		error(
			"Jira configuration missing. Please set values via set_config endpoint or use JIRA_BASE_URL, JIRA_EMAIL, and JIRA_API_TOKEN environment variables."
		)
	end

	-- Check config values
	debug_log(
		string.format(
			"API request config: base_url=%s, email=%s, token_length=%s",
			config.base_url or "nil",
			config.email or "nil",
			config.api_token and string.len(config.api_token) or "nil"
		)
	)

	local auth = string.format("%s:%s", config.email, config.api_token)
	debug_log("Making Jira request to endpoint: " .. endpoint)

	-- Create base64 authorization string using Lua instead of shell commands
	local function base64encode(str)
		local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		return (
			(str:gsub(".", function(x)
				local r, b = "", x:byte()
				for i = 8, 1, -1 do
					r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
				end
				return r
			end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
				if #x < 6 then
					return ""
				end
				local c = 0
				for i = 1, 6 do
					c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
				end
				return b:sub(c + 1, c + 1)
			end) .. ({ "", "==", "=" })[#str % 3 + 1]
		)
	end

	local auth_base64 = base64encode(auth)
	debug_log("Generated base64 auth string (first 10 chars): " .. string.sub(auth_base64, 1, 10) .. "...")

	-- Use -i to include headers in response and -s for silent mode without progress meter
	local curl_cmd = string.format(
		'curl -i -s -X %s "%s/rest/api/3/%s" -H "Authorization: Basic %s" -H "Content-Type: application/json"',
		method,
		config.base_url,
		endpoint,
		auth_base64
	)

	-- If there's data, write it to a temporary file
	local data_file
	if data then
		data_file = os.tmpname()
		local data_handle = io.open(data_file, "w")
		data_handle:write(vim.fn.json_encode(data))
		data_handle:close()
		curl_cmd = curl_cmd .. string.format(" -d '@%s'", data_file)
	end

	debug_log("Executing curl command (auth/data redacted)")
	local result = vim.fn.system(curl_cmd)

	-- Clean up data file if it exists
	if data_file then
		os.remove(data_file)
	end

	if vim.v.shell_error ~= 0 then
		debug_log("Jira API request failed with error: " .. result)
		error(string.format("Jira API request failed: %s", result))
	end

	debug_log("Got response from Jira API")
	-- Try to decode JSON response
	local ok, decoded = pcall(vim.fn.json_decode, result)
	if not ok then
		debug_log("Failed to decode JSON response: " .. tostring(decoded))
		debug_log("Raw response: " .. result)
		error("Failed to decode Jira API response")
	end

	return decoded
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
		if not res then
			res = create_default_response()
		end
		debug_log("Getting issue details for " .. req.params.issue_key)
		local result = make_jira_request("GET", "issue/" .. req.params.issue_key)
		return res:json(result):send()
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
		if not res then
			res = create_default_response()
		end
		debug_log("Creating new issue in project " .. req.params.project_key)

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
		return res:json(result):send()
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
		if not res then
			res = create_default_response()
		end
		debug_log("Searching issues with JQL: " .. req.params.jql)

		local search_data = {
			jql = req.params.jql,
			maxResults = req.params.max_results or 50,
			fields = { "summary", "description", "status", "priority", "issuetype" },
		}

		local result = make_jira_request("POST", "search", search_data)
		return res:json(result):send()
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
		if not res then
			res = create_default_response()
		end
		debug_log("Listing issues for project " .. req.params.project_key)

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

		local result = make_jira_request("POST", "search", search_data)
		return res:json(result):send()
	end,
})

-- Resources

-- Current user info
table.insert(M.server.capabilities.resources, {
	name = "current_user",
	uri = "jira://user/current",
	description = "Get information about the current Jira user",
	handler = function(req, res)
		if not res then
			res = create_default_response()
		end
		debug_log("Getting current user information")
		local result = make_jira_request("GET", "myself")
		return res:json(result):send()
	end,
})

-- Resource Templates

-- Issue details template
table.insert(M.server.capabilities.resourceTemplates, {
	name = "issue",
	uriTemplate = "jira://issue/{issue_key}",
	description = "Get detailed information about a specific issue",
	handler = function(req, res)
		if not res then
			res = create_default_response()
		end
		debug_log("Getting detailed information for issue " .. req.params.issue_key)
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
		debug_log("Getting detailed information for project " .. req.params.project_key)
		local result = make_jira_request("GET", string.format("project/%s", req.params.project_key))
		return res:json(result):send()
	end,
})

-- Set debug mode
function M.set_debug_mode(enabled)
	M.debug_mode = enabled
	debug_log("Debug mode " .. (enabled and "enabled" or "disabled"))
end

-- Test function to directly invoke tools/resources
function M.test(tool_name, params)
	-- Enable debug mode for testing
	M.set_debug_mode(true)
	debug_log("Testing tool: " .. tool_name)

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

	-- Create test request and response objects
	local req = {
		params = params or {},
	}
	local res = create_default_response()

	-- Execute the tool handler
	debug_log("Executing tool with params: " .. vim.inspect(params))
	local result = tool.handler(req, res)
	debug_log("Tool execution result: " .. vim.inspect(result))

	return result
end

return M
