# Glossary for personal skills and agents

Terms used across the personal skills and agents. Skills and agents link here
instead of restating a definition.

## Code and artifacts

**Application**: Code that owns domain rules and state that outlive one run. If
changing it correctly requires a shared vocabulary, it is an application.
_Avoid_: service, app

**Script**: Code that performs a task and exits. Scripts, infrastructure, and
workflows are not applications and do not need a glossary. _Avoid_: tool

**Project**: The directory that owns a body of code, such as one application or
one infrastructure module.

**Design artifact**: A design document, ADR, glossary, or specification.

**Design document**: A written description of a design. A specification is a
design document.

**Specification**: The agreed request or acceptance criteria that a change is
reviewed against.

**ADR**: An architecture decision record. `domain-modeling` sets when to write
one.

**Project glossary**: The `GLOSSARY.md` that defines terms for one project.

**Repo-wide glossary**: The glossary for terms used by several projects, in the
location the repository documents. `domain-modeling` says how a project glossary
overrides it.

**Seam**: Defined in `codebase-design`.

**Slice**: A narrow but complete path through every layer that can be
demonstrated or verified on its own.

**Ticket**: A slice with the other tickets that block it.

**Frontier**: Every item in a dependency graph that can start now, because
everything it depends on is done or settled. For tickets, the open tickets whose
blockers are all done. For `grill-me`, the decisions whose prerequisites are
settled.

**Default artifact locations**: Used when the repository documents none. Design
documents, including specifications, in `docs/design/<topic>.md`; ADRs in an
existing ADR directory, else `docs/adr/`; a project glossary at the project
root; a repo-wide glossary at `docs/GLOSSARY.md`. Specifications are also looked
for under `specs/`.

**Workstream**: A directory `<workstream root>/<workstream-name>/` for one body
of work across agent conversations, where the workstream root is
`~/.llm-workstreams/`. It holds `<workstream-name>-handoff.md` (the living
handoff document), `scratch/` (temporary and intermediate material), and
`workdirs/` (symlinks to the git working directories involved). `handoff`
creates and fills it, and `load-handoff` resumes from it. A conversation has an
active workstream when the user named one or `handoff` or `load-handoff` set one
up in it. _Avoid_: session (a harness session or conversation is not a
workstream)

**Scratch location**: Where skills write temporary files. The `scratch/`
directory of the active **Workstream** when there is one, otherwise the session
scratchpad directory the harness provides, otherwise `$TMPDIR` (else `/tmp`).
Never the repository workspace. Give the absolute path in full when telling the
user where a file is.

**Domain modeling**: Defined in `domain-modeling`, which only `grill-me` runs.

## Review

**Review scope**: The input that selects which axes a review covers.
`change-review` defines the values.

**Axis**: One independent dimension of a review, Standards or Specification.
Findings from different axes are never merged.

**Coordinator**: The agent or person who builds the review packet, delegates the
reviewers, and evaluates findings.

**Review packet**: The evidence the coordinator gives each reviewer.
`change-review` defines its contents.

**Violation**: A finding that a requirement in the documented standards or an
explicit contract is broken.

**Design suggestion**: A finding about a preference or heuristic. It is never
reported as a violation. Design smells are always design suggestions. _Avoid_:
judgement call

**Design smell**: A structural heuristic from Fowler's _Refactoring_, such as
Duplicated Code or Feature Envy. Checked only in application code.
