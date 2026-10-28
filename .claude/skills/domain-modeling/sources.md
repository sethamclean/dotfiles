# Sources and adaptation

The domain-modeling skill is adapted from third-party MIT-licensed content. This
file is the provenance record that the skill definition's `metadata` points to.
Update it, and that `metadata`, whenever the skill is re-synced with upstream or
changed in a way that departs further from it.

## Provenance

| Field            | `SKILL.md`                                                | `ADR-FORMAT.md`                                         | `GLOSSARY-FORMAT.md`                                    |
| ---------------- | --------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------- |
| Repository       | [mattpocock/skills](https://github.com/mattpocock/skills) | same                                                    | same                                                    |
| Path             | `skills/engineering/domain-modeling/SKILL.md`             | `skills/engineering/domain-modeling/ADR-FORMAT.md`      | `skills/engineering/domain-modeling/GLOSSARY-FORMAT.md` |
| Snapshot commit  | `5beb35b040e3de97e54fa9e386d7e42d15c295c2` (2026-10-19)   | same                                                    | same                                                    |
| Last file change | `d80fa0f4ebe0c5714af0adf8670336065233ecc6` (2026-09-17)   | `321658273cb1d20b76026717d027d505790106d4` (2026-08-19) | `d80fa0f4ebe0c5714af0adf8670336065233ecc6` (2026-09-17) |
| File blob        | `a4438c6879c517d1a08e2b5fbca049b632688dfe`                | `d7e61f30a9fd8ca70d9ee68f019c2a9ebf2d13f7`              | `9c0b4c7a2e8507c23cbb5e0baa66d81699321cc6`              |

License: MIT, Copyright (c) 2026 Matt Pocock; full text [below](#license).
Adapted: 2026-10-23.

## What was transformed

- **Layout.** Upstream is one `SKILL.md` with two format files. Here the
  behavior lives in [procedure.md](procedure.md), beside a thin `SKILL.md`. The
  glossary and ADR format guidance was folded into the procedure.
- **Scope.** Upstream applies to any repository. Here it applies only to
  applications whose domain justifies it, and stops for scripts, infrastructure,
  and workflows.
- **Glossary placement.** Upstream keeps one root `GLOSSARY.md`, or a
  `GLOSSARY-MAP.md` for several contexts. Here a project glossary sits in its
  project, and repo-wide terms go in a repo-wide glossary where the repository
  documents one. The override rule is in `procedure.md`.
- **Consent.** Upstream writes `GLOSSARY.md` inline and creates files lazily.
  Here nothing is written without the user's consent to the kind and path.
- **ADR location and template.** Upstream uses `docs/adr/` with four-digit
  numbering and a minimal template. Here an ADR joins the project's existing ADR
  directory and uses its numbering and template.
- **Invocation.** Upstream lets the user or the model start it. Here it runs
  only when `grill-me` calls it, and stops if invoked directly; the description
  says so, and the scope gate lives in `grill-me`.

## What was not carried over

- **`GLOSSARY-MAP.md`.** Replaced by project and repo-wide glossaries with local
  override.
- **Upstream's optional ADR sections** (status frontmatter, considered options,
  consequences). The target directory's ADR template covers them.
- **`agents/openai.yaml`.** Upstream's Codex display metadata. Neither supported
  harness reads it.

## Checking for upstream changes

A `sha` that differs from a table blob means that upstream file has changed
since the snapshot. Compare it before re-syncing:

```bash
for f in SKILL.md ADR-FORMAT.md GLOSSARY-FORMAT.md; do
  gh api "repos/mattpocock/skills/contents/skills/engineering/domain-modeling/$f" \
    --jq "\"$f \(.sha)\""
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
