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
				description = "Full Jira domain",
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

		-- Create response if not provided (for testing)
		if not res then
			res = M.create_default_response()
		end

		-- Create error response properly that always returns a table
		local function send_error(msg)
			M.debug_log("Sending error: " .. msg)

			-- Create a clean response object for consistent structure
			local response = M.create_default_response()

			-- Set error properties
			response.body = msg
			response.mime_type = "text/plain"
			response.is_error = true

			-- Return structured response directly
			return {
				body = response.body,
				mime_type = response.mime_type,
				is_error = response.is_error,
			}
		end

		-- Validate domain parameter
		if not req.params.domain then
			return send_error("Domain parameter is required")
		end

		if type(req.params.domain) ~= "string" then
			return send_error("Domain must be a string")
		end

		-- Basic domain validation
		if not req.params.domain:match("^[%w%.-]+%.%w+$") then
			return send_error("Invalid domain format. Please provide a valid domain name.")
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
-- This function handles authentication using Personal Access Tokens (PATs)
-- PATs must be provided via JIRA_TOKEN environment variable
-- PATs are supported in Jira Server/Data Center 8.14+ and must be used as Bearer tokens
-- Usage limitations:
-- 1. Only works with REST API endpoints
-- 2. Cannot be used for basic auth or non-REST authentication
-- 3. Session handling depends on atlassian.pats.invalidate.session.enabled setting
-- Helper function to build JQL queries
function M.build_jql_query(params)
	local conditions = {}

	-- Handle project key(s)
	if params.project_keys then
		-- Multiple project keys
		table.insert(conditions, "project in (" .. table.concat(params.project_keys, ", ") .. ")")
	elseif params.project_key then
		-- Single project key
		table.insert(conditions, "project = " .. params.project_key)
	end

	-- Handle status (quoted because it often contains spaces)
	if params.status then
		table.insert(conditions, 'status = "' .. params.status .. '"')
	end

	-- Handle priority (no quotes for single word values)
	if params.priority then
		table.insert(conditions, "priority = " .. params.priority)
	end

	-- Handle text search (quoted as it's a text search)
	if params.text_search then
		table.insert(conditions, 'text ~ "' .. params.text_search .. '"')
	end

	-- Combine conditions with AND
	local query = table.concat(conditions, " AND ")

	-- Add ordering if specified
	if params.order_by then
		query = query .. " ORDER BY " .. params.order_by
		if params.order_direction then
			query = query .. " " .. params.order_direction
		end
	end

	return query
end

local function make_jira_request(method, endpoint, data)
	local api_token = get_api_token()
	-- Use v2 API explicitly instead of 'latest'
	local url = string.format("%s/rest/api/2/%s", get_base_url(), endpoint)

	M.debug_log(string.format("Making %s request to %s", method, url))

	-- Validate required fields before making request
	if not api_token then
		return nil, "No API token found. Please set JIRA_TOKEN environment variable."
	end

	-- Initialize request options with proper headers and debug-friendly settings
	local options = {
		method = method,
		headers = {
			["Authorization"] = "Bearer " .. api_token,
			["Content-Type"] = "application/json",
			["Accept"] = "application/json",
		},
		debug = M.debug_mode, -- Only enable debug in debug mode
		debug_options = {
			write_debug_script = M.debug_mode, -- Only write debug script in debug mode
			include_headers = false, -- Don't include headers in normal response
			show_progress = false,
			max_time = 30,
			fail_on_error = true, -- Exit on HTTP errors for cleaner error handling
			silent = not M.debug_mode, -- Only show output in debug mode
		},
	}

	if data then
		-- Special handling for search endpoint
		if endpoint == "search" then
			-- Keep JQL query as is without extra escaping
			if data.jql then
				M.debug_log("Raw JQL query: " .. vim.inspect(data.jql))

				-- Validate JQL query format
				if type(data.jql) ~= "string" then
					return nil, "JQL query must be a string"
				end
			end

			-- Ensure fields are specified with proper defaults
			if not data.fields then
				data.fields = {
					"summary",
					"description",
					"status",
					"priority",
					"issuetype",
					"created",
					"updated",
					"assignee",
					"reporter",
				}
			end

			-- Always include validation and proper expansion
			data.validateQuery = true
			data.expand = data.expand or { "schema", "names" }
		end

		-- Let curl_utils handle proper JSON encoding
		options.data = vim.fn.json_encode(data)
		M.debug_log("Request payload: " .. vim.inspect(options.data))
	end

	local response, error_or_headers = curl_utils.make_request(method, url, options)
	local error_msg

	-- Check if we got both a response and headers
	if response and error_or_headers then
		M.debug_log("Got response with headers. Response: " .. vim.inspect(response))
		M.debug_log("Headers: " .. vim.inspect(error_or_headers))

		-- Try to parse the response as JSON
		local success, parsed = pcall(vim.fn.json_decode, response)
		if success then
			M.debug_log("Successfully parsed response JSON: " .. vim.inspect(parsed))
			
			-- Only treat as error if we have explicit error indicators
			if parsed.errorMessages or parsed.errors or (parsed.error and not parsed.id) then
				-- Extract error messages from Jira response format
				if parsed.errorMessages then
					error_msg = table.concat(parsed.errorMessages, "; ")
				elseif parsed.errors then
					local error_msgs = {}
					for k, v in pairs(parsed.errors) do
						table.insert(error_msgs, k .. ": " .. v)
					end
					error_msg = table.concat(error_msgs, "; ")
				elseif parsed.error then
					error_msg = parsed.error
				end
				
				M.debug_log("Extracted error message: " .. error_msg)
				return nil, error_msg
			else
				-- If no error indicators, this is a successful response with headers
				return parsed
			end
		else
			-- If not JSON, return the raw response
			M.debug_log("Response not JSON, using raw response")
			return nil, response
		end
	end

	-- No response means a connection/curl error
	if not response then
		if type(error_or_headers) == "string" then
			if error_or_headers:match("401") then
				error_msg = "Authentication failed: Invalid or expired PAT token. Please ensure your JIRA_TOKEN environment variable contains a valid token."
			elseif error_or_headers:match("403") then
				error_msg = "Authorization failed: Your PAT token lacks the required permissions for this operation."
			elseif error_or_headers:match("429") then
				error_msg = "Rate limit exceeded: Too many API requests. Please try again later."
			elseif error_or_headers:match("400") then
				-- For 400 errors without a response body, try one more time with debug
				local raw_response = curl_utils.make_request(method, url, {
					headers = options.headers,
					data = options.data,
					debug = true,
				})
				error_msg = raw_response or error_or_headers
			else
				error_msg = error_or_headers
			end
		else
			error_msg = vim.inspect(error_or_headers)
		end
		
		M.debug_log("Connection/curl error: " .. error_msg, vim.log.levels.ERROR)
		return nil, error_msg
	end

	-- Log the raw response for debugging
	M.debug_log("Raw response: " .. vim.inspect(response))

	if not response then
		local error_msg
		-- Check for common PAT-related errors
		if type(error_or_headers) == "string" then
			if error_or_headers:match("401") then
				error_msg =
					"Authentication failed: Invalid or expired PAT token. Please ensure your JIRA_TOKEN environment variable contains a valid token."
			elseif error_or_headers:match("403") then
				error_msg = "Authorization failed: Your PAT token lacks the required permissions for this operation."
			elseif error_or_headers:match("429") then
				error_msg = "Rate limit exceeded: Too many API requests. Please try again later."
			elseif error_or_headers:match("400") then
				-- For 400 errors, try to make the request again with more debugging info
				local raw_response = curl_utils.make_request("POST", url, {
					headers = options.headers,
					data = options.data,
					debug = true, -- Enable curl debug output
				})
				error_msg = string.format(
					"Bad request (400). Request failed with error:\n%s\nRaw request:\nURL: %s\nHeaders: %s\nData: %s\nRaw response: %s",
					tostring(error_or_headers),
					url,
					vim.inspect(options.headers),
					vim.fn.json_encode(options.data),
					tostring(raw_response)
				)
			else
				error_msg = string.format(
					"Request failed: %s\nURL: %s\nHeaders: %s",
					tostring(error_or_headers),
					url,
					vim.inspect(options.headers)
				)
			end
		else
			error_msg = string.format(
				"Request failed: %s\nURL: %s\nHeaders: %s",
				tostring(error_or_headers),
				url,
				vim.inspect(options.headers)
			)
		end
		M.debug_log(error_msg, vim.log.levels.ERROR)
		return nil, error_msg
	end

	-- Try to parse response to get more detailed error information
	if response and type(response) == "string" then
		local success, parsed = pcall(vim.fn.json_decode, response)
		if success then
			-- Log the entire response for debugging
			M.debug_log("Full API Response: " .. vim.inspect(parsed))

			-- Check for specific error details
			if parsed.errorMessages then
				local error_msg = "Jira API Error: " .. table.concat(parsed.errorMessages, "; ")
				M.debug_log("API Error Messages: " .. error_msg)
				return nil, error_msg
			end

			if parsed.errors then
				local error_msgs = {}
				for k, v in pairs(parsed.errors) do
					table.insert(error_msgs, k .. ": " .. v)
				end
				local error_msg = "Jira API Errors: " .. table.concat(error_msgs, "; ")
				M.debug_log("API Errors: " .. error_msg)
				return nil, error_msg
			end

			return parsed
		else
			-- If JSON parsing fails, return raw response
			return response
		end
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
		M.debug_log("Request params: " .. vim.inspect(req.params))

		-- Build the issue data according to Jira API v2 format
		-- Convert description to text format
		local description = req.params.description
		if type(description) ~= "string" then
			description = ""
		end

		local issue_data = {
			fields = {
				project = { key = req.params.project_key },
				summary = req.params.summary,
				description = description,
				issuetype = { name = req.params.issue_type or "Task" },
			},
		}

		M.debug_log("Issue data before request: " .. vim.inspect(issue_data))

		local result, err = make_jira_request("POST", "issue", issue_data)
		if err then
			M.debug_log("Error creating issue: " .. tostring(err), vim.log.levels.ERROR)
			return res:error(err)
		end

		M.debug_log("Create issue response: " .. vim.inspect(result))

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
			start_at = {
				type = "number",
				description = "Index of the first issue to return (0-based)",
				default = 0,
			},
			max_results = {
				type = "number",
				description = "Maximum number of results to return (default: 50, max: 100)",
				default = 50,
			},
			fields = {
				type = "array",
				items = {
					type = "string",
				},
				description = "List of fields to return",
				default = { "summary", "status", "priority", "issuetype", "created", "updated", "assignee", "reporter" },
			},
			validate_query = {
				type = "boolean",
				description = "Whether to validate the JQL query",
				default = true,
			},
			-- Note: The fieldsByKeys parameter is documented in the Jira API docs but has been
			-- removed here as it causes issues with some Jira instances despite being documented.
			-- The API returns an error when this parameter is used.
			expand = {
				type = "array",
				items = {
					type = "string",
				},
				description = "A list of entities to expand in the response",
				default = { "names", "schema" },
			},
		},
		required = { "jql" },
	},
	handler = function(req, res)
		M.debug_log("Searching issues with JQL: " .. req.params.jql)

		-- Ensure max_results stays within bounds (1-100)
		local max_results = req.params.max_results or 50
		max_results = math.min(math.max(1, max_results), 100)

		local search_data = {
			jql = req.params.jql,
			startAt = req.params.start_at or 0,
			maxResults = max_results,
			fields = req.params.fields or {
				"summary",
				"status",
				"priority",
				"issuetype",
				"created",
				"updated",
				"assignee",
				"reporter",
			},
			validateQuery = true,
			expand = { "schema", "names" }, -- Force schema and names expansion for better error messages
		}

		local result, err = make_jira_request("POST", "search", search_data)
		if err then
			return res:error(err)
		end

		M.debug_log("search_issues response: " .. vim.inspect(result))

		-- Check if json method is available, otherwise fallback to text
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

		local result = make_jira_request("POST", "search", search_data)
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

-- Get server info
table.insert(M.server.capabilities.tools, {
	name = "get_server_info",
	description = "Get Jira server information including version details",
	inputSchema = {
		type = "object",
		properties = {},
	},
	handler = function(_, res)
		M.debug_log("Getting server information")
		local result = make_jira_request("GET", "serverInfo")
		if res.json then
			return res:json(result):send()
		else
			return res:text(vim.fn.json_encode(result)):send()
		end
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
