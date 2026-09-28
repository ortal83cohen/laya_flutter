# Research: Snake prompt wording — living scored English, closed controls, and extra facts

## Question

What English does one living Snake step score today, which prompt and control decisions stay closed, and which extra facts can be added so the model is told the snake is hungry and should avoid walls, without a new action space?

## Answer

**Living scored text (`research/scored-text.md`):** One living step sends a short English state string, then one `choice` question id `turn` with fixed instructions `Choose the best safe turn toward the food.` and three criteria values keyed `left`, then `right`, then `straight`, rendered as `key: description` and encoded under a hard 48-token option cap. There is no separate “hungry” or “avoid walls” clause in the living state or criteria today.

**Closed controls (`research/closed-decisions.md`):** Relative keys `left` / `right` / `straight`, choice id `turn`, no post-model shield, no timer, restart-after-death, and the eighty-by-eighty board stay closed. The 2026-09-28 wording request reopens only the short English prompt surface; exact sentences for state, instructions, and option descriptions remain open within those controls.

**Extra facts (`research/extra-facts.md`):** Keep that action space. That stream chooses both a hunger-and-avoid-walls sentence in the choice instructions and a few board facts the controller already computes but does not put in the state string today (Manhattan distance from head to food, and which relative side of the heading the food lies on), while leaving per-key verdicts as the place that names blocked walls or body and closer or farther open cells. No path planner, multi-step plan, or post-predict safety shield.

**DISAGREEMENT (not resolved here):** `research/extra-facts.md` chooses instructions-plus-extra-state-facts as the answer for this slice. `research/closed-decisions.md` leaves state-only versus state-plus-instructions as two viable options and marks which English surfaces this slice may change as unresolved. Both positions are retained below.

## Findings

### Prior solution does not prescribe Snake scored text or prompt facts

- Claim: The only indexed solutions entry concerns macOS ONNX session load via `integration_test` and a sandbox cache entitlement. It does not name Snake state text, option verdicts, tokenization length caps, choice labels, or control flow after death.
- Evidence: Solution summary and guidance stay on host session proof and entitlements; INDEX routes that file for session-sandbox failures, not Snake prompts.
- Source: `research/scored-text.md`, `research/closed-decisions.md`, and `research/extra-facts.md`, all citing `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` (and INDEX in the closed-decisions stream).

### Closed product surface: relative keys, no shield, no timer, 80×80 board, restart after death

- Claim: The goal and classic-Snake product note fix relative `left` / `right` / `straight`, choice id `turn`, a short English state, wall or body ends the game, food on a random empty cell, no step timer, and no post-model shield. Absolute `UP`/`DOWN`/`LEFT`/`RIGHT`, opaque `A`/`B`/`C`, boolean-word keys, and planner-enriched option text stay rejected or unused for this example. ADR 0003 closes restart after death by replacing the ended controller and continuing the await-gated loop, with no restart button and no timer, delayed future, or ticker; predict failure is not death. The example screen constructs the controller at width 80 and height 80. Survival length is not a success check; SC-003 cares about classic mechanics and a model-chosen relative turn.
- Evidence: Closed assumptions and SC-003; product note on relative keys, rejected styles, board size, and step gating; ADR outcome and confirmation.
- Source: `research/closed-decisions.md` (primary inventory of closed controls and ADR 0003); also `research/scored-text.md` and `research/extra-facts.md` for relative keys, no shield, no timer, survival-not-success, and (scored-text) 80×80 construction plus restart replacing with `_createController`.

### Living state string is one fixed English template

- Claim: `buildStateString` returns exactly `Heading <heading.name>. Head <head>. Food <food or none>. Left <kind>. Right <kind>. Ahead <kind>.` where each `<kind>` is one of `wall`, `body`, `food`, or `empty` from `_classify`. The turn verdict is intentionally not repeated in that string. There is no separate “hungry” or “avoid walls” clause in the state string today.
- Evidence: Template concatenation, classifier branches, and comment that the turn verdict lives on the option text.
- Source: `research/scored-text.md` and `research/extra-facts.md`, both citing `example/lib/snake_controller.dart` lines 214–230 (scored-text also 386–396); closed-decisions notes the same builder as the concrete reopened surface without proposing sentences.

### Living turn question: fixed instructions and short verdict criteria

