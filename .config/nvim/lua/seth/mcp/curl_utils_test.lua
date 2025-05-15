--[[
Test suite for curl_utils.lua
--]]

local curl_utils = require("seth.mcp.curl_utils")

-- This is a regular table, not a function
local tests = {}

-- Setup function to configure test environment
function tests.setup()
	-- Ensure debug mode is enabled for tests
	-- Setup debug mode
	local orig_set_debug_mode = curl_utils.set_debug_mode
	curl_utils._set_debug_mode = function(_)
		-- Enable debug mode during tests to diagnose issues
		orig_set_debug_mode(true)
	end
	curl_utils._set_debug_mode(true)
end

-- Run setup immediately
tests.setup()

-- Test GET request with JSON response
function tests.test_get_json()
	local result = curl_utils.make_request("GET", "https://jsonplaceholder.typicode.com/posts/1")
	assert(type(result) == "table", "Expected table response")
	assert(result.id == 1, "Expected post with id 1")
	assert(type(result.title) == "string", "Expected title field")
	assert(type(result.body) == "string", "Expected body field")
	return true
end

-- Test POST request with JSON body
function tests.test_post_json()
	local test_data = {
		name = "Test Post",
		description = "This is a test post",
	}

	local result = curl_utils.make_request("POST", "https://jsonplaceholder.typicode.com/posts", { data = test_data })
	assert(type(result) == "table", "Expected table response")
	assert(type(result.id) == "number", "Expected numeric id in response")
	assert(result.name == test_data.name, "Response should contain our data")
	assert(result.description == test_data.description, "Response should contain our description")
	return true
end

-- Test PUT request
function tests.test_put_json()
	local test_data = {
		id = 1,
		name = "Updated Test",
	}

	local result = curl_utils.make_request("PUT", "https://jsonplaceholder.typicode.com/posts/1", { data = test_data })
	assert(type(result) == "table", "Expected table response")
	assert(type(result.id) == "number", "Expected numeric id in response")
	assert(result.name == test_data.name, "Expected name to be updated")
	return true
end

-- Test DELETE request
function tests.test_delete()
	local result, headers = curl_utils.make_request("DELETE", "https://jsonplaceholder.typicode.com/posts/1")
	assert(type(result) == "table", "Expected table response")
	assert(
		headers and headers["content-type"] and headers["content-type"]:lower():match("application/json"),
		"Expected JSON response"
	)
	return true
end

-- Test URL encoding
function tests.test_url_encoding()
	-- Basic test - encode spaces
	local test = "hello world"
	local encoded = curl_utils.url_encode(test)
	assert(not encoded:match(" "), "Space should be encoded")
	assert(encoded:match("hello%%20world"), "Should use %20 for spaces")

	-- Extended test - basic characters remain intact
	local alphanumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	assert(curl_utils.url_encode(alphanumeric) == alphanumeric, "Alphanumeric chars should not be encoded")

	-- Extended test - special characters are encoded
	local special = "!@#$%^&*()+="
	local encoded_special = curl_utils.url_encode(special)
	assert(not encoded_special:match("[^%w%%%.]"), "Special chars should be encoded")

	-- Integration test with API - just verify encoding works
	local result = curl_utils.make_request(
		"GET",
		"https://jsonplaceholder.typicode.com/posts?title=" .. curl_utils.url_encode("test value")
	)
	-- Only verify we got a valid response back, don't check content since API might filter empty results
	assert(type(result) == "table", "Expected table response")
	return true
end

-- Test error handling (404)
function tests.test_404_error()
	local success, err = pcall(function()
		local result = curl_utils.make_request("GET", "https://httpbin.org/status/404")
		error("Should not reach here - expected 404 error")
	end)

	assert(not success, "Expected error for 404")
	local err_str = tostring(err)
	assert(
		err_str:match("404"),
		string.format("Error should indicate 404 status, but got: %s", err_str)
	)
	return true
end

