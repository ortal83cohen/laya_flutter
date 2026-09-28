# Plan review — round 01

- Work item: 0016-absolute-snake-checkpoint
- Reviewed artifact: `wiki/work/0016-absolute-snake-checkpoint/01-plan.md`
- Reviewer: Codex (independent plan validator)
- Date: 2026-09-28

## Verdict

**FAIL**

The plan does not cover the contract's explicit incompatible-checkpoint error or the complete record
required for every finished model attempt.

## Verification performed

Read only `01-plan.md`, `02-criteria.md`, `04-product-contract.md`,
`wiki/conventions/validation-rubrics.md`, and `wiki/templates/validation-report.md`. Ran this
read-only cross-check:

```text
$ rg -n 'R-003 \||R-004 \||AC-003 \||AC-004 \||Done when:|^\| (Complete local bundle|Missing bundle|Reverse into neck|Unknown key)|Published checkpoint export is incompatible' wiki/work/0016-absolute-snake-checkpoint/01-plan.md wiki/work/0016-absolute-snake-checkpoint/02-criteria.md wiki/work/0016-absolute-snake-checkpoint/04-product-contract.md
wiki/work/0016-absolute-snake-checkpoint/02-criteria.md:14:| AC-003 | R-003 | A configured local ONNX bundle shall be selected without downloading the default base graph. | Opening-path tests | Missing bundle silently opens base |
wiki/work/0016-absolute-snake-checkpoint/02-criteria.md:15:| AC-004 | R-004 | Each finished step shall report raw direction, attempted cell, progress and accepted/collision/invalid/failure classification. | Record tests | Dangerous choice is changed or omitted from log |
wiki/work/0016-absolute-snake-checkpoint/02-criteria.md:17:| AC-006 | R-001, R-003 | The example shall retain one awaited prediction per step and shall present a setup error when the local Snake bundle is absent. | Widget and source checks | Timer moves the board or base is opened implicitly |
wiki/work/0016-absolute-snake-checkpoint/04-product-contract.md:21:| R-003 | A runner with a prepared local checkpoint shall be able to select it for the example; missing or incompatible artifacts shall produce an explicit error instead of silently loading a different checkpoint. |
wiki/work/0016-absolute-snake-checkpoint/04-product-contract.md:22:| R-004 | Every finished model attempt shall record the input, chosen direction, candidate outcome, progress, and failure or collision classification. |
wiki/work/0016-absolute-snake-checkpoint/04-product-contract.md:29:| F-001 | Configure local checkpoint, open it, send an encoded board, apply returned absolute direction, then record the result. | R-001, R-002, R-003, R-004 |
wiki/work/0016-absolute-snake-checkpoint/04-product-contract.md:37:| AE-002 | Head faces right; model returns left into its neck; the model choice is logged and the run ends. | R-001, R-004 |
wiki/work/0016-absolute-snake-checkpoint/04-product-contract.md:38:| AE-003 | No configured local Snake checkpoint exists; the example reports setup is required and does not open the base checkpoint. | R-003 |
wiki/work/0016-absolute-snake-checkpoint/01-plan.md:27:Done when: the real example uses the four absolute choices, matches the published question and state schema, and logs the unmodified model choice.
wiki/work/0016-absolute-snake-checkpoint/01-plan.md:34:| Reverse into neck | edge | East-facing head, left answer | Step | Body collision is logged and run ends | R-001, R-004 |
wiki/work/0016-absolute-snake-checkpoint/01-plan.md:35:| Unknown key | error | Invalid answer | Step | No movement and explicit diagnostic | R-001, R-004 |
wiki/work/0016-absolute-snake-checkpoint/01-plan.md:39:Done when: a configured local ONNX bundle opens through the library and the example never silently substitutes the base graph.
wiki/work/0016-absolute-snake-checkpoint/01-plan.md:45:| Complete local bundle | integration | ONNX and companions in configured directory | Open | Runtime uses those files | R-003 |
wiki/work/0016-absolute-snake-checkpoint/01-plan.md:46:| Missing bundle | error | No configured directory or files | Open | Clear setup error, no base download | R-003 |
wiki/work/0016-absolute-snake-checkpoint/01-plan.md:50:Done when: a separate evaluator can report independent seeded games and documentation states which validation remains blocked by unavailable weights.
wiki/work/0016-absolute-snake-checkpoint/01-plan.md:71:| Published checkpoint export is incompatible | Medium | High | Keep export external and verify graph names plus parity before use | Export or session check fails |
```

No runtime or source checks were performed; this is a plan review.

## Findings

### F-001 — Incompatible local bundle has no specified runner outcome

- Severity: BLOCKER
- Location: `wiki/work/0016-absolute-snake-checkpoint/01-plan.md:43`
- Criterion affected: AC-003 (R-003 contract)
- Observation: U2's scenarios cover a complete bundle and an absent bundle at lines 45–46. The risk
  entry at line 71 acknowledges incompatibility but does not specify the runner's observable
  outcome. The contract requires an explicit error for incompatible artifacts at
  `wiki/work/0016-absolute-snake-checkpoint/04-product-contract.md:21`.
- Why it matters: The planned opening path could fail a compatibility check without meeting the
  explicit-error contract.

### F-002 — Decision record is narrower than the required per-attempt record

- Severity: BLOCKER
- Location: `wiki/work/0016-absolute-snake-checkpoint/01-plan.md:27`
- Criterion affected: AC-004
- Observation: U1 is done when it logs the unmodified model choice. Its R-004 scenarios at lines
  34–35 cover a collision log and an invalid-answer diagnostic. They do not cover recording the
  input, attempted cell or candidate outcome, progress, and accepted or failure classification for
  every finished attempt, required by
  `wiki/work/0016-absolute-snake-checkpoint/04-product-contract.md:22` and
  `wiki/work/0016-absolute-snake-checkpoint/02-criteria.md:15`.
- Why it matters: Implementing the unit as written could satisfy its stated done condition while
  omitting required fields and outcomes.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| F-001   | plan             |
| F-002   | plan             |
