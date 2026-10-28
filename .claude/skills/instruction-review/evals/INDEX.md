# Evaluating instruction-review

Load only when testing or changing the skill's behavior:

- [Review cases](review-cases.md): detection, false positives, and rewrites.
- [Activation cases](activation-cases.md): intended requests and near matches.
- [Loading cases](loading-cases.md): entry-point loading from different working
  directories.

Recorded runs from the 2026-10-18 pilot, instruction-chain, and bloat
calibration evaluations were not carried over; only the case definitions are
here. Record new runs in a `results/` directory beside these files.

For each trial, record exact input, harness/version/model, relevant
configuration, whether the skill was available or explicitly invoked, output and
observed tool activity, and pass/fail/inconclusive with evidence. Track missed
defects, false positives, requirement preservation, usefulness, unnecessary
work, and time/token cost when available.

Compare representative cases with no skill or the previous version under
equivalent inputs and clean environments. Grade outcomes rather than exact
wording. Valid alternative corrections can pass. Read unexpected traces for
fixture ambiguity, environment problems, or grader mistakes before blaming the
skill. Repeat trials when needed and report counts rather than certainty from a
single run.

Add real failures and clean counterexamples over time. Keep some cases outside
the examples used to tune instructions. Generalize fixes instead of adding a
special rule for every fixture. Fixture definitions are evaluation
specifications; only recorded runs establish which trials were executed.
