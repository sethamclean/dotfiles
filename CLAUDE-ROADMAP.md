# Claude skills and agents roadmap

Tracks the personal Claude Code skills and agents in `.claude/skills/` and
`.claude/agents/`. Repository-specific standards and skills belong in each
repository, not here. It records status and next steps only.

**Status:** `Gap` (not covered) → `Drafted` (written, not yet committed and
stowed) → `Adopted` (committed, stowed, and used in real work). `Deferred` items
have a recorded reason to wait.

## Coverage

| Area                                  | Status   | Location                                           | Next step                                                                                 |
| ------------------------------------- | -------- | -------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `grill-me` skill                      | Drafted  | `.claude/skills/grill-me/`                         | Trial on three real design discussions (see below)                                        |
| `domain-modeling` skill               | Drafted  | `.claude/skills/domain-modeling/`                  | Trial with `grill-me`                                                                     |
| `change-review` skill                 | Drafted  | `.claude/skills/change-review/`                    | Run on two or three real merged changes                                                   |
| Standards reviewer                    | Drafted  | `.claude/agents/standards-reviewer.md`             | Add evals                                                                                 |
| Specification reviewer                | Drafted  | `.claude/agents/spec-reviewer.md`                  | Add evals                                                                                 |
| Shared reviewer rules                 | Drafted  | `.claude/skills/change-review/reviews.md`          | Add evals with the reviewers                                                              |
| `instruction-review` skill            | Drafted  | `.claude/skills/instruction-review/`               | Re-record eval results (earlier runs not carried)                                         |
| Security reviewer                     | Gap      | —                                                  | Add a role or route the built-in `/security-review`                                       |
| Correctness review                    | Gap      | —                                                  | Decide whether to add a bug-finding axis                                                  |
| `to-spec` skill                       | Drafted  | `.claude/skills/to-spec/`                          | Trial after a `grill-me` session                                                          |
| `to-tickets` skill                    | Drafted  | `.claude/skills/to-tickets/`                       | Trial on a real spec                                                                      |
| `implement` and `tdd` skills          | Drafted  | `.claude/skills/implement/`, `.claude/skills/tdd/` | Trial on one ticket; compare `tdd` with the repo's test standards                         |
| `pr` skill                            | Drafted  | `.claude/skills/pr/`                               | Trial on a real change                                                                    |
| `handoff` skill                       | Drafted  | `.claude/skills/handoff/`                          | Trial at a conversation boundary                                                          |
| `load-handoff` skill                  | Drafted  | `.claude/skills/load-handoff/`                     | Trial: resume from a handoff in a fresh conversation (original skill, no upstream source) |
| `codebase-design` skill               | Drafted  | `.claude/skills/codebase-design/`                  | Trial through `improve-codebase-architecture`                                             |
| `improve-codebase-architecture` skill | Drafted  | `.claude/skills/improve-codebase-architecture/`    | Run on one application; adopt or remove                                                   |
| Debugging procedure                   | Gap      | —                                                  | Deferred: `diagnosing-bugs` is the candidate                                              |
| Specialist standards reviewers        | Deferred | —                                                  | See [specialist reviewers](#deferred-specialist-reviewers)                                |

## Open items

- [ ] Trial `grill-me` and its conditional `domain-modeling` pass on one script
      change, one application without a glossary, and one application with one.
      Adopt or remove each based on observed sessions.
- [ ] Add evals for the standards and specification reviewers, reusing the
      baseline from the specialist pilot below.
- [ ] Check whether the design-smell heuristics in `standards-reviewer` add
      useful findings without padding, using those evals.
- [ ] Add a security review role or route the built-in `/security-review` from
      `change-review`.
- [ ] Neither reviewer hunts for correctness bugs. Decide whether to add a third
      axis or route the built-in `/code-review`.
- [ ] Check in a fresh session whether `change-review` or the built-in
      `/code-review` activates for "review this PR", and adjust the description.
- [ ] Decide whether `instruction-review` should compare restated terms with the
      skills glossary, with an eval case containing a planted mismatch. Today it
      catches that only when the request asks for cross-file consistency.
- [x] Re-run `instruction-review` on the skills and agents after the 2026-10-23
      fixes (done three times; the last findings are applied).
- [x] Make the skills available in OpenCode: it discovers `~/.claude/skills`
      itself, so no per-skill allowlist is kept. `opencode.jsonc` allows reads of
      `~/.claude` and `~/.llm-workstreams`; org-synced skills are off through
      `syncClaudeAiSkills: false` in `.claude/settings.json`.
- [ ] Verify OpenCode v2 honors `disable-model-invocation` (documented, not
      tested), and that it ignores `~/.claude/skills/.trash/`.
- [ ] Trial the workstream layout in `handoff`
      (`~/.llm-workstreams/<workstream-name>/` with
      `<workstream-name>-handoff.md`, `scratch/`, and `workdirs/`): resume from
      the handoff in a fresh conversation with `load-handoff`, and check that
      skills write to the active workstream's `scratch/`. How a fresh
      conversation learns which workstream is active is not defined yet beyond
      the user naming it or reading the handoff.
- [ ] Trial `to-spec`, `to-tickets`, `implement`, `tdd`, `pr`, and `handoff` on
      one real piece of work, end to end, and adopt or remove each.
- [ ] Run `improve-codebase-architecture` on one application (for example the
      largest), then a deepening through `grill-me`, and check that the Markdown
      report and the test-replacement rule hold up.
- [ ] Deferred: parallel exploration of alternative interfaces (upstream's
      `DESIGN-IT-TWICE.md`, three or more sub-agents). Not adopted yet.
- [ ] Deferred: an HTML report for `improve-codebase-architecture`; the Markdown
      report replaces it unless a browser view proves worth the external
      scripts.
- [ ] Debugging procedure: gap, ignored for now. `diagnosing-bugs` is the
      candidate; the later phases (hypothesise, instrument, fix, cleanup) were
      not read.
- [ ] Not adopted yet: `retro` (feedback) and `git-guardrails-claude-code`
      (hook-based git guardrails; review its substring matching first).
- [ ] Repo-specific items were identified and are ignored for now: a pull
      request template and the repository's ticket destination. They belong in
      the repository roadmaps.

Provenance: `grill-me`, `domain-modeling`, `to-spec`, `to-tickets`, `implement`,
`tdd`, `pr`, `handoff`, and the review refinements come from `mattpocock/skills`
at commit `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (MIT). See each skill's
`sources.md`.

## Deferred: specialist reviewers

Decide whether conditional specialist reviewers improve findings enough to
justify additional context, latency, and coordination. No new roles or review
requirements are approved.

Candidates, keeping the standards reviewer as the default:

- **Concurrency and lifecycle:** ownership, synchronization, cancellation,
  backpressure, shutdown, cleanup, and uncertain effects. Triggers: workers,
  queues, leases, async or thread boundaries, and resource lifetimes.
- **Infrastructure and configuration:** Terraform identity and lifecycle,
  rendered manifests, overlays, environment differences, and promotion controls.
  Trigger: substantial Terraform or GitOps changes. Evaluate separately.

- [ ] Select representative changes and record the broad-review baseline.
- [ ] Pilot concurrency and lifecycle review first, with explicit scope and
      concrete execution scenarios.
- [ ] Define generalist and specialist ownership to avoid duplicates and gaps
      when a specialist is not selected.
- [ ] Compare actionable findings, false positives, missed contracts, duplicate
      work, context use, latency, and coordination effort.
- [ ] Retain, revise, or reject each role and its triggers.
