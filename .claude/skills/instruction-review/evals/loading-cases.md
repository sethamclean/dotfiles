# Shared-procedure loading cases

Test each harness independently. Each loads the skill entry point,
`instruction-review/SKILL.md`, from its skills directory. Run once from a
repository root and once from an existing nested project directory.

Request: “Use instruction-review to review the supplied instruction.” Supply
[review case R1](review-cases.md#r1-contradictory-rules) as quoted material.

Verify through resource reads or equivalent host evidence that:

1. The intended entry point was selected.
2. It loaded `procedure.md` from the skill directory.
3. It loaded `criteria/shared.md` and `criteria/prompts.md` relative to that
   procedure, without loading unrelated criteria or evaluation fixtures.
4. The review addressed R1 without path-resolution errors.

Record which entry point loaded. If a same-named skill exists in a project
skills directory, selection can be ambiguous; expose only the intended entry
point in a disposable evaluation environment. Correct output alone does not
prove document loading; mark verification inconclusive when the host exposes
insufficient evidence.
