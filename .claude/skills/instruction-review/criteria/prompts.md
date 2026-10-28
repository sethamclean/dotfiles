# Prompt criteria

Apply alongside [shared criteria](shared.md), including for templates embedded
in other artifacts when they need separate assessment.

## Instructions and supplied data

Can the model distinguish its task from quoted documents, examples, and other
inputs? Flag ambiguous boundaries when supplied content could redirect behavior.
Markdown, delimiters, and XML are options, not universal requirements.

## Context and examples

Does supplied context support the task without assuming unavailable facts? Check
that examples demonstrate the intended behavior, cover useful distinctions, and
agree with constraints. Recommend examples only where they add value.

## Output constraints

Are format and content expectations usable by the recipient? Check required
fields, allowed uncertainty, and competing constraints against intended use. Do
not demand a structured schema for an ordinary prose response without cause.

## Model-dependent techniques

Assess prompting techniques against the intended model and workload. Do not
universally require chain-of-thought disclosure, aggressive emphasis, role
personas, or repeated self-checks. Recommend comparative trials where static
inspection cannot establish an improvement.
