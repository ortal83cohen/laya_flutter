# Plan review — round 01

- Work item: 0011-snake-prompt-wording
- Reviewed artifact: `wiki/work/0011-snake-prompt-wording/01-plan.md` (with `02-criteria.md`,
  `04-product-contract.md`)
- Reviewer: plan-validator
- Date: 2026-09-28

## Verdict

**PASS**

Every acceptance criterion maps to a unit with input-action-outcome scenarios inside the product
contract, shared English and relative-side choices are decided, and codebase checks confirm today’s
builders, closed option verdicts, and no-post-predict-rewrite apply path match the plan’s “leave
alone” claims; remaining defects are non-blocking coverage gaps.

## Verification performed

Criterion hygiene and plan prose checks:

```text
$ rg -n '```' wiki/work/0011-snake-prompt-wording/01-plan.md || echo 'no code fences'
no code fences

$ rg -n 'correctly|properly|as expected' wiki/work/0011-snake-prompt-wording/02-criteria.md || echo 'criteria: no vague adverbs'
criteria: no vague adverbs

$ rg -n 'parallel|Parallel' wiki/work/0011-snake-prompt-wording/01-plan.md || echo 'no parallel markers'
no parallel markers

$ test ! -f wiki/work/0011-snake-prompt-wording/03-tasks.md && echo '03-tasks.md absent'
03-tasks.md absent

$ python3 tools/lint_wiki.py
lint_wiki: clean (0 warning(s)).
```

Codebase claims used by the plan (current instructions, state template, apply path, closed verdicts,
product note):

```text
$ sed -n '217,247p' example/lib/snake_controller.dart
  String buildStateString() {
    ...
    return 'Heading ${heading.name}. Head $h. Food $foodText. '
        'Left $leftKind. Right $rightKind. Ahead $aheadKind.';
  }
  ...
  LayaQuestion buildTurnQuestion() {
    return LayaQuestion(
      id: 'turn',
      type: LayaQuestionType.choice,
      instructions: 'Choose the best safe turn toward the food.',
      criteria: <String, String>{
        'left': _optionVerdict('left'),
        'right': _optionVerdict('right'),
        'straight': _optionVerdict('straight'),
      },
    );
  }

