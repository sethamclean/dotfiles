-- Curl utilities for making HTTP requests from Lua
local M = {}

-- Debug mode flag
M.debug_mode = false

-- Debug logging function
function M.debug_log(msg, level)
	if msg == nil then return end
	if not M.debug_mode then
		return
	end
	level = level or vim.log.levels.INFO
	vim.notify("[Curl Utils] " .. tostring(msg), level)
end

-- Helper function to URL encode a string
function M.url_encode(str)
	if str then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w%-%_%.%~])", function(c)
			return string.format("%%%02X", string.byte(c))
		end)
		str = string.gsub(str, " ", "%%20") -- Encode spaces as %20 instead of +
	end
	return str
end

-- Helper function to build a curl command with common options
function M.build_curl_command(method, url, options)
	-- Base curl command with common headers
	local curl_cmd = {
		"curl",
		"--request",
		method,
		"--location",
		"--silent",
		"--show-error",
		"--fail", -- Fail on HTTP errors
		"--include", -- Include response headers
		"--max-time",
		(function()
			local timeout = options.timeout
			if timeout ~= nil then
				assert(type(timeout) == "number", "timeout must be a number")
				assert(timeout > 0, "timeout must be positive")
				return tostring(timeout)
			end
			return "30" -- Default 30 second timeout
		end)()
	}

	-- Add headers if provided
	if options.headers then
		assert(type(options.headers) == "table", "headers must be a table")
		for key, value in pairs(options.headers) do
			assert(type(key) == "string", "header key must be a string")
			assert(type(value) == "string", "header value must be a string")
			table.insert(curl_cmd, "--header")
			table.insert(curl_cmd, vim.fn.shellescape(string.format("%s: %s", key, value)))
		end
	end

	-- Add URL (properly escaped)
	-- Note: We don't escape the URL with shellescape here since we're using it directly
	-- URL encoding should be handled by the caller if needed
	M.debug_log("URL: " .. url)
	table.insert(curl_cmd, url)

	-- Handle data based on options
	if options.data then
		if type(options.data) == "table" then
			-- For JSON data
			local ok, json_str = pcall(vim.fn.json_encode, options.data)
			if not ok then
				error(string.format("Failed to encode JSON data: %s", json_str))
			end

			-- Log the raw JSON before escaping
			M.debug_log("Raw JSON data: " .. json_str)

			-- Escape the JSON for shell
			local escaped_json = vim.fn.shellescape(json_str)
			M.debug_log("Escaped JSON data: " .. escaped_json)

			table.insert(curl_cmd, "--header")
			table.insert(curl_cmd, vim.fn.shellescape("Content-Type: application/json"))
			table.insert(curl_cmd, "--data")
			table.insert(curl_cmd, escaped_json)
		elseif type(options.data) == "string" and options.data:match("^@") then
			-- For file uploads (data starts with @ indicating a file path)
			table.insert(curl_cmd, "--form")
			table.insert(curl_cmd, vim.fn.shellescape(string.format("file=%s", options.data)))
		else
			-- For raw string data
			local escaped_data = vim.fn.shellescape(options.data)
			table.insert(curl_cmd, "--data")
			table.insert(curl_cmd, escaped_data)
		end
	end

	return table.concat(curl_cmd, " ")
end

-- Execute curl command and process response
function M.execute_curl_command(cmd)
	local result = vim.fn.system(cmd)
	if not result then
		return nil, "No response received from curl command", {}
	end

	-- Split headers and body
	local headers, body = result:match("(.-\r?\n\r?\n)(.*)")

	-- Parse headers and status code first
	local header_table = {}
	local status_code = 200 -- Default to 200 if we can't find it
	
	if headers then
		-- First parse status code from status line
		local status_line = headers:match("^HTTP/%d+%.%d+ (%d+)")
		if status_line then
			status_code = tonumber(status_line) or 500 -- Default to 500 if parsing fails
		end
		
		-- Then parse headers
		for header in headers:gmatch("([^\r\n]+)") do
			-- Skip status line
			if not header:match("^HTTP/%d+%.%d+") then
				local name, value = header:match("^([^:]+):%s*(.+)")
				if name and value then
					header_table[name:lower()] = value
				end
			end
		end
	end

	-- Check for curl errors first
	if vim.v.shell_error ~= 0 then
		-- Handle timeouts
		if result:match("Operation timed out") then
			return nil, "Request timed out", header_table
		end
		
		-- Log all non-timeout errors
		M.debug_log(string.format("Curl failed with error %d: %s", vim.v.shell_error, result))
		
		-- For HTTP status errors (like 404, 500, etc)
		if status_code >= 400 then
			error(string.format("Request failed (status %d)", status_code), 0)
		end
		
		-- For any other curl errors
		error(string.format("Request failed: %s", result:gsub("\r?\n.*", "")), 0)
	end

	-- Use body if we successfully split headers, otherwise use full result
	local content = body or result
	if content == nil then
		M.debug_log("Empty response content")
		return {}, header_table -- Return empty table for nil responses
	end

	if content == "" then
		M.debug_log("Empty string response content")
		return {}, header_table -- Return empty table for empty string responses
	end

	-- Try to decode JSON response
	local ok, decoded = pcall(vim.fn.json_decode, content)
	if not ok then
		M.debug_log("Failed to decode JSON response: " .. content)
		return { raw_content = content, data = content }, header_table
	end

	return decoded, header_table
end

-- Make an HTTP request with curl
-- @param method string: HTTP method (GET, POST, PUT, DELETE, etc.)
-- @param url string: The URL to make the request to
-- @param options table: Optional configuration table
-- @return table|nil: Response data (decoded JSON) or nil on error
-- @return table|string: Headers table on success, error message on failure
function M.make_request(method, url, options)
	assert(type(method) == "string", "method must be a string")
	assert(type(url) == "string", "url must be a string")
	options = options or {}
	assert(type(options) == "table", "options must be a table")
	M.debug_log("Making " .. method .. " request to: " .. url)

	-- Build curl command
	local cmd = M.build_curl_command(method, url, options)

	-- Execute command and process response
	return M.execute_curl_command(cmd)
end

-- Set debug mode
function M.set_debug_mode(enabled)
	M.debug_mode = enabled
	M.debug_log("Debug mode " .. (enabled and "enabled" or "disabled"))
end

return M
