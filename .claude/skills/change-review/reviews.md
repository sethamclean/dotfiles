# Reviewer rules

Rules shared by the `standards-reviewer` and `spec-reviewer` agents. This file
is for reviewers; the coordinator follows `procedure.md`. Each reviewer reads
this file first, then applies its own axis.

## Boundaries

- Work from the coordinator's review packet. Tie every finding to the supplied
  change; read surrounding code only to understand a contract.
- Do not edit files, execute commands, invoke other agents, or claim tests were
  run. Ask the coordinator for evidence that read and search tools cannot reach.
- Do not repeat formatting, lint, or other findings that automated checks
  already establish.
- Do not compare your findings with the other axis, and do not invent findings
  to fill a quota.
- Do not include sensitive content in the report.

## When you cannot review

If a required input is missing or unreadable, start your reply with "Review not
performed: <reason>" and report no findings. Do not report partial findings: the
coordinator must be able to tell "not performed" from "no actionable findings".

## Report

Start with the scope and the sources consulted. Then list actionable findings
ordered by impact. Each finding has:

- A file and a line in the source snapshot, not in the diff file. Take the line
  number from the file itself, as the Read tool numbers it, never from a diff
  hunk or from a line count within the diff file.
- Evidence from the change and the cited standard or requirement.
- The concrete consequence and a focused correction direction.

Keep the report to about 400 words unless findings need more to be actionable.
End with unverified items, a finding count, and the most severe finding. When
there are no findings, say "no actionable <axis> findings".
