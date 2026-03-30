local wezterm = require("wezterm")

local config = wezterm.config_builder()

local CODESPACE_SLOT_COUNT = 8
local CODESPACE_BASE_PORT_REAL = 22300
local CODESPACE_BASE_PORT_TOY = 22400
local CODESPACE_REMOTE_MUX_BRIDGE_PORT_REAL = 22350
local CODESPACE_REMOTE_MUX_BRIDGE_PORT_TOY = 22450
local NCAT_BINARY = "ncat"
local WINSOCAT_BINARY = "winsocat"
local OIDC_REMOTE_PORT = 4000
local OIDC_LOCAL_PORT = 8250
local COMMAND_TIMEOUT_SECONDS = 20
local PORT_PROBE_ATTEMPTS = 20
local PORT_PROBE_TIMEOUT_SECONDS = 2
local PKI_FORENSICS_DEBUG = true

local target_triple = wezterm.target_triple

local function is_windows()
	return target_triple:find("windows", 1, true) ~= nil
end

local function is_macos()
	return target_triple:find("apple-darwin", 1, true) ~= nil
end

local function is_linux()
	return target_triple:find("linux", 1, true) ~= nil
end

local function path_sep()
	if is_windows() then
		return "\\"
	end
	return "/"
end

local function join_path(...)
	return table.concat({ ... }, path_sep())
end

local function trim(text)
	return (text or ""):gsub("^%s*(.-)%s*$", "%1")
end

local function split_lines(text)
	local lines = {}
	for line in (text or ""):gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end
	return lines
end

local function command_succeeded(exit_code)
	return exit_code == 0 or exit_code == true
end

local function quote_for_log(arg)
	if arg == nil then
		return ""
	end
	local text = tostring(arg)
	if text:find("[%s\"']") then
		return wezterm.shell_quote_arg(text)
	end
	return text
end

local function argv_to_log_string(argv)
	local parts = {}
	for _, arg in ipairs(argv or {}) do
		table.insert(parts, quote_for_log(arg))
	end
	return table.concat(parts, " ")
end

local function escape_powershell_single_quoted(text)
	return (text or ""):gsub("'", "''")
end

local function file_exists(path)
	local file = io.open(path, "r")
	if not file then
		return false
	end
	file:close()
	return true
end

