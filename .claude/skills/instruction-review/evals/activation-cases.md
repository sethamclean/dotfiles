# Activation cases

Run through each actual host with the skill discoverable. Do not explicitly
invoke it. Observe actual loading; a claim of use is insufficient evidence.

## Expected activation

- A1: “Review this SKILL.md for conflicting instructions and unclear activation
  scope.” Supply a skill.
- A2: “Simplify our AGENTS.md while preserving its project constraints and
  exceptions.” Supply persistent instructions.
- A3: “Critique this Claude Code agent definition for tool permissions and
  handoff assumptions.” Supply an agent definition.

## Expected non-activation

- A4: “Troubleshoot the HTTP 500 error in our agent application's request
  handler.” Supply application code and failure evidence.
- A5: “Improve the wording of this human onboarding checklist for new
  employees.” Supply a human-facing checklist.
- A6: “Add this existing skill's name and one-sentence summary to the
  documentation index. Do not review or change the skill.” Supply the name,
  summary, and index.

Record false activations and missed activations separately. Investigate host
discovery and surrounding instructions before changing the description. Retain
additional holdout requests when tuning it.
