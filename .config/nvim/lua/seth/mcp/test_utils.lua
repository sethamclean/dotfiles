-- Helper module for MCP testing utilities
local M = {}

-- Assertion helpers
function M.assert_json_response(response, expected_keys)
    assert(response, "Expected response to exist")
    assert(not response.is_error, "Expected response to not be an error")
    assert(response.mime_type == "application/json", "Expected JSON response")
    
    local data = vim.fn.json_decode(response.body)
    if expected_keys then
        for _, key in ipairs(expected_keys) do
            assert(data[key] ~= nil, "Expected response to contain key: " .. key)
        end
    end
    return data
end

function M.assert_error_response(response, expected_error)
    assert(response, "Expected response to exist")
    assert(response.is_error, "Expected response to be an error")
    assert(response.body:match(expected_error), 
           string.format("Expected error '%s' but got '%s'", 
                        expected_error, response.body))
end

function M.assert_text_response(response, expected_pattern)
    assert(response, "Expected response to exist")
    assert(not response.is_error, "Expected response to not be an error")
    assert(response.mime_type == "text/plain", "Expected text response")
    if expected_pattern then
        assert(response.body:match(expected_pattern),
               string.format("Expected response matching '%s' but got '%s'",
                           expected_pattern, response.body))
    end
end

-- Test fixtures
M.fixtures = {
    jira = {
        valid_domain = "jira.idexx.com",
        invalid_domain = "invalid.example.com",
        sample_issue = {
            project_key = "TEST",
            summary = "Test Issue",
            description = "Test Description",
            issue_type = "Task"
        }
    }
}

-- Response factory
function M.create_mock_response(preset)
    local base_res = {
        text = function(self, content, mime_type)
            self.body = content
            self.mime_type = mime_type or "text/plain"
            return self
        end,
        json = function(self, content)
            self.body = vim.fn.json_encode(content)
            self.mime_type = "application/json"
            return self
        end,
        error = function(self, msg)
            self.body = msg
            self.mime_type = "text/plain"
            self.is_error = true
            return self:send()
        end,
        send = function(self)
            return {
                body = self.body,
                mime_type = self.mime_type,
                is_error = self.is_error,
            }
        end
    }
    
    if preset == "error" then
        return base_res:error("Preset error response")
    elseif preset == "empty_json" then
        return base_res:json({})
    end
    
    return base_res
end

-- Test context management
M.TestContext = {}

function M.TestContext:new(server)
    local ctx = {
        server = server,
        cleanup_tasks = {}
    }
    setmetatable(ctx, self)
    self.__index = self
    return ctx
end

function M.TestContext:add_cleanup(fn)
    table.insert(self.cleanup_tasks, fn)
end

function M.TestContext:cleanup()
    for i = #self.cleanup_tasks, 1, -1 do
        pcall(self.cleanup_tasks[i])
    end
    self.cleanup_tasks = {}
end

-- Simulates MCPHub request handling for testing MCP servers
function M.simulate_mcp_request(server, tool_name, params, options)
    options = options or {}
    
    -- Initialize the server if not done
    if server.init and not server.is_registered then
        server.init()
    end

    -- Find the requested tool
    local tool
    for _, t in ipairs(server.server.capabilities.tools) do
        if t.name == tool_name then
            tool = t
            break
        end
    end

    if not tool then
        error("Tool not found: " .. tool_name)
    end

    -- Create a request object like MCPHub would
    local req = {
        params = params or {},
        context = options.context or {},
        headers = options.headers or {}
    }

    -- Use mock response if provided, otherwise create new
    local res = options.mock_response or M.create_mock_response()

    -- Call the tool handler directly as MCPHub would
    local result = tool.handler(req, res)
    return result
end

return M
