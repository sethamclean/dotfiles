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
		print("Making request to invalid post...")
		local result, headers = curl_utils.make_request("GET", "https://jsonplaceholder.typicode.com/posts/999999")
		print("Result:", vim.inspect(result))
		print("Headers:", vim.inspect(headers))
		error("Should not reach here - expected 404 error")
	end)
	print("pcall result:", success)
	print("pcall error:", vim.inspect(err))
	assert(not success, "Expected error for 404")
	assert(
		tostring(err):match("Request failed: .*404"),
		string.format("Error should match pattern 'Request failed: .*404' but got: %s", tostring(err))
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
	local result = curl_utils.make_request("GET", "https://jsonplaceholder.typicode.com/posts")
	assert(type(result) == "table", "Expected table response")
	-- Check it's either a non-empty array or a raw content string response
	if not result.raw_content then
		assert(#result > 0, "Expected at least one post")
		local first_post = result[1]
		assert(type(first_post.id) == "number", "Expected numeric id")
		assert(type(first_post.title) == "string", "Expected title string")
	end
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
	local result, err = curl_utils.make_request(
		"GET",
		"https://httpstat.us/200?sleep=5000", -- This endpoint delays response by 5s
		{ timeout = 1 } -- Set 1 second timeout
	)
	assert(result == nil, "Expected nil result for timeout")
	assert(err == "Request timed out", "Expected timeout error message")
	return true
end

-- Test Invalid JSON Response
function tests.test_invalid_json()
	local result, _ = curl_utils.make_request(
		"GET",
		"https://httpstat.us/200" -- Returns plain text, not JSON
	)
	assert(type(result) == "table", "Expected table response")
	assert(result.raw_content ~= nil, "Expected raw content field")
	assert(result.raw_content ~= "", "Expected non-empty raw content")
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
