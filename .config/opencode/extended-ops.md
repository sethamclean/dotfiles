# Extended Ops Reference

Use this file only when triggered by task context from `AGENTS.md`.

## Local Agent Tools
- Prefer standardized local tools in `~/bin` with the `agent-` prefix before ad-hoc scripts when applicable.
- Current tools:
  - `agent-ci-status-head`: show GitHub Actions status for a ref (default `HEAD`), with optional logs via `log_mode=none|failed|all`.

## CI
- Prefer quick status-first checks, then fetch only failed logs if needed.
- Use evidence from run status and logs before proposing fixes.
- Keep diagnosis minimal and falsifiable (observation -> hypothesis -> confirm/falsify).

## Maintenance Rules for `agent-*` Scripts
- If creating or modifying scripts in `~/bin` with the `agent-` prefix:
  - Update `~/bin/agent-tools.yaml` in the same change.
  - Update `Local Agent Tools` in `.config/opencode/AGENTS.md` in the same change.
  - Provide `--help` with usage, arguments, environment variables, safety mode, and examples.
  - Default new scripts to read-only unless explicit instructions require write or destructive behavior.
