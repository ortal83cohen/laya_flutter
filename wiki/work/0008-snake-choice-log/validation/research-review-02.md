# Research review — round 02

- Work item: 0008-snake-choice-log
- Reviewed artifact: `wiki/work/0008-snake-choice-log/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-28

## Verdict

**PASS**

Round-01 blockers and important gaps are closed in the revised artifact; remaining issues are
citation polish that do not leave the plan without a supported answer to the research question.

## Verification performed

Opened and read every path listed under Sources, plus the two stream files named in Findings:

- `wiki/work/0008-snake-choice-log/00-research.md`
- `wiki/work/0008-snake-choice-log/research/step-record.md`
- `wiki/work/0008-snake-choice-log/research/test-capture.md`
- `wiki/product/GOAL.md` (lines 28–47)
- `wiki/product/classic-snake-example.md` (full)
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` (lines 1–40)
- `wiki/work/0010-restart-on-death/STATE.yaml` (lines 1–12)
- `example/lib/snake_controller.dart` (lines 42–114, 143–198, 278–288)
- `example/lib/snake_screen.dart` (lines 32–73)
- `example/test/snake_controller_test.dart` (lines 85–120, 302–366)
- `lib/src/answers.dart` (lines 55–112)
- `wiki/work/0008-snake-choice-log/validation/research-review-01.md` (recurrence only)

Repository search for developer-log / print APIs (validator re-ran; did not rely on the author’s
search claim):

```text
pattern: debugPrint|\bprint\(|Logger|package:logging|package:logger|dart:developer
glob: *.dart
result: No matches found
```

Confirmed `wiki/work/0008-snake-choice-log/validation/research-review-02.md` did not exist before
this round.

Spot-checks against cited ranges:

- `buildStateString` / `_classify` at `snake_controller.dart` 143–157 and 278–288 match the
  Ahead/food/neighbour claim.
- `buildTurnQuestion` criteria keys `left` / `right` / `straight` at 160–171; `step` reads
  `answers['turn']?.choice` at 194–197; `LayaAnswer.choice` carries `probabilities` and `confidence`
  at `answers.dart` 55–66 and 93–112.
- `SnakeScreen` awaits `step` and redraws only (`snake_screen.dart` 32–38, 57–73).
- Board-only turn tests assert heading/head at `snake_controller_test.dart` 85–120; predict capture
  test at 302–366 observes request locals only.
- Library open/predict freeze sentence is at `classic-snake-example.md:39`, now cited.
- `0010-restart-on-death` title at `STATE.yaml` lines 1–4 supports out-of-scope separation; no false
  phase claim.
- Options table now includes returning the record from `step`.
- Sandbox solution supports “VM `flutter test` is not a session-load proof” (lines 30–30), not the
  classic-rules inject/no-session rule (that rule is at `classic-snake-example.md` 31–33).

## Per-criterion results

N/A — research review.

## Findings

### F-001 — Classic-rules inject/no-session sentence cites the sandbox solution

- Severity: NIT
- Location: `wiki/work/0008-snake-choice-log/00-research.md:65`
- Criterion affected: none
- Observation: The constraint states that classic-rules tests inject predict and do not open a
  session, then cites `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`. That file explains
  why a VM test is not a session-load proof. The inject-and-no-session product rule is at
  `wiki/product/classic-snake-example.md` lines 31–33. The second sentence of the constraint is
  supported by the sandbox file; the first sentence is not.
- Why it matters: Provenance for the harness rule is slightly misattached; the constraint content
  itself matches classic-snake product text already listed under Sources.

## Recurrence check

- Previous round: `wiki/work/0008-snake-choice-log/validation/research-review-01.md`
- Recurring findings: none
- Oscillating: no

Round-01 status against this artifact:

| Round 01                                       | Status in round 02                                                                     |
|------------------------------------------------|----------------------------------------------------------------------------------------|
| F-001 (library API freeze cited outside range) | Addressed — Source now includes `classic-snake-example.md` line 39                     |
| F-002 (false 0007 phase claim)                 | Addressed — cites `0010-restart-on-death` by title only                                |
| F-003 (return-value seam omitted)              | Addressed — Options row rejects returning the record from `step`                       |
| F-004 (probability key labels on wrong ranges) | Addressed — criteria keys tied to `buildTurnQuestion` 160–171                          |
| F-005 (sandbox source unused)                  | Addressed — Constraints references the sandbox file; not the same defect as F-001 here |

No material identity with round-01 findings. Escalation for oscillation is not warranted.

## Routing

| Finding       | Belongs to phase |
|---------------|------------------|
| (no blockers) | —                |
