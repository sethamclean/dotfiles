-- Knowledge Base MCP Server Implementation
--
-- This MCP server presents a static directory of notes and reference materials
-- as a contextual data source for the LLM. It leverages tools like `rg` (ripgrep)
-- and `fd` to efficiently search through this knowledge base.
--
-- USAGE:
-- The Knowledge Base server is designed to be auto-discovered by LLMs during
-- context analysis. When keywords related to "knowledge", "notes", "documentation",
-- "reference", or "search information" appear in user queries, the LLM should
-- recognize the Knowledge Base server as an appropriate tool.

local M = {}

-- Default knowledge base path - user should configure this
local kb_path = vim.fn.expand("~/Documents/obsidian-vault/main")
local debug_mode = false

-- Debug function to log info only when debug mode is enabled
local function debug_log(msg, level)
	level = level or vim.log.levels.INFO
	if not debug_mode then
		return
	end
	vim.notify("[KB MCP] " .. msg, level)
end

-- This flag will be set to true when the server is successfully registered
M.is_registered = false

-- Initialize function that will be called from init.lua
function M.init()
	debug_log("Knowledge Base MCP server initialization started")
	-- Allow the server to be auto-discovered by LLMs
	M.server.metadata = {
		priority = "high",
		keywords = {
			"knowledge",
			"notes",
			"documentation",
			"reference",
			"search",
			"information",
			"obsidian",
			"wiki",
			"lookup",
			"find",
			"research",
			"personal knowledge",
		},
		description = "Knowledge Base server for personal notes and documentation",
		suggested_invocation = "When users ask to search for information or reference materials in their notes, automatically consider using the Knowledge Base tools to search through personal documentation.",
	}

	-- Concise LLM guidance to encourage automatic discovery
	M.server.llm_hints = {
		auto_detect_patterns = {
			"notes",
			"knowledge base",
			"documentation",
			"reference",
			"my files",
			"find information",
			"personal wiki",
			"did I write",
			"lookup",
		},
		use_cases = {
			"Finding information in personal notes",
			"Searching through user's documentation",
			"Retrieving context from personal knowledge base",
			"Combining personal notes with workspace context",
		},
		preferred_tools = {
			primary = "search_knowledge_base",
			browsing = "list_knowledge_files",
			specific = "get_file_content",
		},
		integration_strategy = "Combine knowledge base results with workspace context when relevant",
	}

	debug_log("Knowledge Base MCP server initialized with metadata and LLM guide")
	return true
end

-- Default knowledge base path - user should configure this
local kb_path = vim.fn.expand("~/Documents/obsidian-vault/main")
local debug_mode = false

-- Debug function to log info only when debug mode is enabled
local function debug_log(msg, level)
	level = level or vim.log.levels.INFO
	if not debug_mode then
		return
	end
	vim.notify("[KB MCP] " .. msg, level)
end

-- Check if knowledge base directory exists
local function kb_dir_exists()
	return vim.fn.isdirectory(kb_path) == 1
end

-- Cache for recently accessed content
local content_cache = {}
local cache_max_size = 50 -- Maximum number of items to keep in cache
local cache_ttl = 300 -- Cache TTL in seconds

-- Simple LRU cache implementation
local function cache_get(key)
	local item = content_cache[key]
	if item and os.time() - item.timestamp < cache_ttl then
		item.timestamp = os.time() -- Update timestamp on access
		return item.data
	end
	return nil
end

local function cache_set(key, data)
	-- Simple cleanup if cache gets too large
	if vim.tbl_count(content_cache) >= cache_max_size then
		local oldest_key = nil
		local oldest_time = os.time()

		for k, v in pairs(content_cache) do
			if v.timestamp < oldest_time then
				oldest_time = v.timestamp
				oldest_key = k
			end
		end

		if oldest_key then
			content_cache[oldest_key] = nil
		end
	end

	content_cache[key] = {
		data = data,
		timestamp = os.time(),
	}
end

-- Function to run shell commands and return output
local function run_command(cmd)
	local handle = io.popen(cmd)
	if not handle then
		return nil, "Failed to execute command: " .. cmd
	end

	local result = handle:read("*a")
	handle:close()
	return result
end

-- Function to safely escape shell arguments
local function shell_escape(str)
	return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

-- Change the knowledge base path
local function set_kb_path(path)
	if path and vim.fn.isdirectory(path) == 1 then
		kb_path = path
		return true, "Knowledge base path updated to: " .. path
	else
		return false, "Invalid path or directory does not exist: " .. tostring(path)
	end
end

