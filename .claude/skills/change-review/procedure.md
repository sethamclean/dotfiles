# Change review

This process guides the coordinator of implementation-change reviews. The
`standards-reviewer` and `spec-reviewer` agents follow their own procedures and
the shared [reviewer rules](reviews.md) using the supplied review packet; they
do not need to load this coordination process. For reviews of LLM instructions,
prompts, skills, or agent definitions, use the `instruction-review` skill. Other
review types should use task-appropriate criteria rather than require a code
diff. Terms are defined in the [glossary](../GLOSSARY.md).

## Choose the review scope

The review scope is an input: **full** (Standards and Specification),
**standards only**, or **specification only**. If the requester did not provide
one, ask before doing anything else. Sections below that name an axis apply only
to the axes in scope.

A full review uses two independent assessments: **Standards** and
**Specification**. A correct implementation can violate standards; well-designed
code can implement the wrong behavior. Keep their findings separate so one does
not mask the other.

## Prepare explicit inputs

The coordinating agent or person supplies both reviewers with:

- Repository root and the exact scope: base/head revisions, staged changes, or
  unstaged changes. Resolve and record immutable commit IDs for revision
  reviews.
- The exact diff command, changed paths, and its output inline or in a readable
  diff artifact written to the **Scratch location** in the
  [glossary](../GLOSSARY.md). A command alone is insufficient for
  command-prohibited reviewers. Identify the captured working-tree state;
  refresh the evidence if it changes during review.
- A readable source snapshot or worktree, created in the **Scratch location**
  when it must be created, matching the reviewed head or captured state,
  including relevant surrounding implementation and tests. Identify its path
  separately from the live checkout when they differ.
- Relevant verification results, including failed or unrun checks.
- The glossary definitions the reviewers need (application, script, design
  suggestion, and design smell), copied from the [glossary](../GLOSSARY.md).
- Applicable scoped instructions and any known limits on the review.

Use a merge-base comparison for branch changes when appropriate. Do not silently
substitute `HEAD` for staged or working-tree changes. Reviewers may read
surrounding code to understand a contract, but should tie findings to the
supplied change. Read surrounding source from the matching snapshot. If it is
unavailable, report the resulting review limitation; do not treat a different
checkout state as authoritative evidence for the supplied diff.

The standards reviewer finds the repository's standards from the repository
root. If none of `CODING_STANDARDS.md`, `CONTRIBUTING.md`, and `AGENTS.md`
exists, tell the user and ask whether to proceed against project contracts only,
to provide a standards path, or to abort. Record the choice on the packet's
`Standards:` line.

Give the specification reviewer the agreed request, acceptance criteria, or
specification path. Locate it in this order and record which source was used:

1. A path supplied by the requester, such as the `Spec:` line of a ticket.
2. Issue or ticket references in the commit messages, such as `#123` or
   `Closes #45`.
3. A specification file in the design-document location the repository
   documents, or the **Default artifact locations** in the
   [glossary](../GLOSSARY.md), matching the branch or feature name.
4. Ask the requester.

Include the issue text or a readable copy of the specification in the packet;
the specification reviewer cannot fetch it. If none exists, report specification
review as unavailable; do not invent requirements from the implementation.

Compact packet example (placeholders must be replaced with actual evidence):

```text
Root: /absolute/path/to/repository
Scope: staged changes captured at <timestamp>; unstaged changes excluded
Diff command: git diff --cached --no-ext-diff --no-color
Diff evidence: /absolute/path/to/captured-staged.diff (readable by both reviewers)
Source snapshot: /absolute/path/to/matching-source (matches the captured index)
Changed paths: <paths from that diff>
Standards: <applicable instruction, standards, and project-contract paths>
Specification: <agreed request or acceptance-criteria text/path>
Checks: <exact command and result>; <unrun check and reason>
Terms: <glossary definitions the reviewers need>
Limits: <unavailable evidence or unverified behavior>
```

Keep the packet focused; reviewers can read surrounding source as needed. Do not
include secrets in captured evidence. If no agreed specification exists, use the
unavailable-specification outcome above rather than filling in a guessed one.

## Validate before delegating

Confirm that each base and head revision resolves to a commit, that the captured
diff is not empty, and that any supplied source snapshot matches the reviewed
head or captured state. Stop and report an unresolved revision, an empty diff,
or a mismatched snapshot to the requester; do not start reviewers on invalid
input. An unavailable snapshot is not a mismatch: continue and report the
limitation as described above.

## Delegate or run the assessments explicitly

Use the `standards-reviewer` and `spec-reviewer` agents. Definitions alone do
not guarantee invocation.

Whenever the host exposes the reviewer agents, delegate: run them in separate
contexts, in parallel if possible. Only when it does not, perform and label the
assessments separately, noting that they were not independent subagent reviews.
If a reviewer replies "Review not performed", supply the missing input and rerun
it, or report that axis as not reviewed; never report it as "no actionable
findings". Do not give one reviewer the other's conclusions before its
assessment is complete.

Prefer a session that did not write the change. If the authoring session
performs the review, label it as non-independent in the report, as with the
non-subagent case above.

## Report and follow up

Present separate **Standards** and **Specification** results for the axes in
scope, including review scope, actionable findings, and verification gaps. Each
finding needs a location, evidence, consequence, and cited standard or
requirement. Distinguish correctness or contract violations from contextual
design suggestions. Omit formatting, lint, and other findings already
established by automated checks; report their status and failures separately
without treating a passing gate as a complete review.

Reviewers report; they do not edit code, run deployments, or commit changes. The
coordinator evaluates findings, fixes accepted issues, and runs focused
verification. Substantial fixes need one follow-up review limited to the
affected contract and the accepted findings. Do not repeat reviews until none
are reported; new design suggestions on later passes are expected and are not
grounds for another pass. If the follow-up still reports a **Violation** or a
**Missing** or **incorrect** specification finding, stop and ask the requester.
Never manufacture findings to fill a quota. State “no actionable findings” when
that is the result, and identify missing evidence instead of claiming
unperformed verification.

Next: when `implement` requested the review, return the results to it. Otherwise
offer to fix the accepted findings, and when the review is clean offer to write
the pull request body with the `pr` skill.
