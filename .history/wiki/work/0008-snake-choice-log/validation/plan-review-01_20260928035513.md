# Plan review — round 01

- Work item: 0008-snake-choice-log
- Reviewed artifact: `wiki/work/0008-snake-choice-log/01-plan.md` (with `02-criteria.md`, `04-product-contract.md`)
- Reviewer: plan-validator
- Date: 2026-09-28

## Verdict

**PASS**

Every acceptance criterion maps to a unit that realises its cited requirement, the plan stays inside the product contract, shared callback and record-shape decisions are closed in prose, and codebase assumptions about the predict inject seam, pre-step English state, silent failure paths, and absence of print/debugPrint hold.

## Verification performed

Criterion hygiene, plan prose, and wiki lint:

````text
$ rg -n '```' wiki/work/0008-snake-choice-log/01-plan.md; echo fenced_exit:$?
fenced_exit:1

$ rg -n 'correctly|properly|as expected' wiki/work/0008-snake-choice-log/02-criteria.md || echo 'criteria: no vague adverbs'
criteria: no vague adverbs

$ test ! -f wiki/work/0008-snake-choice-log/03-tasks.md && echo '03-tasks.md absent'
03-tasks.md absent

$ python3 - <<'PY'
from pathlib import Path
import re
plan = Path('wiki/work/0008-snake-choice-log/01-plan.md').read_text()
UNIT = re.compile(r'^### U\d+\.\s+\S')
FENCE = re.compile(r'^```')
units = [i+1 for i,l in enumerate(plan.splitlines()) if UNIT.match(l)]
fences = [i+1 for i,l in enumerate(plan.splitlines()) if FENCE.match(l)]
print('units_at_lines', units)
print('fences_at_lines', fences or 'none')
print('has_unit', bool(units))
print('has_fence', bool(fences))
PY
units_at_lines [29, 42, 55, 68]
fences_at_lines none
has_unit True
has_fence False

$ python3 tools/lint_wiki.py; echo lint_exit:$?
lint_wiki: clean (0 warning(s)).
lint_exit:0
````

Note on work-item 0007 (outside this slice): earlier in this same review session,
`lint_wiki` once reported
`error: wiki/work/0007-restart-on-death: number 0007 already used by 0007-model-load-progress.`
(with `warning: wiki/work/0007-model-load-progress: no 01-plan.md yet.`). The tree now has
`0007-model-load-progress` and `0010-restart-on-death`; the final lint run pasted above is
clean. **0008's own plan has neither a fenced-code-block failure nor a missing-unit
failure** (`units_at_lines [29, 42, 55, 68]`, `fences_at_lines none`).

Codebase claims used by the plan (constructor inject seam, step early returns, screen
wiring, no print/debugPrint in example):

```text
$ sed -n '56,81p' example/lib/snake_controller.dart
  SnakeController({
    required this.width,
    required this.height,
    required this.predict,
    required this.random,
    List<GridCell>? initialSnake,
    CardinalHeading initialHeading = CardinalHeading.east,
    GridCell? initialFood,
  }) : heading = initialHeading,
       _snake = List<GridCell>.from(
         initialSnake ??
             <GridCell>[
               const GridCell(2, 0),
               const GridCell(1, 0),
               const GridCell(0, 0),
             ],
       ) {
    if (width < 1 || height < 1) {
      throw ArgumentError('width and height must be positive');
    }
    if (initialFood != null) {
      food = initialFood;
    } else {
      spawnFood();
    }
  }

$ sed -n '179,199p' example/lib/snake_controller.dart
  Future<void> step() async {
    if (ended) {
      return;
    }
    final String state = buildStateString();
    final LayaQuestion question = buildTurnQuestion();
    final Map<String, LayaQuestion> questions = <String, LayaQuestion>{
      question.id: question,
    };
    final Map<String, LayaAnswer> answers;
    try {
      answers = await predict(state, questions);
    } catch (_) {
      return;
    }
    final String? choice = answers['turn']?.choice;
    if (choice == null || !_isRelativeTurnKey(choice)) {
      return;
    }
    _applyChoiceAndAdvance(choice);
  }

$ sed -n '32,39p' example/lib/snake_screen.dart
    _controller = SnakeController(
      width: 40,
      height: 40,
      random: math.Random(),
      // Real offline predict — not a local turn table.
      predict: (Object state, Object questions) =>
          runtime.predict(state, questions),
    );

$ rg -n 'print\(|debugPrint' example || echo 'example: no print/debugPrint'
example: no print/debugPrint

$ sed -n '55,112p' lib/src/answers.dart
# LayaAnswer.choice exposes choice, probabilities (Map<String, double>), and confidence
```

`03-tasks.md` is absent; the plan does not mark work parallel. Parallelism safety was not applicable.

## Per-criterion results

Plan-phase coverage map (not an implementation review). Result means whether a unit addresses the criterion without a coverage gap found in this round.

| Criterion | Result | Evidence (file:line)                                                      | Negative case in plan scenarios                                         |
| --------- | ------ | ------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| AC-001    | pass   | `01-plan.md:29–40` (U1); also `01-plan.md:76` (U4)                        | yes — `01-plan.md:40`, `01-plan.md:80`                                  |
| AC-002    | pass   | `01-plan.md:31`, `01-plan.md:37` (U1)                                     | yes — U2 failure paths leave cells unchanged (`01-plan.md:50–52`)       |
| AC-003    | pass   | `01-plan.md:42–53` (U2); also `01-plan.md:77` (U4)                        | yes — `01-plan.md:50`, `01-plan.md:53`                                  |
| AC-004    | pass   | `01-plan.md:51–53` (U2); also `01-plan.md:78` (U4)                        | yes — `01-plan.md:51–53`                                                |
| AC-005    | pass   | `01-plan.md:55–64` (U3); also `01-plan.md:79` (U4)                        | yes — `01-plan.md:64`                                                   |
| AC-006    | pass   | `01-plan.md:57`, `01-plan.md:65` (U3); `01-plan.md:88`                    | yes — omit callback / no line (`02-criteria.md:17`; plan review wiring) |
| AC-007    | pass   | `01-plan.md:40` (U1), `01-plan.md:68–80` (U4)                             | yes — `01-plan.md:80`                                                   |
| AC-008    | pass   | `01-plan.md:70`, `01-plan.md:76–78`, `01-plan.md:123` (U4 / verification) | yes — session open forbidden (`01-plan.md:70`, `01-plan.md:123`)        |

## Findings

None.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
| ------- | ---------------- |
| (none)  | —                |
