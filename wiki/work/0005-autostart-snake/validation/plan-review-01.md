# Plan review — round 01

- Work item: 0005-autostart-snake
- Reviewed artifact: `wiki/work/0005-autostart-snake/01-plan.md` (with `02-criteria.md`,
  `04-product-contract.md`)
- Reviewer: plan-validator
- Date: 2026-09-27

## Verdict

**PASS**

Every acceptance criterion maps to a unit, the plan stays inside the product contract, and codebase
assumptions about the example root, play control, and idle widget test hold; the only defect is an
incomplete unit-scenario expected outcome for the successful Snake navigation half of AC-001.

## Verification performed

Criterion hygiene and plan prose checks:

```text
$ rg -n '```' wiki/work/0005-autostart-snake/01-plan.md; echo exit:$?
exit:1

$ rg -n 'correctly|properly|as expected' wiki/work/0005-autostart-snake/02-criteria.md || echo 'criteria: no vague adverbs'
criteria: no vague adverbs

$ test ! -f wiki/work/0005-autostart-snake/03-tasks.md && echo '03-tasks.md absent'
03-tasks.md absent

$ python3 tools/lint_wiki.py
warning: wiki/work/0006-snake-platform-launch: no 01-plan.md yet.
lint_wiki: clean (1 warning(s)).
```

Codebase claims used by the plan (example root, idle pump, open path chrome):

```text
$ sed -n '15,17p' example/lib/main.dart
void main() {
  runApp(const ExampleApp());
}

$ sed -n '36,50p' example/lib/main.dart
/// The idle home does not open an ONNX session. Opening happens only when the
/// user starts Snake, so VM widget tests can pump this tree safely.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'laya_flutter example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const ExampleHomePage(),
    );
  }
}

$ sed -n '114,117p' example/lib/main.dart
              FilledButton(
                onPressed: _opening ? null : _openSnake,
                child: Text(_opening ? 'Opening…' : 'Play Snake'),
              ),

$ sed -n '8,13p' example/test/widget_test.dart
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Laya'), findsWidgets);
    expect(find.text('Play Snake'), findsOneWidget);
    // Idle pump must not require or trigger ONNX session open.
    expect(find.text('Opening…'), findsNothing);
```

`03-tasks.md` is absent; the plan does not mark work parallel. Parallelism safety was not
applicable.

## Per-criterion results

Plan-phase coverage map (not an implementation review). Result means whether a unit addresses the
criterion without a coverage gap found in this round.

| Criterion | Result | Evidence (file:line)                                              | Negative case in plan scenarios                                                                                                   |
|-----------|--------|-------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| AC-001    | pass   | `01-plan.md:27–35` (U1), `01-plan.md:39–46` (U2), `01-plan.md:62` | partial — play absent and opening/failure chrome named; successful Snake navigation only outside unit scenario tables (see F-001) |
| AC-002    | pass   | `01-plan.md:46` (U2)                                              | yes — `01-plan.md:46`                                                                                                             |
| AC-003    | pass   | `01-plan.md:33`, `01-plan.md:56–57` (U1/U3)                       | yes — `01-plan.md:57`                                                                                                             |
| AC-004    | pass   | `01-plan.md:33`, `01-plan.md:56` (U1/U3)                          | yes — Play Snake not required (`01-plan.md:56`)                                                                                   |
| AC-005    | pass   | `01-plan.md:35` (U1)                                              | yes — `01-plan.md:35`                                                                                                             |
| AC-006    | pass   | `01-plan.md:92–94` (verification approach), `01-plan.md:89`       | yes — VM test must not be treated as session-load proof                                                                           |

## Findings

### F-001 — Successful Snake navigation is missing from unit scenario expected outcomes

- Severity: IMPORTANT
- Location: `wiki/work/0005-autostart-snake/01-plan.md:34`
- Criterion affected: AC-001
- Observation: AC-001 and R-001 require that after a successful open the Classic Snake screen is
  presented (`02-criteria.md:12`, `04-product-contract.md:18`). Goal prose (`01-plan.md:5`),
  Interfaces (`01-plan.md:62`), and Verification approach (`01-plan.md:94`) state that navigation.
  U1’s “Autostart begins open” scenario claims Covers R-001 and AE-001 but its expected outcome
  stops at play-button absence and opening (or failure) chrome (`01-plan.md:34`). U2’s
  production-path scenario expected outcome stops at root construction and no open before runApp (
  `01-plan.md:45`). No unit scenario names successful open → Snake presented as an expected outcome.
- Why it matters: Implement and verify can treat AC-001 as satisfied by chrome-only checks and skip
  the success-navigation half that the criterion and contract require.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| F-001   | plan             |
