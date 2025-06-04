-- Jira MCP server
local M = { is_registered = false }

-- Debug mode flag
M.debug_mode = true

-- Debug log ring buffer (max 500 messages)
local DEBUG_LOG_MAX = 500
local debug_log_buffer = {}
local debug_log_index = 1
local debug_log_size = 0

M.is_registered = false

local Response = require("seth.mcp.response")

local function create_mcphub_response()
	return Response:new()
end

-- Log file location under Neovim's data directory
local log_dir = vim.fn.stdpath("data") .. "/mcp-logs"
local log_file = log_dir .. "/jira-mcp.log"

local function ensure_log_dir()
	local stat = vim.loop.fs_stat(log_dir)
	if not stat then
		vim.fn.mkdir(log_dir, "p")
	end
end

function M.debug_log(msg, level)
	if not M.debug_mode then
		return
	end
	level = level or vim.log.levels.INFO
	local entry = os.date("%Y-%m-%d %H:%M:%S") .. " [" .. (level or "INFO") .. "] " .. msg
	-- Write to in-memory buffer
	debug_log_buffer[debug_log_index] = entry
	debug_log_index = debug_log_index % DEBUG_LOG_MAX + 1
	if debug_log_size < DEBUG_LOG_MAX then
		debug_log_size = debug_log_size + 1
	end
	-- Write to file
	ensure_log_dir()
	local f = io.open(log_file, "a")
	if f then
		f:write(entry .. "\n")
		f:close()
	end
end

function M.create_default_response()
	local Response = require("seth.mcp.response")
	return Response:new()
end

function M.init()
	M.debug_log("Jira MCP server initialization started")
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

M.server = {
	name = "jira",
	displayName = "Jira",
	capabilities = {
		tools = {},
		resources = {},
		resourceTemplates = {},
	},
}

local config = { domain = nil }

local function get_api_token()
	local token = os.getenv("JIRA_TOKEN")
	if not token or token == "" then
		error("JIRA_TOKEN environment variable not set or is empty")
	end
	return token
end

local function get_base_url()
	if not config.domain then
		error("Jira domain not configured. Please set via set_config endpoint.")
	end
	local base_url = config.domain
	if not base_url then
		error("Base URL is nil")
	end
	if type(base_url) == "string" and not base_url:match("^https?://") then
		base_url = "https://" .. base_url
	end
	if type(base_url) == "string" then
		base_url = base_url:gsub("/+%$", "")
		base_url = base_url:gsub("%s+", "")
		if not base_url:match("^https?://[%w%.%-]+%.%w+") then
			error("Invalid base URL format: " .. base_url)
		end
	end
	return base_url
end

local curl_utils = require("seth.mcp.curl_utils")

function M.build_jql_query(params)
	local conditions = {}
	if params.project_keys then
		table.insert(conditions, "project in (" .. table.concat(params.project_keys, ", ") .. ")")
	elseif params.project_key then
		table.insert(conditions, "project = " .. params.project_key)
	end
	if params.status then
		table.insert(conditions, 'status = "' .. params.status .. '"')
	end
	if params.priority then
		table.insert(conditions, "priority = " .. params.priority)
	end
	if params.text_search then
		table.insert(conditions, 'text ~ "' .. params.text_search .. '"')
	end
	local query = table.concat(conditions, " AND ")
	if params.order_by then
		query = query .. " ORDER BY " .. params.order_by
		if params.order_direction then
			query = query .. " " .. params.order_direction
		end
	end
	return query
end

-- Handler functions

