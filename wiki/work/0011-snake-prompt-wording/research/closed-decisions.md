# Research: Closed Snake prompt and control decisions versus open wording

## Question

Which Snake prompt and control changes are already closed by the goal, the classic-snake product
note, and accepted ADRs, and which wording surfaces remain open for a user-requested rewrite?

## Answer

Control shape, relative choice keys, choice id `turn`, no post-model shield, no timer,
restart-after-death, and the eighty-by-eighty board are closed and must not be reopened by this
wording slice. The 2026-09-28 user request to improve the English the model sees is the new product
decision that reopens the short English prompt surface named in `classic-snake-example.md`; the
exact sentences for state, instructions, and option descriptions are open within those closed
controls. The only `wiki/solutions/` entry does not answer Snake prompt wording.

## Findings

### Goal closes classic mechanics and relative turns, not English sentences

- Claim: The goal’s closed Snake assumptions require wall or body ends the game, food on a random
  empty cell, a model choice of left turn, right turn, or straight ahead relative to the current
  heading, and no step timer. SC-003 checks those mechanics and model-gated steps; it does not
  prescribe the English words in the state string or option descriptions. Survival length is not a
  success check.
- Evidence: Closed assumptions name relative left / right / straight and no timer; SC-003’s check
  and negative case are about spawn, collision, await-gated motion, and timers, not prompt prose.
  The product note states survival length is not a success check.
- Source: `wiki/product/GOAL.md` lines 32–32, 43–43; `wiki/product/classic-snake-example.md` lines
  19–19.

### Product note closes keys, shield, and rejected key styles; names the reopened prompt surface

- Claim: Absolute `UP`/`DOWN`/`LEFT`/`RIGHT` keys and a shield that overrides the model’s choice are
  deliberate rejections. Opaque `A`/`B`/`C` keys and planner-enriched option text stay unused for
  this example. Boolean-word keys stay rejected. The short English state string and the choice id
  `turn` were the fixed prompt contract; changing them for better play without a new product
  decision reopens SC-003’s prompt surface. The shared design for this work item states that the
  2026-09-28 wording request is that new product decision and that choice id stays `turn` while keys
  stay `left`, `right`, `straight`.
- Evidence: “Why relative turn keys” rejects absolute keys and overriding shields, leaves opaque and
  planner-enriched unused, rejects boolean-word keys, and names the state string plus `turn` as the
  prompt contract that a new product decision reopens.
- Source: `wiki/product/classic-snake-example.md` lines 15–19; work-item shared design choices in
  the researcher brief for `0011-snake-prompt-wording` (choice id and keys stay; shield and rejected
  key styles stay rejected).

### ADR 0003 closes restart after death; it does not touch prompt wording

- Claim: After a wall or body collision, the example replaces the ended controller and continues the
  same await-gated loop, with no restart button and no timer, delayed future, or ticker. Predict
  failure is not death. That decision does not prescribe state or option English.
- Evidence: Decision outcome and drivers; confirmation forbids a paced hold or button restart and
  forbids treating predict failure as a new run.
- Source: `wiki/adr/0003-restart-snake-after-death.md` lines 21–28, 48–52, 59–63.

### Board size and no-timer screen rules stay closed

- Claim: The example screen constructs the controller at width 80 and height 80. Classic-rules tests
  may use a smaller board. The screen must not use a timer, delayed future, or ticker for stepping
  or pacing. Shared design for this slice keeps restart, no timer, and the eighty-by-eighty board as
  they are.
- Evidence: Board-size section; restart and step-gating sections; ADR confirmation of no Timer /
  Future.delayed / Ticker on the Snake screen.
- Source: `wiki/product/classic-snake-example.md` lines 21–25, 27–29, 31–33;
  `wiki/adr/0003-restart-snake-after-death.md` lines 25–26, 61–61.

### Work item 0003 closed prompt keys and rejected shield; left bake-offs unresolved

- Claim: Research for classic Snake chose relative semantic keys `left` / `right` / `straight` with
  a short English state naming cardinal heading, head, food, and immediate left / right / ahead
  neighbour kinds. Absolute cardinal keys and a community-style safety shield were rejected for this
  product’s action labels. Opaque `A`/`B`/`C` keys were rejected as the default. The plan and
  product contract fix choice id `turn`, those three keys, relative-turn descriptions, one short
  English state string (not a string map for that slice), no planner text, and no safety shield that
  overrides the model key. Research left unresolved whether measured runs prefer other state
  encodings, whether opaque keys beat semantic keys, and whether planner-enriched per-option
  descriptions are required for long survival.
- Evidence: Prompt research answer and options table; synthesised research answer; plan closed
  decisions and U2; contract R-002, R-007, assumptions, and out-of-scope.
- Source: `wiki/work/0003-classic-snake/research/prompt.md` lines 7–9, 61–65, 76–80;
  `wiki/work/0003-classic-snake/00-research.md` lines 9–9, 61–65, 79–83;
  `wiki/work/0003-classic-snake/01-plan.md` lines 11–17, 47–49, 87–89, 121–121;
  `wiki/work/0003-classic-snake/04-product-contract.md` lines 20–20, 25–25, 53–55, 63–67.

### Prior solution does not answer this wording question

- Claim: The only indexed solutions entry concerns macOS ONNX session load via `integration_test`
  and a sandbox cache entitlement. It does not prescribe Snake state text, choice labels, or control
  flow after death.
- Evidence: Solution summary and guidance are about host session proof and entitlements; INDEX
  routes that file for session-sandbox failures, not Snake prompts.
- Source: `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` lines 1–8, 21–32;
  `wiki/INDEX.md` lines 64–64.

