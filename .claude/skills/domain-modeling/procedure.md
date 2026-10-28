# Domain modeling

Build and sharpen an application's domain model while it is being designed:
challenge terms, test edge cases, and propose glossary entries and ADRs. Adapted
from Matt Pocock's `domain-modeling` skill; see [sources](sources.md) for
provenance, changes from upstream, and license. Merely reading a glossary for
vocabulary is not this skill; use it when the model is changing.

## Scope and inputs

This skill is called by `grill-me` and is not for direct use. Proceed only when
the invocation says `from grill-me` and names the target project, the glossaries
in use, and the consent given. Otherwise say that it is not for direct use, ask
the user to run `grill-me`, and stop. `grill-me` has already decided that the
target is an application that warrants modeling; do not re-decide that.

Where artifacts live comes from the repository's `CODING_STANDARDS.md`,
`CONTRIBUTING.md`, or `AGENTS.md`, or the defaults the user approved in
`grill-me`.

Before starting, read the project glossary and the repo-wide glossary when they
exist, and name the ones in use. Write only the artifact kinds and paths the
user consented to. Without consent, propose entries in the conversation and
write nothing.

## During the session

- **Challenge against the glossary.** When a term conflicts with a glossary
  entry, say so at once: "Your glossary defines 'cancellation' as X, but you
  seem to mean Y. Which is it?"
- **Sharpen fuzzy language.** For a vague or overloaded term, propose a precise
  canonical one: "Do you mean the Customer or the User?"
- **Test with scenarios.** Invent concrete edge cases that force exact
  boundaries between concepts.
- **Cross-reference with code.** When the user states how something works, check
  the code. Surface any contradiction and ask which is right.
- **Place terms by scope.** A term used by several projects with one meaning
  belongs in the repo-wide glossary; propose it there. A project glossary may
  override a repo-wide term for that project; say so in the entry.
- **Record terms as they settle.** With consent, add the entry to the right
  glossary when the term resolves, not in a batch. A glossary holds terms only,
  never a specification, scratch notes, or implementation decisions.

## Glossary entries

```text
# <Application name>

<One or two sentences on what the application is and why it exists.>

## Language

**Order**:
A request to buy one or more products, placed by a customer.
_Avoid_: purchase, transaction
```

- Be opinionated: pick one word per concept and list the others under `_Avoid_`.
- Keep each definition to one or two sentences about what the term is, not what
  it does.
- Include only terms specific to this context. General programming concepts do
  not belong, even if the application uses them heavily.
- Group terms under subheadings when natural clusters appear.

## ADRs

Offer an ADR sparingly: only when the decision is hard to reverse, surprising
without context, and the result of a real trade-off. If any is missing, skip it.
Qualifying decisions include architectural shape, integration patterns between
contexts, technology choices with lock-in, boundary and scope decisions,
deliberate deviations from the obvious path, constraints not visible in the
code, and non-obvious rejected alternatives.

Put the ADR in the existing ADR directory that covers the project, found by
searching for `adr/` directories in the project and under `docs/`, and use its
numbering and template. If none covers the project, ask where it should live and
which numbering and template to use. An ADR can be short; record that the
decision was made and why.
