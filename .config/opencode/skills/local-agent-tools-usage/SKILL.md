---
name: local-agent-tools-usage
description: Use standardized local agent-* tools and enforce maintenance rules for script changes.
compatibility: opencode
---

## When to use me

- The task references tools in `/root/bin` with the `agent-` prefix.
- The task involves creating or modifying `agent-*` scripts.
- The task needs local helper tooling instead of ad hoc scripts.

## Workflow

1. Prefer existing `agent-*` tools before ad hoc commands.
2. If modifying `agent-*` scripts, update `/root/bin/agent-tools.yaml` in the same change.
3. Update `.config/opencode/AGENTS.md` Local Agent Tools section in the same change.
4. Ensure script `--help` includes usage, args, env vars, safety mode, and examples.
5. Keep default behavior read-only unless explicitly instructed otherwise.

## Output contract

- Selected tool and rationale
- Changes made
- Required companion updates
- Verification notes
