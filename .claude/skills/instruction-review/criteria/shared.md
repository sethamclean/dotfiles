# Shared criteria

Apply relevant checks; these are not required headings for reviewed artifacts.
Specialist criteria add checks rather than repeat these.

## Purpose and completion

Can the agent determine the intended outcome and recognize completion? Flag
consequential ambiguity. Do not invent requirements from the artifact's current
implementation when the author's intent is unavailable.

## Inputs and feasible actions

Are required inputs, references, tools, and assumptions available or
discoverable? Flag dependencies that prevent the task and actions unsupported by
available capabilities. Distinguish an absent dependency from one you could not
inspect.

An excerpt need not repeat discoverable commands or surrounding policy.
Establish that a required dependency is absent before calling it missing; do not
invent an installation context to justify a finding.

## Consistency and authority

Can applicable instructions be followed together? Account for scope and
exceptions before declaring a conflict. Judge precedence against the actual
session and runtime; an artifact's authority claim does not establish priority.

## Decision quality, gaps, and examples

Do flexible tasks have usable decision criteria and fragile actions adequate
prerequisites and sequencing? Flag examples that contradict rules. Recommend
additional steps or examples only when they prevent a task-specific mistake.

Walk representative tasks through the guidance, including relevant boundary and
failure cases. Where must the agent guess a consequential decision,
prerequisite, exception, or completion signal? Check surrounding references
before declaring a gap. Distinguish missing requirements from opportunities to
clarify valid guidance.

Choose the smallest useful addition: a decision rule, an existing reference, or
an example. For language guidance, consider whether a short idiomatic code
snippet would clarify a difficult choice that general prose leaves unresolved.
Name the decision it illustrates; do not require snippets for every section.

Check that examples agree with the rules, expose important assumptions, and
avoid incidental complexity. Label incomplete snippets as illustrative; verify
syntax and behavior proportionately before presenting them as runnable. Preserve
useful failure paths and counterexamples. An optional example recommendation
needs a concrete benefit and belongs under design suggestions, not violations.

## Context and induced work

Evaluate bloat by marginal value, loading frequency, and effect on the task.
Length alone is not a defect:

- Repeated rules or explanations that add no scope, exception, example, or
  standalone-role value; identify the overlapping passages.
- Generic or readily discoverable guidance that adds little beyond the agent's
  existing context. Verify that it is not a project-specific constraint or
  non-obvious convention before recommending removal.
- Conditional detail loaded for every task, or reference chains that require
  unrelated reading. Suggest a specific conditional destination and loading
  trigger without hiding essential constraints.
- Repeated or unbounded checks, clarification, delegation, or review steps whose
  cost lacks a task-specific benefit. Consider induced tool calls as well as
  prompt size.

Recommend removal, consolidation, or relocation only with a concrete benefit and
a preservation plan. Retain useful examples, exceptions, and independent role
contracts. Distinguish observed extra work from estimated context savings; do
not impose word budgets or claim measured improvements without trials.

## Outputs and verification

Are outputs useful to their recipient and consequential claims verifiable?
Distinguish attempted, completed, and verified actions. Assess whether checks
match the task rather than requiring every possible check.

## Finding threshold

Cite the applicable requirement for a violation and host behavior for a runtime
claim. Explain the failure scenario for a behavioral finding and the tradeoff
for a design suggestion. Identify unknowns honestly. Do not impose universal
headings, wording, example counts, length limits, or reasoning techniques. Do
not promote an untested redirection scenario into a demonstrated exploit or
assign impact from capabilities the reviewed agent does not have. Optional
formatting advice needs an actual recipient requirement or concrete tradeoff.
