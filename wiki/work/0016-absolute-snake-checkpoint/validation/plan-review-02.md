# Plan review — round 02

- Work item: 0016-absolute-snake-checkpoint
- Reviewed artifact: `wiki/work/0016-absolute-snake-checkpoint/01-plan.md`
- Reviewer: Codex (independent plan validator)
- Date: 2026-09-28

## Verdict

**PASS**

The revised plan covers the frozen criteria and product contract, including both defects reported in round 01; no plan blocker remains.

## Verification performed

Read only the plan, frozen criteria, product contract, prior plan review, validation rubric, and validation-report template. Ran the following read-only checks against the reviewed documents:

```text
$ rg -n '^(### U[0-9]|Done when:|\| (Turn north|Reverse into neck|Unknown key|Failed prediction|Accepted move|Complete local bundle|Missing bundle|Incompatible bundle|Held-out game|Missing model) |^- The model question id|^- The example selects|^- Evaluation uses|^Run focused)' wiki/work/0016-absolute-snake-checkpoint/01-plan.md
25:### U1. Absolute model decision and matching state
27:Done when: the real example uses the four absolute choices, matches the published question and state schema, and records the input, unmodified model choice, attempted cell and candidate outcome, distance progress, and accepted, collision, invalid or predict-failure classification for every finished living attempt.
33:| Turn north from east | happy path | East-facing head, up answer | Step | Head moves north | R-001, R-002 |
34:| Reverse into neck | edge | East-facing head, left answer | Step | Body collision is logged and run ends | R-001, R-004 |
35:| Unknown key | error | Invalid answer | Step | No movement and explicit diagnostic | R-001, R-004 |
36:| Failed prediction | error | Predictor throws | Step | No movement; input, absent choice and failure classification are recorded | R-004 |
37:| Accepted move | happy path | Valid safe model answer | Step | Input, raw direction, attempted cell, candidate outcome and progress are recorded | R-004 |
39:### U2. Explicit local checkpoint selection
41:Done when: a configured local ONNX bundle opens through the library and the example never silently substitutes the base graph.
47:| Complete local bundle | integration | ONNX and companions in configured directory | Open | Runtime uses those files | R-003 |
48:| Missing bundle | error | No configured directory or files | Open | Clear setup error, no base download | R-003 |
49:| Incompatible bundle | error | Local graph with wrong input/output contract or malformed companions | Open | Explicit compatibility error, no base download | R-003 |
51:### U3. Full-game evaluation and documentation
53:Done when: a separate evaluator can report independent seeded games and documentation states which validation remains blocked by unavailable weights.
59:| Held-out game | happy path | Pinned source and local model | Evaluate | Seeded agreement, food, collision, loop and score metrics | R-005 |
60:| Missing model | error | No model weights | Evaluate | Explicit missing-checkpoint result; no fabricated metrics | R-005 |
64:- The model question id is `move`; keys and descriptions are the four lowercase absolute directions from the public encoder.
65:- The example selects a local checkpoint directory through `LAYA_SNAKE_CHECKPOINT_DIR` as a Dart define.
68:- Evaluation uses raw model actions, independent seeds, and separates decision agreement from full-game metrics.
90:Run focused and full Flutter tests, root and example analysis, web build, wiki lint, and evaluator fixture checks. Record whether a real tuned model could be opened and run.

$ rg -n '^```' wiki/work/0016-absolute-snake-checkpoint/01-plan.md
(no output; exit 1)
```

This was a plan review. No runtime, source, model, or weight checks were performed.

## Findings

None.

## Recurrence check

- Previous round: `wiki/work/0016-absolute-snake-checkpoint/validation/plan-review-01.md`
- Recurring findings: none. Round 01 F-001 is covered by the incompatible-bundle scenario at `01-plan.md:49`; F-002 is covered by the U1 done condition and accepted/failure scenarios at `01-plan.md:27`, `01-plan.md:36`, and `01-plan.md:37`.
- Oscillating: no

## Routing

No findings to route.
