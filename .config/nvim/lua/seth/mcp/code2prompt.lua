-- code2prompt.lua
-- This file defines a native MCP server for converting project code into prompts for LLMs.
-- The server uses the external 'code2prompt' CLI tool to analyze and process codebases.

local M = {}

M.server = {
	name = "code2prompt",
	displayName = "Code to Prompt Server",
	capabilities = {
		tools = {
			{
				name = "extract_code",
				description = [[
Extracts code from files and formats it specifically for use in LLM prompts.
Creates context-aware, well-structured output ideal for feeding into AI models.
Supports markdown, json, or xml formats with optional line numbers, git diff info, and path customization.
Perfect for generating code-aware prompts or adding codebase context to your LLM conversations.
                ]],
				inputSchema = {
					type = "object",
					properties = {
						path = {
							type = "string",
							description = "Path to the codebase directory to process.",
						},
						include = {
							type = "string",
							description = "Optional patterns to include.",
						},
						exclude = {
							type = "string",
							description = "Optional patterns to exclude.",
						},
						output_format = {
							type = "string",
							description = "Output format: markdown, json, or xml.",
							enum = { "markdown", "json", "xml" },
							default = "markdown",
						},
						line_numbers = {
							type = "boolean",
							description = "Whether to add line numbers to the source code.",
							default = false,
						},
						absolute_paths = {
							type = "boolean",
							description = "If true, paths in output will be absolute instead of relative.",
							default = false,
						},
						hidden = {
							type = "boolean",
							description = "Include hidden directories and files.",
							default = false,
						},
						no_ignore = {
							type = "boolean",
							description = "Skip .gitignore rules.",
							default = false,
						},
						sort = {
							type = "string",
							description = "Sort order for files.",
							enum = { "name_asc", "name_desc", "date_asc", "date_desc" },
							default = "name_asc",
						},
					},
					required = { "path" },
				},
				handler = function(req, res)
					local args = {}

					-- Required path argument
					table.insert(args, '"' .. req.params.path .. '"')

					-- Optional parameters
					if req.params.include then
						table.insert(args, '--include "' .. req.params.include .. '"')
					end
					if req.params.exclude then
						table.insert(args, '--exclude "' .. req.params.exclude .. '"')
					end
					if req.params.output_format then
						table.insert(args, "--output-format " .. req.params.output_format)
					end
					if req.params.line_numbers then
						table.insert(args, "--line-numbers")
					end
					if req.params.absolute_paths then
						table.insert(args, "--absolute-paths")
					end
					if req.params.hidden then
						table.insert(args, "--hidden")
					end
					if req.params.no_ignore then
						table.insert(args, "--no-ignore")
					end
					if req.params.sort then
						table.insert(args, "--sort " .. req.params.sort)
					end

					-- Build and execute command with clipboard disabled
					local cmd = "code2prompt --no-clipboard " .. table.concat(args, " ")
					local output = vim.fn.system(cmd)

					if vim.v.shell_error ~= 0 then
						return res:error("Error executing code2prompt: " .. output):send()
					end

					return res:text(output):send()
				end,
			},
			{
				name = "list_directory",
				description = [[
Lists and organizes project files in a tree structure optimized for AI code understanding.
Helps LLMs explore codebases by providing clear directory layouts with customizable filters.
Perfect for initial project exploration or creating codebase navigation prompts.
                ]],
				inputSchema = {
					type = "object",
					properties = {
						path = {
							type = "string",
							description = "Path to the directory to list.",
						},
						include = {
							type = "string",
							description = "Optional patterns to include.",
						},
						exclude = {
							type = "string",
							description = "Optional patterns to exclude.",
						},
						hidden = {
							type = "boolean",
							description = "Include hidden directories and files.",
							default = false,
						},
						sort = {
							type = "string",
							description = "Sort order for files.",
							enum = { "name_asc", "name_desc", "date_asc", "date_desc" },
							default = "name_asc",
						},
					},
					required = { "path" },
				},
				handler = function(req, res)
					local args = {}

					-- Required path and full directory tree flag
					table.insert(args, "--full-directory-tree")
					table.insert(args, '"' .. req.params.path .. '"')

					-- Optional parameters
					if req.params.include then
						table.insert(args, '--include "' .. req.params.include .. '"')
					end
					if req.params.exclude then
						table.insert(args, '--exclude "' .. req.params.exclude .. '"')
					end
					if req.params.hidden then
						table.insert(args, "--hidden")
					end
					if req.params.sort then
						table.insert(args, "--sort " .. req.params.sort)
					end

					-- Build and execute command with clipboard disabled
					local cmd = "code2prompt --no-clipboard " .. table.concat(args, " ")
					local output = vim.fn.system(cmd)

					if vim.v.shell_error ~= 0 then
						return res:error("Error executing code2prompt: " .. output):send()
					end

					return res:text(output):send()
				end,
			},
			{
				name = "get_git_diff",
				description = [[
Analyzes git changes and formats them specifically for LLM code review and understanding.
Generates clear, contextual diffs that help AI models understand code changes and their impact.
Perfect for explaining code modifications, reviewing changes, or providing change context to LLMs.
Supports diff between branches or current changes in markdown, json, or xml formats.
                ]],
				inputSchema = {
					type = "object",
					properties = {
						path = {
							type = "string",
							description = "Path to the codebase directory.",
						},
						branches = {
							type = "array",
							items = {
								type = "string",
							},
							minItems = 2,
							maxItems = 2,
							description = "Two branch names to diff between.",
						},
						output_format = {
							type = "string",
							description = "Output format: markdown, json, or xml.",
							enum = { "markdown", "json", "xml" },
							default = "markdown",
						},
					},
					required = { "path" },
				},
				handler = function(req, res)
					local args = {}

					-- Required path argument
					table.insert(args, '"' .. req.params.path .. '"')

					-- Add diff flag
					if req.params.branches then
						table.insert(
							args,
							'--git-diff-branch "' .. req.params.branches[1] .. '" "' .. req.params.branches[2] .. '"'
						)
					else
						table.insert(args, "--diff")
					end

					-- Optional format
					if req.params.output_format then
						table.insert(args, "--output-format " .. req.params.output_format)
					end

					-- Build and execute command
					local cmd = "code2prompt " .. table.concat(args, " ")
					local output = vim.fn.system(cmd)

					if vim.v.shell_error ~= 0 then
						return res:error("Error executing code2prompt: " .. output):send()
					end

					return res:text(output):send()
				end,
			},
		},
		resources = {},
		resourceTemplates = {},
	},
}

return M
