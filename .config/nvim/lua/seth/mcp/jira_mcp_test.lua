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

	local data = test_utils.assert_json_response(result, { "status", "config" })
	assert(data.config.domain == test_utils.fixtures.jira.valid_domain)
	return true
end

-- Test getting Jira configuration
function tests.test_get_config()
	-- First set some config
	simulate_mcp_request("set_config", {
		domain = test_utils.fixtures.jira.valid_domain,
	})

	-- Then test getting it
	local result = simulate_mcp_request("get_config", {})
	local config = test_utils.assert_json_response(result, { "domain" })
	assert(config.domain == test_utils.fixtures.jira.valid_domain)
	return true
end

-- Test clearing Jira configuration
function tests.test_clear_config()
	-- First set some config
	simulate_mcp_request("set_config", {
		domain = test_utils.fixtures.jira.valid_domain,
	})

	-- Then clear it
	local result = simulate_mcp_request("clear_config", {})
	test_utils.assert_json_response(result, { "status" })

	-- Verify config is cleared
	local get_result = simulate_mcp_request("get_config", {})
	local config = test_utils.assert_json_response(get_result)
	assert(not config.domain, "Expected domain to be cleared")
	return true
end

-- Test setting invalid domain
function tests.test_set_config_invalid_domain()
	local result = simulate_mcp_request("set_config", {
		domain = test_utils.fixtures.jira.invalid_domain,
	})
	test_utils.assert_error_response(result, "Invalid domain")
	return true
end

-- Test getting config when not set
function tests.test_get_config_when_not_set()
	local result = simulate_mcp_request("get_config", {})
	local config = test_utils.assert_json_response(result)
	assert(not config.domain, "Expected no domain when config not set")
	return true
end

-- Return the test suite
return tests
