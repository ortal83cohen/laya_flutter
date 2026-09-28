# Plan review — round 01

- Work item: 0003-classic-snake
- Reviewed artifact: `wiki/work/0003-classic-snake/01-plan.md` (with `02-criteria.md`, `04-product-contract.md`)
- Reviewer: plan-validator
- Date: 2026-09-27

## Verdict

**CONDITIONAL**

Every acceptance criterion maps to a unit, but the plan adds user-visible predict-failure behaviour that `04-product-contract.md` does not state, contradicting its own no-extra-behaviour claim, so that blocker must close before the plan proceeds.

## Verification performed

Criterion hygiene and plan prose checks:

```text
$ rg -n '```' wiki/work/0003-classic-snake/01-plan.md || echo 'no code fences'
no code fences

$ rg -n 'correctly|properly|as expected' wiki/work/0003-classic-snake/02-criteria.md || echo 'criteria: no vague adverbs'
criteria: no vague adverbs

$ rg -n 'fail|surface|error|stopped' wiki/work/0003-classic-snake/04-product-contract.md || echo 'contract: no predict-failure UX terms'
contract: no predict-failure UX terms

$ python3 tools/lint_wiki.py
lint_wiki: clean (0 warning(s)).
```

Codebase claims used by the plan (predict shape, skeleton example, macOS session solution):

```text
$ sed -n '56,63p' lib/src/loaded_runtime.dart
  /// Runs offline inference for one [state] and a non-empty question map or list.
  ///
  /// [state] is a [String] or a [Map] of [String] to [String].
  /// [questions] is a [Map] of id to [LayaQuestion], or a [List] of [LayaQuestion].
  Future<Map<String, LayaAnswer>> predict(
    Object state,
    Object questions,
  ) async {

$ sed -n '29,39p' lib/src/answers.dart
final class LayaQuestion {
  /// Creates a question with a caller-chosen [id].
  const LayaQuestion({
    required this.id,
    required this.type,
    required this.instructions,
    required this.criteria,
  });

  /// Caller-chosen question id.
  final String id;

$ rg -n 'SkeletonHomePage|Replace this page' example/lib/main.dart
22:      home: const SkeletonHomePage(),
27:class SkeletonHomePage extends StatelessWidget {
43:                'Replace this page with the first screen of your app.',

$ test -f wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md && echo 'macos session solution: present'
macos session solution: present

$ test ! -f wiki/work/0003-classic-snake/03-tasks.md && echo '03-tasks.md absent'
03-tasks.md absent
```

`03-tasks.md` is absent; the plan does not mark work parallel. Parallelism safety was not applicable.

## Per-criterion results

Plan-phase coverage map (not an implementation review). Result means whether a unit addresses the criterion without a coverage gap found in this round.

| Criterion | Result | Evidence (file:line) | Negative case in plan scenarios |
|---|---|---|---|
| AC-001 | pass | `01-plan.md:37–38`, `01-plan.md:43` (U1) | yes — `01-plan.md:38`, `01-plan.md:43` |
| AC-002 | pass | `01-plan.md:53–54` (U2) | yes — `01-plan.md:54` |
| AC-003 | pass | `01-plan.md:39–40` (U1), `01-plan.md:66` (U3), `01-plan.md:89` | partial — left and straight exercised; right not named in a scenario (see F-004) |
| AC-004 | pass | `01-plan.md:65–66` (U3) | yes — `01-plan.md:65` |
| AC-005 | pass | `01-plan.md:79–80` (U4) | yes — `01-plan.md:80` |
| AC-006 | pass | `01-plan.md:41–42` (U1) | partial — ended asserted; further step attempts not named (see F-005) |
| AC-007 | pass | `01-plan.md:55` (U2) | yes — `01-plan.md:55` |
| AC-008 | pass | `01-plan.md:33`, `01-plan.md:61`, `01-plan.md:123` (U1/U3 constraints) | yes — stated as forbidden session open |
| AC-009 | pass | `01-plan.md:78` (U4) | yes — hard-coded turns rejected by expected outcome |

## Findings

### F-001 — Predict-failure user surfacing is outside the product contract

- Severity: BLOCKER
- Location: `wiki/work/0003-classic-snake/01-plan.md:97`
- Criterion affected: none (contract boundary; also reflected at `01-plan.md:68`)
- Observation: Interfaces require that on predict failure “the example surfaces the failure in a way the user can see that play stopped” (`01-plan.md:97`). U3’s error scenario likewise expects the failure to be “surfaced” (`01-plan.md:68`). `04-product-contract.md` has no requirement, flow, or acceptance example for predict-failure UX (search for fail/surface/error/stopped terms returned no matches). The plan also asserts “This plan adds no behaviour that file does not state” (`01-plan.md:25`), which this clause contradicts. The no-invented-turn / no-successful-advance half aligns with R-004/R-007; the user-visible surfacing half does not appear in the contract.
- Why it matters: User-visible behaviour in the plan but not in the product contract is a plan defect; implementers and verify would treat failure UI as in scope without a requirement to check.

### F-002 — Choice question id is never decided

- Severity: IMPORTANT
- Location: `wiki/work/0003-classic-snake/01-plan.md:85`
- Criterion affected: AC-002, AC-003, AC-009
- Observation: Shared decisions fix keys left/right/straight and one question per step (`01-plan.md:85`) and say the step “reads the choice answer for the relative-turn question” (`01-plan.md:59`), but never name the `LayaQuestion.id` used to build the question map and to index `Map<String, LayaAnswer>` returned by `LoadedRuntime.predict` (`lib/src/answers.dart:38–39`, `lib/src/loaded_runtime.dart:40–63`). The injectable seam description (`01-plan.md:93`) likewise omits the id.
- Why it matters: Controller, screen closure, and logic tests must agree on one id to read `LayaAnswer.choice`; leaving it open invites inconsistent fixtures and brittle AC-002/AC-003/AC-009 checks.

### F-003 — Wall geometry is left as an unresolved alternative

- Severity: IMPORTANT
- Location: `wiki/work/0003-classic-snake/01-plan.md:99`
- Criterion affected: AC-006
- Observation: Board geometry says walls are “the cells outside the playable interior (or the perimeter rule the controller documents in comments)” and that exact dimensions are “an implementer choice” (`01-plan.md:99`). That is two wall models plus an open grid size, not one shared decision.
- Why it matters: Wall collision for AC-006/R-006 depends on which cells count as walls; an implementer can satisfy the letter of U1 under either reading and still disagree with another unit’s board fixtures.

### F-004 — AC-003’s right-turn case is not named in unit scenarios

- Severity: IMPORTANT
- Location: `wiki/work/0003-classic-snake/01-plan.md:39`
- Criterion affected: AC-003
- Observation: AC-003’s how-checked text requires east+left → north, then “repeat for right and straight on fixed boards” (`02-criteria.md:14`). U1 names only “Relative left turn” for heading change (`01-plan.md:39`). Straight appears in the wall scenario without a heading assertion (`01-plan.md:41`) and in U3’s complete-then-advance case (`01-plan.md:66`). No scenario names a right-turn heading outcome. Shared prose at `01-plan.md:89` states the rotation rule but is not a test scenario.
- Why it matters: Without a right-turn scenario, AC-003’s required cases can silently shrink to left-only during implement/verify.

### F-005 — AC-006’s “further step attempts” outcome is missing from collision scenarios

- Severity: IMPORTANT
- Location: `wiki/work/0003-classic-snake/01-plan.md:41`
- Criterion affected: AC-006
- Observation: AC-006 requires asserting ended and that “further step attempts do not move the snake as a continuing play” (`02-criteria.md:17`). U1 wall ends with “Game is ended; play does not continue into the wall” (`01-plan.md:41`) and body ends with only “Game is ended” (`01-plan.md:42`). Neither scenario’s action/outcome names a further step attempt after ended is true. Collision error handling at `01-plan.md:97` says stepping stops, but that line is not a unit scenario.
- Why it matters: The ended flag alone does not prove AC-006’s negative case that live stepping continues after collision.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| F-001 | plan (contract boundary; either drop the user-visible surfacing from the plan or add it to `04-product-contract.md` and re-validate — not an implement-phase patch) |
| F-002 | plan |
| F-003 | plan |
| F-004 | plan |
| F-005 | plan |
