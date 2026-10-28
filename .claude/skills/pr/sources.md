# Sources and adaptation

The pr skill is adapted from third-party MIT-licensed content. This file is the
provenance record that the skill definition's `metadata` points to. Update it,
and that `metadata`, whenever the skill is re-synced with upstream or changed in
a way that departs further from it.

## Provenance

Repository: [mattpocock/skills](https://github.com/mattpocock/skills). Snapshot
commit: `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19). License: MIT,
Copyright (c) 2026 Matt Pocock; full text [below](#license). Adapted:
2026-10-23.

| File                               | Last file change                                        | File blob                                  |
| ---------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `skills/engineering/pr/SKILL.md`   | `e484a8095543718ced436b9b49a8160ed4554000` (2026-09-24) | `84dd4fb2f068e9f6282690235d20dd505b418119` |
| `skills/engineering/pr/CREDITS.md` | `a7d038f6bf7f01b516408e95e2fb56e0b338fa6f` (2026-09-24) | `5314bda2fa6005e264c9b5c1de7c425e719dc91f` |

## What was transformed

- **Layout.** Upstream is one `SKILL.md`. Here the behavior lives in
  [procedure.md](procedure.md), beside a thin `SKILL.md` that keeps upstream's
  `credits` metadata.
- **Scope.** A sentence was added: write the body only, and create or update the
  PR only when asked. The template and sections are unchanged.

## What was not carried over

- **`agents/openai.yaml`.** Upstream's Codex display metadata.

## Credits

Upstream states that the Summary section's menu of visuals and its placement
guidance come from Dex Horthy's `show-me` skill in
[humanlayer](https://github.com/humanlayer/humanlayer). I did not verify the
license of that source. Review it before sharing this skill beyond personal use.

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