- Claim: `buildTurnQuestion` builds id `turn`, type choice, instructions exactly `Choose the best safe turn toward the food.`, and criteria map entries in declaration order `left`, `right`, `straight`, each value from `_optionVerdict` for that relative key. The closed verdict vocabulary today is only: `Blocked. Wall.`, `Blocked. Body.`, `Best. Eat the food now.`, `Open. Empty cell.`, `Best. Closer to the food.`, `Slower. Also closer to the food.`, `Best. Least far from the food.`, `Worse. Farther from the food.`, `Best. Same distance to the food.`, `Same. Not closer to the food.`. No living criteria string contains the words “hungry” or “avoid”. Instructions mention safe food-seeking but not hunger by name.
- Evidence: Question builder and `_optionVerdict` return literals; `_bestFoodTurn` only selects which open turn may say `Best.` when distances compete.
- Source: `research/scored-text.md` (full vocabulary and line cites); `research/extra-facts.md` (instructions and `_optionVerdict` ranking); `research/closed-decisions.md` (id `turn` and three relative keys with per-option descriptions).

### Step embeds those builders into predict in a fixed order; library scores `key: description`

- Claim: `step` builds the state string first, then the turn question, then calls `predict(state, { 'turn': question })`. No other question id is added on a living step. For a choice question, `renderOptions` walks `criteria.entries` in map order and emits `key: <description>` when descriptions are non-empty, so scored options are `left: …`, then `right: …`, then `straight: …`. Softmax keys use the same order. `buildSequence` lays out `[CLS]` + encoded `choice question: <instructions>` + `[SEP]` + for each option (`[MASK]` + encoded option text) + `[SEP]` + state tokens + `[SEP]`.
- Evidence: Locals and predict call inside `step`; `renderOptions` choice branch; `buildSequence` assembly.
- Source: `research/scored-text.md`, citing `example/lib/snake_controller.dart` lines 258–270 and `lib/src/tokenize.dart` / `lib/src/answers.dart`.

### Caps that can clip longer option sentences

- Claim: Each option’s encode call passes `maxLength: 48`, keeping only the first 48 token ids of that option’s text (not including the prepended MASK id). That is the first hard clip on a longer hungry or avoid-walls option sentence. Further head/option budget cuts use default `headMaxLen` 192; state fills remaining room under default `maxLen` 512. The longest living rendered option string among the closed verdict set is 42 characters; character length is not token length. [UNVERIFIED: every living Snake option encodes to at most 48 tokens under the multilingual tokenizer.]
- Evidence: Option encode `maxLength: 48`; head/option budget; character lengths from living verdict literals.
- Source: `research/scored-text.md`, citing `lib/src/tokenize.dart`, `lib/src/loaded_runtime.dart`, and `example/lib/snake_controller.dart`.

### Wall case on row 0 heading east; production opening is center, not row 0

- Claim: With heading `east` and head on row 0, relative left classifies as `wall`. When right and straight are open and food is strictly south-east of the head, scored options are `left: Blocked. Wall.`, `right: Best. Closer to the food.`, `straight: Slower. Also closer to the food.`. The production screen builds an 80×80 controller with head at `(40, 40)` heading east; on that opening cell left is empty, not wall. A restart after death constructs the same defaults. When the ahead neighbour equals food, scored text is `straight: Best. Eat the food now.`.
- Evidence: Neighbour rotation, `_bestFoodTurn` order, state template, screen construction, centered opening helper, eat branch.
- Source: `research/scored-text.md`.

### Work item 0003 closed prompt keys and rejected shield; left bake-offs unresolved

- Claim: Research for classic Snake chose relative semantic keys with a short English state naming cardinal heading, head, food, and immediate left / right / ahead neighbour kinds. Absolute keys and a community-style safety shield were rejected. The plan and product contract fix choice id `turn`, those three keys, no planner text, and no overriding safety shield. Research left unresolved whether measured runs prefer other state encodings, whether opaque keys beat semantic keys, and whether planner-enriched per-option descriptions are required for long survival. It did not require the words hungry or avoid walls.
- Evidence: Prompt research answer and unresolved list; synthesised research; plan closed decisions; contract assumptions.
- Source: `research/closed-decisions.md` and `research/extra-facts.md`, citing `wiki/work/0003-classic-snake/research/prompt.md` and related 0003 artifacts.

### Controller fields already supply candidate extra facts without a planner

