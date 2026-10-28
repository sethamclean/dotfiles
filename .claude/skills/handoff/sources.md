# Sources and adaptation

The handoff skill is adapted from third-party MIT-licensed content. This file is
the provenance record that the skill definition's `metadata` points to. Update
it, and that `metadata`, whenever the skill is re-synced with upstream or
changed in a way that departs further from it.

## Provenance

Repository: [mattpocock/skills](https://github.com/mattpocock/skills). Snapshot
commit: `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19). License: MIT,
Copyright (c) 2026 Matt Pocock; full text [below](#license). Adapted:
2026-10-23.

| File                                   | Last file change                                        | File blob                                  |
| -------------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `skills/productivity/handoff/SKILL.md` | `0f5e033ebc47b142f5ffa56a582ede6d9d9bada3` (2026-10-06) | `a224edc643a20ddb989f9bca1547440169159810` |

## What was transformed

- **Layout.** Upstream is one `SKILL.md`. Here the behavior lives in
  [procedure.md](procedure.md), beside a thin `SKILL.md` that keeps upstream's
  `argument-hint` and user-only invocation.
- **Wording.** Upstream's sentences are kept, with the changes below.
- **Location.** Upstream saves one file to the OS temporary directory. Here the
  handoff is one living file in a **Workstream** directory, with `scratch/` and
  `workdirs/` beside it. The skill finds or creates the workstream without
  overwriting another one, links the git working directories involved, copies
  referenced scratch files into the workstream, keeps the previous version of
  the handoff in `scratch/`, and records each working directory's branch,
  `HEAD`, and number of changed paths on one line in the handoff.

## What was not carried over

- **`agents/openai.yaml`.** Upstream's Codex display metadata.

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
