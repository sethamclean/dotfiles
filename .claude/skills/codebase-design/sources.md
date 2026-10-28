# Sources and adaptation

The codebase-design skill is adapted from third-party MIT-licensed content. This
file is the provenance record that the skill definition's `metadata` points to.
Update it, and that `metadata`, whenever the skill is re-synced with upstream or
changed in a way that departs further from it.

## Provenance

Repository: [mattpocock/skills](https://github.com/mattpocock/skills). Snapshot
commit: `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19). License: MIT,
Copyright (c) 2026 Matt Pocock; full text [below](#license). Adapted:
2026-10-23.

| File                                              | Last file change                                        | File blob                                  |
| ------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `skills/engineering/codebase-design/SKILL.md`     | `321658273cb1d20b76026717d027d505790106d4` (2026-08-19) | `3f63c8146dd2604b419c929e9876b90c30d410e9` |
| `skills/engineering/codebase-design/DEEPENING.md` | `321658273cb1d20b76026717d027d505790106d4` (2026-08-19) | `cd94075cfd754d147555c5d747a16431ed4c7dd8` |

## What was transformed

- **Layout.** Upstream is one `SKILL.md` plus two reference files. Here the
  behavior lives in [procedure.md](procedure.md) and
  [deepening.md](deepening.md), beside a thin `SKILL.md`.
- **Terms.** The section heading is "Terms" so it is not confused with the
  skills glossary. Upstream's ban on the word "boundary" and its
  rejected-framing entry for it were removed, because the repositories this is
  used in use that word. This skill is the single home for seam, module,
  interface, depth, adapter, leverage, and locality.
- **Scope.** Applies to application code.
- **Test replacement.** Upstream says to delete old unit tests once tests exist
  at the deepened interface. Here the old tests are deleted only after the new
  ones pass and the repository's documented checks, including coverage floors,
  still pass, and tests are never weakened to satisfy coverage.

## What was not carried over

- **`DESIGN-IT-TWICE.md`.** A parallel sub-agent pattern (three or more agents
  each designing the interface under a different constraint). Deferred; it is
  not adopted yet.
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