- Claim: Heading name, head column and row, food column and row, and neighbour kinds are already available. Manhattan distance is already computed by `_manhattan` but is not exposed in the state string. Whether a relative turn’s next cell is closer, same, or farther, and whether it is wall or body, is already decided inside `_optionVerdict`. A relative side for food (ahead, behind, left, right of the current heading) can be derived from head, food, and heading alone; no named helper exists today. After predict returns, `step` accepts only `left` / `right` / `straight` and applies that key; there is no branch that replaces a wall choice with a safer key.
- Evidence: Public and private members; choice acceptance and `_applyChoiceAndAdvance` path.
- Source: `research/extra-facts.md`, citing `example/lib/snake_controller.dart` and the product note’s shield rejection.

### Locked tests freeze today’s state substrings and exact verdict strings

- Claim: Controller tests require state substrings such as heading `east`, head/food cells, neighbour kinds, and also `Left wall` in another fixture. They forbid the substring `Toward food` in state. They lock exact option strings such as `Best. Closer to the food.`, `Worse. Farther from the food.`, `Blocked. Wall.`, `Slower. Also closer to the food.`, and `Best. Eat the food now.`, and ban planner / shield / override / filter wording in instructions and option text. Keys must remain `left`, `right`, `straight` with id `turn`. Any wording change must update those locks in the same slice.
- Evidence: Assertions in the English-state and relative-turn test group.
- Source: `research/extra-facts.md`, citing `example/test/snake_controller_test.dart`.

### Changing the prompt surface needs an explicit product decision for this slice

- Claim: The short English state string and choice id `turn` were the fixed prompt contract; changing them for better play without a new product decision reopens SC-003’s prompt surface. The shared design for this work item states that the 2026-09-28 wording request is that new product decision and that choice id stays `turn` while keys stay `left`, `right`, `straight`.
- Evidence: Product constraint paragraph; work-item title and shared design in the researcher brief; STATE.yaml.
- Source: `research/closed-decisions.md` and `research/extra-facts.md`, citing `wiki/product/classic-snake-example.md` and `wiki/work/0011-snake-prompt-wording/STATE.yaml`.

### Whether any wording raises model confidence is not measured here

- Claim: [UNVERIFIED: that adding hunger, avoid-walls, Manhattan, or relative food-side text will raise `LayaAnswer.confidence` or improve turn quality on `laya-multilingual`.] No repository check records that effect for these strings.
- Evidence: No test or wiki artifact asserts confidence or survival after such wording. SC-003 does not measure survival length.
- Source: `research/extra-facts.md`.

### DISAGREEMENT: which English surfaces this slice changes, and which option is chosen

