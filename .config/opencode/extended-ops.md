# Extended Ops Reference

Use this file only when triggered by task context from `AGENTS.md`.

## Atlassian
- If tenant context is required and the user did not provide one, default to `cloudId=$JIRA_CLOUD_ID` when available.
- If `JIRA_CLOUD_ID` is unavailable, attempt resolution via `agent-jira-cloud-id` using `JIRA_URL` before asking the user.
- Ask the user for `cloudId` or site only if environment/default resolution is unavailable or target site differs.
- If a Jira project is required and unspecified, default to `ISINFRA`.

## Local Agent Tools
- Prefer standardized local tools in `/root/bin` with the `agent-` prefix before ad-hoc scripts when applicable.
- Current tools:
  - `agent-ci-status-head`: show GitHub Actions status for a ref (default `HEAD`), with optional logs via `log_mode=none|failed|all`.
  - `agent-jira-cloud-id`: resolve Jira `cloudId` from `JIRA_URL` (read-only).

## CI
- Prefer quick status-first checks, then fetch only failed logs if needed.
- Use evidence from run status and logs before proposing fixes.
- Keep diagnosis minimal and falsifiable (observation -> hypothesis -> confirm/falsify).

## Maintenance Rules for `agent-*` Scripts
- If creating or modifying scripts in `/root/bin` with the `agent-` prefix:
  - Update `/root/bin/agent-tools.yaml` in the same change.
  - Update `Local Agent Tools` in `.config/opencode/AGENTS.md` in the same change.
  - Provide `--help` with usage, arguments, environment variables, safety mode, and examples.
  - Default new scripts to read-only unless explicit instructions require write or destructive behavior.
