# Sources and adaptation

The to-tickets skill is adapted from third-party MIT-licensed content. This file
is the provenance record that the skill definition's `metadata` points to.
Update it, and that `metadata`, whenever the skill is re-synced with upstream or
changed in a way that departs further from it.

## Provenance

Repository: [mattpocock/skills](https://github.com/mattpocock/skills). Snapshot
commit: `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19). License: MIT,
Copyright (c) 2026 Matt Pocock; full text [below](#license). Adapted:
2026-10-23.

| File                                     | Last file change                                        | File blob                                  |
| ---------------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `skills/engineering/to-tickets/SKILL.md` | `9e2abf8611a345efbf779aacb171cff015bcdeb6` (2026-10-06) | `9b77a01db9460c99c22d03c910c349f890f12c0e` |

## What was transformed

- **Layout.** Upstream is one `SKILL.md`. Here the behavior lives in
  [procedure.md](procedure.md), beside a thin `SKILL.md`.
- **Publishing.** Upstream's step 5 depends on a tracker configured by
  `/setup-matt-pocock-skills`, with `.scratch/<feature>/issues/` for local files
  and a `ready-for-agent` label. Here the tracker comes from the repository's
  own docs or the user, and files go in a directory beside the specification.
  The ticket templates are otherwise unchanged; the status in the file template
  is `open`.
- **Terms.** Slice and ticket are defined in the skills glossary.

## What was not carried over

- **`ready-for-agent` triage label and tracker setup.** They depend on
  upstream's `/setup-matt-pocock-skills`, which is not adapted.
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
