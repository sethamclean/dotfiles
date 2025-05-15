-- Test file for Jira search functionality
local jira = require('seth.mcp.jira')

-- Enable debug mode for verbose logging
jira.set_debug_mode(true)

local function safe_test(test_name, tool_name, params)
    print("\nRunning test:", test_name)
    local status, result = pcall(function()
        return jira.test(tool_name, params)
    end)
    
    if status then
        print("Success! Result:", vim.inspect(result))
    else
        print("Test failed:", result)
    end
    return status, result
end

local function test_search_issues()
    print("\nTesting search_issues functionality with various JQL formats:")

    -- Test cases with different JQL formats
    local test_cases = {
        {
            name = "Basic JQL - key only",
            jql = "key = TEST-21"
        },
        {
            name = "Basic JQL - exact project match",
            jql = "project='TEST'"
        },
        {
            name = "Project with quotes",
            jql = 'project="TEST"'
        },
        {
            name = "Project without quotes",
            jql = "project=TEST"
        },
        {
            name = "Project with status",
            jql = 'project="TEST" AND status="Created"'
        },
        {
            name = "Project with escaped quotes",
            jql = [[project="TEST" AND summary~"test"]]
        },
        {
            name = "URL encoded query",
            jql = vim.fn.json_encode('project = "TEST"'):sub(2, -2)  -- Remove surrounding quotes
        }
    }

    for _, test_case in ipairs(test_cases) do
        safe_test(test_case.name, 'search_issues', {
            jql = test_case.jql,
            max_results = 1  -- Limit results while testing
        })
    end
end

local function test_list_project_issues()
    print("\nTesting list_project_issues functionality:")
    
    local test_cases = {
        {
            name = "Basic project listing",
            params = {
                project_key = "TEST",
                max_results = 1
            }
        },
        {
            name = "Project with status",
            params = {
                project_key = "TEST",
                status = "Created",
                max_results = 1
            }
        },
        {
            name = "Project with ordering",
            params = {
                project_key = "TEST",
                order_by = "updated",
                order_direction = "DESC",
                max_results = 1
            }
        }
    }

    for _, test_case in ipairs(test_cases) do
        safe_test(test_case.name, 'list_project_issues', test_case.params)
    end
end

-- Set up test environment
print("Setting up Jira configuration...")
local status, config_result = safe_test("Configuration", 'set_config', { domain = 'jira.example.com' })
if not status then
    print("Failed to configure Jira client, aborting tests")
    return
end

-- Run tests
print("\nRunning search tests...")
test_search_issues()
print("\nRunning project listing tests...")
test_list_project_issues()

print("\nTests completed!")
