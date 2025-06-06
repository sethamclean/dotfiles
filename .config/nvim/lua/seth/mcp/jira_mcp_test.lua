local jira = require("seth.mcp.jira")
local test_utils = require("seth.mcp.test_utils")

-- Test suite for Jira MCP functionality
local tests = {}

-- Helper function to wrap the generic simulate_mcp_request for Jira
local function simulate_mcp_request(tool_name, params, options)
	return test_utils.simulate_mcp_request(jira, tool_name, params, options)
end

-- Setup function to run before each test
function tests.setup()
	jira.set_debug_mode(true)
end

-- Teardown function to run after each test
function tests.teardown()
	-- Clear any configuration after tests
	jira.clear_config()
end

-- Test setting Jira configuration
function tests.test_set_config()
	local result = simulate_mcp_request("set_config", {
		domain = test_utils.fixtures.jira.valid_domain,
	})

	test_utils.assert_json_response(result, { "status", "config" })
	return true
end

-- Test getting Jira configuration
function tests.test_get_config()
	-- First set some config
	simulate_mcp_request("set_config", {
		domain = test_utils.fixtures.jira.valid_domain,
	})

	-- Test JSON response when json method is available
	local result = simulate_mcp_request("get_config", {}, {
		mock_response = test_utils.create_mock_response(nil, { enable_json = true }),
	})
	assert(result.mime_type == "application/json", "Expected JSON response when json available")
	local config = vim.fn.json_decode(result.body)
	assert(config.domain == test_utils.fixtures.jira.valid_domain)

	-- Test text fallback when json method is not available (production scenario)
	result = simulate_mcp_request("get_config", {}, {
		mock_response = test_utils.create_mock_response(), -- json disabled by default
	})
	assert(result.mime_type == "text/plain", "Expected text fallback when json not available")
	config = vim.fn.json_decode(result.body)
	assert(config.domain == test_utils.fixtures.jira.valid_domain)

	return true
end

-- Test clearing Jira configuration
function tests.test_clear_config()
	-- First set some config
	simulate_mcp_request("set_config", {
		domain = test_utils.fixtures.jira.valid_domain,
	})

	-- Test clear with JSON enabled
	local result = simulate_mcp_request("clear_config", {}, {
		mock_response = test_utils.create_mock_response(nil, { enable_json = true }),
	})
	test_utils.assert_json_response(result, { "status" })

	-- Verify config is cleared (with JSON)
	local get_result = simulate_mcp_request("get_config", {}, {
		mock_response = test_utils.create_mock_response(nil, { enable_json = true }),
	})
	local config = test_utils.assert_json_response(get_result)
	assert(not config.domain, "Expected domain to be cleared")

	-- Verify clear works with text fallback
	result = simulate_mcp_request("clear_config", {}, {
		mock_response = test_utils.create_mock_response(), -- No json by default
	})
	assert(result.mime_type == "text/plain", "Expected text response when json not available")
	local data = vim.fn.json_decode(result.body)
	assert(data.status, "Expected status in response")

	-- Verify config is cleared (with text fallback)
	get_result = simulate_mcp_request("get_config", {}, {
		mock_response = test_utils.create_mock_response(), -- No json by default
	})
	config = vim.fn.json_decode(get_result.body)
	assert(not config.domain, "Expected domain to be cleared")
	return true
end

-- Test getting config when not set
function tests.test_get_config_when_not_set()
	-- Test with JSON enabled
	local result = simulate_mcp_request("get_config", {}, {
		mock_response = test_utils.create_mock_response(nil, { enable_json = true }),
	})
	local config = test_utils.assert_json_response(result)
	assert(vim.tbl_isempty(config) or config.has_api_token ~= nil, "Expected empty config but it wasn't empty")

	-- Test without JSON (text fallback)
	result = simulate_mcp_request("get_config", {}, {
		mock_response = test_utils.create_mock_response(), -- No json by default
	})
	config = test_utils.assert_json_response(result) -- Should still work, just with text/plain
	assert(vim.tbl_isempty(config) or config.has_api_token ~= nil, "Expected empty config but it wasn't empty")
	return true
end

-- Test JQL query building and formatting
function tests.test_search_jql_formatting()
	-- We don't need to configure the server for JQL format testing
	local jira_instance = require("seth.mcp.jira")

	-- Test cases for JQL formatting
	local test_cases = {
		{
			input = {
				project_key = "TEST",
				status = "In Progress",
			},
			expected = 'project = TEST AND status = "In Progress"',
		},
		{
			input = {
				project_key = "TEST",
				status = "In Progress",
				priority = "High",
				order_by = "created",
				order_direction = "DESC",
			},
			expected = 'project = TEST AND status = "In Progress" AND priority = High ORDER BY created DESC',
		},
		{
			input = {
				project_key = "TEST",
				text_search = "important bug",
			},
			expected = 'project = TEST AND text ~ "important bug"',
		},
		{
			input = {
				project_keys = { "TEST", "DEV" },
				status = "Open",
			},
			expected = 'project in (TEST, DEV) AND status = "Open"',
		},
	}

	-- Run each test case
	for i, case in ipairs(test_cases) do
		local query = jira_instance.build_jql_query(case.input)
		assert(
			query == case.expected,
			string.format("Test case %d failed:\nExpected: %s\nGot: %s", i, case.expected, query)
		)
	end

	return true
end

-- Return the test suite
return tests
