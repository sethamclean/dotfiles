-- GitHub MCP Server for Avante.nvim
-- This server provides tools to interact with GitHub Actions via the gh CLI

local M = {}

-- Define the GitHub MCP server schema
M.server = {
	name = "github_actions",
	displayName = "GitHub Actions",
	capabilities = {
		tools = {
			{
				name = "list_workflows",
				description = "List all workflows in the current repository",
				handler = function(_, res)
					local result = vim.fn.system("gh workflow list")
					if vim.v.shell_error ~= 0 then
						return res:error(
							"Failed to list workflows. Make sure you're in a GitHub repository and the gh CLI is authenticated."
						)
					end
					return res:text(result):send()
				end,
			},
			{
				name = "list_runs",
				description = "List recent workflow runs in the current repository",
				inputSchema = {
					type = "object",
					properties = {
						workflow = {
							type = "string",
							description = "Optional workflow name or file to filter by (e.g., 'ci.yml')",
						},
						limit = {
							type = "number",
							description = "Maximum number of runs to show (default: 10)",
						},
					},
				},
				handler = function(req, res)
					local limit = req.params.limit or 10
					local cmd = string.format("gh run list --limit %d", limit)

					if req.params.workflow then
						cmd = cmd .. string.format(" --workflow %s", req.params.workflow)
					end

					local result = vim.fn.system(cmd)
					if vim.v.shell_error ~= 0 then
						return res:error(
							"Failed to list workflow runs. Make sure you're in a GitHub repository and the gh CLI is authenticated."
						)
					end
					return res:text(result):send()
				end,
			},
			{
				name = "view_run",
				description = "View details of a specific workflow run",
				inputSchema = {
					type = "object",
					properties = {
						run_id = {
							type = "string",
							description = "Run ID of the workflow to view",
						},
					},
					required = { "run_id" },
				},
				handler = function(req, res)
					local run_id = req.params.run_id
					local result = vim.fn.system(string.format("gh run view %s", run_id))
					if vim.v.shell_error ~= 0 then
						return res:error("Failed to view workflow run. Make sure the run ID is valid.")
					end
					return res:text(result):send()
				end,
			},
			{
				name = "view_job_logs",
				description = "View logs of a specific job in a workflow run",
				inputSchema = {
					type = "object",
					properties = {
						run_id = {
							type = "string",
							description = "Run ID of the workflow containing the job",
						},
						job_name = {
							type = "string",
							description = "Name of the job to view logs for (optional - if not provided, will show logs for all jobs)",
						},
					},
					required = { "run_id" },
				},
				handler = function(req, res)
					local run_id = req.params.run_id
					local cmd = string.format("gh run view %s --log", run_id)

					if req.params.job_name then
						cmd = string.format("gh run view %s --job %s --log", run_id, req.params.job_name)
					end

					local result = vim.fn.system(cmd)
					if vim.v.shell_error ~= 0 then
						return res:error("Failed to view job logs. Make sure the run ID and job name are valid.")
					end
					return res:text(result):send()
				end,
			},
			{
				name = "rerun_workflow",
				description = "Re-run a specific workflow run",
				inputSchema = {
					type = "object",
					properties = {
						run_id = {
							type = "string",
							description = "Run ID of the workflow to re-run",
						},
						failed_only = {
							type = "boolean",
							description = "Re-run only failed jobs (default: false)",
						},
					},
					required = { "run_id" },
				},
				handler = function(req, res)
					local run_id = req.params.run_id
					local cmd = string.format("gh run rerun %s", run_id)

					if req.params.failed_only then
						cmd = cmd .. " --failed"
					end

					_ = vim.fn.system(cmd)
					if vim.v.shell_error ~= 0 then
						return res:error("Failed to re-run workflow. Make sure the run ID is valid.")
					end
					return res:text("Workflow re-run initiated successfully."):send()
				end,
			},
			{
				name = "get_commit_workflow_logs",
				description = "Get logs for all workflows run on a specific commit",
				inputSchema = {
					type = "object",
					properties = {
						commit_sha = {
							type = "string",
							description = "Commit SHA to get workflow runs for",
						},
						repo = {
							type = "string",
							description = "Repository in the format 'owner/repo' (optional - defaults to current repo)",
						},
					},
					required = { "commit_sha" },
				},
				handler = function(req, res)
					local commit_sha = req.params.commit_sha
					local repo_flag = ""

					if req.params.repo then
						repo_flag = string.format(" -R %s", req.params.repo)
					end

					-- First, find all workflow runs for the commit
					local cmd = string.format(
						"gh run list%s --commit %s --limit 50 --json databaseId,name,workflowName,status,conclusion",
						repo_flag,
						commit_sha
					)

					local result = vim.fn.system(cmd)
					if vim.v.shell_error ~= 0 then
						return res:error("Failed to list workflow runs for commit. Make sure the commit SHA is valid.")
					end

					-- Parse the JSON result
					local ok, runs = pcall(vim.fn.json_decode, result)
					if not ok or not runs or #runs == 0 then
						return res:text("No workflow runs found for commit " .. commit_sha):send()
					end

					local response = string.format("Workflow Runs for Commit %s:\n\n", commit_sha)

					-- Process each workflow run
					for i, run in ipairs(runs) do
						response = response
							.. string.format(
								"%d. %s (%s) - %s/%s\n",
								i,
								run.workflowName,
								run.name,
								run.status,
								run.conclusion or "pending"
							)

						-- Get the logs for this run
						local log_cmd = string.format("gh run view %s%s --log", run.databaseId, repo_flag)
						local log_result = vim.fn.system(log_cmd)

						if vim.v.shell_error == 0 then
							response = response .. "\nLogs:\n"

							-- Only include the first 50 lines of logs per workflow to avoid excessive output
							local log_lines = {}
							for line in log_result:gmatch("[^\r\n]+") do
								table.insert(log_lines, line)
								if #log_lines >= 50 then
									table.insert(log_lines, "... (truncated, use view_job_logs for complete logs)")
									break
								end
							end

							response = response .. table.concat(log_lines, "\n") .. "\n"
						else
							response = response .. "\nLogs not available for this run.\n"
						end

						response = response .. "\n" .. string.rep("-", 80) .. "\n\n"
					end

					return res:text(response):send()
				end,
			},
		},
		resources = {
			{
				name = "latest_runs",
				uri = "github://actions/runs",
				description = "Get the latest workflow runs for the current repository",
				handler = function(_, res)
					local result = vim.fn.system("gh run list --limit 5")
					if vim.v.shell_error ~= 0 then
						return res:error(
							"Failed to get latest runs. Make sure you're in a GitHub repository and the gh CLI is authenticated."
						)
					end
					return res:text(result):send()
				end,
			},
		},
		resourceTemplates = {
			{
				name = "workflow_runs",
				uriTemplate = "github://actions/workflows/{workflow}/runs",
				description = "Get runs for a specific workflow",
				handler = function(req, res)
					local workflow = req.params.workflow
					local result = vim.fn.system(string.format("gh run list --workflow %s --limit 5", workflow))
					if vim.v.shell_error ~= 0 then
						return res:error("Failed to get workflow runs. Make sure the workflow exists.")
					end
					return res:text(result):send()
				end,
			},
		},
	},
}

return M