-- Move make_jira_request above all handler functions so it is in scope
local function make_jira_request(method, endpoint, data)
	local api_token = get_api_token()
	local url = string.format("%s/rest/api/2/%s", get_base_url(), endpoint)
	M.debug_log(string.format("Making %s request to %s", method, url))
	if not api_token then
		return nil, "No API token found. Please set JIRA_TOKEN environment variable."
	end
	local options = {
		method = method,
		headers = {
			["Authorization"] = "Bearer " .. api_token,
			["Content-Type"] = "application/json",
			["Accept"] = "application/json",
		},
		debug = M.debug_mode,
		debug_options = {
			write_debug_script = M.debug_mode,
			include_headers = false,
			show_progress = false,
			max_time = 30,
			fail_on_error = true,
			silent = not M.debug_mode,
		},
	}
	if data then
		if endpoint == "search" then
			if data.jql then
				M.debug_log("Raw JQL query: " .. vim.inspect(data.jql))
				if type(data.jql) ~= "string" then
					return nil, "JQL query must be a string"
				end
			end
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
			data.validateQuery = true
			data.expand = data.expand or { "schema", "names" }
		end
		options.data = vim.fn.json_encode(data)
		M.debug_log("Request payload: " .. vim.inspect(options.data))
	end
	local response, error_or_headers = curl_utils.make_request(method, url, options)
	local error_msg
	if response and error_or_headers then
		M.debug_log("Got response with headers. Response: " .. vim.inspect(response))
		M.debug_log("Headers: " .. vim.inspect(error_or_headers))
		local success, parsed = pcall(vim.fn.json_decode, response)
		if success then
			M.debug_log("Successfully parsed response JSON: " .. vim.inspect(parsed))
			if parsed.errorMessages or parsed.errors or (parsed.error and not parsed.id) then
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
				return parsed
			end
		else
			M.debug_log("Response not JSON, using raw response")
			return nil, response
		end
	end
	if not response then
		if type(error_or_headers) == "string" then
			if error_or_headers:match("401") then
				error_msg =
					"Authentication failed: Invalid or expired PAT token. Please ensure your JIRA_TOKEN environment variable contains a valid token."
			elseif error_or_headers:match("403") then
				error_msg = "Authorization failed: Your PAT token lacks the required permissions for this operation."
			elseif error_or_headers:match("429") then
				error_msg = "Rate limit exceeded: Too many API requests. Please try again later."
			elseif error_or_headers:match("400") then
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
	M.debug_log("Raw response: " .. vim.inspect(response))
	if response and type(response) == "string" then
		local success, parsed = pcall(vim.fn.json_decode, response)
		if success then
			M.debug_log("Full API Response: " .. vim.inspect(parsed))
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
			return response
		end
	end
	return response, error_or_headers
end

local function handle_get_issue(req, res)
	M.debug_log("Creating new issue in project " .. req.params.project_key)
	M.debug_log("Request params: " .. vim.inspect(req.params))
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
	if res.json then
		return res:json(result):send()
	else
		return res:text(vim.fn.json_encode(result)):send()
	end
end

