-- Import the wezterm module
local wezterm = require("wezterm")

-- --- Main WezTerm Configuration ---
local config = wezterm.config_builder()

-- Disable WezTerm's SSH agent mux only on Windows

config.ssh_domains = {
	{
		name = "active-codespace",
		remote_address = "active-codespace",
	},
}

config.color_scheme = "Tokyo Night"
config.exit_behavior = "Hold"

-- Slightly transparent and blurred background
config.window_background_opacity = 0.9
config.macos_window_background_blur = 30

-- Smaller frame
config.window_decorations = "RESIZE"

-- Tab bar location
config.tab_bar_at_bottom = true

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
tabline.setup()

local tmux = wezterm.plugin.require("https://github.com/sei40kr/wez-tmux")
tmux.apply_to_config(config, {})

config.notification_handling = "AlwaysShow"

if wezterm.gui then
	-- Function to get the full, platform-specific path to an executable.
	-- It attempts to find the executable using system-specific commands ('where' on Windows,
	-- 'command -v' on Unix-like systems).
	-- Returns the full path string if found, otherwise nil.
	local function get_executable_path(executable_name)
		local target_triple = wezterm.target_triple
		wezterm.log_info("Attempting to find path for: " .. executable_name)
		wezterm.log_info(
			"Current target_triple: ["
				.. target_triple
				.. "] (type: "
				.. type(target_triple)
				.. ", length: "
				.. #target_triple
				.. ")"
		)

		local char_codes = {}
		for i = 1, #target_triple do
			table.insert(char_codes, string.byte(target_triple, i))
		end
		wezterm.log_info("target_triple char codes: " .. table.concat(char_codes, ", "))

		if target_triple == "aarch64-apple-darwin" then
			wezterm.log_info("target_triple is EXACTLY 'aarch64-apple-darwin'")
		else
			wezterm.log_info("target_triple is NOT EXACTLY 'aarch64-apple-darwin'")
		end

		local is_windows = target_triple:find("windows", 1, true) ~= nil
		local is_macos = target_triple:find("apple-darwin", 1, true) ~= nil
		local is_linux = target_triple:find("linux", 1, true) ~= nil

		wezterm.log_info("is_windows: " .. tostring(is_windows))
		wezterm.log_info("is_macos: " .. tostring(is_macos))
		wezterm.log_info("is_linux: " .. tostring(is_linux))

		local command_to_find
		if is_windows then
			command_to_find = "where " .. executable_name
		elseif is_macos then
			-- On macOS, Homebrew is common. Try Homebrew's default paths first.
			local actual_executable_name = executable_name
			if target_triple:find("aarch64", 1, true) then
				local explicit_path = "/opt/homebrew/bin/" .. actual_executable_name
				local f = io.open(explicit_path, "r")
				if f then
					f:close()
					wezterm.log_info(
						"Found " .. executable_name .. " at explicit Apple Silicon Homebrew path: " .. explicit_path
					)
					return explicit_path
				end
			else
				local explicit_path = "/usr/local/bin/" .. actual_executable_name
				local f = io.open(explicit_path, "r")
				if f then
					f:close()
					wezterm.log_info(
						"Found " .. executable_name .. " at explicit Intel Homebrew path: " .. explicit_path
					)
					return explicit_path
				end
			end
			command_to_find = "command -v " .. actual_executable_name
		elseif is_linux then
			command_to_find = "command -v " .. executable_name
		else
			wezterm.log_warn(
				"Unsupported OS detected: " .. target_triple .. ". Cannot reliably find " .. executable_name .. " path."
			)
			return nil
		end

		local handle = io.popen(command_to_find .. " 2>&1")
		if not handle then
			wezterm.log_error("Failed to open pipe for command: " .. command_to_find)
			return nil
		end

		local output = handle:read("*a")
		local exit_code = handle:close()

		output = output:gsub("^%s*(.-)%s*$", "%1")

		wezterm.log_info(
			"Command '" .. command_to_find .. "' output: [" .. output .. "], Exit Code: " .. tostring(exit_code)
		)

		if (exit_code == 0 or exit_code == true) and output ~= "" then
			return output
		else
			wezterm.log_warn("Could not find '" .. executable_name .. "' in PATH or command failed. Output: " .. output)
			return nil
		end
	end

	local function get_ssh_config_path()
		if package.config:sub(1, 1) == "\\" then
			return wezterm.home_dir .. "\\.ssh\\config"
		else
			return wezterm.home_dir .. "/.ssh/config"
		end
	end

	local function update_ssh_config_with_alias(config_block, alias)
		wezterm.log_info("Writing SSH config block for alias: " .. alias)
		wezterm.log_info("SSH config block:\n" .. config_block)
		local ssh_config_path = get_ssh_config_path()
		local config_file = io.open(ssh_config_path, "r")
		local existing = config_file and config_file:read("*a") or ""
		if config_file then
			config_file:close()
		end
		-- Remove any existing block for the alias
		local cleaned = existing:gsub("Host " .. alias .. "[^\n]*\n(.-\n)*", "")
		-- Ensure the config_block ends with a newline
		if not config_block:match("\n$") then
			config_block = config_block .. "\n"
		end
		-- Add RemoteCommand and RequestTTY to the Host block
		local modified_block = config_block:gsub("^(Host[^\n]*\n)", "%1  RemoteCommand zsh -l\n  RequestTTY yes\n")
		-- Insert the new block at the end
		local new_config = cleaned:gsub("%s+$", "") .. "\n" .. modified_block
		local out = io.open(ssh_config_path, "w")
		out:write(new_config)
		out:close()
		-- Log the resulting SSH config file
		local verify_file = io.open(ssh_config_path, "r")
		if verify_file then
			local verify_contents = verify_file:read("*a")
			wezterm.log_info("Full SSH config after update:\n" .. verify_contents)
			verify_file:close()
		end
	end

	local function connect_to_codespace(window, pane, codespace_name, gh_cli_path, wezterm_cli_path)
		wezterm.log_info("Attempting to connect to codespace: " .. codespace_name)
		local null_device = wezterm.target_triple:find("windows", 1, true) and "NUL" or "/dev/null"
		local homebrew_bin_path = ""
		local target_triple = wezterm.target_triple
		if target_triple:find("apple-darwin", 1, true) then
			if target_triple:find("aarch64", 1, true) then
				homebrew_bin_path = "/opt/homebrew/bin"
			else
				homebrew_bin_path = "/usr/local/bin"
			end
		end
		-- 1. Run 'pwd' over SSH (as a test/initial connection)
		local pwd_command = '"'
			.. gh_cli_path
			.. '"'
			.. " codespace ssh -c "
			.. wezterm.shell_quote_arg(codespace_name)
			.. " pwd > "
			.. null_device
			.. " 2>&1"
		wezterm.log_info("Executing (silent): " .. pwd_command)
		local pwd_handle = io.popen(pwd_command)
		if pwd_handle then
			local pwd_output = pwd_handle:read("*a")
			local pwd_exit = pwd_handle:close()
			wezterm.log_info(
				"pwd command finished. Exit: [" .. tostring(pwd_exit) .. "] (type: " .. type(pwd_exit) .. ")"
			)
			if not (pwd_exit == 0 or pwd_exit == true) then
				local error_msg = "Failed to connect to "
					.. codespace_name
					.. " (pwd test). Output: "
					.. pwd_output
					.. " (Exit: "
					.. tostring(pwd_exit)
					.. ")"
				wezterm.log_error(error_msg)
				window:toast_notification("Codespace Error", error_msg, "Error", 5000)
				return
			end
		else
			local error_msg = "Failed to run pwd command for " .. codespace_name
			wezterm.log_error(error_msg)
			window:toast_notification("Codespace Error", error_msg, "Error", 5000)
			return
		end
		-- 2. Get SSH config block and rewrite Host
		local config_command = '"'
			.. gh_cli_path
			.. '"'
			.. " codespace ssh -c "
			.. wezterm.shell_quote_arg(codespace_name)
			.. " --config"
		local config_handle = io.popen(config_command)
		local config_output = config_handle and config_handle:read("*a") or ""
		if config_handle then
			config_handle:close()
		end
		if config_output == "" then
			local error_msg = "Failed to get SSH config for " .. codespace_name
			wezterm.log_error(error_msg)
			window:toast_notification("Codespace Error", error_msg, "Error", 5000)
			return
		end
		-- Replace Host line
		local modified_block = config_output:gsub("Host%s+[%w%-%._]+", "Host active-codespace", 1)
		update_ssh_config_with_alias(modified_block, "active-codespace")
		-- Instead of spawning a new terminal, notify the user that the codespace config is set up
		local success_msg = "SSH config for codespace '"
			.. codespace_name
			.. "' is set up! Switch to the 'active-codespace' domain manually to connect."
		wezterm.log_info(success_msg)
		window:toast_notification("Codespace", success_msg, nil, 5000)
	end

	local gh_cli_path = get_executable_path("gh")
	local wezterm_cli_path = get_executable_path("wezterm")

	if gh_cli_path and wezterm_cli_path then
		wezterm.log_info("GitHub CLI (gh) found at: " .. gh_cli_path)
		wezterm.log_info("WezTerm CLI found at: " .. wezterm_cli_path)

		-- Define the action to list and connect to codespaces
		local function list_and_connect_codespaces(window, pane)
			wezterm.log_info("Attempting to list codespaces...")
			local list_command = '"' .. gh_cli_path .. '" codespace list --json name 2>&1'
			local list_handle = io.popen(list_command)
			if not list_handle then
				local error_msg = "Failed to run gh codespace list (pipe open failed)."
				wezterm.log_error(error_msg)
				window:toast_notification("Codespace Error", error_msg, "Error", 5000)
				return
			end

			local list_output = list_handle:read("*a")
			local list_exit = list_handle:close()

			wezterm.log_info("gh codespace list raw output: [" .. list_output .. "]")
			wezterm.log_info(
				"gh codespace list raw exit: [" .. tostring(list_exit) .. "] (type: " .. type(list_exit) .. ")"
			)

			local success, codespaces = pcall(wezterm.json_parse, list_output)

			if not success then
				local error_msg = "Failed to parse codespace list JSON. Output: "
					.. list_output
					.. ". Parse Error: "
					.. tostring(codespaces)
				wezterm.log_error(error_msg)
				window:toast_notification("Codespace Error", error_msg, "Error", 5000)
				return
			end

			if not (list_exit == 0 or list_exit == true) then
				local warn_msg = "gh codespace list returned non-zero/non-numeric exit code ("
					.. tostring(list_exit)
					.. ") but produced valid JSON. Output: "
					.. list_output
				wezterm.log_warn(warn_msg)
			end

			if not codespaces or #codespaces == 0 then
				local info_msg = "No codespaces found."
				wezterm.log_info(info_msg)
				window:toast_notification("Codespace", info_msg, nil, 4000)
			elseif #codespaces == 1 then
				local codespace_name = codespaces[1].name
				wezterm.log_info("One codespace found: " .. codespace_name .. ". Connecting directly.")
				connect_to_codespace(window, pane, codespace_name, gh_cli_path, wezterm_cli_path)
			else
				wezterm.log_info("Multiple codespaces found. Presenting choice.")
				local options = {}
				for i, cs in ipairs(codespaces) do
					table.insert(options, cs.name)
				end

				window:perform_action(
					wezterm.action.PromptInputLine({
						description = "Select a codespace to connect to:",
						choices = options,
						action = wezterm.action_callback(function(window_obj, pane_obj, line)
							if line then
								wezterm.log_info("User selected codespace: " .. line)
								connect_to_codespace(window_obj, pane_obj, line, gh_cli_path, wezterm_cli_path)
							else
								local info_msg = "Codespace selection cancelled by user."
								wezterm.log_info(info_msg)
								window_obj:toast_notification("Codespace", info_msg, nil, 3000)
							end
						end),
					}),
					pane
				)
			end
		end

		config.keys = config.keys or {}
		table.insert(config.keys, {
			key = "G",
			mods = "CTRL|SHIFT",
			action = wezterm.action_callback(list_and_connect_codespaces),
		})
		table.insert(config.keys, {
			key = "D",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ShowLauncher,
		})
	else
		local error_msg =
			"GitHub CLI (gh) and/or WezTerm CLI not found or could not be located. Codespace features will be unavailable."
		wezterm.log_error(error_msg)
	end
end -- WEZTERM_EXECUTABLE guard

return config
