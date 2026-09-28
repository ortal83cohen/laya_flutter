# Research: Extra facts for hungry Snake and wall avoidance

## Question

Which extra facts can the English Snake state or the turn-option text carry so the model is told the
snake is hungry and should avoid walls, without a new action space?

## Answer

Keep keys `left` / `right` / `straight` and choice id `turn`. Put an explicit hunger-and-avoid-walls
sentence in the choice instructions, and add a few board facts the controller already computes but
does not put in the state string today: Manhattan distance from head to food, and which relative
side of the heading the food lies on. Leave the per-key verdicts as the place that names blocked
walls or body and closer or farther open cells. Do not add a path planner, a multi-step plan, or a
post-predict safety shield.

## Findings

### Closed action space already forbids new keys and shields

- Claim: The product goal fixes relative left, right, or straight turns; a wall or body ends the
  run; there is no step timer. Community absolute keys, planner text, and a post-model safety shield
  are deliberate rejections for this example. Opaque `A`/`B`/`C` and boolean keys stay unused.
  Survival length is not a success check.
- Evidence: Closed assumptions and SC-003 name relative turns and collision end. The product note
  rejects absolute keys, shields that override the model, opaque keys, and boolean keys, and states
  that survival length is not a success check.
- Source: `wiki/product/GOAL.md` lines 32–32, 43–43; `wiki/product/classic-snake-example.md` lines
  15–19.

### Current English state already carries heading, cells, and neighbour kinds

- Claim: `buildStateString` emits heading name, head cell, food cell or `none`, and the neighbour
  kind for relative left, right, and straight (`wall`, `body`, `food`, or `empty`). The turn verdict
  is intentionally not repeated in that string.
- Evidence: Builder return string and comment that the turn verdict lives on the option text.
- Source: `example/lib/snake_controller.dart` lines 214–230.

### Current instructions mention safe food-seeking but not hunger by name

- Claim: The choice question uses id `turn`, type choice, instructions
  `Choose the best safe turn toward the food.`, and criteria keys `left`, `right`, `straight` whose
  descriptions come from `_optionVerdict`.
- Evidence: `buildTurnQuestion` hard-codes that id, instructions, and three criteria entries.
- Source: `example/lib/snake_controller.dart` lines 233–248.

### Option text already encodes wall or body blocks and relative food distance

- Claim: For each relative key, `_optionVerdict` returns `Blocked. Wall.` or `Blocked. Body.` when
  the next cell is unsafe, `Best. Eat the food now.` when that cell is food, otherwise ranks open
  cells with Best / Slower / Worse / Same wording from Manhattan before and after the step and from
  `_bestFoodTurn`. `_manhattan` is the absolute column plus row distance between two cells.
- Evidence: `_optionVerdict`, `_bestFoodTurn`, and `_manhattan` implement those strings and scores
  without exposing the numeric distance in the state string.
- Source: `example/lib/snake_controller.dart` lines 399–460.

### Controller fields already supply every candidate fact without a planner

- Claim: Heading name, head column and row, food column and row, and neighbour kinds are already
  available through `heading`, `head`, `food`, and `_classify` on `_neighbourCell`. Manhattan
  distance is already computed by `_manhattan`. Whether a relative turn’s next cell is closer, same,
  or farther, and whether it is wall or body, is already decided inside `_optionVerdict`. A relative
  side for food (ahead, behind, left, right of the current heading) can be derived from head, food,
  and heading alone; no named helper exists today.
- Evidence: Public and private members listed above; no multi-step planner API appears on the
  controller.
- Source: `example/lib/snake_controller.dart` lines 155–159, 184–185, 217–230, 363–397, 427–460.

### Locked tests freeze today’s state substrings and exact verdict strings

