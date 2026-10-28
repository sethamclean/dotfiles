# Sources and applicability

Research baseline: 2026-10-18. Use current primary documentation for
version-dependent findings. Normative specification requirements, runtime
contracts, authoring recommendations, and empirical results have different
authority; cite the relevant section rather than treating every recommendation
as mandatory.

## Structure and runtime contracts

- [Agent Skills specification](https://agentskills.io/specification): skill
  structure, metadata constraints, and recommended progressive disclosure.
- [AGENTS.md](https://agents.md/): a Markdown convention, not a universal host
  loading or priority contract.
- [OpenCode skills](https://opencode.ai/docs/skills/) and
  [agents](https://opencode.ai/docs/agents/): host discovery and configuration.
- [Claude Code subagents](https://code.claude.com/docs/en/sub-agents): context
  handoff, tools, permissions, and host-specific configuration.

## Authoring and evaluation guidance

- [Skill authoring](https://agentskills.io/skill-creation/best-practices):
  task-grounded workflows, useful detail, and selective references.
- [Skill descriptions](https://agentskills.io/skill-creation/optimizing-descriptions):
  positive and near-miss activation trials.
- [Skill evaluation](https://agentskills.io/skill-creation/evaluating-skills):
  baseline comparisons, observable outcomes, and trace inspection.
- [Claude Code best practices](https://code.claude.com/docs/en/best-practices):
  persistent context and verifiable task outcomes.
- [Context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents):
  appropriate instruction detail and selective context.
- [OpenAI prompting guidance](https://developers.openai.com/api/docs/guides/prompt-guidance):
  model-dependent instruction following and verification behavior.
- [Agent evaluation](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents):
  balanced cases, stable environments, and calibrated graders.

## Empirical evidence and limits

[Evaluating AGENTS.md](https://arxiv.org/html/2602.11988v3) studies repository
context files in Python coding tasks. Generated files did not significantly
improve task success and increased costs; developer-written files showed a
small, statistically insignificant improvement over no file. The study found no
clear relationship between length and performance. It does not establish
universal length limits or measure every security, policy, or maintainability
outcome.

Description voice, example counts, emphasis, and reasoning advice vary across
sources and models. Treat these as conditional heuristics unless an applicable
contract or evaluation supports a stronger claim.