local function handle_search_issues(req, res)
	M.debug_log("Searching issues with JQL: " .. req.params.jql)
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
		expand = { "schema", "names" },
	}
	local result, err = make_jira_request("POST", "search", search_data)
	if err then
		M.debug_log("Error in search_issues: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	M.debug_log("search_issues response: " .. vim.inspect(result))
	if res.json then
		return res:json(result):send()
	else
		return res:text(vim.fn.json_encode(result)):send()
	end
end

local function handle_list_project_issues(req, res)
	M.debug_log("Listing issues for project " .. req.params.project_key)
	local jql_parts = {
		string.format("project = %s", req.params.project_key),
	}
	if req.params.status then
		table.insert(jql_parts, string.format("status = '%s'", req.params.status))
	end
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
	local result, err = make_jira_request("POST", "search", search_data)
	if err then
		M.debug_log("Error in list_project_issues: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	M.debug_log("list_project_issues response: " .. vim.inspect(result))
	if res.json then
		return res:json(result):send()
	else
		return res:text(vim.fn.json_encode(result)):send()
	end
end

local function handle_set_config(req, res)
	M.debug_log("Setting Jira config: " .. vim.inspect(req.params))
	if not req.params.domain or req.params.domain == "" then
		return res:error("Domain is required.")
	end
	config.domain = req.params.domain
	return res:json({ success = true, domain = config.domain }):send()
end

local function handle_get_config(_, res)
	M.debug_log("Getting Jira config")
	return res:json({ domain = config.domain }):send()
end

local function handle_get_projects(_, res)
	M.debug_log("Listing all Jira projects")
	local result, err = make_jira_request("GET", "project")
	if err then
		M.debug_log("Error in get_projects: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_get_project(req, res)
	M.debug_log("Getting project details for " .. req.params.project_key)
	local result, err = make_jira_request("GET", "project/" .. req.params.project_key)
	if err then
		M.debug_log("Error in get_project: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_get_issue_types(req, res)
	M.debug_log("Listing issue types for project " .. req.params.project_key)
	local result, err = make_jira_request("GET", "project/" .. req.params.project_key .. "/issuetypes")
	if err then
		M.debug_log("Error in get_issue_types: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_get_statuses(_, res)
	M.debug_log("Listing all Jira statuses")
	local result, err = make_jira_request("GET", "status")
	if err then
		M.debug_log("Error in get_statuses: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_get_priorities(_, res)
	M.debug_log("Listing all Jira priorities")
	local result, err = make_jira_request("GET", "priority")
	if err then
		M.debug_log("Error in get_priorities: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_get_myself(_, res)
	M.debug_log("Getting current user info")
	local result, err = make_jira_request("GET", "myself")
	if err then
		M.debug_log("Error in get_myself: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_get_boards(_, res)
	M.debug_log("Listing all Jira boards")
	local result, err = make_jira_request("GET", "board")
	if err then
		M.debug_log("Error in get_boards: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_get_sprints(req, res)
	M.debug_log("Listing sprints for board " .. tostring(req.params.board_id))
	local result, err = make_jira_request("GET", "board/" .. req.params.board_id .. "/sprint")
	if err then
		M.debug_log("Error in get_sprints: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_get_transitions(req, res)
	M.debug_log("Listing transitions for issue " .. req.params.issue_key)
	local result, err = make_jira_request("GET", "issue/" .. req.params.issue_key .. "/transitions")
	if err then
		M.debug_log("Error in get_transitions: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_transition_issue(req, res)
	M.debug_log("Transitioning issue " .. req.params.issue_key .. " to transition " .. req.params.transition_id)
	local data = { transition = { id = req.params.transition_id } }
	local result, err = make_jira_request("POST", "issue/" .. req.params.issue_key .. "/transitions", data)
	if err then
		M.debug_log("Error in transition_issue: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result or { success = true }):send()
end

local function handle_assign_issue(req, res)
	M.debug_log("Assigning issue " .. req.params.issue_key .. " to " .. req.params.assignee)
	local data = { accountId = req.params.assignee }
	local result, err = make_jira_request("PUT", "issue/" .. req.params.issue_key .. "/assignee", data)
	if err then
		M.debug_log("Error in assign_issue: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result or { success = true }):send()
end

local function handle_comment_issue(req, res)
	M.debug_log("Adding comment to issue " .. req.params.issue_key)
	local data = { body = req.params.comment }
	local result, err = make_jira_request("POST", "issue/" .. req.params.issue_key .. "/comment", data)
	if err then
		M.debug_log("Error in comment_issue: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result):send()
end

local function handle_update_issue(req, res)
	M.debug_log("Updating issue " .. req.params.issue_key .. " with fields: " .. vim.inspect(req.params.fields))
	local data = { fields = req.params.fields }
	local result, err = make_jira_request("PUT", "issue/" .. req.params.issue_key, data)
	if err then
		M.debug_log("Error in update_issue: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result or { success = true }):send()
end

local function handle_delete_issue(req, res)
	M.debug_log("Deleting issue " .. req.params.issue_key)
	local result, err = make_jira_request("DELETE", "issue/" .. req.params.issue_key)
	if err then
		M.debug_log("Error in delete_issue: " .. tostring(err), vim.log.levels.ERROR)
		return res:error(err)
	end
	return res:json(result or { success = true }):send()
end

local function make_jira_request(method, endpoint, data)
	local api_token = get_api_token()
	local url = string.format("%s/rest/api/2/%s", get_base_url(), endpoint)
	M.debug_log(string.format("Making %s request to %s", method, url))
	if not api_token then
		return nil, "No API token found. Please set JIRA_TOKEN environment variable."
	end
	local options = {
		method = method,
		headers = {
			["Authorization"] = "Bearer " .. api_token,
			["Content-Type"] = "application/json",
			["Accept"] = "application/json",
		},
		debug = M.debug_mode,
		debug_options = {
			write_debug_script = M.debug_mode,
			include_headers = false,
			show_progress = false,
			max_time = 30,
			fail_on_error = true,
			silent = not M.debug_mode,
		},
	}
	if data then
		if endpoint == "search" then
			if data.jql then
				M.debug_log("Raw JQL query: " .. vim.inspect(data.jql))
				if type(data.jql) ~= "string" then
					return nil, "JQL query must be a string"
				end
			end
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
			data.validateQuery = true
			data.expand = data.expand or { "schema", "names" }
		end
		options.data = vim.fn.json_encode(data)
		M.debug_log("Request payload: " .. vim.inspect(options.data))
	end
	local response, error_or_headers = curl_utils.make_request(method, url, options)
	local error_msg
	if response and error_or_headers then
		M.debug_log("Got response with headers. Response: " .. vim.inspect(response))
		M.debug_log("Headers: " .. vim.inspect(error_or_headers))
		local success, parsed = pcall(vim.fn.json_decode, response)
		if success then
			M.debug_log("Successfully parsed response JSON: " .. vim.inspect(parsed))
			if parsed.errorMessages or parsed.errors or (parsed.error and not parsed.id) then
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
				return parsed
			end
		else
			M.debug_log("Response not JSON, using raw response")
			return nil, response
		end
	end
	if not response then
		if type(error_or_headers) == "string" then
			if error_or_headers:match("401") then
				error_msg =
					"Authentication failed: Invalid or expired PAT token. Please ensure your JIRA_TOKEN environment variable contains a valid token."
			elseif error_or_headers:match("403") then
				error_msg = "Authorization failed: Your PAT token lacks the required permissions for this operation."
			elseif error_or_headers:match("429") then
				error_msg = "Rate limit exceeded: Too many API requests. Please try again later."
			elseif error_or_headers:match("400") then
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
	M.debug_log("Raw response: " .. vim.inspect(response))
	if response and type(response) == "string" then
		local success, parsed = pcall(vim.fn.json_decode, response)
		if success then
			M.debug_log("Full API Response: " .. vim.inspect(parsed))
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
			return response
		end
	end
	return response, error_or_headers
end

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
	handler = Response.with_request_response_guard(handle_get_issue, M.debug_log),
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
	handler = Response.with_request_response_guard(handle_create_issue, M.debug_log),
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
	handler = Response.with_request_response_guard(handle_search_issues, M.debug_log),
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
	handler = Response.with_request_response_guard(handle_list_project_issues, M.debug_log),
})

-- Set Jira config (domain, etc)
table.insert(M.server.capabilities.tools, {
	name = "set_config",
	description = "Set Jira configuration (domain, etc)",
	inputSchema = {
		type = "object",
		properties = {
			domain = { type = "string", description = "Jira domain (e.g. https://yourcompany.atlassian.net)" },
		},
		required = { "domain" },
	},
	handler = Response.with_request_response_guard(handle_set_config, M.debug_log),
})

-- Get Jira config
table.insert(M.server.capabilities.tools, {
	name = "get_config",
	description = "Get current Jira configuration",
	inputSchema = { type = "object", properties = {} },
	handler = handle_get_config,
})

-- List all Jira projects
table.insert(M.server.capabilities.tools, {
	name = "get_projects",
	description = "List all Jira projects",
	inputSchema = { type = "object", properties = {} },
	handler = Response.with_request_response_guard(handle_get_projects, M.debug_log),
})

-- Get details for a specific project
table.insert(M.server.capabilities.tools, {
	name = "get_project",
	description = "Get details for a specific Jira project",
	inputSchema = {
		type = "object",
		properties = {
			project_key = { type = "string", description = "Project key" },
		},
		required = { "project_key" },
	},
	handler = Response.with_request_response_guard(handle_get_project, M.debug_log),
})

-- List issue types for a project
table.insert(M.server.capabilities.tools, {
	name = "get_issue_types",
	description = "List issue types for a Jira project",
	inputSchema = {
		type = "object",
		properties = {
			project_key = { type = "string", description = "Project key" },
		},
		required = { "project_key" },
	},
	handler = Response.with_request_response_guard(handle_get_issue_types, M.debug_log),
})

-- List all statuses
table.insert(M.server.capabilities.tools, {
	name = "get_statuses",
	description = "List all Jira statuses",
	inputSchema = { type = "object", properties = {} },
	handler = Response.with_request_response_guard(handle_get_statuses, M.debug_log),
})

-- List all priorities
table.insert(M.server.capabilities.tools, {
	name = "get_priorities",
	description = "List all Jira priorities",
	inputSchema = { type = "object", properties = {} },
	handler = Response.with_request_response_guard(handle_get_priorities, M.debug_log),
})

-- Get current user info
table.insert(M.server.capabilities.tools, {
	name = "get_myself",
	description = "Get current Jira user info",
	inputSchema = { type = "object", properties = {} },
	handler = Response.with_request_response_guard(handle_get_myself, M.debug_log),
})

-- List boards
table.insert(M.server.capabilities.tools, {
	name = "get_boards",
	description = "List all Jira boards",
	inputSchema = { type = "object", properties = {} },
	handler = Response.with_request_response_guard(handle_get_boards, M.debug_log),
})

-- List sprints for a board
table.insert(M.server.capabilities.tools, {
	name = "get_sprints",
	description = "List sprints for a Jira board",
	inputSchema = {
		type = "object",
		properties = {
			board_id = { type = "number", description = "Board ID" },
		},
		required = { "board_id" },
	},
	handler = Response.with_request_response_guard(handle_get_sprints, M.debug_log),
})

-- List possible transitions for an issue
table.insert(M.server.capabilities.tools, {
	name = "get_transitions",
	description = "List possible transitions for a Jira issue",
	inputSchema = {
		type = "object",
		properties = {
			issue_key = { type = "string", description = "Issue key" },
		},
		required = { "issue_key" },
	},
	handler = Response.with_request_response_guard(handle_get_transitions, M.debug_log),
})

-- Perform a transition on an issue
table.insert(M.server.capabilities.tools, {
	name = "transition_issue",
	description = "Perform a transition on a Jira issue",
	inputSchema = {
		type = "object",
		properties = {
			issue_key = { type = "string", description = "Issue key" },
			transition_id = { type = "string", description = "Transition ID" },
		},
		required = { "issue_key", "transition_id" },
	},
	handler = Response.with_request_response_guard(handle_transition_issue, M.debug_log),
})

-- Assign an issue to a user
table.insert(M.server.capabilities.tools, {
	name = "assign_issue",
	description = "Assign a Jira issue to a user",
	inputSchema = {
		type = "object",
		properties = {
			issue_key = { type = "string", description = "Issue key" },
			assignee = { type = "string", description = "Username or accountId of the assignee" },
		},
		required = { "issue_key", "assignee" },
	},
	handler = Response.with_request_response_guard(handle_assign_issue, M.debug_log),
})

-- Add a comment to an issue
table.insert(M.server.capabilities.tools, {
	name = "comment_issue",
	description = "Add a comment to a Jira issue",
	inputSchema = {
		type = "object",
		properties = {
			issue_key = { type = "string", description = "Issue key" },
			comment = { type = "string", description = "Comment text" },
		},
		required = { "issue_key", "comment" },
	},
	handler = Response.with_request_response_guard(handle_comment_issue, M.debug_log),
})

-- Update fields on an issue
table.insert(M.server.capabilities.tools, {
	name = "update_issue",
	description = "Update fields on a Jira issue",
	inputSchema = {
		type = "object",
		properties = {
			issue_key = { type = "string", description = "Issue key" },
			fields = { type = "object", description = "Fields to update (as a table)" },
		},
		required = { "issue_key", "fields" },
	},
	handler = Response.with_request_response_guard(handle_update_issue, M.debug_log),
})

-- Delete an issue
table.insert(M.server.capabilities.tools, {
	name = "delete_issue",
	description = "Delete a Jira issue",
	inputSchema = {
		type = "object",
		properties = {
			issue_key = { type = "string", description = "Issue key" },
		},
		required = { "issue_key" },
	},
	handler = Response.with_request_response_guard(handle_delete_issue, M.debug_log),
})

-- Set debug mode (enable/disable debug logging)
local function handle_set_debug_mode(req, res)
	if type(req.params.enabled) ~= "boolean" then
		return res:error("'enabled' must be a boolean value.")
	end
	M.debug_mode = req.params.enabled
	return res:json({ success = true, debug_mode = M.debug_mode }):send()
end

-- Fetch debug log buffer
local function handle_get_debug_log(req, res)
	local count = tonumber(req.params.count) or 100
	count = math.max(1, math.min(count, DEBUG_LOG_MAX))
	local logs = {}
	if debug_log_size == 0 then
		return res:json({ logs = {} }):send()
	end
	-- Calculate the start index for the oldest entry
	local start = (debug_log_index - debug_log_size - 1 + DEBUG_LOG_MAX) % DEBUG_LOG_MAX + 1
	for i = 1, math.min(count, debug_log_size) do
		local idx = (start + i - 1 - 1) % DEBUG_LOG_MAX + 1
		logs[#logs + 1] = debug_log_buffer[idx]
	end
	return res:json({ logs = logs }):send()
end

-- Clear debug log buffer
local function handle_clear_debug_log(_, res)
	for i = 1, DEBUG_LOG_MAX do
		debug_log_buffer[i] = nil
	end
	debug_log_index = 1
	debug_log_size = 0
	return res:json({ success = true }):send()
end

table.insert(M.server.capabilities.tools, {
	name = "set_debug_mode",
	description = "Enable or disable debug logging for the Jira MCP server",
	inputSchema = {
		type = "object",
		properties = {
			enabled = { type = "boolean", description = "Enable (true) or disable (false) debug logging" },
		},
		required = { "enabled" },
	},
	handler = Response.with_request_response_guard(handle_set_debug_mode, M.debug_log),
})

-- Fetch debug log buffer
table.insert(M.server.capabilities.tools, {
	name = "get_debug_log",
	description = "Fetch the last N debug log entries from the Jira MCP server",
	inputSchema = {
		type = "object",
		properties = {
			count = {
				type = "number",
				description = "Number of log entries to return (default: 100, max: 500)",
				default = 100,
			},
		},
	},
	handler = Response.with_request_response_guard(handle_get_debug_log, M.debug_log),
})

-- Clear debug log buffer
table.insert(M.server.capabilities.tools, {
	name = "clear_debug_log",
	description = "Clear the debug log buffer for the Jira MCP server",
	inputSchema = { type = "object", properties = {} },
	handler = Response.with_request_response_guard(handle_clear_debug_log, M.debug_log),
})

return M
