# Sources and adaptation

The to-spec skill is adapted from third-party MIT-licensed content. This file is
the provenance record that the skill definition's `metadata` points to. Update
it, and that `metadata`, whenever the skill is re-synced with upstream or
changed in a way that departs further from it.

## Provenance

Repository: [mattpocock/skills](https://github.com/mattpocock/skills). Snapshot
commit: `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19). License: MIT,
Copyright (c) 2026 Matt Pocock; full text [below](#license). Adapted:
2026-10-23.

| File                                  | Last file change                                        | File blob                                  |
| ------------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| `skills/engineering/to-spec/SKILL.md` | `5c89081d4bbeb3d039a42093653f90bb698d780e` (2026-08-19) | `3f52599ae2a4347aee5a07432c2707518e691a7f` |

## What was transformed

- **Layout.** Upstream is one `SKILL.md`. Here the behavior lives in
  [procedure.md](procedure.md), beside a thin `SKILL.md`.
- **Destination.** Upstream publishes the spec to the project issue tracker with
  a `ready-for-agent` label. Here the spec is saved as a design document, in the
  location the repository documents, else the glossary's default, confirmed with
  the user, and an existing file is never overwritten.
- **Consent.** Running the skill is consent to write the spec; the path is
  confirmed first.
- **Template.** Unchanged from upstream.

## What was not carried over

- **Tracker publishing and triage labels.** They depend on upstream's
  `/setup-matt-pocock-skills` configuration, which is not adapted.
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