### Current example already exposes the reopened English surfaces

- Claim: The living controller builds a short English state string and a choice question with id
  `turn`, instructions, and criteria keys `left`, `right`, and `straight`. That is the concrete
  surface a wording rewrite would edit; this research does not propose new sentences.
- Evidence: `buildStateString` returns heading, head, food, and neighbour kinds; `buildTurnQuestion`
  uses id `turn` and the three relative keys with per-option description strings.
- Source: `example/lib/snake_controller.dart` lines 214–246.

## Options considered

| Option                                                                                                                                                                                                               | How it works                                                                                    | Cost                                                                                                                                              | Why rejected / chosen                                                                                                                                                                               |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Rewrite only the short English state string (facts, hunger, wall awareness in state), keep choice id `turn`, keys `left`/`right`/`straight`, and leave option descriptions as relative-turn meaning without a shield | Touches the state builder the product note names as the prompt contract; control loop unchanged | Smallest surface; may under-serve the user’s ask if instructions or option lines also need clearer English                                        | Viable for this slice. Matches the product note’s named prompt surface and the shared “keys stay” / “no shield” constraints.                                                                        |
| Rewrite the state string and the choice instructions / option-description English, still with id `turn`, keys `left`/`right`/`straight`, no overriding shield, no absolute / boolean / opaque keys                   | Improves every English string the model ranks while keeping the closed control and key contract | Larger copy change; must stay clear of planner-enriched option text that the product note says stays unused, and clear of any post-model override | Viable for this slice. Fits the user ask (avoid walls, hunger, more facts) without reopening closed controls. Preferred when the open surface is “English the model sees,” not only the state line. |
| Change choice keys, add a post-model shield, switch to absolute or opaque keys, add a step timer, drop restart-after-death, or change the eighty-by-eighty board                                                     | Reopens GOAL / ADR / product-note control decisions under the banner of wording                 | High: conflicts with closed assumptions, SC-003, ADR 0003, and shared design                                                                      | Rejected for this slice. Those decisions are closed; the wording request does not reopen them.                                                                                                      |

## Constraints discovered

- Relative action space is closed: left turn, right turn, or straight ahead relative to heading (
  `wiki/product/GOAL.md` line 32).
- Choice id stays `turn`; keys stay `left`, `right`, `straight` (shared design;
  `wiki/product/classic-snake-example.md` lines 17–19; `wiki/work/0003-classic-snake/01-plan.md`
  lines 87–87).
- A shield that overrides the model’s choice stays rejected (`wiki/product/classic-snake-example.md`
  lines 17–17; `wiki/work/0003-classic-snake/04-product-contract.md` line 25).
- Absolute direction keys, boolean-word keys, and opaque `A`/`B`/`C` keys stay rejected or unused
  for this example (`wiki/product/classic-snake-example.md` lines 17–17;
  `wiki/work/0003-classic-snake/research/prompt.md` lines 61–65).
- Planner-enriched option text stays unused per the product note, even though 0003 research left a
  measured bake-off unresolved (`wiki/product/classic-snake-example.md` lines 17–17;
  `wiki/work/0003-classic-snake/research/prompt.md` lines 80–80).
- No step timer, decorative ticker, or post-predict pacing delay (`wiki/product/GOAL.md` line 32;
  `wiki/product/classic-snake-example.md` lines 21–23; `wiki/adr/0003-restart-snake-after-death.md`
  lines 25–26).
- Restart after death by replacing the controller and continuing the await-gated loop (
  `wiki/adr/0003-restart-snake-after-death.md` lines 48–52).
- Example board construction stays width 80 and height 80 (`wiki/product/classic-snake-example.md`
  lines 31–33).
- Survival length is not a success check; SC-003 is classic mechanics plus a model-chosen relative
  turn each step (`wiki/product/classic-snake-example.md` lines 19–19; `wiki/product/GOAL.md` lines
  43–43).
- The macOS session sandbox solution is out of scope for prompt wording (
  `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` lines 1–8).

## Unresolved

- [UNRESOLVED: whether this wording slice may change only the short English state string, or also the choice
  `instructions` and per-option description sentences, given that the product note names the state string and id
  `turn` as the prompt contract while the user ask targets “the English wording the model sees.”]
- [UNRESOLVED: where the line sits between allowed richer factual English in option descriptions and the product note’s rule that planner-enriched option text stays unused.]
- [UNRESOLVED: whether the state must keep naming exactly the 0003 fact set (cardinal heading, head, food, left / right / ahead kinds) and only rephrase those facts, or may add further facts (for example hunger) without a new bake-off.]
- [UNRESOLVED: the exact English sentences to ship — out of research scope for this stream; plan and implement must draft them.]

## Sources

- `wiki/product/GOAL.md`, consulted 2026-09-28
- `wiki/product/classic-snake-example.md`, consulted 2026-09-28
- `wiki/adr/0003-restart-snake-after-death.md`, consulted 2026-09-28
- `wiki/INDEX.md`, consulted 2026-09-28 as router only
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-28
- `wiki/work/0003-classic-snake/research/prompt.md`, consulted 2026-09-28
- `wiki/work/0003-classic-snake/00-research.md`, consulted 2026-09-28
- `wiki/work/0003-classic-snake/01-plan.md`, consulted 2026-09-28 (prompt keys, shields, option
  text)
- `wiki/work/0003-classic-snake/04-product-contract.md`, consulted 2026-09-28
- `example/lib/snake_controller.dart`, consulted 2026-09-28
- Shared design choices in the `0011-snake-prompt-wording` researcher brief, consulted 2026-09-28
