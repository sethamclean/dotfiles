---
name: jira-context-resolver
description: Resolve Jira tenant and project context with safe defaults before Atlassian operations.
compatibility: opencode
---

## When to use me

- The task references Jira but cloudId or site context is missing.
- The task needs project defaults before querying issues.
- Atlassian operations are requested with partial environment context.

## Workflow

1. If available, default to `JIRA_CLOUD_ID` for cloudId.
2. If missing, attempt resolution via `agent-jira-cloud-id` using `JIRA_URL`.
3. Default project to `ISINFRA` when project is required and unspecified.
4. Ask one targeted question only if context remains unresolved.
5. Return resolved context and any assumptions.

## Output contract

- Resolved tenant context
- Resolved project context
- Assumptions
- Remaining unknowns
