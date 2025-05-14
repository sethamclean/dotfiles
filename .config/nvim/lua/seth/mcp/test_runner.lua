--[[
Generic test runner for MCP tests
--]]

local print = print
local vim = vim
local ipairs = ipairs
local type = type
local pairs = pairs
local table = table
local tostring = tostring
local pcall = pcall
local string = string
local assert = assert
local error = error
local require = require

local M = {}

-- Initialize configuration and stats
M.debug = false
M.verbose = false
M.stats = {
	passed = 0,
	failed = 0,
	total = 0,
}

-- Set debug mode
function M.set_debug(enabled)
	M.debug = enabled
end

-- Enable verbose mode
function M.set_verbose(enabled)
	M.verbose = enabled
end

-- Helper function to run a test
function M.run_test(module, test_name)
	if not module[test_name] or type(module[test_name]) ~= "function" then
		print(string.format("Error: '%s' is not a valid test function", test_name))
		return false
	end

	-- Run test and capture result
	if M.verbose then
		print("\nRunning test: " .. test_name)
	end
	local ok, result = pcall(module[test_name])
	if not ok then
		if M.verbose then
			print("Test failed with error:", result)
		end
		M.stats.failed = M.stats.failed + 1
		return false
	end

	if result == true then
		if M.verbose then
			print("Test passed!")
		end
		M.stats.passed = M.stats.passed + 1
		return true
	else
		if M.verbose then
			print("Test did not return true")
		end
		M.stats.failed = M.stats.failed + 1
		return false
	end
end

-- Get list of test functions from a module
function M.list_tests(module)
	if M.debug then
		print("Module type: " .. type(module))
	end

	if type(module) ~= "table" then
		print(string.format("Error: Module must be a table but got %s", type(module)))
		return {}
	end

	local tests = {}
	for name, func in pairs(module) do
		if type(func) == "function" and name:match("^test_") then
			table.insert(tests, name)
		end
	end

	table.sort(tests)
	return tests
end

-- Helper function to discover test files in a directory
function M.discover_test_files(directory)
	return vim.fn.glob(directory .. "/**/*_test.lua", false, true)
end

-- Helper function to convert file path to module name
function M.file_to_module_name(file)
	return file:gsub("^.*/lua/", ""):gsub(".lua$", ""):gsub("/", ".")
end

-- Load and run tests from a specific test file
function M.run_test_file(file, pattern)
	if M.debug then
		print("\nRunning tests from: " .. file)
	end

	-- Convert file path to module name
	local module_name = M.file_to_module_name(file)
	local ok, module = pcall(require, module_name)

	if not ok then
		print(string.format("Error loading module %s: %s", module_name, module))
		return false
	end

	-- Get list of tests
	local tests = M.list_tests(module)

	-- Filter tests if pattern is provided
	if pattern then
		local filtered = {}
		for _, test in ipairs(tests) do
			if test:match(pattern) then
				table.insert(filtered, test)
			end
		end
		tests = filtered
	end

	-- Run each test
	local passed = true
	for _, test_name in ipairs(tests) do
		if not M.run_test(module, test_name) then
			passed = false
		end
	end

	-- Update total after running tests
	M.stats.total = M.stats.total + #tests
	-- Enable verbose mode
	function M.set_verbose(enabled)
		print("Setting verbose mode to:", enabled) -- Debug output
		M.verbose = enabled
	end

	return passed
end

-- Run tests based on various criteria
-- Options:
-- - directory: Directory to search for test files (required if no module specified)
-- - pattern: Test name pattern to filter by (optional)
-- - module: Specific module to run tests from (optional)
-- - filter: Function to filter test names (optional)
function M.run_tests(options)
	-- Reset stats
	M.stats = { passed = 0, failed = 0, total = 0 }

	-- If specific module is provided, only run tests from that module
	if options.module then
		local ok, module = pcall(require, options.module)
		if not ok then
			print(string.format("Error loading module %s: %s", options.module, module))
			return false
		end

		-- Run tests from the module
		local tests = M.list_tests(module)
		if options.pattern then
			local filtered = {}
			for _, test in ipairs(tests) do
				if test:match(options.pattern) then
					table.insert(filtered, test)
				end
			end
			tests = filtered
		end

		local all_passed = true
		for _, test_name in ipairs(tests) do
			M.stats.total = M.stats.total + 1
			if not M.run_test(module, test_name) then
				all_passed = false
			end
		end

		M.print_summary()
		return all_passed
	end

	-- Discover and run all test files
	local test_files = M.discover_test_files(options.directory)
	if #test_files == 0 then
		print("No test files found!")
		return true -- No tests is not a failure
	end

	-- Run each test file
	local all_passed = true
	for _, file in ipairs(test_files) do
		if not M.run_test_file(file, options.pattern) then
			all_passed = false
		end
	end

	M.print_summary()
	return all_passed
end

-- Print test summary
function M.print_summary()
	print(string.format("\nTest Results Summary:"))
	print(string.format("Total Tests Run: %d", M.stats.total))
	print(string.format("✓ Passed: %d", M.stats.passed))
	print(string.format("✗ Failed: %d", M.stats.failed))
end

-- Helper function to list available test modules
function M.list_test_modules(directory)
	local modules = {}
	local files = M.discover_test_files(directory)
	for _, file in ipairs(files) do
		table.insert(modules, {
			file = file,
			module = M.file_to_module_name(file),
		})
	end
	return modules
end

_G.test_runner = M
return M
