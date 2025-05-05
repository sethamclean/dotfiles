-- Obsidian MCP Server for MCPHub.nvim
-- This is a native MCP server that wraps Obsidian.nvim commands

local M = {}

-- Debug mode flag (inherited from parent module)
M.debug_mode = false

-- Debug function to log info only when debug mode is enabled
local function debug_log(msg, level)
	if not M.debug_mode then
		return
	end
	level = level or vim.log.levels.INFO
	vim.notify("[MCP Obsidian] " .. msg, level)
end

-- Function to enable/disable debug mode
function M.set_debug_mode(enabled)
	M.debug_mode = enabled
	debug_log("Debug mode " .. (enabled and "enabled" or "disabled"))
end

-- Define the MCP server
M.server = {
	name = "obsidian",
	displayName = "Obsidian",
	capabilities = {
		tools = {
			{
				name = "open_note",
				description = "Open a note in the Obsidian app",
				inputSchema = {
					type = "object",
					properties = {
						query = {
							type = "string",
							description = "Query to resolve the note by ID, path, or alias",
						},
					},
				},
				handler = function(req, res)
					debug_log("Executing obsidian open with query: " .. (req.params.query or "current buffer"))
					local cmd = "ObsidianOpen"
					if req.params.query then
						cmd = cmd .. " " .. req.params.query
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to open note: " .. tostring(result)):send()
					end
					return res:text("Opened note in Obsidian app"):send()
				end,
			},
			{
				name = "new_note",
				description = "Create a new note",
				inputSchema = {
					type = "object",
					properties = {
						title = {
							type = "string",
							description = "Title of the new note",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianNew"
					if req.params.title then
						cmd = cmd .. " " .. req.params.title
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to create new note: " .. tostring(result)):send()
					end
					return res:text(
						"Created new note" .. (req.params.title and (" with title: " .. req.params.title) or "")
					):send()
				end,
			},
			{
				name = "quick_switch",
				description = "Quickly switch to (or open) another note in your vault",
				inputSchema = {
					type = "object",
					properties = {},
				},
				handler = function(_, res)
					local ok, result = pcall(vim.cmd, "ObsidianQuickSwitch")
					if not ok then
						return res:error("Failed to execute quick switch: " .. tostring(result)):send()
					end
					return res:text("Initiated quick switch"):send()
				end,
			},
			{
				name = "follow_link",
				description = "Follow a note reference under the cursor",
				inputSchema = {
					type = "object",
					properties = {
						mode = {
							type = "string",
							description = "Open mode: vsplit, hsplit, or current (default)",
							enum = { "vsplit", "hsplit" },
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianFollowLink"
					if req.params.mode then
						cmd = cmd .. " " .. req.params.mode
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to follow link: " .. tostring(result)):send()
					end
					return res:text("Followed link" .. (req.params.mode and (" in " .. req.params.mode) or "")):send()
				end,
			},
			{
				name = "backlinks",
				description = "Get a picker list of references to the current buffer",
				inputSchema = {
					type = "object",
					properties = {},
				},
				handler = function(_, res)
					local ok, result = pcall(vim.cmd, "ObsidianBacklinks")
					if not ok then
						return res:error("Failed to get backlinks: " .. tostring(result)):send()
					end
					return res:text("Showed backlinks picker"):send()
				end,
			},
			{
				name = "search_tags",
				description = "Get a picker list of all occurrences of the given tags",
				inputSchema = {
					type = "object",
					properties = {
						tags = {
							type = "array",
							items = {
								type = "string",
							},
							description = "List of tags to search for",
						},
					},
				},
				handler = function(req, res)
					if not req.params.tags or #req.params.tags == 0 then
						return res:error("No tags provided"):send()
					end

					local cmd = "ObsidianTags " .. table.concat(req.params.tags, " ")
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to search tags: " .. tostring(result)):send()
					end
					return res:text("Showed tag search results for: " .. table.concat(req.params.tags, ", ")):send()
				end,
			},
			{
				name = "daily_note",
				description = "Open/create a daily note",
				inputSchema = {
					type = "object",
					properties = {
						offset = {
							type = "number",
							description = "Day offset from today (-1 for yesterday, 1 for tomorrow, etc.)",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianToday"
					if req.params.offset then
						cmd = cmd .. " " .. tostring(req.params.offset)
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to open daily note: " .. tostring(result)):send()
					end
					local day_desc = "today's"
					if req.params.offset then
						if req.params.offset < 0 then
							day_desc = math.abs(req.params.offset) .. " days ago"
						elseif req.params.offset > 0 then
							day_desc = req.params.offset .. " days from now"
						end
					end
					return res:text("Opened " .. day_desc .. " daily note"):send()
				end,
			},
			{
				name = "yesterday",
				description = "Open/create the daily note for the previous working day",
				inputSchema = {
					type = "object",
					properties = {},
				},
				handler = function(_, res)
					local ok, result = pcall(vim.cmd, "ObsidianYesterday")
					if not ok then
						return res:error("Failed to open yesterday's note: " .. tostring(result)):send()
					end
					return res:text("Opened yesterday's daily note"):send()
				end,
			},
			{
				name = "tomorrow",
				description = "Open/create the daily note for the next working day",
				inputSchema = {
					type = "object",
					properties = {},
				},
				handler = function(_, res)
					local ok, result = pcall(vim.cmd, "ObsidianTomorrow")
					if not ok then
						return res:error("Failed to open tomorrow's note: " .. tostring(result)):send()
					end
					return res:text("Opened tomorrow's daily note"):send()
				end,
			},
			{
				name = "list_dailies",
				description = "Open a picker list of daily notes",
				inputSchema = {
					type = "object",
					properties = {
						range = {
							type = "array",
							items = {
								type = "number",
							},
							description = "Day range [start_offset, end_offset]",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianDailies"
					if req.params.range and #req.params.range > 0 then
						cmd = cmd .. " " .. table.concat(req.params.range, " ")
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to list daily notes: " .. tostring(result)):send()
					end
					return res:text("Showed daily notes picker"):send()
				end,
			},
			{
				name = "insert_template",
				description = "Insert a template from the templates folder",
				inputSchema = {
					type = "object",
					properties = {
						name = {
							type = "string",
							description = "Template name (optional, will prompt if not provided)",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianTemplate"
					if req.params.name then
						cmd = cmd .. " " .. req.params.name
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to insert template: " .. tostring(result)):send()
					end
					return res:text("Inserted template" .. (req.params.name and (" '" .. req.params.name .. "'") or ""))
						:send()
				end,
			},
			{
				name = "search",
				description = "Search for (or create) notes in your vault",
				inputSchema = {
					type = "object",
					properties = {
						query = {
							type = "string",
							description = "Search query",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianSearch"
					if req.params.query then
						cmd = cmd .. " " .. req.params.query
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to search: " .. tostring(result)):send()
					end
					return res:text(
						"Executed search" .. (req.params.query and (" for '" .. req.params.query .. "'") or "")
					):send()
				end,
			},
			{
				name = "link_text",
				description = "Link an inline visual selection of text to a note",
				inputSchema = {
					type = "object",
					properties = {
						query = {
							type = "string",
							description = "Query to resolve the target note",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianLink"
					if req.params.query then
						cmd = cmd .. " " .. req.params.query
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to link text: " .. tostring(result)):send()
					end
					return res:text("Linked text to note"):send()
				end,
			},
			{
				name = "link_new",
				description = "Create a new note and link it to an inline visual selection of text",
				inputSchema = {
					type = "object",
					properties = {
						title = {
							type = "string",
							description = "Title of the new note",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianLinkNew"
					if req.params.title then
						cmd = cmd .. " " .. req.params.title
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to create and link new note: " .. tostring(result)):send()
					end
					return res:text(
						"Created and linked new note"
							.. (req.params.title and (" with title '" .. req.params.title .. "'") or "")
					):send()
				end,
			},
			{
				name = "browse_links",
				description = "Collect all links within the current buffer into a picker window",
				inputSchema = {
					type = "object",
					properties = {},
				},
				handler = function(_, res)
					local ok, result = pcall(vim.cmd, "ObsidianLinks")
					if not ok then
						return res:error("Failed to browse links: " .. tostring(result)):send()
					end
					return res:text("Showed links picker"):send()
				end,
			},
			{
				name = "extract_note",
				description = "Extract the visually selected text into a new note and link to it",
				inputSchema = {
					type = "object",
					properties = {
						title = {
							type = "string",
							description = "Title of the new note",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianExtractNote"
					if req.params.title then
						cmd = cmd .. " " .. req.params.title
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to extract note: " .. tostring(result)):send()
					end
					return res:text(
						"Extracted selection to new note"
							.. (req.params.title and (" with title '" .. req.params.title .. "'") or "")
					):send()
				end,
			},
			{
				name = "switch_workspace",
				description = "Switch to another workspace",
				inputSchema = {
					type = "object",
					properties = {
						name = {
							type = "string",
							description = "Workspace name",
						},
					},
				},
				handler = function(req, res)
					if not req.params.name then
						return res:error("Workspace name is required"):send()
					end
					local cmd = "ObsidianWorkspace " .. req.params.name
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to switch workspace: " .. tostring(result)):send()
					end
					return res:text("Switched to workspace '" .. req.params.name .. "'"):send()
				end,
			},
			{
				name = "paste_image",
				description = "Paste an image from the clipboard into the note",
				inputSchema = {
					type = "object",
					properties = {
						name = {
							type = "string",
							description = "Image name (optional)",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianPasteImg"
					if req.params.name then
						cmd = cmd .. " " .. req.params.name
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to paste image: " .. tostring(result)):send()
					end
					return res:text(
						"Pasted image" .. (req.params.name and (" with name '" .. req.params.name .. "'") or "")
					):send()
				end,
			},
			{
				name = "rename",
				description = "Rename the note of the current buffer or reference under the cursor",
				inputSchema = {
					type = "object",
					properties = {
						new_name = {
							type = "string",
							description = "New name for the note",
						},
						dry_run = {
							type = "boolean",
							description = "Perform a dry run without making actual changes",
						},
					},
					required = { "new_name" },
				},
				handler = function(req, res)
					if not req.params.new_name then
						return res:error("New name is required"):send()
					end
					local cmd = "ObsidianRename " .. req.params.new_name
					if req.params.dry_run then
						cmd = cmd .. " --dry-run"
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to rename note: " .. tostring(result)):send()
					end
					return res
						:text(
							"Renamed note to '"
								.. req.params.new_name
								.. "'"
								.. (req.params.dry_run and " (dry run)" or "")
						)
						:send()
				end,
			},
			{
				name = "toggle_checkbox",
				description = "Toggle checkbox state",
				inputSchema = {
					type = "object",
					properties = {},
				},
				handler = function(_, res)
					local ok, result = pcall(vim.cmd, "ObsidianToggleCheckbox")
					if not ok then
						return res:error("Failed to toggle checkbox: " .. tostring(result)):send()
					end
					return res:text("Toggled checkbox"):send()
				end,
			},
			{
				name = "new_from_template",
				description = "Create a new note from a template",
				inputSchema = {
					type = "object",
					properties = {
						title = {
							type = "string",
							description = "Title of the new note",
						},
					},
				},
				handler = function(req, res)
					local cmd = "ObsidianNewFromTemplate"
					if req.params.title then
						cmd = cmd .. " " .. req.params.title
					end
					local ok, result = pcall(vim.cmd, cmd)
					if not ok then
						return res:error("Failed to create note from template: " .. tostring(result)):send()
					end
					return res:text(
						"Created new note from template"
							.. (req.params.title and (" with title '" .. req.params.title .. "'") or "")
					):send()
				end,
			},
			{
				name = "view_toc",
				description = "Load the table of contents of the current note into a picker list",
				inputSchema = {
					type = "object",
					properties = {},
				},
				handler = function(_, res)
					local ok, result = pcall(vim.cmd, "ObsidianTOC")
					if not ok then
						return res:error("Failed to view table of contents: " .. tostring(result)):send()
					end
					return res:text("Showed table of contents"):send()
				end,
			},
		},
		resources = {
			{
				name = "status",
				description = "Get current Obsidian.nvim status",
				uri = "obsidian://status",
				handler = function(_, res)
					-- Try to access the obsidian module to check its status
					-- Use a more reliable approach that doesn't depend on internal API
					local status_text = "Obsidian.nvim Status:\n\n"

					-- Check if we're in an Obsidian buffer
					local in_obsidian_buffer = false
					local _, is_md = pcall(function()
						return vim.bo.filetype == "markdown"
					end)

					if is_md then
						local filename = vim.fn.expand("%:p")
						if filename and filename ~= "" then
							-- Try to execute ObsidianOpen without arguments - succeeds only in Obsidian notes
							local open_ok, _ = pcall(vim.cmd, "ObsidianOpen")
							in_obsidian_buffer = open_ok
						end
					end

					if not in_obsidian_buffer then
						status_text = status_text .. "Not currently in an Obsidian note.\n"
					else
						status_text = status_text .. "Currently in an Obsidian note.\n"
					end

					-- Try to get current workspace info by running a command
					local ok, _ = pcall(vim.cmd, "ObsidianWorkspace")
					if not ok then
						status_text = status_text .. "Unable to retrieve workspace information.\n"
						status_text = status_text .. "Obsidian.nvim is installed but may not be properly configured."
					else
						status_text = status_text .. "Obsidian.nvim is active and configured.\n"
						status_text = status_text .. "Use ObsidianWorkspace command to view or switch workspaces."
					end

					return res:text(status_text):send()
				end,
			},
		},
	},
}

return M
