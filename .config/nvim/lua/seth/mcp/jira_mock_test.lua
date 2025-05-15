-- Jira MCP Server Mock Tests
local M = {}

-- Import required modules
local jira = require("seth.mcp.jira")
local curl_utils = require("seth.mcp.curl_utils")

-- Mock responses for different endpoints
local mock_responses = {
    serverInfo = {
        version = "10.3.2",
        buildNumber = 100000,
        serverTitle = "Mock Jira Server"
    },
    myself = {
        name = "mockuser",
        emailAddress = "mock@example.com",
        displayName = "Mock User"
    },
    ["issue/MOCK-1"] = {
        id = "10000",
        key = "MOCK-1",
        fields = {
            summary = "Test Issue",
            description = "Test Description",
            status = { name = "Open" }
        }
    },
    search = {
        issues = {
            {
                key = "MOCK-1",
                fields = {
                    summary = "Test Issue 1",
                    status = { name = "Open" }
                }
            },
            {
                key = "MOCK-2",
                fields = {
                    summary = "Test Issue 2",
                    status = { name = "In Progress" }
                }
            }
        },
        total = 2,
        maxResults = 50
    }
}

-- Mock make_request function for testing
local function mock_make_request(method, url, options)
    -- Extract endpoint from URL
    local endpoint = url:match("/rest/api/2/(.+)$")
    if not endpoint then
        return nil, "Invalid URL format"
    end

    -- Clean up endpoint (remove query params)
    endpoint = endpoint:gsub("?.*$", "")

    -- Return mock response based on endpoint
    if mock_responses[endpoint] then
        return vim.fn.json_encode(mock_responses[endpoint])
    end

    return nil, "Endpoint not mocked: " .. endpoint
end

-- Tests
function M.test_jira_server_info()
    -- Store original function
    local original_make_request = curl_utils.make_request
    
    -- Set up mock
    curl_utils.make_request = mock_make_request
    
    -- Configure Jira client
    jira.test("set_config", { domain = "mock-jira.example.com" })
    
    -- Get server info
    local response = jira.test("get_server_info", {})
    
    -- Restore original function
    curl_utils.make_request = original_make_request
    
    -- Verify response
    assert(response, "Response should not be nil")
    local data = vim.fn.json_decode(response.body)
    assert(data.version == "10.3.2", "Version should match mock data")
    
    return true
end

return M