- Claim: Controller tests require state substrings such as heading `east`, `Head (2,1)`,
  `Food (3,1)`, `Left empty`, `Right empty`, `Ahead food`, and also `Left wall` / `Ahead empty` in
  another fixture. They forbid the substring `Toward food` in state. They lock exact option strings
  such as `Best. Closer to the food.`, `Worse. Farther from the food.`, `Blocked. Wall.`,
  `Slower. Also closer to the food.`, and `Best. Eat the food now.`, and ban planner / shield /
  override / filter wording in instructions and option text. Keys must remain `left`, `right`,
  `straight` with id `turn`.
- Evidence: Assertions in the English-state and relative-turn test group.
- Source: `example/test/snake_controller_test.dart` lines 392–430, 432–473, 475–490, 519–553.

### Changing the prompt surface needs an explicit product decision for this slice

- Claim: The short English state string and choice id `turn` are called the slice’s fixed prompt
  contract; changing them for better play without a new product decision reopens SC-003’s prompt
  surface. This work item’s title is that prompt improvement while keeping the relative action
  space.
- Evidence: Product constraint paragraph; work-item title and goal check SC-003.
- Source: `wiki/product/classic-snake-example.md` lines 19–19;
  `wiki/work/0011-snake-prompt-wording/STATE.yaml` lines 3–4, 21–21.

### Prior prompt research chose relative keys; it did not freeze hunger wording or distance facts

- Claim: Work 0003 recommended relative keys plus short English state with cardinal heading, head
  and food cells, and immediate neighbour kinds. It left unresolved whether relative food offsets
  beat absolute coordinates, and whether planner-enriched option text is required for long survival.
  It did not require the words hungry or avoid walls.
- Evidence: Chosen option and unresolved list in that research file.
- Source: `wiki/work/0003-classic-snake/research/prompt.md` lines 7–9, 45–50, 61–65, 78–80.

### Predict still applies the model’s key with no post-choice rewrite

- Claim: After predict returns, `step` accepts only `left` / `right` / `straight` and then applies
  that key; there is no branch that replaces a wall choice with a safer key. Shared design for this
  item keeps that rule.
- Evidence: Choice acceptance and `_applyChoiceAndAdvance` path; product rejection of a shield that
  overrides the model.
- Source: `example/lib/snake_controller.dart` lines 279–298, 309–326;
  `wiki/product/classic-snake-example.md` lines 17–17.

### Solutions index does not prescribe Snake prompt facts

- Claim: The only solutions summary concerns macOS ONNX session load and sandbox cache exceptions,
  not Snake state or option wording.
- Evidence: Solution title and summary frontmatter.
- Source: `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` lines 1–8.

### Whether any wording raises model confidence is not measured here

-
Claim: [UNVERIFIED: that adding hunger, avoid-walls, Manhattan, or relative food-side text will raise
`LayaAnswer.confidence` or improve turn quality on `laya-multilingual`.] No repository check records
that effect for these strings.
- Evidence: No test or wiki artifact asserts confidence or survival after such wording. SC-003 does
  not measure survival length.
- Source: `wiki/product/classic-snake-example.md` lines 19–19;
  `example/test/snake_controller_test.dart` lines 432–553 (locks shape and banned phrases, not
  confidence gains).

## Options considered

