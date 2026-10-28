# Implement

Implement the work described in the specification or tickets the user names.

If the user passes a ticket or specification reference, read it and state its
title before starting. If the reference is ambiguous, ask.

For a ticket, read its `Spec:` line and use that specification throughout,
including for the review. If the ticket has no `Spec:` line, ask the user for
the specification path. If it says `None`, tell `change-review` that
specification review is unavailable. Check its `Blocked by` entries: a blocker
is done when its file ticket's `Status` is `done` or its tracker issue is
closed. If any blocker is not done, name it and ask whether to continue.

Before changing anything, record the base revision: the current commit and
whether the tree has uncommitted changes.

Call the Skill tool with "tdd" for every slice that adds or changes behavior.
Start from the specification's Testing Decisions section when it has one; `tdd`
confirms the seams with the user before any test is written.

Skip `tdd` without asking when the work only updates documents. For any change
to code, including configuration and scripts, do not skip `tdd` or write tests
after the implementation without the user's approval. When you think `tdd` does
not apply (for example, there is no seam to test through), say why and ask. Name
any approved skip in the final summary.

When the work deepens a cluster of shallow modules, read
[deepening.md](../codebase-design/deepening.md) first and follow its rule for
replacing old tests: delete them only after the new interface tests and the
repository's documented checks, including coverage floors, pass.

Run the repository's documented checks as you go: the narrowest relevant test or
check often, and the full set once at the end. Find the commands in
`CODING_STANDARDS.md`, `CONTRIBUTING.md`, or `AGENTS.md`. If none are
documented, look in the README, build files, and CI configuration, state the
commands you will run, and ask if they are unclear.

When done, call the Skill tool with "change-review" to review the work, passing
review scope `full`, the specification path, and the base revision you recorded.
After the review, offer to write the pull request body with the `pr` skill.

When the user accepts the work, set a file ticket's `Status` to `done`. For a
tracker issue, offer to close it and close it only if the user agrees. Then name
the tickets now on the [frontier](../GLOSSARY.md) and recommend one, or say that
none remain.

If tickets remain and the work will continue in a fresh conversation, suggest
running `handoff` here and `load-handoff` there.

Do not commit, push, or amend unless the user asks.
