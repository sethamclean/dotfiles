# Agent definition criteria

Apply alongside [shared criteria](shared.md).

## Configuration and delegation

Validate metadata against the intended host and version. Does the discovery
description identify a coherent responsibility and when delegation is useful? Do
not assume a definition guarantees invocation or require delegation where the
session does not permit it.

## Handoff and context

Does the agent receive the task, scope, required evidence, and relevant context?
Check assumptions about parent history, inherited instructions, and preloaded
skills against actual host behavior. Identify missing handoff data without
requiring every agent to receive the entire parent context.

## Capabilities and boundaries

Do configured tools support the task and claimed restrictions? Consider shell,
MCP, delegated, and other exposed capabilities when evaluating “read-only.”
Prose restrictions are advisory unless enforced by the runtime. Do not assume
denying edit tools prevents mutation through other tools.

## Return contract

Can the caller distinguish completed work, findings, blockers, and uncertainty?
Check that useful evidence survives the handoff and that the agent knows when to
return incomplete work rather than invent results or retry indefinitely.
