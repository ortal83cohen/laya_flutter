# Research: Exact strings one living Snake step scores today

## Question

What exact strings does one living Snake step embed for the model today, in what order, and which length caps can clip a longer hungry or avoid-walls sentence?

## Answer

One living step sends a short English state string, then one `choice` question id `turn` whose instructions are fixed and whose three criteria values are short verdict sentences keyed `left`, then `right`, then `straight`. The library renders those criteria as `key: description` in that same map order, encodes each option with a hard 48-token cap (the cap that would clip a longer hungry or avoid-walls option sentence), then places the state after the options under `maxLen` 512 with `headMaxLen` 192 shaping the question head. For heading east on row 0 with open right and straight and food south-east of the head, the scored option texts are `left: Blocked. Wall.`, `right: Best. Closer to the food.`, and `straight: Slower. Also closer to the food.`.

## Findings

### Prior solution does not prescribe Snake scored text

- Claim: The only solutions entry concerns macOS ONNX session load and sandbox cache exceptions. It does not name Snake state text, option verdicts, or tokenization length caps for prompts.
- Evidence: Solution summary and guidance stay on `integration_test` and entitlements.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` lines 1–40.

### Closed product surface keeps relative keys and no shield

- Claim: The goal and classic-Snake product note already fix relative `left` / `right` / `straight`, choice id `turn`, a short English state, no timer, and no post-model shield. This research only reads what that living surface embeds; it does not reopen those choices.
- Evidence: Closed assumptions and SC-003; product note on relative keys and prompt contract.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 28–32, 43–43; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md` lines 15–19, 31–33.

### Living state string is one fixed English template

- Claim: `buildStateString` returns exactly `Heading <heading.name>. Head <head>. Food <food or none>. Left <kind>. Right <kind>. Ahead <kind>.` where each `<kind>` is one of `wall`, `body`, `food`, or `empty` from `_classify`. There is no separate “hungry” or “avoid walls” clause in the state string today.
- Evidence: Template concatenation and classifier branches.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines 214–230, 386–396.

### Living turn question: fixed instructions and short verdict criteria

- Claim: `buildTurnQuestion` builds id `turn`, type choice, instructions exactly `Choose the best safe turn toward the food.`, and criteria map entries in declaration order `left`, `right`, `straight`, each value from `_optionVerdict` for that relative key. The closed verdict vocabulary today is only: `Blocked. Wall.`, `Blocked. Body.`, `Best. Eat the food now.`, `Open. Empty cell.`, `Best. Closer to the food.`, `Slower. Also closer to the food.`, `Best. Least far from the food.`, `Worse. Farther from the food.`, `Best. Same distance to the food.`, `Same. Not closer to the food.`. No living criteria string contains the words “hungry” or “avoid”.
- Evidence: Question builder and `_optionVerdict` return literals; `_bestFoodTurn` only selects which open turn may say `Best.` when distances compete.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines 233–248, 399–456.

### Step embeds those builders into predict in a fixed order

- Claim: `step` builds the state string first, then the turn question, then calls `predict(state, { 'turn': question })`. No other question id is added on a living step.
- Evidence: Locals and predict call inside `step`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines 258–270.

### Library option text is `key: description` in criteria map order

- Claim: For a choice question, `renderOptions` walks `criteria.entries` in map order and emits either `key` alone (empty description) or `key: <description>`. Snake always supplies non-empty descriptions, so each scored option string is `left: …`, then `right: …`, then `straight: …`. Softmax keys in `shapeAnswers` use the same `criteria.keys` order, so logit index `i` aligns with that rendered option.
- Evidence: `renderOptions` choice branch; `_choiceKeys` and choice shaping loop.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart` lines 120–133; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart` lines 197–202, 242–258.

### Sequence layout: head, then options with MASK, then state

- Claim: `buildSequence` builds token ids as `[CLS]` + encoded `choice question: <instructions>` + `[SEP]` + for each option (`[MASK]` + encoded ` <option text>`) + `[SEP]` + state tokens + `[SEP]`. Instructions have any mask-token substring replaced with a space before encode. Option text likewise replaces the mask token and is encoded with a leading space.
- Evidence: `buildSequence` assembly and encode calls.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart` lines 202–268.

### Caps that can clip longer option sentences

- Claim: Each option’s encode call passes `maxLength: 48`, keeping only the first 48 token ids of that option’s text (not including the prepended MASK id). That is the first hard clip on a longer hungry or avoid-walls option sentence. If the sum of option id lengths leaves `optBudget < 16` against `headMaxLen` (default 192), each option list is further cut to `per = max(4, (headMaxLen - 16) / optionCount)`. The instruction head is then cut to `headKeep = max(8, optBudget)`. State tokens fill remaining room under `maxLen` (default 512); for a `String` state, `truncateLeft` is false, so excess state is clipped from the right. A final `ids.length > maxLen` cut keeps the left prefix of the whole sequence.
- Evidence: Option encode `maxLength: 48`; head/option budget; state room and final clip; `tokenizeForOnnx` sets `truncateLeft` only when `state is List`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart` lines 82–95, 207–276, 332–356; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/loaded_runtime.dart` lines 50–54, 73–78.

### Living short verdicts are far below the 48-token option cap in characters

- Claim: The longest living rendered option string among the closed verdict set is 42 characters (`straight: Slower. Also closer to the food.` and `straight: Best. Same distance to the food.`). Character length is not token length; exact token counts for these strings were not measured against `tokenizer.json` in this research. [UNVERIFIED: every living Snake option encodes to at most 48 tokens under the multilingual tokenizer.] A much longer hungry or avoid-walls sentence would still hit the 48-token option encode first, before `headMaxLen` or `maxLen`, whenever that sentence alone tokenizes past 48.
- Evidence: Closed verdict literals at `_optionVerdict`; option `maxLength: 48` at encode; character lengths computed from those literals for this artifact (longest rendered forms 42 characters).
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines 427–456; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart` lines 220–225.

