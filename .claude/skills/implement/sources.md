# Sources and adaptation

The implement skill is adapted from third-party MIT-licensed content. This file
is the provenance record that the skill definition's `metadata` points to.
Update it, and that `metadata`, whenever the skill is re-synced with upstream or
changed in a way that departs further from it.

## Provenance

Repository: [mattpocock/skills](https://github.com/mattpocock/skills). Snapshot
commit: `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19). License: MIT,
Copyright (c) 2026 Matt Pocock; full text [below](#license). Adapted:
2026-10-23.

| File                                    | Last file change                                        | File blob                                  |
| --------------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `skills/engineering/implement/SKILL.md` | `6d6a5b9072f47ee7ba1d972d8ce0ee98b7ed4394` (2026-10-07) | `bd49e472984c7b99aac40286fdae749bb955a842` |

## What was transformed

- **Layout.** Upstream is one `SKILL.md`. Here the behavior lives in
  [procedure.md](procedure.md), beside a thin `SKILL.md`.
- **References.** Upstream fetches a ticket from an issue tracker. Here the
  reference is read from wherever the user points.
- **Checks.** Upstream runs typechecking, single test files, and the full test
  suite. Here the repository's documented checks are used, narrowest first and
  the full set once at the end.
- **Review.** Upstream calls its `code-review` skill. Here the call is to
  `change-review`.
- **Committing.** Upstream commits to the current branch. Here nothing is
  committed, pushed, or amended unless the user asks.

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
