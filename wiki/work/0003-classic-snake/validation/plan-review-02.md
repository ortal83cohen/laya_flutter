# Plan review — round 02

- Work item: 0003-classic-snake
- Reviewed artifact: `wiki/work/0003-classic-snake/01-plan.md` (with `02-criteria.md`,
  `04-product-contract.md`)
- Reviewer: plan-validator
- Date: 2026-09-27

## Verdict

**PASS**

Every acceptance criterion maps to a unit with named scenarios, prior round blockers and importants
are closed in the normative Interfaces and unit tables, and the only residual defect is a
non-blocking risk-mitigation phrase that does not reintroduce a hard Interfaces requirement outside
the contract.

## Verification performed

Criterion hygiene and plan prose checks:

```text
$ rg -n '```' wiki/work/0003-classic-snake/01-plan.md || echo 'no code fences'
no code fences

$ rg -n 'correctly|properly|as expected' wiki/work/0003-classic-snake/02-criteria.md || echo 'criteria: no vague adverbs'
criteria: no vague adverbs

$ rg -n 'fail|surface|error|stopped|hung' wiki/work/0003-classic-snake/04-product-contract.md || echo 'contract: no predict-failure UX terms'
contract: no predict-failure UX terms

$ rg -n 'Surface|surface|fail' wiki/work/0003-classic-snake/01-plan.md
17:... semantic keys fail. ...
70:| Predict error ends step cleanly | ... | Board is not advanced and no turn is invented | R-004 |
99:Error handling: if predict fails, the step does not invent a turn and does not advance. ...
111:| Logic tests accidentally open an ONNX session | ... | Tests fail for sandbox ...
113:| Predict failure leaves the UI unclear | ... | Surface failure and stop stepping; do not invent turns | ...

$ python3 tools/lint_wiki.py
lint_wiki: clean (0 warning(s)).

$ test ! -f wiki/work/0003-classic-snake/03-tasks.md && echo '03-tasks.md absent'
03-tasks.md absent

$ rg -n 'parallel|Parallel' wiki/work/0003-classic-snake/01-plan.md || echo 'no parallel markers'
no parallel markers
```

Codebase claims used by the plan (predict shape, choice answers, skeleton example, macOS session
solution):

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

$ sed -n '38,46p' lib/src/answers.dart
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

$ sed -n '93,94p' lib/src/answers.dart
  /// Chosen option key when [type] is choice.
  final String? choice;

$ rg -n 'SkeletonHomePage|Replace this page' example/lib/main.dart
22:      home: const SkeletonHomePage(),
27:class SkeletonHomePage extends StatelessWidget {
43:                'Replace this page with the first screen of your app.',

$ test -f wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md && echo 'macos session solution: present'
macos session solution: present
```

`03-tasks.md` is absent; the plan does not mark work parallel. Parallelism safety was not
applicable.

Round-01 defect locations re-checked on the patched plan (not trusted from author claims):

| Round-01 finding                        | Patched evidence                                                                                                            |
|-----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| F-001 Interfaces user-visible surfacing | Removed from `01-plan.md:99` and U3 `01-plan.md:70`; only residual risk phrasing at `01-plan.md:113` (see F-001 this round) |
| F-002 unset question id                 | Decided as string `turn` at `01-plan.md:87`                                                                                 |
| F-003 open wall geometry                | Single outside-is-wall rule, width/height 12 for screen, at `01-plan.md:101`                                                |
| F-004 missing right-turn scenario       | Present at `01-plan.md:40` (with left/straight at `01-plan.md:39–41`)                                                       |
| F-005 missing further-step-after-ended  | Wall and body scenarios at `01-plan.md:43–44`                                                                               |

## Per-criterion results

Plan-phase coverage map (not an implementation review). Result means whether a unit addresses the
criterion without a coverage gap found in this round.

| Criterion | Result | Evidence (file:line)                                                   | Negative case in plan scenarios                                                             |
|-----------|--------|------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| AC-001    | pass   | `01-plan.md:37–38`, `01-plan.md:45` (U1)                               | yes — `01-plan.md:38`, `01-plan.md:45`                                                      |
| AC-002    | pass   | `01-plan.md:55–56`, `01-plan.md:87–89` (U2)                            | yes — `01-plan.md:56`                                                                       |
| AC-003    | pass   | `01-plan.md:39–41` (U1), `01-plan.md:68`, `01-plan.md:91`              | yes — right and straight named; absolute remapping rejected in AC text and U2 keys scenario |
| AC-004    | pass   | `01-plan.md:67–68` (U3)                                                | yes — `01-plan.md:67`                                                                       |
| AC-005    | pass   | `01-plan.md:81–82` (U4)                                                | yes — `01-plan.md:81`                                                                       |
| AC-006    | pass   | `01-plan.md:43–44` (U1), `01-plan.md:99`                               | yes — second step after ended at `01-plan.md:43–44`                                         |
| AC-007    | pass   | `01-plan.md:57` (U2), `01-plan.md:87`                                  | yes — `01-plan.md:57`                                                                       |
| AC-008    | pass   | `01-plan.md:33`, `01-plan.md:63`, `01-plan.md:125` (U1/U3 constraints) | yes — session open forbidden                                                                |
| AC-009    | pass   | `01-plan.md:80` (U4)                                                   | yes — hard-coded turns rejected by expected outcome                                         |

## Findings

### F-001 — Risk mitigation still tells implementers to surface predict failure

- Severity: IMPORTANT
- Location: `wiki/work/0003-classic-snake/01-plan.md:113`
- Criterion affected: none (contract boundary remnant)
- Observation: The normative Error handling clause now limits predict failure to “does not invent a
  turn and does not advance” (`01-plan.md:99`), and U3’s error scenario expects only “Board is not
  advanced and no turn is invented” (`01-plan.md:70`). Those match R-004 without adding UX. The
  Risks row still mitigates “Predict failure leaves the UI unclear” with “Surface failure and stop
  stepping” (`01-plan.md:113`). `04-product-contract.md` still has no
  fail/surface/error/stopped/hung terms. This is weaker than round-01 F-001 (which was a hard
  Interfaces requirement), but an implementer can still read the risk table as licensing
  user-visible failure UI outside the contract, contrary to `01-plan.md:25`.
- Why it matters: Residual guidance outside the product contract can expand scope during implement
  without an R-ID or AC to check against.

## Recurrence check

- Previous round: `wiki/work/0003-classic-snake/validation/plan-review-01.md`
- Recurring findings: none that are materially identical. Round-01 F-001 (BLOCKER: Interfaces
  required user-visible surfacing at former `01-plan.md:97` / U3 “surfaced”) is not re-asserted as a
  blocker; this round’s F-001 is a weaker remnant in the Risks table only. Round-01 F-002 through
  F-005 do not recur.
- Oscillating: no

## Routing

| Finding | Belongs to phase                                                                                                                                           |
|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| F-001   | plan (optional cleanup of risk mitigation wording; not required to reopen research or block implement if the main agent records acceptance of the remnant) |