-- Test custom headers
function tests.test_custom_headers()
	local result = curl_utils.make_request("GET", "https://jsonplaceholder.typicode.com/posts/1", {
		headers = {
			["X-Custom-Header"] = "test-value",
			["Accept"] = "application/json",
		},
	})
	assert(type(result) == "table", "Expected table response")
	assert(result.id == 1, "Expected post with id 1")
	assert(type(result.title) == "string", "Expected title field")
	return true
end

-- Test query parameters
function tests.test_query_params()
	local result = curl_utils.make_request("GET", "https://httpbin.org/get?foo=bar")
	assert(type(result) == "table", "Expected table response")
	assert(result.args.foo == "bar", "Expected query param to be preserved")
	return true
end

-- Test Response Headers
function tests.test_response_headers()
	local _, headers = curl_utils.make_request("GET", "https://jsonplaceholder.typicode.com/posts/1")
	assert(headers, "Expected headers table to be returned")
	assert(headers and type(headers["content-type"]) == "string", "Expected content-type header")
	assert(headers["content-type"]:lower():match("application/json"), "Expected JSON content type")
	return true
end

-- Test Timeout Handling
function tests.test_timeout()
	local success, result_or_err = pcall(function()
		return curl_utils.make_request(
			"GET",
			"https://example.com:81", -- This port is typically closed, causing a quick timeout
			{ timeout = 1 } -- Set 1 second timeout
		)
	end)

	-- We expect this to fail with a timeout error
	assert(not success, "Expected timeout to trigger an error")
	local err_str = tostring(result_or_err)
	-- Check for either timeout or connection error
	local err_str = tostring(result_or_err)
	assert(
		err_str:match("timed? ?out") or err_str:match("Could not resolve host") or err_str:match("Request failed"),
		"Expected timeout or connection error message but got: " .. err_str
	)
	return true
end

-- Test error response body propagation
function tests.test_error_response_body_propagation()
    local success, err = pcall(function()
        local result, headers = curl_utils.make_request("POST", "https://httpbin.org/status/400", {
            data = {
                test = "data"
            }
        })
        error("Should not reach here - expected error from 400 status")
    end)

    assert(not success, "Expected error for 400 status")
    local err_str = tostring(err)
    assert(
        err_str:match("400"),
        string.format("Error should indicate 400 status, but got: %s", err_str)
    )
    return true
end

-- Test Invalid JSON Response
function tests.test_invalid_json()
	local result, headers = curl_utils.make_request(
		"GET",
		"https://example.com" -- Returns HTML, not JSON
	)
	assert(type(result) == "string", "Expected string response for non-JSON content")
	assert(result ~= "", "Expected non-empty response")
	assert(headers and headers["content-type"]:match("text/html"), "Expected text/html content type")
	return true
end

-- Test URL Encoding (More Comprehensive)
function tests.test_url_encoding_comprehensive()
	local special_chars = "Hello World!@#$%^&*()+ "
	local encoded = curl_utils.url_encode(special_chars)
	-- Check if encoded string only contains allowed characters: alphanumeric, percent, dot, dash, underscore
	assert(not encoded:match("[^%w%%%%-_.~]"), "URL encoded string should only contain safe characters")
	-- Verify space encoding
	assert(encoded:match("Hello%%20World"), "Spaces should be percent-encoded")
	return true
end

-- Test Large Payload
function tests.test_large_payload()
	local test_data = {
		title = string.rep("a", 100),
		body = string.rep("b", 1000),
		userId = 1,
	}

	local result = curl_utils.make_request("POST", "https://jsonplaceholder.typicode.com/posts", { data = test_data })
	assert(type(result) == "table", "Expected json response")
	assert(type(result.id) == "number", "Expected numeric id in response")
	assert(result.title == test_data.title, "Expected title to be preserved")
	assert(result.body == test_data.body, "Expected body to be preserved")
	return true
end

-- Return the tests table
return tests