- Claim from `research/closed-decisions.md`: Two options are viable for this slice — (A) rewrite only the short English state string, keep choice id and keys, leave option descriptions as relative-turn meaning without a shield; (B) rewrite the state string and the choice instructions / option-description English, still with id `turn`, keys `left`/`right`/`straight`, no overriding shield. Changing keys, adding a shield, absolute or opaque keys, a step timer, dropping restart-after-death, or changing the eighty-by-eighty board is rejected. That stream marks unresolved whether this wording slice may change only the short English state string, or also the choice `instructions` and per-option description sentences; where the line sits between richer factual English in option descriptions and unused planner-enriched option text; and whether the state must keep exactly the 0003 fact set or may add further facts (for example hunger).
- Claim from `research/extra-facts.md`: Instruction-only and richer-state-only are each rejected as the sole change. The chosen option is both a hunger-and-avoid-walls instruction and a few extra state facts (Manhattan distance to food plus the food’s relative side ahead / behind / left / right of heading), while option text keeps wall/body Blocked and closer/farther Best/Slower/Worse/Same language without planner, multi-step plan, or shield wording.
- Explicit disagreement: The closed-decisions stream leaves state-only versus state-plus-instructions unresolved as two viable options. The extra-facts stream already chooses instructions-plus-extra-state-facts. This merge does not pick a winner.
- Evidence: Options tables and unresolved lists in those two streams.
- Source: `research/closed-decisions.md`; `research/extra-facts.md`.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Document today’s living short-verdict criteria plus state template, and name the 48-token option encode as the clip that would cut a longer hungry / avoid-walls option sentence | Read `buildStateString`, `buildTurnQuestion`, `_optionVerdict`, `renderOptions`, and `buildSequence` caps | Read-only inventory of exact strings and caps | **Chosen** for the living-text question (`research/scored-text.md`). |
| Treat community planner-style hungry / avoid-walls per-option sentences as the living scored text | Infer scored strings from external Snake demos or from a desired future wording | Would invent text the example does not send | **Rejected** (`research/scored-text.md`). Living criteria are the short verdict set; classic-snake-example rejects planner-enriched option text for this example. |
| Rewrite only the short English state string (facts, hunger, wall awareness in state); keep id `turn`, keys `left`/`right`/`straight`; leave option descriptions as relative-turn meaning without a shield | Touches the state builder the product note names as the prompt contract; control loop unchanged | Smallest surface; may under-serve the user’s ask if instructions or option lines also need clearer English | **Viable** for this slice per `research/closed-decisions.md`. **Rejected as the sole change** by `research/extra-facts.md` (never says hungry; only implies wall avoidance). **DISAGREEMENT.** |
| Rewrite the state string and the choice instructions / option-description English, still with id `turn`, keys `left`/`right`/`straight`, no overriding shield, no absolute / boolean / opaque keys | Improves every English string the model ranks while keeping the closed control and key contract | Larger copy change; must stay clear of planner-enriched option text and any post-model override | **Viable** for this slice per `research/closed-decisions.md` (preferred there when the open surface is “English the model sees,” not only the state line). Related to, but not identical with, the extra-facts chosen option below. |
| Instruction sentence only: hunger plus avoid walls; state string unchanged | Change `instructions` so the model is told the snake is hungry and should avoid walls (and still seek food). Keep state and verdicts as today | One string edit; state `contains` checks stay valid | **Rejected as the sole change** (`research/extra-facts.md`). Meets wording ask but leaves unused distance and relative-side facts the controller already computes. |
| Both a hunger and avoid-walls instruction and a few extra state facts | Instructions name hunger and avoiding walls while still choosing a relative turn toward food. State keeps today’s heading, head, food, and neighbour kinds, and adds Manhattan distance to food plus the food’s relative side. Option text keeps Blocked and closer/farther language without planner or shield. Keys and id stay closed | Instruction edit, state append, and test updates | **Chosen** by `research/extra-facts.md`. **DISAGREEMENT** with `research/closed-decisions.md`, which does not choose this and leaves state-only versus state-plus-instructions unresolved. |
| Change choice keys, add a post-model shield, switch to absolute or opaque keys, add a step timer, drop restart-after-death, or change the eighty-by-eighty board | Reopens GOAL / ADR / product-note control decisions under the banner of wording | High: conflicts with closed assumptions, SC-003, ADR 0003, and shared design | **Rejected** for this slice (`research/closed-decisions.md`; same closed controls in the other streams). |

## Constraints discovered

- Relative action space is closed: left turn, right turn, or straight ahead relative to heading; choice id stays `turn`; keys stay `left`, `right`, `straight` (`research/closed-decisions.md`, `research/scored-text.md`, `research/extra-facts.md`).
- A shield that overrides the model’s choice stays rejected; nothing after predict may replace a wall choice with a safe one (`research/closed-decisions.md`, `research/extra-facts.md`).
- Absolute direction keys, boolean-word keys, and opaque `A`/`B`/`C` keys stay rejected or unused (`research/closed-decisions.md`, `research/extra-facts.md`).
- Planner-enriched option text stays unused per the product note, even though 0003 research left a measured bake-off unresolved (`research/closed-decisions.md`).
- No step timer, decorative ticker, or post-predict pacing delay; restart after death by replacing the controller and continuing the await-gated loop; example board construction stays width 80 and height 80 (`research/closed-decisions.md`; scored-text for 80×80 and restart defaults).
- Survival length is not a success check; SC-003 is classic mechanics plus a model-chosen relative turn each step (`research/closed-decisions.md`, `research/scored-text.md`, `research/extra-facts.md`).
- Option encode hard-caps at 48 tokens per option; head budget default `headMaxLen` 192; sequence default `maxLen` 512 (`research/scored-text.md`).
- Returned choice key is the criteria key at softmax argmax over the same order as `renderOptions` (`research/scored-text.md`).
- Candidate facts must tie to controller fields already present: heading, head, food, neighbour classification, `_manhattan`, and the closer/same/farther and wall/body checks inside `_optionVerdict` (`research/extra-facts.md`).
- State must remain a short English `String` (or an allowed string map at the library boundary); the example sends a `String` today (`research/extra-facts.md`).
- Tests lock many state substrings, forbid `Toward food` in state, and lock several exact criteria strings; any wording change must update those locks in the same slice (`research/extra-facts.md`).
- Changing the English state or prompt for play quality is a product decision for this work item, not a silent tweak (`research/closed-decisions.md`, `research/extra-facts.md`).
- The macOS session sandbox solution is out of scope for prompt wording (`research/closed-decisions.md`, `research/scored-text.md`, `research/extra-facts.md`).

