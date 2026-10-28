# Sources and adaptation

The improve-codebase-architecture skill is adapted from third-party MIT-licensed
content. This file is the provenance record that the skill definition's
`metadata` points to. Update it, and that `metadata`, whenever the skill is
re-synced with upstream or changed in a way that departs further from it.

## Provenance

Repository: [mattpocock/skills](https://github.com/mattpocock/skills). Snapshot
commit: `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19). License: MIT,
Copyright (c) 2026 Matt Pocock; full text [below](#license). Adapted:
2026-10-23.

| File                                                        | Last file change                                        | File blob                                  |
| ----------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `skills/engineering/improve-codebase-architecture/SKILL.md` | `d80fa0f4ebe0c5714af0adf8670336065233ecc6` (2026-09-17) | `44cc7d3136c44534d68ac523fa6cd37e759d2846` |

## What was transformed

- **Layout.** Upstream is one `SKILL.md` plus `HTML-REPORT.md`. Here the
  behavior lives in [procedure.md](procedure.md), beside a thin `SKILL.md`.
- **Report.** Upstream writes a self-contained HTML file that loads Tailwind and
  Mermaid from public CDNs and opens a browser. Here the report is a Markdown
  file with Mermaid code blocks in the glossary's scratch location, summarized
  in the conversation, with nothing opened and no external scripts.
- **Scope.** Limited to application code.
- **Scan.** Upstream always spawns a sub-agent to walk the codebase. Here a
  sub-agent is used only when session instructions allow.
- **Grilling.** Upstream calls `grilling` and then `domain-modeling` directly.
  Here the call is to `grill-me`, which decides whether domain modeling applies.
- **ADR lookup.** Upstream reads `docs/adr/`. Here ADR directories are found by
  searching for `adr/` directories.
- **Alternative interfaces.** Upstream calls `codebase-design`'s design-it-twice
  pattern. Here that is not adopted; options are compared in the grilling.

## What was not carried over

- **`HTML-REPORT.md`.** The HTML scaffold, diagram patterns, and styling
  guidance. Replaced by the Markdown report.
- **Domain-model side effects inline.** Glossary updates and ADRs are left to
  `grill-me` and `domain-modeling`.
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
