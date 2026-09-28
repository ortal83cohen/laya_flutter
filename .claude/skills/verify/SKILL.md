---
name: verify
description: Runs the verify phase - executes the full check suite, then delegates a blind per-criterion verification of the diff against the frozen acceptance criteria.
when_to_use: Use after an implementation is complete to establish that it satisfies its criteria with evidence. Also use when the user asks to check, verify or prove that a change works. Invoked automatically by the feature pipeline.
argument-hint: "[work-item-id]"
arguments: [item]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Verify phase

Work item: `$item`

## Run the checks yourself first

Run the project's full check suite and paste the output. This is a cheap pre-filter: if it is red, there is no point spending a frontier-model review, so return to the implement phase now.

Passing this pre-filter is not verification. It shows the code does not fail its own tests, which is a much weaker claim than satisfying the criteria.

## Delegate the real verification

Spawn one `impl-validator`. Pass it exactly two things: `02-criteria.md` and the diff under review.

Do not pass the implementer's report, its summary, or its claim that anything was fixed. A model reports having incorporated feedback far more often than it has, so the validator re-runs the check rather than reading the claim.

## Gate

Every one of these, or the phase is not done:

- verdict is `PASS`;
- every criterion has an explicit verdict in the per-criterion table — silence on a criterion is a failed review, not a passing criterion;
- every criterion has a file-and-line citation;
- every criterion has a negative case that actually fails when the behaviour is wrong;
- the verification commands and their output are pasted into the report;
- `python3 tools/lint_wiki.py` exits clean.

## Verdict handling

Identical to the validate phase: one round, and the main agent decides what happens next. Read `wiki/conventions/validation-rubrics.md`.

The one rule worth restating: a `FAIL` whose routing names a plan defect goes back to the plan phase. It does not go back to the implementer. Writing more code to satisfy a plan-level finding produces code that passes a test and solves the wrong problem.

## Test gaming

Read the validator's findings on test gaming specifically — a mock added to pass a test, an assertion widened to accept current output, a test skipped, a test asserting what the code does rather than what the criterion requires. Each is a blocker. These grow with the size of the change and are invisible in a green run, which is why the validator hunts them explicitly rather than trusting the suite.

Set `STATE.yaml` phase to `document`.