-- Set debug mode function
function M.set_debug_mode(enabled)
	debug_mode = enabled
	debug_log("Debug mode " .. (enabled and "enabled" or "disabled"))
end

-- Define the knowledge base MCP server
M.server = {
	name = "knowledge_base",
	displayName = "Knowledge Base",
	capabilities = {
		tools = {
			{
				name = "set_knowledge_base_path",
				description = "Set the path to the knowledge base directory",
				inputSchema = {
					type = "object",
					properties = {
						path = {
							type = "string",
							description = "Full path to the knowledge base directory",
						},
					},
					required = { "path" },
				},
				handler = function(req, res)
					local success, msg = set_kb_path(req.params.path)
					if success then
						return res:text(msg):send()
					else
						return res:error(msg)
					end
				end,
			},
			{
				name = "search_knowledge_base",
				description = "Search the knowledge base using ripgrep (rg)",
				inputSchema = {
					type = "object",
					properties = {
						query = {
							type = "string",
							description = "Search query",
						},
						file_pattern = {
							type = "string",
							description = "Optional file pattern (e.g., '*.md', '*.txt')",
						},
						case_sensitive = {
							type = "boolean",
							description = "Whether the search should be case sensitive",
							default = false,
						},
						context_lines = {
							type = "integer",
							description = "Number of context lines to include",
							default = 2,
						},
						max_results = {
							type = "integer",
							description = "Maximum number of results to return",
							default = 20,
						},
					},
					required = { "query" },
				},
				handler = function(req, res)
					if not kb_dir_exists() then
						return res:error("Knowledge base directory not found: " .. kb_path)
					end

					local query = req.params.query
					local file_pattern = req.params.file_pattern or ""
					local case_sensitive = req.params.case_sensitive or false
					local context_lines = req.params.context_lines or 2
					local max_results = req.params.max_results or 20

					-- Construct rg command
					local cmd = "cd " .. shell_escape(kb_path) .. " && rg"

					-- Add options
					if not case_sensitive then
						cmd = cmd .. " -i"
					end

					-- Add context
					cmd = cmd .. " -C" .. tostring(context_lines)

					-- Add max count
					cmd = cmd .. " -m " .. tostring(max_results)

					-- Add file pattern if specified
					if file_pattern and file_pattern ~= "" then
						cmd = cmd .. " -g " .. shell_escape(file_pattern)
					end

					-- Add query
					cmd = cmd .. " " .. shell_escape(query)

					-- Add nice formatting
					cmd = cmd .. " --heading --color never"

					debug_log("Executing command: " .. cmd)

					local result, err = run_command(cmd)
					if not result then
						return res:error("Search failed: " .. (err or "unknown error"))
					end

					if result == "" then
						return res:text("No results found for query: " .. query):send()
					end

					return res:text("Search results for '" .. query .. "':\n\n" .. result):send()
				end,
			},
			{
				name = "list_knowledge_files",
				description = "List files in the knowledge base using fd",
				inputSchema = {
					type = "object",
					properties = {
						pattern = {
							type = "string",
							description = "File pattern to match (e.g., '*.md')",
						},
						directory = {
							type = "string",
							description = "Subdirectory within knowledge base to search",
						},
						max_depth = {
							type = "integer",
							description = "Maximum directory depth to search",
							default = 10,
						},
					},
				},
				handler = function(req, res)
					if not kb_dir_exists() then
						return res:error("Knowledge base directory not found: " .. kb_path)
					end

					local pattern = req.params.pattern or ""
					local directory = req.params.directory or ""
					local max_depth = req.params.max_depth or 10

					local search_path = kb_path
					if directory and directory ~= "" then
						search_path = vim.fn.expand(kb_path .. "/" .. directory)
						if vim.fn.isdirectory(search_path) ~= 1 then
							return res:error("Subdirectory not found: " .. directory)
						end
					end

					-- Construct fd command
					local cmd = "cd " .. shell_escape(kb_path) .. " && fd"

					-- Add max depth
					cmd = cmd .. " --max-depth " .. tostring(max_depth)

					-- Add pattern if specified
					if pattern and pattern ~= "" then
						cmd = cmd .. " -e " .. shell_escape(pattern:gsub("*.", ""))
					end

					-- Add directory if specified
					if directory and directory ~= "" then
						cmd = cmd .. " . " .. shell_escape(directory)
					end

					-- Sort by modification time, newest first
					cmd = cmd .. " --color never"

					debug_log("Executing command: " .. cmd)

					local result, err = run_command(cmd)
					if not result then
						return res:error("File listing failed: " .. (err or "unknown error"))
					end

					if result == "" then
						return res:text("No files found matching criteria"):send()
					end

					-- Format the output as a list
					local files = {}
					for file in result:gmatch("[^\r\n]+") do
						table.insert(files, file)
					end

					local output = "Knowledge Base Files:\n"
					for i, file in ipairs(files) do
						output = output .. "- " .. file .. "\n"
					end

					return res:text(output):send()
				end,
			},
			{
				name = "get_file_content",
				description = "Retrieve the content of a specific file from the knowledge base",
				inputSchema = {
					type = "object",
					properties = {
						file_path = {
							type = "string",
							description = "Path to the file within the knowledge base",
						},
					},
					required = { "file_path" },
				},
				handler = function(req, res)
					if not kb_dir_exists() then
						return res:error("Knowledge base directory not found: " .. kb_path)
					end

					local file_path = req.params.file_path
					local full_path = vim.fn.expand(kb_path .. "/" .. file_path)

					-- Security check to prevent directory traversal
					if not vim.startswith(vim.fn.fnamemodify(full_path, ":p"), vim.fn.fnamemodify(kb_path, ":p")) then
						return res:error("Invalid file path: Attempted directory traversal")
					end

					if vim.fn.filereadable(full_path) ~= 1 then
						return res:error("File not found or not readable: " .. file_path)
					end

					-- Check cache first
					local cached = cache_get(full_path)
					if cached then
						debug_log("Returning cached content for: " .. file_path)
						return res:text(cached):send()
					end

					-- Read file content
					local f, err = io.open(full_path, "r")
					if not f then
						return res:error("Failed to open file: " .. (err or "unknown error"))
					end

					local content = f:read("*all")
					f:close()

					-- Cache the content
					cache_set(full_path, content)

					-- Determine the MIME type based on file extension
					local ext = vim.fn.fnamemodify(full_path, ":e"):lower()
					local mime_type = "text/plain"

					if ext == "md" or ext == "markdown" then
						mime_type = "text/markdown"
					elseif ext == "json" then
						mime_type = "application/json"
					elseif ext == "html" or ext == "htm" then
						mime_type = "text/html"
					elseif ext == "csv" then
						mime_type = "text/csv"
					elseif ext == "yaml" or ext == "yml" then
						mime_type = "application/yaml"
					elseif ext == "txt" then
						mime_type = "text/plain"
					end

					return res:text(content, mime_type):send()
				end,
			},
			{
				name = "get_kb_summary",
				description = "Get a summary of the knowledge base structure and content",
				handler = function(req, res)
					if not kb_dir_exists() then
						return res:error("Knowledge base directory not found: " .. kb_path)
					end

					-- Get total files count
					local total_cmd = "find " .. shell_escape(kb_path) .. " -type f | wc -l"
					local total_files, err = run_command(total_cmd)
					if not total_files then
						return res:error("Failed to count files: " .. (err or "unknown error"))
					end
					total_files = total_files:gsub("%s+", "")

					-- Get file types distribution
					local types_cmd = "find "
						.. shell_escape(kb_path)
						.. " -type f | grep -o '\\.[^.\\/:*?\"<>|\\r\\n]*$' | sort | uniq -c | sort -rn"
					local file_types, err = run_command(types_cmd)
					if not file_types then
						file_types = "Unable to determine file types"
					end

					-- Get newest files
					local newest_cmd = "find "
						.. shell_escape(kb_path)
						.. " -type f -printf '%T@ %p\\n' | sort -rn | head -5 | cut -d' ' -f2-"
					local newest_files, err = run_command(newest_cmd)
					if not newest_files then
						newest_files = "Unable to determine newest files"
					else
						-- Format newest files
						local formatted = "Recently Modified:\n"
						for line in newest_files:gmatch("[^\r\n]+") do
							-- Strip the base path to show relative paths
							line = line:gsub("^" .. vim.pesc(kb_path) .. "/", "")
							formatted = formatted .. "- " .. line .. "\n"
						end
						newest_files = formatted
					end

					-- Format the output
					local summary = "Knowledge Base Summary\n"
						.. "====================\n\n"
						.. "Location: "
						.. kb_path
						.. "\n"
						.. "Total Files: "
						.. total_files
						.. "\n\n"
						.. "File Types:\n"
						.. file_types
						.. "\n\n"
						.. newest_files

					return res:text(summary):send()
				end,
			},
		},
		resources = {
			{
				name = "summary",
				uri = "knowledge_base://summary",
				description = "Summary of the knowledge base content",
				handler = function(req, res)
					if not kb_dir_exists() then
						return res:text("Knowledge base directory not configured or not found: " .. kb_path):send()
					end

					-- Count files by type
					local cmd = "find "
						.. shell_escape(kb_path)
						.. " -type f | grep -o '\\.[^.\\/:*?\"<>|\\r\\n]*$' | sort | uniq -c | sort -rn"
					local result, err = run_command(cmd)

					local summary = "Knowledge Base at " .. kb_path .. "\n\n"

					if result and result ~= "" then
						summary = summary .. "File types:\n" .. result .. "\n"
					else
						summary = summary .. "Unable to get file type statistics\n"
					end

					return res:text(summary):send()
				end,
			},
		},
		resourceTemplates = {
			{
				name = "file_content",
				uriTemplate = "knowledge_base://file/{file_path}",
				description = "Content of a specific file in the knowledge base",
				handler = function(req, res)
					if not kb_dir_exists() then
						return res:error("Knowledge base directory not found: " .. kb_path)
					end

					local file_path = req.params.file_path
					if not file_path then
						return res:error("File path not specified")
					end

					local full_path = vim.fn.expand(kb_path .. "/" .. file_path)

					-- Security check to prevent directory traversal
					if not vim.startswith(vim.fn.fnamemodify(full_path, ":p"), vim.fn.fnamemodify(kb_path, ":p")) then
						return res:error("Invalid file path: Attempted directory traversal")
					end

					if vim.fn.filereadable(full_path) ~= 1 then
						return res:error("File not found or not readable: " .. file_path)
					end

					-- Check cache first
					local cached = cache_get(full_path)
					if cached then
						debug_log("Returning cached content for: " .. file_path)
						return res:text(cached):send()
					end

					-- Read file content
					local f, err = io.open(full_path, "r")
					if not f then
						return res:error("Failed to open file: " .. (err or "unknown error"))
					end

					local content = f:read("*all")
					f:close()

					-- Cache the content
					cache_set(full_path, content)

					-- Determine MIME type based on file extension
					local ext = vim.fn.fnamemodify(full_path, ":e"):lower()
					local mime_type = "text/plain"

					if ext == "md" or ext == "markdown" then
						mime_type = "text/markdown"
					elseif ext == "json" then
						mime_type = "application/json"
					elseif ext == "html" or ext == "htm" then
						mime_type = "text/html"
					elseif ext == "csv" then
						mime_type = "text/csv"
					elseif ext == "yaml" or ext == "yml" then
						mime_type = "application/yaml"
					elseif ext == "txt" then
						mime_type = "text/plain"
					end

					return res:text(content, mime_type):send()
				end,
			},
			{
				name = "directory_listing",
				uriTemplate = "knowledge_base://dir/{dir_path}",
				description = "List files in a knowledge base directory",
				handler = function(req, res)
					if not kb_dir_exists() then
						return res:error("Knowledge base directory not found: " .. kb_path)
					end

					local dir_path = req.params.dir_path or ""
					local search_dir = kb_path

					if dir_path and dir_path ~= "" then
						search_dir = vim.fn.expand(kb_path .. "/" .. dir_path)

						-- Security check to prevent directory traversal
						if
							not vim.startswith(vim.fn.fnamemodify(search_dir, ":p"), vim.fn.fnamemodify(kb_path, ":p"))
						then
							return res:error("Invalid directory path: Attempted directory traversal")
						end

						if vim.fn.isdirectory(search_dir) ~= 1 then
							return res:error("Directory not found: " .. dir_path)
						end
					end

					-- List files using ls command
					local cmd = "ls -la " .. shell_escape(search_dir)
					local result, err = run_command(cmd)

					if not result then
						return res:error("Failed to list directory: " .. (err or "unknown error"))
					end

					local output = "Directory listing for: " .. (dir_path == "" and "/" or dir_path) .. "\n\n" .. result
					return res:text(output):send()
				end,
			},
			{
				name = "search_results",
				uriTemplate = "knowledge_base://search/{query}",
				description = "Search results for a query in the knowledge base",
				handler = function(req, res)
					if not kb_dir_exists() then
						return res:error("Knowledge base directory not found: " .. kb_path)
					end

					local query = req.params.query
					if not query or query == "" then
						return res:error("Search query not specified")
					end

					-- Construct rg command for basic search
					local cmd = "cd "
						.. shell_escape(kb_path)
						.. " && rg -i -C2 --heading --color never "
						.. shell_escape(query)

					local result, err = run_command(cmd)
					if not result then
						return res:error("Search failed: " .. (err or "unknown error"))
					end

					if result == "" then
						return res:text("No results found for query: " .. query):send()
					end

					return res:text("Search results for '" .. query .. "':\n\n" .. result):send()
				end,
			},
		},
	},
}

return M
