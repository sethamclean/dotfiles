# Grill me

Interview the user relentlessly about a plan, decision, or idea until you reach
a shared understanding. Adapted from Matt Pocock's `grill-me` and `grilling`
skills; see [sources](sources.md) for provenance, changes from upstream, and
license. Terms such as application, script, design artifact, and frontier are
defined in the [glossary](../GLOSSARY.md).

## Workflow

1. **Scope the session.** If you were called with a candidate and a report path,
   read the report first and take the candidate as the topic. Before round 1,
   read the repository's `CODING_STANDARDS.md`, `CONTRIBUTING.md`, and
   `AGENTS.md` when they exist; they say where design artifacts live. If they
   are silent, propose the **Default artifact locations** from the
   [glossary](../GLOSSARY.md) in round 1 for the user to approve. Then find the
   target project and its design artifacts: the project's `GLOSSARY.md`, a
   repo-wide glossary, and any existing ADR directory that covers the project.
   Find ADR directories by searching for `adr/` directories in the project and
   under `docs/`; do not assume a path. Decide whether domain modeling applies:
   - On, without asking, when the target project has a `GLOSSARY.md`.
   - Off, without asking, when the target is a script, infrastructure, a
     workflow, or other non-application work, as the glossary defines
     **Application** and **Script**.
   - Otherwise, for an application without a glossary or an unclear target, ask
     in round 1. Recommend yes only when the application has several domain
     concepts with their own rules, vocabulary used inconsistently, or model
     decisions that are costly to reverse. Say that yes creates a new
     `GLOSSARY.md` that needs an owner.

   When it applies, call the Skill tool with `domain-modeling`, passing
   `from grill-me`, the target project, the glossaries in use, and the consent
   from step 2. Do the call after step 2 is answered.

2. **Ask consent for artifacts.** Put one question in round 1: may you write
   design artifacts during or after the session, which kinds (design document,
   ADR, glossary entries), and the target path for each, taken from the
   repository's documented locations or the approved defaults. The default is
   none. Write nothing before consent, ask again before writing a kind or path
   it did not cover, and never overwrite an existing file.
3. Map the topic as a **design tree**: every decision branches into the
   decisions that depend on it.
4. Work the tree in **rounds**. The **frontier** is every decision whose
   prerequisites are already settled: the questions you can ask now without
   guessing at answers you have not heard yet. Ask the whole frontier in one
   round, number each question, and give your recommended answer. Word each
   question so "yes" accepts the recommendation. Then wait for the user's
   answers.
5. Recompute the frontier from the answers. Settled decisions push it outward
   and unblock the questions that depended on them. A question whose answer
   depends on another question still open belongs to a later round.
6. Finding facts is your job, never the user's. When a frontier question needs a
   fact from the repository or environment, look it up, delegating to a subagent
   when session instructions allow. Do not block on it: only the questions
   downstream of a pending lookup wait. Decisions belong to the user; put each
   one to them and wait.
7. Stop when the frontier is empty: every branch visited and nothing silently
   assumed. Do not act on the outcome until the user confirms you have reached a
   shared understanding. Then write only the artifacts the user consented to,
   and list the files written. Glossary entries may be written as terms settle
   when the user consented to them. Write an ADR in the template and numbering
   of the existing ADR directory, as its README describes. Design documents have
   no required template: keep them to what the session settled and list open
   questions. Do not write a specification here; offer `to-spec`, which the user
   runs, and `to-tickets` after it.

## Round format

```markdown
**Q1. <question title>**: <question body, which may span paragraphs and list
choices>

Recommended: <your recommended answer>

---

**Q2. <question title>**: <question body>

Recommended: <your recommended answer>
```