| Option                                                                                                                     | How it works                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Cost                                                                                                                                                            | Why rejected / chosen                                                                                                                                                                                                          |
|----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| (1) Instruction sentence only: hunger plus avoid walls; state string unchanged                                             | Change `instructions` so the model is told the snake is hungry and should avoid walls (and still seek food). Keep `buildStateString` as today. Keep keys and id. Leave `_optionVerdict` strings as today’s ranking language.                                                                                                                                                                                                                                                                                                   | One string edit; update any test that joins instructions only if banned words appear; state `contains` checks stay valid                                        | **Rejected as the sole change.** It meets the hunger and avoid-walls wording request, but leaves unused the distance and relative-side facts the controller already computes, and the user asked to consider adding more data. |
| (2) Richer state only: add facts such as Manhattan distance and which relative side the food is on; instructions unchanged | Extend `buildStateString` with distance and relative food side derived from head, food, and heading. Keep instructions `Choose the best safe turn toward the food.` Keep option verdicts.                                                                                                                                                                                                                                                                                                                                      | State builder plus test updates for new substrings; must keep existing `contains` facts and must not introduce `Toward food` unless that lock is revised        | **Rejected as the sole change.** It adds data the options already hint at only per turn, but never says hungry and only implies wall avoidance via neighbour kinds and option `Blocked` text, missing the user’s wording ask.  |
| (3) Both a hunger and avoid-walls instruction and a few extra state facts                                                  | Instructions name hunger and avoiding walls while still choosing a relative turn toward food. State keeps today’s heading, head, food, and neighbour kinds, and adds Manhattan distance to food plus the food’s relative side (ahead / behind / left / right of heading). Option text keeps wall/body Blocked and closer/farther Best/Slower/Worse/Same language, without planner, multi-step plan, or shield wording. Keys stay `left` / `right` / `straight`; id stays `turn`; nothing after predict replaces a wall choice. | Instruction edit, state append, and test updates for exact verdict locks if any option wording shifts; product note on prompt surface must record this decision | **Chosen.** Satisfies the user’s hunger and avoid-walls wording and the request to consider more data, using only fields and helpers the controller already has, without a new action space, planner, or shield.               |

## Constraints discovered

- Action space stays relative `left` / `right` / `straight` with choice id `turn` (
  `wiki/product/GOAL.md` line 32; `example/lib/snake_controller.dart` lines 238–247; shared design
  for this work item).
- Nothing after predict may replace a wall choice with a safe one (
  `example/lib/snake_controller.dart` lines 279–326; `wiki/product/classic-snake-example.md` line
  17).
- No absolute `UP`/`DOWN`/`LEFT`/`RIGHT` keys, no `A`/`B`/`C`, no boolean keys (
  `wiki/product/classic-snake-example.md` lines 17–17; `example/test/snake_controller_test.dart`
  lines 449–469).
- No path planner, multi-step plan, or safety shield in question text (
  `example/test/snake_controller_test.dart` lines 475–490; shared design).
- Candidate facts must tie to controller fields already present: heading, head, food, neighbour
  classification, `_manhattan`, and the closer/same/farther and wall/body checks inside
  `_optionVerdict` (`example/lib/snake_controller.dart` lines 155–185, 217–230, 386–460).
- State must remain a short English `String` (or an allowed string map at the library boundary); the
  example sends a `String` today (`example/lib/snake_controller.dart` lines 262–270;
  `lib/src/tokenize.dart` lines 98–108).
- Tests lock many state substrings, forbid `Toward food` in state, and lock several exact criteria
  strings; any wording change must update those locks in the same slice (
  `example/test/snake_controller_test.dart` lines 392–430, 443–445, 540–540).
- Changing the English state or prompt for play quality is a product decision for this work item,
  not a silent tweak (`wiki/product/classic-snake-example.md` line 19;
  `wiki/work/0011-snake-prompt-wording/STATE.yaml` lines 3–4).

## Unresolved

- [UNRESOLVED: whether hunger-and-avoid-walls instructions plus Manhattan and relative food-side state raise choice confidence or reduce wall choices on
  `laya-multilingual` for this example’s boards.]
- [UNRESOLVED: the exact English sentence for instructions and the exact phrases for distance and relative food side, pending plan and frozen criteria.]
- [UNRESOLVED: whether option verdict strings should also mention hunger, or whether instructions alone should carry that word so the locked Best/Slower/Worse/Blocked phrases can stay.]

## Sources

- `wiki/product/GOAL.md`, consulted 2026-09-28
- `wiki/product/classic-snake-example.md`, consulted 2026-09-28
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-28
- `wiki/work/0011-snake-prompt-wording/STATE.yaml`, consulted 2026-09-28
- `wiki/work/0003-classic-snake/research/prompt.md`, consulted 2026-09-28
- `example/lib/snake_controller.dart`, consulted 2026-09-28
- `example/test/snake_controller_test.dart`, consulted 2026-09-28
- `lib/src/tokenize.dart`, consulted 2026-09-28
