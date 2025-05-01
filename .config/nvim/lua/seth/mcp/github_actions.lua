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
        handler = function(req, res)
          local result = vim.fn.system("gh workflow list")
          if vim.v.shell_error ~= 0 then
            return res:error("Failed to list workflows. Make sure you're in a GitHub repository and the gh CLI is authenticated.")
          end
          return res:text(result):send()
        end
      },
      {
        name = "list_runs",
        description = "List recent workflow runs in the current repository",
        inputSchema = {
          type = "object",
          properties = {
            workflow = {
              type = "string",
              description = "Optional workflow name or file to filter by (e.g., 'ci.yml')"
            },
            limit = {
              type = "number",
              description = "Maximum number of runs to show (default: 10)"
            }
          }
        },
        handler = function(req, res)
          local limit = req.params.limit or 10
          local cmd = string.format("gh run list --limit %d", limit)
          
          if req.params.workflow then
            cmd = cmd .. string.format(" --workflow %s", req.params.workflow)
          end
          
          local result = vim.fn.system(cmd)
          if vim.v.shell_error ~= 0 then
            return res:error("Failed to list workflow runs. Make sure you're in a GitHub repository and the gh CLI is authenticated.")
          end
          return res:text(result):send()
        end
      },
      {
        name = "view_run",
        description = "View details of a specific workflow run",
        inputSchema = {
          type = "object",
          properties = {
            run_id = {
              type = "string",
              description = "Run ID of the workflow to view"
            }
          },
          required = {"run_id"}
        },
        handler = function(req, res)
          local run_id = req.params.run_id
          local result = vim.fn.system(string.format("gh run view %s", run_id))
          if vim.v.shell_error ~= 0 then
            return res:error("Failed to view workflow run. Make sure the run ID is valid.")
          end
          return res:text(result):send()
        end
      },
      {
        name = "view_job_logs",
        description = "View logs of a specific job in a workflow run",
        inputSchema = {
          type = "object",
          properties = {
            run_id = {
              type = "string",
              description = "Run ID of the workflow containing the job"
            },
            job_name = {
              type = "string",
              description = "Name of the job to view logs for (optional - if not provided, will show logs for all jobs)"
            }
          },
          required = {"run_id"}
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
        end
      },
      {
        name = "rerun_workflow",
        description = "Re-run a specific workflow run",
        inputSchema = {
          type = "object",
          properties = {
            run_id = {
              type = "string",
              description = "Run ID of the workflow to re-run"
            },
            failed_only = {
              type = "boolean",
              description = "Re-run only failed jobs (default: false)"
            }
          },
          required = {"run_id"}
        },
        handler = function(req, res)
          local run_id = req.params.run_id
          local cmd = string.format("gh run rerun %s", run_id)
          
          if req.params.failed_only then
            cmd = cmd .. " --failed"
          end
          
          local result = vim.fn.system(cmd)
          if vim.v.shell_error ~= 0 then
            return res:error("Failed to re-run workflow. Make sure the run ID is valid.")
          end
          return res:text("Workflow re-run initiated successfully."):send()
        end
      }
    },
    resources = {
      {
        name = "latest_runs",
        uri = "github://actions/runs",
        description = "Get the latest workflow runs for the current repository",
        handler = function(req, res)
          local result = vim.fn.system("gh run list --limit 5")
          if vim.v.shell_error ~= 0 then
            return res:error("Failed to get latest runs. Make sure you're in a GitHub repository and the gh CLI is authenticated.")
          end
          return res:text(result):send()
        end
      }
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
        end
      }
    }
  }
}

return M