### Wall case on row 0 heading east with food south-east

- Claim: With heading `east` and head on row 0, relative left is north and classifies as `wall`. Relative right is south `(col, 1)` and relative straight is east `(col+1, 0)`. When both of those cells are open (not wall/body) and food is strictly south-east of the head (`food.col > head.col` and `food.row > 0`), both right and straight reduce Manhattan distance by one. `_bestFoodTurn` scans `right`, then `left`, then `straight` and keeps the first minimum score, so `right` is preferred. Therefore `_optionVerdict` yields `Blocked. Wall.` for left, `Best. Closer to the food.` for right, and `Slower. Also closer to the food.` for straight. After `renderOptions`, the model-scored option strings are exactly `left: Blocked. Wall.`, `right: Best. Closer to the food.`, `straight: Slower. Also closer to the food.`. The state string is `Heading east. Head (<col>,0). Food (<fc>,<fr>). Left wall. Right empty. Ahead empty.` when right and ahead are empty (not food/body). Instructions remain `Choose the best safe turn toward the food.`.
- Evidence: Neighbour rotation and cells; Manhattan compare and preferred-best branch; `_bestFoodTurn` key order; state template; tests that assert `Left wall` plus `Blocked. Wall.` / `Best. Closer…` on a top-row board (that test’s food is due south, so straight is farther there — the south-east tie case follows from the same `_optionVerdict` / `_bestFoodTurn` code paths above).
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines 214–248, 332–377, 399–456; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart` lines 128–132; `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/snake_controller_test.dart` lines 404–429.

### Production opening board is center row, not row 0

- Claim: The example screen builds an 80×80 controller with the default opening snake: head at `(width ~/ 2, height ~/ 2)` = `(40, 40)`, trailing west, heading east. On that opening cell, relative left is north into an on-board empty cell, so the state says `Left empty`, not `Left wall`. A restart after death constructs the same defaults. A device log that shows `Left wall` at the first step is therefore not explained by production construction defaults; it matches a head on the north edge (as in the top-row test fixture), not the centered opening.
- Evidence: Screen construction; centered opening helper; restart replaces with `_createController`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart` lines 49–70; `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines 110–126, 167–178; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md` lines 31–33.

### Adjacent-ahead food scores Eat on straight

- Claim: When the ahead neighbour cell equals food, `_optionVerdict('straight')` returns `Best. Eat the food now.`, and `renderOptions` scores `straight: Best. Eat the food now.`. That is the living text for the “food immediately ahead” situation.
- Evidence: Eat branch in `_optionVerdict`; step-capture test expectation.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines 435–436; `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/snake_controller_test.dart` lines 524–540.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Document today’s living short-verdict criteria plus state template, and name the 48-token option encode as the clip that would cut a longer hungry / avoid-walls option sentence | Read `buildStateString`, `buildTurnQuestion`, `_optionVerdict`, `renderOptions`, and `buildSequence` caps | Read-only inventory of exact strings and caps | **Chosen.** Answers what one living step embeds and scores now, and which cap would clip longer option prose that is not present in the example today. |
| Treat community planner-style hungry / avoid-walls per-option sentences as the living scored text | Infer scored strings from external Snake demos or from a desired future wording | Would invent text the example does not send | **Rejected.** Living criteria are the short `Blocked.` / `Best.` / `Slower.` / `Worse.` / `Same.` / `Open.` verdicts; classic-snake-example rejects planner-enriched option text for this example. Prior 0003 prompt research already compared absolute/planner demos and kept relative short criteria. |

## Constraints discovered

- Choice id stays `turn`; keys stay `left`, `right`, `straight` in that criteria order (`example/lib/snake_controller.dart` lines 238–247; shared design choices for this work item).
- No post-model shield, no absolute direction keys, no A/B/C or boolean keys, no timer or board-size change in scope (`wiki/product/classic-snake-example.md` lines 15–25, 31–33; shared design choices).
- Option encode hard-caps at 48 tokens per option; head budget default `headMaxLen` 192; sequence default `maxLen` 512 (`lib/src/tokenize.dart` lines 207–208, 224; `lib/src/loaded_runtime.dart` lines 50–54).
- Returned choice key is the criteria key at softmax argmax over the same order as `renderOptions` (`lib/src/answers.dart` lines 242–258).
- Survival quality of the living wording is not a success check; SC-003 cares about classic mechanics and a model-chosen relative turn (`wiki/product/classic-snake-example.md` lines 15–19).

## Unresolved

- [UNRESOLVED: exact multilingual tokenizer token counts for each living rendered option string and for representative longer hungry / avoid-walls sentences under `maxLength: 48`.]
- [UNRESOLVED: whether a measured device run that logged `Left wall` on an 80×80 board had already moved the head onto row 0, used a non-production `initialSnake`, or misread the opening cell — production construction places the head at `(40, 40)`.]
- [UNRESOLVED: whether `head_max_len` or `max_len` in a given on-disk `rl_agent_config.json` differ from the Dart defaults 192 and 512 for the checkpoint the device used.]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/snake_controller_test.dart`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/loaded_runtime.dart`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0003-classic-snake/research/prompt.md`, consulted 2026-09-28 (cited for prior relative-vs-planner comparison; not reopened)
