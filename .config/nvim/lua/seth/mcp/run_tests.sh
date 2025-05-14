#!/bin/bash

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -l, --list                 List all available tests"
    echo "  -t, --test TEST_PATTERN    Run tests matching pattern"
    echo "  -m, --module MODULE        Run all tests in a specific module"
    echo "  -d, --debug               Enable debug output"
    echo "  -v, --verbose             Show verbose test output"
    echo "  -h, --help                Show this help message"
    echo
    echo "Without options, runs all tests in all modules"
}

# Set up common Neovim command prefix
NVIM_CMD="nvim --headless --noplugin -u NONE"
MCP_LIB_PATH="/workspaces/.codespaces/.persistedshare/dotfiles/.config/nvim/lua"

# Parse command line arguments
DEBUG=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--list)
            # List all test files and their tests
            $NVIM_CMD -c "lua package.path = '${MCP_LIB_PATH}/?.lua;' .. package.path" \
                -c "lua local test_runner = require('seth.mcp.test_runner')" \
                -c "lua test_runner.set_debug(true)" \
                -c "lua local modules = test_runner.list_test_modules('${SCRIPT_DIR}'); for _, mod in ipairs(modules) do print('\nTests in ' .. mod.file .. ':'); local ok, module = pcall(require, mod.module); if ok then local tests = test_runner.list_tests(module); if #tests == 0 then print('  (no tests)') else for _, test in ipairs(tests) do print('  - ' .. test) end end else print('  Error loading module: ' .. module) end end" \
                -c "quit"
            exit 0
            ;;
        -t|--test)
            if [ -z "$2" ]; then
                echo "Error: Test pattern is required"
                echo "Usage: $0 -t|--test TEST_PATTERN"
                exit 1
            fi
            TEST_PATTERN="$2"
            shift 2
            ;;
        -m|--module)
            if [ -z "$2" ]; then
                echo "Error: Module name is required"
                echo "Usage: $0 -m|--module MODULE"
                exit 1
            fi
            MODULE_NAME="$2"
            shift 2
            ;;
        -d|--debug)
            DEBUG=true
            shift 1
            ;;
        -v|--verbose)
            VERBOSE=true
            shift 1
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Build the Lua test execution code
if [ -n "$MODULE_NAME" ]; then
    # Run tests from specific module
    $NVIM_CMD -c "lua package.path = '${MCP_LIB_PATH}/?.lua;' .. package.path" \
        -c "lua test_runner = require('seth.mcp.test_runner')" \
        -c "lua test_runner.set_debug($DEBUG)" \
        -c "lua test_runner.set_verbose($VERBOSE)" \
        -c "lua local success = test_runner.run_tests({module = '$MODULE_NAME', pattern = '$TEST_PATTERN'})" \
        -c "lua if not success then vim.cmd('cquit 1') end" \
        -c "quit"
else
    # Run all tests or with pattern
    $NVIM_CMD -c "lua package.path = '${MCP_LIB_PATH}/?.lua;' .. package.path" \
        -c "lua test_runner = require('seth.mcp.test_runner')" \
        -c "lua test_runner.set_debug($DEBUG)" \
        -c "lua test_runner.set_verbose($VERBOSE)" \
        -c "lua local success = test_runner.run_tests({directory = '${SCRIPT_DIR}', pattern = '$TEST_PATTERN'})" \
        -c "lua if not success then vim.cmd('cquit 1') end" \
        -c "quit"
fi

# Get the exit code from Neovim 
EXIT_CODE=$?

# Exit with Neovim's exit code
exit $EXIT_CODE