local function read_file(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

local function write_file_atomic(path, content)
	local tmp_path = path .. ".tmp"
	local bak_path = path .. ".bak"

	local tmp = io.open(tmp_path, "wb")
	if not tmp then
		return false, "unable to open tmp file: " .. tmp_path
	end
	if content and content ~= "" then
		tmp:write(content)
	end
	tmp:close()

	os.remove(bak_path)
	if file_exists(path) then
		if not os.rename(path, bak_path) then
			os.remove(tmp_path)
			return false, "unable to move existing file to backup: " .. bak_path
		end
	end

	if not os.rename(tmp_path, path) then
		if file_exists(bak_path) then
			os.rename(bak_path, path)
		end
		os.remove(tmp_path)
		return false, "unable to promote tmp file: " .. path
	end

	os.remove(bak_path)
	return true, nil
end

local function run_command(command, timeout_seconds)
	local full_command = command
	if timeout_seconds and timeout_seconds > 0 and not is_windows() then
		full_command = "timeout " .. timeout_seconds .. "s " .. command
	end
	local handle = io.popen(full_command .. " 2>&1")
	if not handle then
		return nil, nil
	end
	local output = handle:read("*a")
	local exit_code = handle:close()
	return trim(output), exit_code
end

local function run_command_argv_raw(argv, timeout_seconds)
	if not argv or #argv == 0 then
		return nil, nil, nil
	end

	if not wezterm.run_child_process then
		local output, exit_code = run_command(argv_to_log_string(argv), timeout_seconds)
		return output, "", exit_code
	end

	local exec_argv = argv
	if timeout_seconds and timeout_seconds > 0 and not is_windows() then
		exec_argv = { "timeout", tostring(timeout_seconds) .. "s" }
		for _, arg in ipairs(argv) do
			table.insert(exec_argv, arg)
		end
	end

	local ok, stdout, stderr = wezterm.run_child_process(exec_argv)
	return stdout or "", stderr or "", ok
end

local function run_command_argv(argv, timeout_seconds)
	if not argv or #argv == 0 then
		return nil, nil
	end
	local stdout, stderr, ok = run_command_argv_raw(argv, timeout_seconds)
	local combined = trim((stdout or "") .. ((stderr and stderr ~= "") and ("\n" .. stderr) or ""))
	return combined, ok
end

local function ensure_directory(path)
	if wezterm.run_child_process then
		if is_windows() then
			local script = "New-Item -Path '"
				.. escape_powershell_single_quoted(path)
				.. "' -ItemType Directory -Force | Out-Null"
			local _, exit_code = run_command_argv({
				"powershell",
				"-NoProfile",
				"-NonInteractive",
				"-ExecutionPolicy",
				"Bypass",
				"-Command",
				script,
			}, 3)
			return command_succeeded(exit_code)
		end

		local _, exit_code = run_command_argv({ "mkdir", "-p", path }, 3)
		return command_succeeded(exit_code)
	end

	local command = "mkdir -p " .. wezterm.shell_quote_arg(path) .. " >/dev/null 2>&1"
	local _, exit_code = run_command(command, 0)
	return command_succeeded(exit_code)
end

local function domain_name_for_slot(slot, target)
	if target == "toy" then
		return "codespace-toy-" .. slot
	end
	return "codespace-" .. slot
end

local function local_port_for_slot(slot, target)
	if target == "toy" then
		return CODESPACE_BASE_PORT_TOY + slot
	end
	return CODESPACE_BASE_PORT_REAL + slot
end

local cache_dir = join_path(wezterm.home_dir, ".cache", "wezterm")
local remote_mux_socket_path = "/run/wezterm/wezterm-mux.sock"

local function build_codespace_unix_domains()
	local domains = {}
	for slot = 1, CODESPACE_SLOT_COUNT do
		for _, target in ipairs({ "real", "toy" }) do
			local proxy_command
			if is_windows() then
				proxy_command = { NCAT_BINARY, "--no-shutdown", "127.0.0.1", tostring(local_port_for_slot(slot, target)) }
			else
				proxy_command = { NCAT_BINARY, "--no-shutdown", "127.0.0.1", tostring(local_port_for_slot(slot, target)) }
			end

			table.insert(domains, {
				name = domain_name_for_slot(slot, target),
				proxy_command = proxy_command,
			})
		end
	end
	return domains
end

config.unix_domains = build_codespace_unix_domains()

config.color_scheme = "Tokyo Night"
config.colors = {
	split = "#b8b8b8",
}
config.exit_behavior = "Hold"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 30
config.window_decorations = "RESIZE"
config.tab_bar_at_bottom = true
config.notification_handling = "AlwaysShow"
config.term = "wezterm"
config.leader = {
	key = "b",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
tabline.setup()

local tmux = wezterm.plugin.require("https://github.com/sei40kr/wez-tmux")
tmux.apply_to_config(config, {})

if wezterm.gui then
	local slot_by_codespace = {}
	local codespace_by_slot = {}
	local forwarded_slots = {}
	local oidc_forward_codespace = nil
	local is_connecting = false
	local active_mux_remote_port = CODESPACE_REMOTE_MUX_BRIDGE_PORT_REAL

	local debug_log_path = join_path(cache_dir, "codespace-debug.log")

	local function start_debug_run(title)
		ensure_directory(cache_dir)
		local file = io.open(debug_log_path, "w")
		if not file then
			return
		end
		file:write(os.date("%Y-%m-%d %H:%M:%S") .. " RUN_START " .. tostring(title) .. "\n")
		file:close()
	end

	local function append_debug(message)
		ensure_directory(cache_dir)
		local file = io.open(debug_log_path, "a")
		if not file then
			return
		end
		file:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. message .. "\n")
		file:close()
	end

	local function codespace_error(window, message)
		wezterm.log_error(message)
		window:toast_notification("Codespace Error", message, "Error", 6000)
	end

	local function codespace_error_with_code(window, code, message)
		local full = "[" .. code .. "] " .. message .. " (debug: " .. debug_log_path .. ")"
		append_debug("ERROR " .. full)
		window:set_right_status("Codespace: failed " .. code)
		codespace_error(window, full)
	end

	local function set_codespace_status(window, message)
		window:set_right_status("Codespace: " .. message)
		append_debug("STATUS " .. message)
	end

	local function mux_target_label()
		if active_mux_remote_port == CODESPACE_REMOTE_MUX_BRIDGE_PORT_TOY then
			return "toy"
		end
		return "real"
	end

	local function current_mux_target()
		if active_mux_remote_port == CODESPACE_REMOTE_MUX_BRIDGE_PORT_TOY then
			return "toy"
		end
		return "real"
	end

	local function set_mux_target(window, remote_port)
		active_mux_remote_port = remote_port
		for slot = 1, CODESPACE_SLOT_COUNT do
			forwarded_slots[slot] = false
		end
		local message = "mux target set to "
			.. mux_target_label()
			.. " remote:"
			.. tostring(active_mux_remote_port)
		window:toast_notification("Codespace", message, nil, 3500)
		set_codespace_status(window, message)
		append_debug("MUX_TARGET remote_port=" .. tostring(active_mux_remote_port) .. " label=" .. mux_target_label())
	end

	local function truncate_for_report(text, max_len)
		local value = trim(tostring(text or ""))
		if #value <= max_len then
			return value
		end
		return value:sub(1, max_len) .. "..."
	end

	local short_pause

	local function spawn_new_tab_checked(window, spawn_spec, label)
		if not window or not window.mux_window then
			return false, "gui window mux handle unavailable"
		end

		local ok_mux, mux_window = pcall(function()
			return window:mux_window()
		end)
		if not ok_mux or not mux_window then
			return false, "failed to resolve mux window"
		end

		local ok_spawn, tab, pane_obj, window_obj = pcall(function()
			return mux_window:spawn_tab(spawn_spec)
		end)
		if not ok_spawn then
			append_debug("SPAWN_TAB_FAILED label=" .. tostring(label) .. " err=" .. tostring(tab))
			return false, "spawn_tab failed: " .. tostring(tab)
		end

		if not tab or not pane_obj or not window_obj then
			append_debug("SPAWN_TAB_FAILED label=" .. tostring(label) .. " err=nil result")
			return false, "spawn_tab returned nil"
		end

		append_debug("SPAWN_TAB_OK label=" .. tostring(label))
		return true, nil
	end

	local function spawn_new_window_fallback(spawn_spec, label)
		local ok_spawn, tab, pane_obj, mux_window = pcall(function()
			return wezterm.mux.spawn_window(spawn_spec)
		end)
		if not ok_spawn then
			append_debug("SPAWN_WINDOW_FAILED label=" .. tostring(label) .. " err=" .. tostring(tab))
			return false, "spawn_window failed: " .. tostring(tab)
		end

		if not tab or not pane_obj or not mux_window then
			append_debug("SPAWN_WINDOW_FAILED label=" .. tostring(label) .. " err=nil result")
			return false, "spawn_window returned nil"
		end

		if wezterm.gui and wezterm.gui.gui_window_for_mux_window then
			pcall(function()
				local gui_win = wezterm.gui.gui_window_for_mux_window(mux_window)
				if gui_win and gui_win.focus then
					gui_win:focus()
				end
			end)
		end

		append_debug("SPAWN_WINDOW_OK label=" .. tostring(label))
		return true, nil
	end

	local function resolve_macos_homebrew_path(executable_name)
		if not is_macos() then
			return nil
		end
		local homebrew_bin = target_triple:find("aarch64", 1, true) and "/opt/homebrew/bin/" or "/usr/local/bin/"
		local explicit_path = homebrew_bin .. executable_name
		if file_exists(explicit_path) then
			return explicit_path
		end
		return nil
	end

	local function get_executable_path(executable_name)
		local explicit_path = resolve_macos_homebrew_path(executable_name)
		if explicit_path then
			return explicit_path
		end

		local find_argv
		if is_windows() then
			find_argv = { "where", executable_name }
		elseif is_macos() or is_linux() then
			find_argv = { "which", executable_name }
		else
			return nil
		end

		local output, exit_code = run_command_argv(find_argv, COMMAND_TIMEOUT_SECONDS)
		if output and command_succeeded(exit_code) and output ~= "" then
			local lines = split_lines(output)
			return lines[1] or output
		end
		return nil
	end

	short_pause = function()
		local until_at = os.clock() + 0.35
		while os.clock() < until_at do
		end
	end

	local function build_codespace_list_argv(gh_cli_path)
		return { gh_cli_path, "codespace", "list", "--json", "name" }
	end

	local function build_codespace_forward_argv(gh_cli_path, codespace_name, remote_port, local_port)
		return {
			gh_cli_path,
			"codespace",
			"ports",
			"forward",
			"-c",
			codespace_name,
			tostring(remote_port) .. ":" .. tostring(local_port),
		}
	end

	local function build_codespace_ssh_argv(gh_cli_path, codespace_name, script)
		return {
			gh_cli_path,
			"codespace",
			"ssh",
			"-c",
			codespace_name,
			"--",
			"sh",
			"-c",
			script,
		}
	end

	local function build_forward_tab_command_argv(forward_argv, forward_label)
		if is_windows() then
			append_debug("FORWARD_TAB_WINDOWS label=" .. tostring(forward_label) .. " command=direct-gh")
			return forward_argv
		end

		local pieces = {
			"printf %s\\n " .. wezterm.shell_quote_arg("[WEZTERM FORWARD] " .. tostring(forward_label)),
			"printf %s\\n "
				.. wezterm.shell_quote_arg("[WEZTERM FORWARD] mapping " .. tostring(forward_argv[#forward_argv] or "")),
		}
		local quoted = {}
		for _, arg in ipairs(forward_argv) do
			table.insert(quoted, wezterm.shell_quote_arg(arg))
		end
		table.insert(pieces, "exec " .. table.concat(quoted, " "))
		return { "sh", "-lc", table.concat(pieces, "; ") }
	end

	local function start_forward_in_tab(window, forward_argv, forward_label)
		local tab_argv = build_forward_tab_command_argv(forward_argv, forward_label)
		local spawn_local_spec = {
			args = tab_argv,
			domain = { DomainName = "local" },
		}

		append_debug("FORWARD_TAB_START label=" .. tostring(forward_label) .. " argv=" .. argv_to_log_string(forward_argv))
		local ok_local, err_local = spawn_new_tab_checked(window, spawn_local_spec, forward_label .. " local")
		if ok_local then
			append_debug("FORWARD_TAB_OPENED label=" .. tostring(forward_label) .. " domain=local")
			return true, nil
		end

		append_debug("FORWARD_TAB_LOCAL_FAILED err=" .. tostring(err_local))
		local spawn_current_spec = { args = tab_argv }
		local ok_current, err_current = spawn_new_tab_checked(window, spawn_current_spec, forward_label .. " current")
		if ok_current then
			append_debug("FORWARD_TAB_OPENED label=" .. tostring(forward_label) .. " domain=current")
			return true, nil
		end

		append_debug("FORWARD_TAB_CURRENT_FAILED err=" .. tostring(err_current))
		local ok_window, err_window = spawn_new_window_fallback(spawn_local_spec, forward_label .. " fallback")
		if ok_window then
			append_debug("FORWARD_TAB_OPENED label=" .. tostring(forward_label) .. " domain=new-window")
			return true, nil
		end

		append_debug("FORWARD_TAB_FAILED err=" .. tostring(err_window))
		return false, tostring(err_window)
	end

	local function probe_local_tcp_port(port)
		if is_windows() then
			local probe_script = "if ((Test-NetConnection -ComputerName 127.0.0.1 -Port "
				.. tostring(port)
				.. " -WarningAction SilentlyContinue).TcpTestSucceeded) { exit 0 } else { exit 1 }"
			local _, exit_code = run_command_argv({
				"powershell",
				"-NoProfile",
				"-NonInteractive",
				"-ExecutionPolicy",
				"Bypass",
				"-Command",
				probe_script,
			}, PORT_PROBE_TIMEOUT_SECONDS)
			return command_succeeded(exit_code)
		end

		local _, exit_code =
			run_command_argv({ "nc", "-z", "127.0.0.1", tostring(port) }, PORT_PROBE_TIMEOUT_SECONDS)
		return command_succeeded(exit_code)
	end

	local function wait_for_mux_port(slot, window)
		local target = current_mux_target()
		local alias = domain_name_for_slot(slot, target)
		local local_port = local_port_for_slot(slot, target)
		for attempt = 1, PORT_PROBE_ATTEMPTS do
			if window then
				set_codespace_status(window, "probing mux " .. alias .. " (" .. attempt .. "/" .. PORT_PROBE_ATTEMPTS .. ")")
			end
			local ok = probe_local_tcp_port(local_port)
			append_debug(
				"PORT_PROBE alias=" .. alias .. " attempt=" .. tostring(attempt) .. " ok=" .. tostring(ok)
			)
			if ok then
				return true
			end
			if attempt < PORT_PROBE_ATTEMPTS then
				short_pause()
			end
		end
		return false
	end

	local function parse_codespaces(list_output)
		local success, codespaces = pcall(wezterm.json_parse, list_output)
		if not success then
			return nil, "Failed to parse codespace list JSON."
		end
		return codespaces, nil
	end

	local function allocate_codespace_slot(codespace_name)
		local assigned_slot = slot_by_codespace[codespace_name]
		if assigned_slot then
			return assigned_slot, nil
		end

		for slot = 1, CODESPACE_SLOT_COUNT do
			if not codespace_by_slot[slot] then
				slot_by_codespace[codespace_name] = slot
				codespace_by_slot[slot] = codespace_name
				return slot, nil
			end
		end

		return nil, "No free codespace slots. Increase CODESPACE_SLOT_COUNT."
	end

	local function local_wezterm_config_path()
		if is_windows() then
			return join_path(wezterm.home_dir, ".wezterm.lua")
		end
		return join_path(wezterm.home_dir, ".config", "wezterm", "wezterm.lua")
	end

	local function local_wezterm_source_config_path()
		return join_path(wezterm.home_dir, ".config", "wezterm", "wezterm.lua")
	end

	local function has_required_config_markers(content)
		if not content or content == "" then
			return false, "downloaded config was empty"
		end

		local required = {
			"collect_pki_forensics",
			"WEZ_ROOT=",
			"WEZ_HASH size=",
		}
		for _, marker in ipairs(required) do
			if not content:find(marker, 1, true) then
				return false, "missing marker: " .. marker
			end
		end

		return true, nil
	end

	local function parent_dir(path)
		return (path or ""):match("^(.*)[/\\][^/\\]+$")
	end

	local function copy_local_file(src, dst)
		local content = read_file(src)
		if not content then
			return false, "Failed to read file: " .. tostring(src)
		end
		local wrote, err = write_file_atomic(dst, content)
		if not wrote then
			return false, "Failed to write file: " .. tostring(dst) .. " (" .. tostring(err) .. ")"
		end
		return true, nil
	end

	local function pull_remote_wezterm_config(codespace_name, gh_cli_path, window)
		set_codespace_status(window, "downloading remote wezterm config")

		local destination = local_wezterm_config_path()
		local destination_parent = parent_dir(destination)
		if not destination_parent or destination_parent == "" or not ensure_directory(destination_parent) then
			return false, "Unable to create local config directory for " .. destination
		end

		local tmp_destination = destination .. ".download"
		local remote_candidates = {
			"remote:~/.config/wezterm/wezterm.lua",
			"remote:~/.wezterm.lua",
		}

		local chosen_source = nil
		local last_cp_output = ""
		for _, remote_source in ipairs(remote_candidates) do
			local cp_argv = {
				gh_cli_path,
				"codespace",
				"cp",
				"-c",
				codespace_name,
				"--expand",
				remote_source,
				tmp_destination,
			}

			append_debug("PULL_WEZTERM_START codespace=" .. codespace_name .. " source=" .. remote_source)
			local cp_output, cp_exit = run_command_argv(cp_argv, COMMAND_TIMEOUT_SECONDS * 3)
			if command_succeeded(cp_exit) then
				chosen_source = remote_source
				break
			end
			last_cp_output = tostring(cp_output)
			append_debug("PULL_WEZTERM_SOURCE_FAILED source=" .. remote_source .. " exit=" .. tostring(cp_exit))
		end

		if not chosen_source then
			append_debug("PULL_WEZTERM_FAILED err=no-source")
			return false, "gh codespace cp failed for all remote config paths: " .. last_cp_output
		end

		local content = read_file(tmp_destination)
		if not content then
			os.remove(tmp_destination)
			return false, "Failed to read downloaded config: " .. tmp_destination
		end

		local valid, validation_err = has_required_config_markers(content)
		if not valid then
			os.remove(tmp_destination)
			append_debug("PULL_WEZTERM_INVALID source=" .. tostring(chosen_source) .. " err=" .. tostring(validation_err))
			return false, "Downloaded config failed validation (" .. tostring(validation_err) .. ")"
		end

		local wrote, write_err = write_file_atomic(destination, content)
		os.remove(tmp_destination)
		if not wrote then
			return false, "Failed to save local config: " .. tostring(write_err)
		end

		append_debug("PULL_WEZTERM_OK source=" .. tostring(chosen_source) .. " destination=" .. destination)
		local active_pane = window:active_pane()
		if active_pane then
			window:perform_action(wezterm.action.ReloadConfiguration, active_pane)
			append_debug("PULL_WEZTERM_RELOAD ok=true")
		else
			append_debug("PULL_WEZTERM_RELOAD ok=false reason=no-active-pane")
		end
		window:toast_notification(
			"Codespace",
			"Downloaded remote config from " .. tostring(chosen_source) .. " to " .. destination,
			nil,
			5000
		)
		window:set_right_status("Codespace: downloaded remote config from " .. tostring(chosen_source))
		return true, nil
	end

	local function push_local_wezterm_config(codespace_name, gh_cli_path, window)
		set_codespace_status(window, "uploading local wezterm config")

		local source = local_wezterm_source_config_path()
		if not file_exists(source) then
			source = local_wezterm_config_path()
		end
		if not file_exists(source) then
			return false, "Local config file not found at ~/.config/wezterm/wezterm.lua or ~/.wezterm.lua"
		end

		local content = read_file(source)
		local valid, validation_err = has_required_config_markers(content)
		if not valid then
			return false, "Local config failed validation (" .. tostring(validation_err) .. ")"
		end

		local remote_tmp = "remote:~/.config/wezterm/wezterm.lua.upload"
		local cp_argv = {
			gh_cli_path,
			"codespace",
			"cp",
			"-c",
			codespace_name,
			"--expand",
			source,
			remote_tmp,
		}
		append_debug("PUSH_WEZTERM_START codespace=" .. codespace_name .. " source=" .. source)
		local cp_output, cp_exit = run_command_argv(cp_argv, COMMAND_TIMEOUT_SECONDS * 3)
		if not command_succeeded(cp_exit) then
			append_debug("PUSH_WEZTERM_FAILED stage=cp exit=" .. tostring(cp_exit))
			return false, "gh codespace cp upload failed: " .. tostring(cp_output)
		end

		local finalize_script = "set -eu; mkdir -p ~/.config/wezterm; mv ~/.config/wezterm/wezterm.lua.upload ~/.config/wezterm/wezterm.lua; "
			.. "if [ -L ~/.wezterm.lua ] || [ ! -e ~/.wezterm.lua ]; then ln -sfn ~/.config/wezterm/wezterm.lua ~/.wezterm.lua; fi"
		local finalize_out, finalize_exit =
			run_command_argv(build_codespace_ssh_argv(gh_cli_path, codespace_name, finalize_script), COMMAND_TIMEOUT_SECONDS)
		if not command_succeeded(finalize_exit) then
			append_debug("PUSH_WEZTERM_FAILED stage=finalize exit=" .. tostring(finalize_exit))
			return false, "Remote finalize failed: " .. tostring(finalize_out)
		end

		append_debug("PUSH_WEZTERM_OK source=" .. source .. " destination=~/.config/wezterm/wezterm.lua")
		window:toast_notification(
			"Codespace",
			"Uploaded local config to ~/.config/wezterm/wezterm.lua",
			nil,
			5000
		)
		window:set_right_status("Codespace: uploaded local config to remote")
		return true, nil
	end

	local function ensure_local_proxy_available()
		if is_windows() then
			local ncat_path = get_executable_path(NCAT_BINARY)
			if ncat_path and ncat_path ~= "" then
				return true, nil
			end

			local winsocat = get_executable_path(WINSOCAT_BINARY)
			if winsocat and winsocat ~= "" then
				return true, nil
			end
			return false, NCAT_BINARY .. " and " .. WINSOCAT_BINARY .. " not found on local machine"
		end

		local ncat_path = get_executable_path(NCAT_BINARY)
		if ncat_path and ncat_path ~= "" then
			return true, nil
		end
		return false, NCAT_BINARY .. " not found on local machine"
	end

	local function local_file_sha256(path)
		if not file_exists(path) then
			return nil, nil, "missing local file"
		end

		local file = io.open(path, "rb")
		if not file then
			return nil, nil, "failed to open local file"
		end
		local size = file:seek("end") or 0
		file:close()

		if is_windows() then
			local out, err, ok = run_command_argv_raw({ "certutil", "-hashfile", path, "SHA256" }, COMMAND_TIMEOUT_SECONDS)
			if not command_succeeded(ok) then
				return nil, size, "certutil failed: " .. truncate_for_report(err or out, 240)
			end
			for line in (out or ""):gmatch("[^\r\n]+") do
				local hex = line:gsub("%s+", ""):lower()
				if hex:match("^[0-9a-f]+$") and #hex >= 64 then
					return hex:sub(1, 64), size, nil
				end
			end
			return nil, size, "unable to parse certutil SHA256 output"
		end

		local sha256_path = get_executable_path("sha256sum")
		if sha256_path then
			local out, err, ok = run_command_argv_raw({ sha256_path, path }, COMMAND_TIMEOUT_SECONDS)
			if command_succeeded(ok) then
				local hash = trim((out or ""):match("^([0-9a-fA-F]+)") or ""):lower()
				if hash ~= "" then
					return hash, size, nil
				end
			else
				return nil, size, "sha256sum failed: " .. truncate_for_report(err or out, 240)
			end
		end

		local openssl_path = get_executable_path("openssl")
		if openssl_path then
			local out, err, ok = run_command_argv_raw({ openssl_path, "dgst", "-sha256", path }, COMMAND_TIMEOUT_SECONDS)
			if not command_succeeded(ok) then
				return nil, size, "openssl dgst failed: " .. truncate_for_report(err or out, 240)
			end
			local hash = trim((out or ""):match("= ([0-9a-fA-F]+)") or ""):lower()
			if hash ~= "" then
				return hash, size, nil
			end
			return nil, size, "unable to parse openssl SHA256 output"
		end

		return nil, size, "no local sha256 tool available"
	end

	local function remote_file_sha256_and_size(codespace_name, gh_cli_path, remote_path)
		local script = "set -eu; export LC_ALL=C LANG=C; F="
			.. wezterm.shell_quote_arg(remote_path)
			.. "; [ -f \"$F\" ]; "
			.. "size=$(wc -c < \"$F\" | tr -d '[:space:]'); "
			.. "if command -v sha256sum >/dev/null 2>&1; then sha=$(sha256sum \"$F\" | awk '{print $1}'); "
			.. "else sha=$(openssl dgst -sha256 \"$F\" | awk '{print $2}'); fi; "
			.. "printf 'WEZ_HASH size=%s sha=%s\\n' \"$size\" \"$sha\""
		local out, err, ok = run_command_argv_raw(
			build_codespace_ssh_argv(gh_cli_path, codespace_name, script),
			COMMAND_TIMEOUT_SECONDS
		)
		if not command_succeeded(ok) then
			return nil, nil, "remote hash failed: " .. truncate_for_report(err or out, 240)
		end

		local marker = nil
		for _, line in ipairs(split_lines(out or "")) do
			local parsed = line:match("^WEZ_HASH%s+size=([0-9]+)%s+sha=([0-9a-fA-F]+)$")
			if parsed then
				marker = line
			end
		end
		if not marker then
			return nil, nil, "unable to parse remote hash output"
		end

		local size_str, sha = marker:match("^WEZ_HASH%s+size=([0-9]+)%s+sha=([0-9a-fA-F]+)$")
		local size = tonumber(size_str)
		sha = (sha or ""):lower()
		if not size or sha == "" then
			return nil, nil, "unable to parse remote hash output"
		end
		return sha, size, nil
	end

	local function collect_pki_forensics(window, codespace_name, gh_cli_path, reason)
		if not PKI_FORENSICS_DEBUG then
			return
		end

		set_codespace_status(window, "collecting pki forensics")
		local forensic_root = join_path(cache_dir, "forensics")
		if not ensure_directory(forensic_root) then
			append_debug("PKI_FORENSICS_FAILED err=unable to create local forensic root")
			return
		end

		local run_id = os.date("%Y%m%d-%H%M%S") .. "-" .. tostring(os.time())
		local local_run_dir = join_path(forensic_root, run_id)
		if not ensure_directory(local_run_dir) then
			append_debug("PKI_FORENSICS_FAILED err=unable to create local run dir")
			return
		end

		local report_lines = {}
		local function add_report(line)
			table.insert(report_lines, tostring(line))
		end

		local report_local_path = join_path(local_run_dir, "report.txt")
		local function finalize_report(success)
			local content = table.concat(report_lines, "\n") .. "\n"
			local wrote = write_file_atomic(report_local_path, content)
			if not wrote then
				append_debug("PKI_FORENSICS_FAILED err=unable to write local report path=" .. report_local_path)
				return
			end
			if success then
				append_debug("PKI_FORENSICS_REPORT path=" .. report_local_path)
				window:toast_notification("Codespace", "PKI forensic report saved: " .. report_local_path, nil, 6000)
			else
				append_debug("PKI_FORENSICS_REPORT_PARTIAL path=" .. report_local_path)
				window:toast_notification("Codespace", "PKI forensic partial report saved: " .. report_local_path, "Warn", 8000)
			end
		end

		add_report("reason=" .. tostring(reason or ""))
		add_report("codespace=" .. tostring(codespace_name))
		add_report("run_id=" .. run_id)
		add_report("generated_at=" .. os.date("%Y-%m-%d %H:%M:%S"))

		local remote_root_rel = ".cache/wezterm-pki-debug/" .. run_id
		local remote_root = nil
		local remote_setup_script = "set -eu; export LC_ALL=C LANG=C; REL="
			.. wezterm.shell_quote_arg(remote_root_rel)
			.. "; ROOT=\"$HOME/$REL\"; mkdir -p \"$ROOT/local\" \"$ROOT/remote\"; "
			.. "[ -d \"$ROOT/local\" ] && [ -d \"$ROOT/remote\" ]; printf 'WEZ_ROOT=%s\\n' \"$ROOT\""
		local setup_out, setup_err, setup_exit = run_command_argv_raw(
			build_codespace_ssh_argv(gh_cli_path, codespace_name, remote_setup_script),
			COMMAND_TIMEOUT_SECONDS
		)
		if not command_succeeded(setup_exit) then
			append_debug("PKI_FORENSICS_FAILED err=remote setup failed exit=" .. tostring(setup_exit))
			add_report("remote_setup=failed")
			add_report("remote_setup_output=" .. truncate_for_report((setup_out or "") .. " " .. (setup_err or ""), 500))
			finalize_report(false)
			return
		end
		for _, line in ipairs(split_lines(setup_out or "")) do
			local t = trim(line)
			local parsed = t:match("^WEZ_ROOT=(.+)$")
			if parsed and parsed ~= "" then
				remote_root = parsed
			end
		end
		if not remote_root then
			append_debug("PKI_FORENSICS_FAILED err=remote setup returned empty root")
			add_report("remote_setup=failed")
			add_report("remote_setup_output=" .. truncate_for_report((setup_out or "") .. " " .. (setup_err or ""), 500))
			finalize_report(false)
			return
		end
		add_report("remote_setup=ok")
		add_report("remote_root=" .. remote_root)

		local upload_items = {
			{ name = ".wezterm.lua", required = false },
			{ name = "codespace-debug.log", required = false },
		}
		local local_map = {
			[".wezterm.lua"] = join_path(wezterm.home_dir, ".wezterm.lua"),
			["codespace-debug.log"] = debug_log_path,
		}
		local core_uploads_ok = true

		for _, item in ipairs(upload_items) do
			local file_name = item.name
			local src = local_map[file_name]
			local required = item.required

			if not file_exists(src) then
				append_debug("PKI_FORENSICS_PUSH file=" .. file_name .. " ok=false reason=missing-local")
				add_report("upload file=" .. file_name .. " required=" .. tostring(required) .. " status=missing-local")
				if required then
					core_uploads_ok = false
				end
			else
				local local_sha, local_size, local_hash_err = local_file_sha256(src)
				if not local_sha then
					append_debug("PKI_FORENSICS_PUSH file=" .. file_name .. " ok=false reason=local-hash-failed")
					add_report(
						"upload file="
							.. file_name
							.. " required="
							.. tostring(required)
							.. " status=local-hash-failed err="
							.. tostring(local_hash_err)
					)
					if required then
						core_uploads_ok = false
					end
				else
					local remote_target = "remote:~/" .. remote_root_rel .. "/local/" .. file_name
					local cp_argv = {
						gh_cli_path,
						"codespace",
						"cp",
						"-c",
						codespace_name,
						"--expand",
						src,
						remote_target,
					}
					local cp_output, cp_exit = run_command_argv(cp_argv, COMMAND_TIMEOUT_SECONDS * 3)
					local cp_ok = command_succeeded(cp_exit)
					append_debug(
						"PKI_FORENSICS_PUSH file="
							.. file_name
							.. " ok="
							.. tostring(cp_ok)
							.. " exit="
							.. tostring(cp_exit)
					)
					add_report(
						"upload file="
							.. file_name
							.. " required="
							.. tostring(required)
							.. " local_size="
							.. tostring(local_size)
							.. " local_sha="
							.. tostring(local_sha)
							.. " cp_exit="
							.. tostring(cp_exit)
							.. " cp_output="
							.. truncate_for_report(cp_output, 300)
					)

					if cp_ok then
						local remote_sha, remote_size, remote_hash_err =
							remote_file_sha256_and_size(codespace_name, gh_cli_path, remote_root .. "/local/" .. file_name)
						if not remote_sha then
							add_report(
								"upload_verify file=" .. file_name .. " status=remote-hash-failed err=" .. tostring(remote_hash_err)
							)
							if required then
								core_uploads_ok = false
							end
						else
							local matches = (remote_sha == local_sha and remote_size == local_size)
							add_report(
								"upload_verify file="
									.. file_name
									.. " status="
									.. (matches and "ok" or "mismatch")
									.. " remote_size="
									.. tostring(remote_size)
									.. " remote_sha="
									.. tostring(remote_sha)
							)
							if not matches and required then
								core_uploads_ok = false
							end
						end
					elseif required then
						core_uploads_ok = false
					end
				end
			end
		end

		if not core_uploads_ok then
			append_debug("PKI_FORENSICS_FAILED err=core upload/verify failed")
			add_report("result=core-upload-failed")
			finalize_report(false)
			return
		end

		local report_script = "set -eu; export LC_ALL=C LANG=C; ROOT="
			.. wezterm.shell_quote_arg(remote_root)
			.. "; REASON="
			.. wezterm.shell_quote_arg(tostring(reason or ""))
			.. "; mkdir -p \"$ROOT/remote\"; "
			.. "if [ -f /etc/wezterm/wezterm-mux.lua ]; then cp /etc/wezterm/wezterm-mux.lua \"$ROOT/remote/wezterm-mux.lua\"; fi; "
			.. "if [ -f /usr/local/bin/wezterm-mux-service ]; then cp /usr/local/bin/wezterm-mux-service \"$ROOT/remote/wezterm-mux-service.sh\"; fi; "
			.. "if [ -S "
			.. wezterm.shell_quote_arg(remote_mux_socket_path)
			.. " ]; then printf 'socket_present=true\n' > \"$ROOT/remote/socket-status.txt\"; else printf 'socket_present=false\n' > \"$ROOT/remote/socket-status.txt\"; fi; "
			.. "if command -v ss >/dev/null 2>&1; then ss -ltnp > \"$ROOT/remote/listeners.txt\"; fi; "
			.. "first_non_empty_line(){ awk 'NF{print; exit}' \"$1\" 2>/dev/null || true; }; "
			.. "sha_file(){ if [ -f \"$1\" ]; then sha256sum \"$1\" | awk '{print $1}'; else echo MISSING; fi; }; "
			.. "{ echo \"reason=$REASON\"; echo \"root=$ROOT\"; "
			.. "for f in wezterm-mux.lua wezterm-mux-service.sh socket-status.txt listeners.txt; do R=\"$ROOT/remote/$f\"; "
			.. "echo \"remote_file=$f\"; "
			.. "echo \"  remote_exists=$( [ -f \"$R\" ] && echo true || echo false )\"; "
			.. "echo \"  remote_sha=$(sha_file \"$R\")\"; "
			.. "echo \"  remote_header=$(first_non_empty_line \"$R\")\"; "
			.. "done; "
			.. "for f in .wezterm.lua codespace-debug.log; do L=\"$ROOT/local/$f\"; "
			.. "echo \"uploaded_file=$f\"; "
			.. "echo \"  local_exists=$( [ -f \"$L\" ] && echo true || echo false )\"; "
			.. "echo \"  local_sha=$(sha_file \"$L\")\"; "
			.. "echo \"  local_header=$(first_non_empty_line \"$L\")\"; "
			.. "done; } > \"$ROOT/report.txt\"; printf 'WEZ_REPORT=%s\\n' \"$ROOT/report.txt\""

		local report_output, report_err, report_exit = run_command_argv_raw(
			build_codespace_ssh_argv(gh_cli_path, codespace_name, report_script),
			COMMAND_TIMEOUT_SECONDS * 3
		)
		if not command_succeeded(report_exit) then
			append_debug("PKI_FORENSICS_FAILED err=report generation failed exit=" .. tostring(report_exit))
			add_report("remote_report_generation=failed")
			add_report("remote_report_output=" .. truncate_for_report((report_output or "") .. " " .. (report_err or ""), 500))
			finalize_report(false)
			return
		end
		add_report("remote_report_generation=ok")

		local report_remote_path = nil
		for _, line in ipairs(split_lines(report_output or "")) do
			local parsed = trim(line):match("^WEZ_REPORT=(.+)$")
			if parsed and parsed ~= "" then
				report_remote_path = parsed
			end
		end
		if report_remote_path == "" then
			report_remote_path = remote_root .. "/report.txt"
		end
		if not report_remote_path then
			report_remote_path = remote_root .. "/report.txt"
		end

		local remote_report_local_path = join_path(local_run_dir, "remote-report.txt")
		local cp_report_argv = {
			gh_cli_path,
			"codespace",
			"cp",
			"-c",
			codespace_name,
			"--expand",
			"remote:" .. report_remote_path,
			remote_report_local_path,
		}
		local report_cp_out, report_cp_exit = run_command_argv(cp_report_argv, COMMAND_TIMEOUT_SECONDS * 3)
		if not command_succeeded(report_cp_exit) then
			append_debug("PKI_FORENSICS_FAILED err=report copy failed exit=" .. tostring(report_cp_exit))
			add_report("remote_report_copy=failed")
			add_report("remote_report_copy_output=" .. truncate_for_report(report_cp_out, 500))
			finalize_report(false)
			return
		end
		add_report("remote_report_copy=ok")
		add_report("remote_report_path=" .. remote_report_local_path)

		finalize_report(true)
	end

	local function ensure_codespace_mux_forward(codespace_name, gh_cli_path, slot, window)
		local target = current_mux_target()
		local local_port = local_port_for_slot(slot, target)

		if forwarded_slots[slot] then
			if window then
				set_codespace_status(window, "reusing existing mux forward " .. domain_name_for_slot(slot, target))
			end
			if wait_for_mux_port(slot, window) then
				return true, nil
			end
			forwarded_slots[slot] = false
		end

		local forward_argv =
			build_codespace_forward_argv(gh_cli_path, codespace_name, active_mux_remote_port, local_port)
		if window then
			set_codespace_status(window, "opening mux forward tab " .. domain_name_for_slot(slot, target))
		end
		append_debug(
			"FORWARD_START codespace="
				.. codespace_name
				.. " slot="
				.. tostring(slot)
				.. " local_port="
				.. tostring(local_port)
				.. " remote_port="
				.. tostring(active_mux_remote_port)
		)

		local started, start_error = start_forward_in_tab(window, forward_argv, domain_name_for_slot(slot, target) .. " mux")
		if not started then
			append_debug("FORWARD_START_FAILED err=" .. tostring(start_error))
			return false, "Failed to open mux forward tab (" .. tostring(start_error) .. ")"
		end

		local ready = wait_for_mux_port(slot, window)
		if ready then
			forwarded_slots[slot] = true
			append_debug("FORWARD_READY slot=" .. tostring(slot) .. " local_port=" .. tostring(local_port))
			return true, nil
		end

		forwarded_slots[slot] = false
		return false,
			"Forward tab started, but mux port did not open on localhost:"
				.. local_port
				.. ". Keep forward tab open and review logs."
	end

	local function ensure_oidc_forward_tab(codespace_name, gh_cli_path, window)
		if oidc_forward_codespace == codespace_name then
			return true, nil
		end

		if oidc_forward_codespace and oidc_forward_codespace ~= codespace_name then
			return false,
				"OIDC forward localhost:"
					.. tostring(OIDC_LOCAL_PORT)
					.. " is already active for "
					.. oidc_forward_codespace
					.. ". Close that forward tab first."
		end

		if window then
			set_codespace_status(
				window,
				"opening oidc forward tab " .. tostring(OIDC_LOCAL_PORT) .. "<-" .. tostring(OIDC_REMOTE_PORT)
			)
		end

		local oidc_argv = build_codespace_forward_argv(gh_cli_path, codespace_name, OIDC_REMOTE_PORT, OIDC_LOCAL_PORT)
		local started, err =
			start_forward_in_tab(window, oidc_argv, "oidc " .. tostring(OIDC_LOCAL_PORT) .. "<-" .. tostring(OIDC_REMOTE_PORT))
		if not started then
			return false, "Failed to open OIDC forward tab (" .. tostring(err) .. ")"
		end

		oidc_forward_codespace = codespace_name
		append_debug(
			"OIDC_FORWARD_READY codespace="
				.. codespace_name
				.. " local_port="
				.. tostring(OIDC_LOCAL_PORT)
				.. " remote_port="
				.. tostring(OIDC_REMOTE_PORT)
		)
		return true, nil
	end

	local function open_codespace_domain(window, slot)
		local target = current_mux_target()
		local domain_spec = { domain = { DomainName = domain_name_for_slot(slot, target) } }
		local ok_tab, err_tab = spawn_new_tab_checked(window, domain_spec, "remote " .. domain_name_for_slot(slot, target))
		if ok_tab then
			append_debug("REMOTE_TAB_OPENED domain=" .. domain_name_for_slot(slot, target) .. " location=current-window")
			return true, nil
		end

		append_debug("REMOTE_TAB_CURRENT_FAILED err=" .. tostring(err_tab))
		append_debug("REMOTE_TAB_FAILED err=" .. tostring(err_tab))
		return false, tostring(err_tab)
	end

	local function connect_to_codespace(window, codespace_name, gh_cli_path)
		append_debug("CONNECT_BEGIN codespace=" .. codespace_name)

		set_codespace_status(window, "allocating slot for " .. codespace_name)
		local slot, slot_error = allocate_codespace_slot(codespace_name)
		if not slot then
			codespace_error_with_code(window, "E_SLOT", slot_error)
			return false
		end

		local proxy_ok, proxy_err = ensure_local_proxy_available()
		if not proxy_ok then
			codespace_error_with_code(window, "E_PROXY", tostring(proxy_err))
			return false
		end

		set_codespace_status(window, "starting mux port forward")
		local forwarded, forward_error = ensure_codespace_mux_forward(codespace_name, gh_cli_path, slot, window)
		if not forwarded then
			codespace_error_with_code(window, "E_FORWARD", forward_error)
			return false
		end

		local oidc_ok, oidc_error = ensure_oidc_forward_tab(codespace_name, gh_cli_path, window)
		if not oidc_ok then
			append_debug("OIDC_FORWARD_WARN " .. tostring(oidc_error))
			window:toast_notification("Codespace", "OIDC forward warning: " .. tostring(oidc_error), nil, 5000)
		end

		set_codespace_status(window, "opening remote mux tab")
		local opened, open_err = open_codespace_domain(window, slot)
		if not opened then
			append_debug("REMOTE_OPEN_FAIL err=" .. tostring(open_err))
			collect_pki_forensics(window, codespace_name, gh_cli_path, open_err)
			codespace_error_with_code(window, "E_TAB_OPEN", "Failed to open remote mux tab (" .. tostring(open_err) .. ")")
			return false
		end

		local target = current_mux_target()
		local success_msg = "Connected "
			.. codespace_name
			.. " via "
			.. domain_name_for_slot(slot, target)
			.. " on localhost:"
			.. local_port_for_slot(slot, target)
			.. " ("
			.. mux_target_label()
			.. " remote:"
			.. tostring(active_mux_remote_port)
			.. ")."
		window:toast_notification("Codespace", success_msg, nil, 4000)
		window:set_right_status("Codespace: connected " .. domain_name_for_slot(slot, target))
		append_debug("CONNECT_OK codespace=" .. codespace_name .. " slot=" .. tostring(slot))
		return true
	end

	local gh_cli_path = get_executable_path("gh")
	if gh_cli_path then
		local function list_and_push_local_wezterm_config(window, pane)
			if is_connecting then
				window:toast_notification("Codespace", "A connection flow is already running.", nil, 2500)
				return
			end

			is_connecting = true
			start_debug_run("push_local_wezterm_config")
			set_codespace_status(window, "listing codespaces")

			local list_argv = build_codespace_list_argv(gh_cli_path)
			local list_output, list_exit = run_command_argv(list_argv, COMMAND_TIMEOUT_SECONDS)
			if not list_output or not command_succeeded(list_exit) then
				is_connecting = false
				codespace_error_with_code(window, "E_LIST", "Failed to list codespaces.")
				return
			end

			local codespaces, parse_error = parse_codespaces(list_output)
			if parse_error then
				is_connecting = false
				codespace_error_with_code(window, "E_PARSE", parse_error)
				return
			end

			if not codespaces or #codespaces == 0 then
				is_connecting = false
				window:toast_notification("Codespace", "No codespaces found.", nil, 3000)
				return
			end

			if #codespaces == 1 then
				local ok, push_err = push_local_wezterm_config(codespaces[1].name, gh_cli_path, window)
				if not ok then
					codespace_error_with_code(window, "E_CONFIG_PUSH", tostring(push_err))
				end
				is_connecting = false
				return
			end

			local choices = {}
			for _, codespace in ipairs(codespaces) do
				table.insert(choices, {
					id = codespace.name,
					label = codespace.name,
				})
			end

			window:perform_action(
				wezterm.action.InputSelector({
					title = "Codespaces",
					description = "Choose a codespace to upload local config",
					fuzzy = true,
					choices = choices,
					action = wezterm.action_callback(function(window_obj, _, id)
						if not id then
							is_connecting = false
							window_obj:toast_notification("Codespace", "Selection cancelled.", nil, 2000)
							return
						end

						local ok, push_err = push_local_wezterm_config(id, gh_cli_path, window_obj)
						if not ok then
							codespace_error_with_code(window_obj, "E_CONFIG_PUSH", tostring(push_err))
						end
						is_connecting = false
					end),
				}),
				pane
			)
		end

		local function list_and_pull_remote_wezterm_config(window, pane)
			if is_connecting then
				window:toast_notification("Codespace", "A connection flow is already running.", nil, 2500)
				return
			end

			is_connecting = true
			start_debug_run("pull_remote_wezterm_config")
			set_codespace_status(window, "listing codespaces")

			local list_argv = build_codespace_list_argv(gh_cli_path)
			local list_output, list_exit = run_command_argv(list_argv, COMMAND_TIMEOUT_SECONDS)
			if not list_output or not command_succeeded(list_exit) then
				is_connecting = false
				codespace_error_with_code(window, "E_LIST", "Failed to list codespaces.")
				return
			end

			local codespaces, parse_error = parse_codespaces(list_output)
			if parse_error then
				is_connecting = false
				codespace_error_with_code(window, "E_PARSE", parse_error)
				return
			end

			if not codespaces or #codespaces == 0 then
				is_connecting = false
				window:toast_notification("Codespace", "No codespaces found.", nil, 3000)
				return
			end

			if #codespaces == 1 then
				local ok, pull_err = pull_remote_wezterm_config(codespaces[1].name, gh_cli_path, window)
				if not ok then
					codespace_error_with_code(window, "E_CONFIG_PULL", tostring(pull_err))
				end
				is_connecting = false
				return
			end

			local choices = {}
			for _, codespace in ipairs(codespaces) do
				table.insert(choices, {
					id = codespace.name,
					label = codespace.name,
				})
			end

			window:perform_action(
				wezterm.action.InputSelector({
					title = "Codespaces",
					description = "Choose a codespace to download remote wezterm config",
					fuzzy = true,
					choices = choices,
					action = wezterm.action_callback(function(window_obj, _, id)
						if not id then
							is_connecting = false
							window_obj:toast_notification("Codespace", "Selection cancelled.", nil, 2000)
							return
						end

						local ok, pull_err = pull_remote_wezterm_config(id, gh_cli_path, window_obj)
						if not ok then
							codespace_error_with_code(window_obj, "E_CONFIG_PULL", tostring(pull_err))
						end
						is_connecting = false
					end),
				}),
				pane
			)
		end

		local function list_and_connect_codespaces(window, pane)
			if is_connecting then
				window:toast_notification("Codespace", "A connection flow is already running.", nil, 2500)
				return
			end

			is_connecting = true
			start_debug_run("connect_flow")
			set_codespace_status(window, "listing codespaces")

			local list_argv = build_codespace_list_argv(gh_cli_path)
			local list_output, list_exit = run_command_argv(list_argv, COMMAND_TIMEOUT_SECONDS)
			if not list_output or not command_succeeded(list_exit) then
				is_connecting = false
				codespace_error_with_code(window, "E_LIST", "Failed to list codespaces.")
				return
			end

			local codespaces, parse_error = parse_codespaces(list_output)
			if parse_error then
				is_connecting = false
				codespace_error_with_code(window, "E_PARSE", parse_error)
				return
			end

			if not codespaces or #codespaces == 0 then
				is_connecting = false
				window:toast_notification("Codespace", "No codespaces found.", nil, 3000)
				return
			end

			if #codespaces == 1 then
				connect_to_codespace(window, codespaces[1].name, gh_cli_path)
				is_connecting = false
				return
			end

			local choices = {}
			for _, codespace in ipairs(codespaces) do
				table.insert(choices, {
					id = codespace.name,
					label = codespace.name,
				})
			end

			window:perform_action(
				wezterm.action.InputSelector({
					title = "Codespaces",
					description = "Choose a codespace to connect",
					fuzzy = true,
					choices = choices,
					action = wezterm.action_callback(function(window_obj, _, id)
						if not id then
							is_connecting = false
							window_obj:toast_notification("Codespace", "Selection cancelled.", nil, 2000)
							return
						end

						connect_to_codespace(window_obj, id, gh_cli_path)
						is_connecting = false
					end),
				}),
				pane
			)
		end

		config.keys = config.keys or {}
		table.insert(config.keys, {
			key = "g",
			mods = "LEADER",
			action = wezterm.action_callback(list_and_connect_codespaces),
		})
		table.insert(config.keys, {
			key = "m",
			mods = "LEADER",
			action = wezterm.action_callback(function(window)
				set_mux_target(window, CODESPACE_REMOTE_MUX_BRIDGE_PORT_REAL)
			end),
		})
		table.insert(config.keys, {
			key = "t",
			mods = "LEADER",
			action = wezterm.action_callback(function(window)
				set_mux_target(window, CODESPACE_REMOTE_MUX_BRIDGE_PORT_TOY)
			end),
		})
		table.insert(config.keys, {
			key = "y",
			mods = "LEADER",
			action = wezterm.action_callback(list_and_pull_remote_wezterm_config),
		})
		table.insert(config.keys, {
			key = "Y",
			mods = "LEADER|SHIFT",
			action = wezterm.action_callback(list_and_push_local_wezterm_config),
		})
		table.insert(config.keys, {
			key = "D",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ShowLauncher,
		})
	else
		wezterm.log_error("GitHub CLI (gh) not found. Codespace features will be unavailable.")
	end
end

return config
