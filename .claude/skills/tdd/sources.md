# Sources and adaptation

The tdd skill is adapted from third-party MIT-licensed content. This file is the
provenance record that the skill definition's `metadata` points to. Update it,
and that `metadata`, whenever the skill is re-synced with upstream or changed in
a way that departs further from it.

## Provenance

Repository: [mattpocock/skills](https://github.com/mattpocock/skills). Snapshot
commit: `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19). License: MIT,
Copyright (c) 2026 Matt Pocock; full text [below](#license). Adapted:
2026-10-23.

| File                                | Last file change                                        | File blob                                  |
| ----------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `skills/engineering/tdd/SKILL.md`   | `3f599139104dfceabc7754eeb91319802f85e042` (2026-10-07) | `01eadaa34e7c9a63a67d6dc3cce1cc81b0e49985` |
| `skills/engineering/tdd/tests.md`   | `43ea0884b07a3e67a5a07f025ce92aefa983177b` (2026-06-29) | `7ab86479f925a1f9e8ba680af33cb3b12e015381` |
| `skills/engineering/tdd/mocking.md` | `62f43a18177be6ec82da242e59ffbc490a4c22ea` (2026-04-28) | `71cbfee674d93244ce81d1830b930ca9a69200bd` |

## What was transformed

- **Layout.** Upstream is one `SKILL.md` plus two reference files. Here the
  behavior lives in [procedure.md](procedure.md), beside a thin `SKILL.md`;
  `tests.md` and `mocking.md` are unchanged.
- **Refactoring.** Upstream excludes refactoring from the loop and assigns it to
  its review stage. Here refactoring is a separate step taken only when green,
  after the cycle or as a fix after `change-review`.
- **Glossary.** Seam is defined in `codebase-design`, and the skills glossary
  points there; this skill refers to it.

## What was not carried over

- **The `codebase-design` reference.** Upstream calls a vocabulary skill for
  module-depth terms; it is not adapted.
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
