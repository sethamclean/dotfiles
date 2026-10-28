# Improve codebase architecture

Surface architectural friction and propose **deepening opportunities**:
refactors that turn shallow modules into deep ones. The aim is testability and
AI-navigability.

This applies to application code only; see **Application** and **Script** in the
[glossary](../GLOSSARY.md). If the target is a script, infrastructure, or a
workflow, say so and stop.

This procedure is _informed_ by the project's domain model and built on a shared
design vocabulary:

- Call the Skill tool with "codebase-design" for the architecture vocabulary
  (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**,
  **locality**) and its principles (the deletion test, "the interface is the
  test surface", "one adapter = hypothetical seam, two = real"). Use these terms
  exactly in every suggestion, and don't drift into "component," "service," or
  "API."
- The project glossary gives names to good seams. ADRs record decisions this
  procedure should not re-litigate; find them by searching for `adr/`
  directories in the project and under `docs/`.

## Process

### 1. Explore

**Scope before you scan: YAGNI.** Deepening a module pays off by making future
changes to it easier, so put extra weight on the parts of the codebase that have
recently changed. Decide _where_ to look before you look:

- If the user named a direction (a module, a subsystem, a pain point), take it,
  and skip the inference below.
- Otherwise, walk back a good stretch of the commit history
  (`git log --oneline`) to find the codebase's hot spots, the files and areas
  that keep coming up, and let those paths pull your attention first. If the
  changes are scattered with no clear hot spot, widen the net.

Read the project glossary and any ADRs in the area you're touching first.

Then walk the codebase, delegating to a sub-agent only when session instructions
allow. Don't follow rigid heuristics; explore organically and note where you
experience friction:

- Where does understanding one concept require bouncing between many small
  modules?
- Where are modules **shallow**, with an interface nearly as complex as the
  implementation?
- Where have pure functions been extracted just for testability, but the real
  bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their
  current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting
it concentrate complexity, or just move it? A "yes, concentrates" is the signal
you want.

### 2. Present candidates as a report

Write a Markdown file to the **Scratch location** in the
[glossary](../GLOSSARY.md) so nothing lands in the repository, as
`architecture-review-<timestamp>.md` so each run gets a fresh file. Tell the
user the absolute path. Do not open a browser or load external scripts. Use
Mermaid code blocks for graph-shaped relationships (call graphs, dependencies,
sequences) and plain text diagrams otherwise. Then summarize the candidates in
the conversation as a table: name, files, and recommendation strength.

For each candidate, write a section with:

- **Files**: which files and modules are involved
- **Problem**: why the current architecture is causing friction
- **Solution**: plain English description of what would change
- **Benefits**: explained in terms of locality and leverage, and how tests would
  improve
- **Before / after diagram**: illustrating the shallowness and the deepening
- **Recommendation strength**: one of `Strong`, `Worth exploring`, or
  `Speculative`

End the report with a **Top recommendation** section: which candidate you'd
tackle first and why.

**Use the project glossary's vocabulary for the domain, and the
`codebase-design` vocabulary for the architecture.** If the glossary defines
"Order," talk about "the Order intake module," not "the FooBarHandler," and not
"the Order service."

**ADR conflicts**: if a candidate contradicts an existing ADR, only surface it
when the friction is real enough to warrant revisiting the ADR. Mark it clearly
in the candidate (for example _"contradicts ADR-0007, but worth reopening
because…"_). Don't list every theoretical refactor an ADR forbids.

Do NOT propose interfaces yet. After the file is written, ask the user: "Which
of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, call the Skill tool with "grill-me", passing
the chosen candidate and the absolute path of the report, to walk the decision
tree with them: constraints, dependencies (classified with the dependency
categories in `codebase-design`'s
[deepening.md](../codebase-design/deepening.md)), the shape of the deepened
module, what sits behind the seam, and what tests survive. `grill-me` decides
whether domain modeling applies.

If the user rejects a candidate with a load-bearing reason, offer an ADR, framed
as: _"Want me to record this as an ADR so future architecture reviews don't
re-suggest it?"_ Only offer when a future explorer would actually need the
reason to avoid re-suggesting the same thing; skip ephemeral reasons ("not worth
it right now") and self-evident ones.

Comparing alternative interfaces for the chosen candidate happens in the
grilling. Exploring them with parallel sub-agents is not adopted yet.
