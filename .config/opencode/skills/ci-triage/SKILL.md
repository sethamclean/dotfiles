---
name: ci-triage
description: Diagnose CI failures with a status-first workflow and minimal evidence-backed hypotheses.
compatibility: opencode
---

## When to use me

- The user asks why CI failed or asks for workflow triage.
- A pull request or branch has failing checks.
- The task requires quick pass/fail diagnosis before proposing fixes.

## Workflow

1. Gather run status first.
2. Inspect only failed logs unless broader context is required.
3. State observations, then hypothesis, then confirm or falsify.
4. Propose the smallest fix direction.
5. List minimal verification commands.

## Output contract

- CI status summary
- Evidence
- Likely root cause
- Suggested fix direction
- Validation checks
