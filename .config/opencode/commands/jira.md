---
description: Jira task operations via jira-acli
agent: jira-ops
subtask: true
---

Use `jira-acli` (not `jira`) to execute Jira operation for: `$ARGUMENTS`.

If the request is backlog/listing and no custom JQL is explicitly requested, prefer `jira-acli --text backlog` (optionally with `--limit`).

If the request is custom JQL and status is needed, use `jira-acli --text jql "<JQL>" --full`.

For list outputs, include `url` with each item.

Return concise results only.
