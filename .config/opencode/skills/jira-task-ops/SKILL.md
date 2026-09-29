---
name: jira-task-ops
description: Operate Jira tasks safely with jira-acli for backlog review, issue updates, status transitions, and ticket creation.
compatibility: opencode
---

## When to use me

- The user wants to view backlog items or filter board tasks.
- The user wants to update an existing Jira issue field.
- The user wants to transition an issue to a new status.
- The user wants to create a new Jira ticket.

## Workflow

1. Execute Jira operations directly in the current agent.
   - Do not call nested `Task` delegation for Jira commands.
   - Keep results concise and do not paste raw wide-table output.
2. Resolve context from `jira-acli` defaults and user input.
3. Start read-only unless the user asked for a mutation.
   - Read operations: `project`, `jql`, `issue`, `transitions`.
   - Mutations: `update`, `status`, `create`.
4. For backlog requests, return status and URL with each item.
   - Prefer `jira-acli --text backlog` (or `jira-acli --text backlog <PROJECT> --limit <N>`) for faster compact output.
   - Use `statusCategory != Done ORDER BY updated DESC` only when the user explicitly asks for custom JQL.
   - Return each item as: `issueKey`, `summary`, `status`, `url` (optionally `updated`).
5. For issue updates, inspect issue details before changing fields.
   - `jira-acli --text issue <KEY>`
   - Then run `jira-acli update <KEY> [field options]`.
6. For status changes, resolve valid transitions first.
   - `jira-acli --text transitions <KEY>`
   - Then run `jira-acli status <KEY> "<transition>"`.
7. For ticket creation, require explicit summary and type.
   - `jira-acli create --project <KEY> --type <TYPE> --summary "<TEXT>" [options]`.
8. Report actions clearly.
   - Show the exact command used.
   - Return key fields from results (issue key, summary, status, url).

## Command reference

- List default project issues:
  - `jira-acli --text project`
- List active backlog with status (fast path):
  - `jira-acli --text backlog`
  - `jira-acli --text backlog PROJ --limit 20`
- Run custom JQL:
  - `jira-acli --text jql "statusCategory != Done ORDER BY updated DESC"`
  - `jira-acli --text jql "statusCategory != Done ORDER BY updated DESC" --full` (when status is required)
- Show issue details:
  - `jira-acli --text issue <ISSUE-KEY>`
- Update fields:
  - `jira-acli update <ISSUE-KEY> --summary "New summary" --priority High --labels platform,automation`
- List transitions:
  - `jira-acli --text transitions <ISSUE-KEY>`
- Move status:
  - `jira-acli status <ISSUE-KEY> "In Progress"`
- Create ticket:
  - `jira-acli create --project <PROJECT-KEY> --type <TYPE> --summary "Example ticket" --description "Details"`

## Output contract

- Operation requested
- Resolved project and assumptions
- Exact command executed
- Result summary
  - Backlog/project/jql lists: `issueKey`, `summary`, `status`, `url` (optionally `updated`)
  - Single issue/mutations: `issueKey`, `summary`, `status`
- Follow-up options (next transitions, additional fields, linked work)