## Unresolved

- [UNRESOLVED: exact multilingual tokenizer token counts for each living rendered option string and for representative longer hungry / avoid-walls sentences under `maxLength: 48`.] (`research/scored-text.md`)
- [UNRESOLVED: whether a measured device run that logged `Left wall` on an 80×80 board had already moved the head onto row 0, used a non-production `initialSnake`, or misread the opening cell — production construction places the head at `(40, 40)`.] (`research/scored-text.md`)
- [UNRESOLVED: whether `head_max_len` or `max_len` in a given on-disk `rl_agent_config.json` differ from the Dart defaults 192 and 512 for the checkpoint the device used.] (`research/scored-text.md`)
- [UNRESOLVED: whether this wording slice may change only the short English state string, or also the choice `instructions` and per-option description sentences, given that the product note names the state string and id `turn` as the prompt contract while the user ask targets “the English wording the model sees.”] (`research/closed-decisions.md`) — **DISAGREEMENT** with `research/extra-facts.md`, which already chooses instructions plus extra state facts.
- [UNRESOLVED: where the line sits between allowed richer factual English in option descriptions and the product note’s rule that planner-enriched option text stays unused.] (`research/closed-decisions.md`)
- [UNRESOLVED: whether the state must keep naming exactly the 0003 fact set (cardinal heading, head, food, left / right / ahead kinds) and only rephrase those facts, or may add further facts (for example hunger) without a new bake-off.] (`research/closed-decisions.md`) — related **DISAGREEMENT** with `research/extra-facts.md`, which chooses adding Manhattan and relative food-side facts.
- [UNRESOLVED: the exact English sentences to ship — out of research scope for this stream; plan and implement must draft them.] (`research/closed-decisions.md`)
- [UNRESOLVED: whether hunger-and-avoid-walls instructions plus Manhattan and relative food-side state raise choice confidence or reduce wall choices on `laya-multilingual` for this example’s boards.] (`research/extra-facts.md`)
- [UNRESOLVED: the exact English sentence for instructions and the exact phrases for distance and relative food side, pending plan and frozen criteria.] (`research/extra-facts.md`)
- [UNRESOLVED: whether option verdict strings should also mention hunger, or whether instructions alone should carry that word so the locked Best/Slower/Worse/Blocked phrases can stay.] (`research/extra-facts.md`)

## Provenance

- `research/scored-text.md` — living state template, instructions, verdict vocabulary, predict embed order, `key: description` rendering, sequence layout, 48-token option cap and related budgets, wall/eat scored examples, production opening at `(40, 40)`, living-text options, tokenizer and device-log unresolved items.
- `research/closed-decisions.md` — closed controls (relative keys, `turn`, no shield, no timer, restart-after-death, 80×80), ADR 0003, 0003 prompt bake-offs left open, viable state-only versus state-plus-instructions options, prompt-surface reopen via the 2026-09-28 wording request, closed-control constraints, unresolved surface-scope and planner-boundary items.
- `research/extra-facts.md` — candidate facts from existing controller fields, locked tests, instruction/state options including the chosen instructions-plus-extra-facts path, no post-choice rewrite, [UNVERIFIED] confidence claim, and related unresolved items.
- Shared closed-control and living-surface claims collapsed above cite every stream that reported them.

## Sources

- `wiki/work/0011-snake-prompt-wording/research/scored-text.md`, consulted 2026-09-28
- `wiki/work/0011-snake-prompt-wording/research/closed-decisions.md`, consulted 2026-09-28
- `wiki/work/0011-snake-prompt-wording/research/extra-facts.md`, consulted 2026-09-28
- Sources listed in those three files, consulted 2026-09-28
