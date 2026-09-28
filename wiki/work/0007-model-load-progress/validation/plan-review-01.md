# Plan review — round 01

- Work item: 0007-model-load-progress
- Reviewed artifact: `wiki/work/0007-model-load-progress/01-plan.md` (with `02-criteria.md`,
  `04-product-contract.md`)
- Reviewer: plan-validator
- Date: 2026-09-28

## Verdict

**FAIL**

U1’s opening-active happy path requires inspecting the home tree while open is in progress, but the
plan never decides a VM-safe way to reach that state, and the only production path that sets the
private opening flag also awaits library open.

## Verification performed

Plan prose and criteria hygiene:

```text
$ rg -n '```' wiki/work/0007-model-load-progress/01-plan.md; echo fenced_exit:$?
fenced_exit:1

$ rg -n 'correctly|properly|as expected' wiki/work/0007-model-load-progress/02-criteria.md || echo 'criteria: no vague adverbs'
criteria: no vague adverbs

$ test ! -f wiki/work/0007-model-load-progress/03-tasks.md && echo '03-tasks.md absent'
03-tasks.md absent

$ python3 -c "from pathlib import Path; print('fenced_blocks', Path('wiki/work/0007-model-load-progress/01-plan.md').read_text().count('\`\`\`'))"
fenced_blocks 0

$ python3 tools/lint_wiki.py
lint_wiki: clean (0 warning(s)).
```

Codebase claims used by the plan (opening gate, chrome branch, idle pump, failure lock, public
signatures, no meter yet):

```text
$ sed -n '88,118p' example/lib/main.dart
class _ExampleHomePageState extends State<ExampleHomePage> {
  bool _opening = false;
  ...
  Future<void> _openSnake() async {
    if (_opening) {
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final LoadedRuntime runtime = await LayaFlutter.open(
        await resolveExampleCache(),
      );

$ sed -n '157,160p' example/lib/main.dart
              if (_opening) ...<Widget>[
                const SizedBox(height: 24),
                const Text('Opening…'),
              ],

$ sed -n '7,18p' example/test/widget_test.dart
  testWidgets('idle example home shows Laya without opening a session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    ...
    await tester.pump();
    ...
    expect(find.text('Opening…'), findsNothing);
  });

$ sed -n '48,85p' example/test/widget_test.dart
    expect(
      source.contains('Opening…'),
      isTrue,
      reason: 'existing opening label must remain',
    );
    ...
    expect(
      failureBody.contains('Could not open runtime:'),
      isTrue,
      ...
    );
    expect(
      failureBody.contains('SnakeScreen'),
      isFalse,
      ...
    );

$ sed -n '25,29p' lib/src/library.dart
  static Future<LoadedRuntime> open(
    Directory cache, {
    @visibleForTesting CheckpointDownloader? download,
    @visibleForTesting Future<OrtSession> Function(String path)? createSession,
  }) async {

$ sed -n '60,63p' lib/src/loaded_runtime.dart
  Future<Map<String, LayaAnswer>> predict(
    Object state,
    Object questions,
  ) async {

$ rg -n 'ProgressIndicator|CircularProgress|LinearProgress' example/ || echo 'NO_PROGRESS_INDICATOR_IN_EXAMPLE'
NO_PROGRESS_INDICATOR_IN_EXAMPLE
```

Parallelism check: `wiki/work/0007-model-load-progress/03-tasks.md` does not exist yet; no parallel
task file ownership to cross-check.

## Per-criterion results

Plan-phase coverage map (not an implementation review). Result means whether a unit addresses the
criterion without a coverage gap found in this round.

| Criterion | Result | Evidence (file:line)                                                                                                                                                            | Negative case in criteria |
|-----------|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------|
| AC-001    | fail   | `01-plan.md:33` (U1 opening chrome visible) and `01-plan.md:35` (Opening… retained) name coverage, but the opening-active tree path is not implementable as written — see F-001 | yes — `02-criteria.md:12` |
| AC-002    | fail   | same U1 happy path (`01-plan.md:33`); timer half of AC-002 is not in that scenario’s expected outcome — see F-001, F-002                                                        | yes — `02-criteria.md:13` |
| AC-003    | pass   | `01-plan.md:34` (Idle chrome absent)                                                                                                                                            | yes — `02-criteria.md:14` |
| AC-004    | pass   | `01-plan.md:45` (Failure path intact)                                                                                                                                           | yes — `02-criteria.md:15` |
| AC-005    | pass   | `01-plan.md:46` (Public signatures closed)                                                                                                                                      | yes — `02-criteria.md:16` |

## Findings

### F-001 — Opening-active tree inspection has no decided VM-safe seam

- Severity: BLOCKER
- Location: `wiki/work/0007-model-load-progress/01-plan.md:33`
- Criterion affected: AC-001, AC-002
- Observation: U1’s “Opening chrome visible” scenario takes input “Example home with open in
  progress” and action “Inspect the home tree”. In the code, `_opening` is private (
  `example/lib/main.dart:89`) and becomes true only inside `_openSnake`, which then awaits
  `LayaFlutter.open` (`example/lib/main.dart:111-118`). There is no test hook, inject, or other
  decided way to render that branch without scheduling open. Pumping `autostart: true` would
  schedule `_openSnake` after a frame (`example/lib/main.dart:93-104`) and hit the same open path —
  a risk the plan’s risk table does not name (`01-plan.md:61-66`). Criteria allow a source
  inspection (`02-criteria.md:12-13`), and U1 also has a source scenario for Opening… (
  `01-plan.md:35`), but the happy path that claims AE-001 / R-002 still demands a live tree during
  open without choosing source-only verification or a seam.
- Why it matters: An implementer cannot complete that scenario as written without inventing a
  harness (and may break the idle VM contract by turning autostart on in a widget test).

### F-002 — Opening-chrome scenario omits the no-fake-percent-timer half of AC-002

- Severity: IMPORTANT
- Location: `wiki/work/0007-model-load-progress/01-plan.md:33`
- Criterion affected: AC-002
- Observation: AC-002 requires both no numeric fraction and no wall-clock timer that invents a
  percentage (`02-criteria.md:13`). The U1 happy-path expected outcome only says the meter has no
  numeric fraction (`01-plan.md:33`). The timer ban appears in Interfaces and Risks (
  `01-plan.md:52`, `01-plan.md:64`) but not in any unit scenario expected outcome.
- Why it matters: Implement and verify can treat AC-002 as satisfied by an indeterminate valued-less
  meter while still adding a timer-driven fake percentage the criterion forbids.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| F-001   | plan             |
| F-002   | plan             |