$ sed -n '279,318p' example/lib/snake_controller.dart
    final LayaAnswer? turn = answers['turn'];
    final String? choice = turn?.choice;
    ...
    _applyChoiceAndAdvance(choice);
  ...
  void _applyChoiceAndAdvance(String choice) {
    ...
    if (_isWall(next) || _isBody(next)) {
      ended = true;
      return;
    }

$ sed -n '427,456p' example/lib/snake_controller.dart
  String _optionVerdict(String relative) {
    ...
      return 'Blocked. Wall.';
    ...
      return 'Blocked. Body.';
    ...
      return 'Best. Eat the food now.';
    ...
      return 'Open. Empty cell.';
    ...
          ? 'Best. Closer to the food.'
          : 'Slower. Also closer to the food.';
    ...
          ? 'Best. Least far from the food.'
          : 'Worse. Farther from the food.';
    ...
        ? 'Best. Same distance to the food.'
        : 'Same. Not closer to the food.';
  }

$ test -f wiki/product/classic-snake-example.md && echo 'product note present'
product note present
```

AE geometry check (Manhattan and relative side for east heading):

```text
$ python3 -c "print(abs(3-2)+abs(1-1), abs(4-4)+abs(45-0), abs(5-2)+abs(3-1))"
1 45 5
```

`03-tasks.md` is absent; the plan does not mark work parallel. Parallelism safety was not
applicable.

## Per-criterion results

Plan-phase coverage map (not an implementation review). Result means whether a unit addresses the
criterion without a coverage gap found in this round.

| Criterion | Result | Evidence (file:line)                                                           | Negative case exercised                                                          |
|-----------|--------|--------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| AC-001    | pass   | `01-plan.md:25–34` (U1 Exact instructions)                                     | yes — `02-criteria.md:12`; U1 also bans hunger on option lines (`01-plan.md:36`) |
| AC-002    | pass   | `01-plan.md:38–45` (U2 Food ahead distance one)                                | yes — `02-criteria.md:13`; U2 No Toward food (`01-plan.md:50`)                   |
| AC-003    | pass   | `01-plan.md:46` (U2 Food right with wall left)                                 | yes — `02-criteria.md:14`                                                        |
| AC-004    | pass   | `01-plan.md:47` (U2 Diagonal two sides)                                        | yes — `02-criteria.md:15`                                                        |
| AC-005    | pass   | `01-plan.md:48` (U2 Food absent)                                               | yes — `02-criteria.md:16`; scenario expects no Distance / Food is                |
| AC-006    | pass   | `01-plan.md:34–35` (U1 Option lines unchanged)                                 | yes — `02-criteria.md:17`                                                        |
| AC-007    | pass   | `01-plan.md:27–36` (U1 Done when + No hunger on options); `01-plan.md:70` (U4) | yes — `02-criteria.md:18`; banned planner words in U1/U4                         |
| AC-008    | pass   | `01-plan.md:52–59` (U3 Wall choice ends run)                                   | yes — `02-criteria.md:19`                                                        |
| AC-009    | pass   | `01-plan.md:63–72` (U4 Product note records decision)                          | yes — `02-criteria.md:20`                                                        |
| AC-010    | pass   | `01-plan.md:73` (U4 Session-free proof)                                        | yes — `02-criteria.md:27`                                                        |

## Findings

### F-001 — Distance-zero state behaviour has no acceptance criterion

- Severity: IMPORTANT
- Location: `wiki/work/0011-snake-prompt-wording/01-plan.md:39`
- Criterion affected: none
- Observation: U2’s Done when requires Distance 0 without Food is when distance is zero (
  `01-plan.md:39`). The product contract Assumptions state the same carve-out (
  `04-product-contract.md:59`). Interfaces repeat it (`01-plan.md:78`). No row in `02-criteria.md`
  asserts that case; AC-002 through AC-005 cover distance greater than zero or food absent only.
- Why it matters: Implement can ship Distance 0 with a Food is phrase (or omit Distance 0) and still
  pass every frozen criterion.

### F-002 — R-005 body-bound no-rewrite half is not in criteria or U3 scenarios

- Severity: IMPORTANT
- Location: `wiki/work/0011-snake-prompt-wording/02-criteria.md:19`
- Criterion affected: none (gap versus R-005)
- Observation: R-005 forbids replacing a wall-bound or body-bound choice after predict (
  `04-product-contract.md:22`). AC-008 and U3’s Wall choice ends run scenario cover only a
  wall-bound left (`02-criteria.md:19`, `01-plan.md:59`). No criterion or unit scenario names a
  body-bound returned key that must not be substituted.
- Why it matters: A post-predict rewrite that only rewrites body collisions could satisfy AC-008
  while still violating R-005.

### F-003 — Approach “appends” can be read as putting Distance after neighbours

- Severity: IMPORTANT
- Location: `wiki/work/0011-snake-prompt-wording/01-plan.md:9`
- Criterion affected: AC-002, AC-003
- Observation: The Approach sentence keeps heading, head, food, and left/right/ahead neighbour
  kinds, then says that when food exists the builder appends Distance and Food is (`01-plan.md:9`).
  That reading places those facts after Ahead. R-002 and AE-001/AE-002 place Distance and Food is
  between Food and Left (`04-product-contract.md:19`, `04-product-contract.md:37–38`). U2 Done when
  cites the R-002 templates (`01-plan.md:39`), so the normative unit text is correct; the Approach
  wording is still ambiguous.
- Why it matters: An implementer following Approach order alone would fail the exact-equality
  criteria even though Done when points at the contract.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| F-001   | plan             |
| F-002   | plan             |
| F-003   | plan             |
