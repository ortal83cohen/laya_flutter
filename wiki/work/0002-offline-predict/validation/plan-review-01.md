# Plan review — round 01

- Work item: 0002-offline-predict
- Reviewed artifact: `wiki/work/0002-offline-predict/01-plan.md` (with `02-criteria.md`, `04-product-contract.md`)
- Reviewer: plan-validator
- Date: 2026-09-27

## Verdict

**FAIL**

AC-004 requires parity on the same questions as the Python reference, but the plan’s fixture unit and shared decisions never commit those questions or decide how the public predict call receives them, so that criterion is not implementable as written.

## Verification performed

Criterion hygiene and plan prose checks:

```text
$ rg -n '```' wiki/work/0002-offline-predict/01-plan.md || echo 'no code fences'
no code fences

$ rg -n 'correctly|properly|as expected' wiki/work/0002-offline-predict/02-criteria.md || echo 'criteria: no vague adverbs'
criteria: no vague adverbs

$ rg -n 'question' wiki/work/0002-offline-predict/01-plan.md wiki/work/0002-offline-predict/02-criteria.md wiki/work/0002-offline-predict/04-product-contract.md
04-product-contract.md:22:| R-004 | ... same checkpoint, state, and questions ...
04-product-contract.md:40:| AE-003 | ... same checkpoint, state, and questions ...
02-criteria.md:15:| AC-004 | R-004 | ... states, and questions ...
01-plan.md:25: ... open product question about the long-term fixture language mix.
(no fixture/API "questions" in 01-plan.md)
```

Codebase claims used by the plan (stub package, no ONNX binding yet):

```text
$ test ! -d test && echo 'test dir: absent'
test dir: absent

$ rg -n 'onnx|flutter_onnxruntime' pubspec.yaml || echo 'pubspec: no onnx dependency'
pubspec: no onnx dependency

$ sed -n '1,5p' lib/src/library.dart
/// The entry point for the library implementation.
final class LayaFlutter {
  /// Creates the library facade.
  const LayaFlutter();
}

$ python3 tools/lint_wiki.py
lint_wiki: clean (0 warning(s)).
```

`03-tasks.md` is absent; the plan does not mark work parallel. Parallelism safety was not applicable.

## Per-criterion results

Plan-phase coverage map (not an implementation review). Result means whether a unit addresses the criterion without a coverage gap found in this round.

| Criterion | Result | Evidence (file:line) | Negative case in plan scenarios |
|---|---|---|---|
| AC-001 | pass | `01-plan.md:63` (U3 First download) | yes — `01-plan.md:65` |
| AC-002 | pass | `01-plan.md:64` (U3 Second run offline) | yes — `01-plan.md:65` |
| AC-003 | pass | `01-plan.md:87` (U5 Three answer types offline) | yes — `01-plan.md:88` |
| AC-004 | fail | `01-plan.md:92–99` (U6) omits committed questions required by AC-004 / R-004 | partial — tamper case at `01-plan.md:99`, but fixture inputs incomplete |
| AC-005 | pass | `01-plan.md:41–53`, `01-plan.md:87` (U1/U2/U5) | yes — `01-plan.md:42`, `01-plan.md:53` |
| AC-006 | pass | `01-plan.md:98`, `01-plan.md:100` (U6) | yes — `01-plan.md:100` |
| AC-007 | pass | `01-plan.md:48`, `01-plan.md:52`, `01-plan.md:112` | yes — bundling rejected in U2 scenario |
| AC-008 | pass | `01-plan.md:41–42` (U1) | yes — `01-plan.md:42` |

## Findings

### F-001 — Frozen fixtures omit the questions AC-004 requires

- Severity: BLOCKER
- Location: `wiki/work/0002-offline-predict/01-plan.md:92`
- Criterion affected: AC-004
- Observation: U6’s done state commits English and non-English states plus Python outputs for choice label, score level, and noul side, but never requires the fixture set to include the question definitions used for that Python run. AC-004 (`02-criteria.md:15`) and R-004 (`04-product-contract.md:22`) explicitly evaluate “the same … questions.” The word “questions” does not appear in `01-plan.md` as a fixture or API input (only in an unrelated “open product question” phrase at line 25).
- Why it matters: Without committed questions in the frozen set, host parity cannot satisfy AC-004 as written; an implementer would have to invent fixture inputs that are not fixed by the plan.

### F-002 — Shared decisions leave predict inputs for questions undecided

- Severity: BLOCKER
- Location: `wiki/work/0002-offline-predict/01-plan.md:110`
- Criterion affected: AC-004 (also blocks completing U5 against AC-003 when fixtures carry distinct questions)
- Observation: Interfaces decide checkpoint id, engine, graph I/O, answer output fields, download directory behaviour, host-vs-device, and error handling (`01-plan.md:104–120`), and explicitly leave public API names to the implementer (`01-plan.md:120`). They do not decide whether or how the caller supplies the questions that produce choice, score, and noul. U5’s happy-path scenario input lists only “one state” (`01-plan.md:87`), while AC-004 / R-004 / AE-003 require the same questions as the Python reference. Completing U5/U6 therefore requires asking a shared-shape question the plan was supposed to close.
- Why it matters: Undecided predict inputs are a shared choice across download, decode, predict, and parity units; leaving them open makes AC-004’s “same questions” bar unimplementable without a further planning decision.

### F-003 — Public API names deferred while parity API must be shared

- Severity: IMPORTANT
- Location: `wiki/work/0002-offline-predict/01-plan.md:120`
- Criterion affected: none directly
- Observation: The plan states that public API names are chosen by the implementer and that plugin method names are not frozen. No parallel tasks are marked, so this is not a cross-task collision yet.
- Why it matters: Download, predict, and host parity tests must call one stable surface; deferring all public names until implementation invites rename churn before criteria freeze.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| F-001 | plan |
| F-002 | plan |
| F-003 | plan |
