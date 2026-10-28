# Sources and adaptation

The grill-me skill is adapted from third-party MIT-licensed content. This file
is the provenance record that the skill definition's `metadata` points to.
Update it, and that `metadata`, whenever the skill is re-synced with upstream or
changed in a way that departs further from it.

## Provenance

Upstream splits this skill in two: `grill-me`, the user-facing entry point, and
`grilling`, the model-invoked skill it delegates to. This skill takes its name
from the first and its behavior from the second.

| Field            | `grilling` (behavior)                                     | `grill-me` (name)                                       |
| ---------------- | --------------------------------------------------------- | ------------------------------------------------------- |
| Repository       | [mattpocock/skills](https://github.com/mattpocock/skills) | same                                                    |
| Path             | `skills/productivity/grilling/SKILL.md`                   | `skills/productivity/grill-me/SKILL.md`                 |
| Snapshot commit  | `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19)   | same                                                    |
| Last file change | `95249b0b49782349740fd9b8c6ce32b4e59e497a` (2026-10-07)   | `fcf0071560d32913c9d4f820e0d7ca467c881619` (2026-08-15) |
| File blob        | `df69d9936880cd3314c28858c6c52f48db23b856`                | `3947ff9c4ad980d14fc07fccbf659d47c114e81d`              |
| Upstream page    | [grilling at the snapshot][grilling-page]                 | [grill-me at the snapshot][grill-me-page]               |

License: MIT, Copyright (c) 2026 Matt Pocock; full text [below](#license).
Adapted: 2026-10-22.

[grilling-page]:
  https://github.com/mattpocock/skills/blob/5beb35b040e3de97e54fa9e386d7e42d15c295c2/skills/productivity/grilling/SKILL.md
[grill-me-page]:
  https://github.com/mattpocock/skills/blob/5beb35b040e3de97e54fa9e386d7e42d15c295c2/skills/productivity/grill-me/SKILL.md

## What was transformed

- **Rename.** Upstream's two skills became one, named `grill-me` after
  upstream's user-facing entry point rather than `grilling`, the model-invoked
  skill that entry point delegates to. The skill was first adapted here as
  `grilling` and renamed before merge on 2026-10-22: the skill `name`, its
  heading, and its directory all changed from `grilling` to `grill-me`. Upstream
  text that refers to `grilling`, including skills that invoke it such as
  `grill-with-docs`, means this skill; a ported caller must invoke `grill-me`.
- **Layout.** Upstream is one `SKILL.md` per skill. Here the behavior lives in
  [procedure.md](procedure.md), beside a thin `SKILL.md`.
- **Description.** Rewritten to name the trigger phrases ("grill me", "grill
  this") in the definition's `description`, which is what the harness uses to
  select the skill.
- **Structure.** Upstream's prose paragraphs became five numbered workflow
  steps. The wording of each rule is kept close to upstream.
- **Delegation.** Upstream always dispatches a subagent to look up facts. Here
  delegation happens only when session instructions allow it, consistent with
  sessions that restrict delegation; otherwise the agent looks the fact up
  itself.
- **Round format.** The emoji question and answer markers were replaced with
  plain text (`**Q1. title**` and `Recommended:`). Numbering, one recommended
  answer per question, and "yes accepts the recommendation" are unchanged.
- **Scope and consent step (2026-10-23).** Not in upstream. Before round 1 the
  skill finds the target project and its design artifacts, decides whether
  domain modeling applies, and asks for consent to write design artifacts.
  Upstream's `grill-with-docs` always runs `grilling` and `domain-modeling`
  together; here `domain-modeling`, adapted in its own
  [record](../domain-modeling/sources.md), runs only for applications that have
  or warrant a glossary. Artifact locations come from the repository's own
  `CODING_STANDARDS.md`, `CONTRIBUTING.md`, or `AGENTS.md`, or the glossary's
  default artifact locations when those are silent. A specification is not
  written here; the skill offers `to-spec` instead.

## What was not carried over

- **The `grill-me` wrapper body.** Upstream's `grill-me` only invokes `grilling`
  and sets `disable-model-invocation: true`, so the model never selects the
  entry point itself. Here the single skill keeps model invocation, as
  upstream's `grilling` does, so a "grill me" request can activate it without
  the user typing the skill name.
- **`agents/openai.yaml`.** Upstream's Codex display metadata for both skills.
  Neither supported harness reads it.
- **Related upstream skills.** `improve-codebase-architecture` builds on
  `grilling` and depends on upstream conventions that this setup does not use.
  `grill-with-docs` is not carried over as its own skill; its combination of
  `grilling` and `domain-modeling` is conditional here, as described below.

## Checking for upstream changes

A `sha` that differs from the table's file blob means that upstream file has
changed since the snapshot. Compare it before re-syncing:

```bash
for s in grilling grill-me; do
  gh api "repos/mattpocock/skills/contents/skills/productivity/$s/SKILL.md" \
    --jq "\"$s \(.sha)\""
done
```

## License

MIT License

Copyright (c) 2026 Matt Pocock

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
