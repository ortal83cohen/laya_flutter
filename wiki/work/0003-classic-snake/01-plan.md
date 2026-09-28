# Plan: Classic Snake example driven by offline Laya predict

## Goal

The example app presents a classic Snake board that, on every step, asks the already-loaded offline
Laya runtime for a relative turn (left, right, or straight), applies that turn, and advances exactly
one cell only after predict completes. Food spawns on a random empty cell. A wall or the snake’s own
body ends the game. Logic tests prove spawn, collision, relative turns, and the absence of
timer-driven motion without opening an ONNX session.

## Approach

Keep all classic rules and the await-gated step loop in a pure Dart controller under the example
application library. That controller owns the board, heading, growth, food spawn, collision end, the
short English state string, and the single choice question with keys left, right, and straight. It
accepts an injectable predict function so tests can hold the future incomplete. The example Snake
screen wires that controller to the real LoadedRuntime.predict from the closed library API and
redraws by setting widget state after each awaited step. Neither the controller nor the screen
introduces Timer, Future.delayed, or Ticker for stepping or for decoration.

The state string names the cardinal heading, the head cell, the food cell, and the neighbour
immediately left, right, and ahead of the head, each labelled empty, wall, body, or food. Option
descriptions state that each key is a turn relative to the current heading. There is no planner text
and no safety shield that overrides the model’s key. Absolute screen directions are never the choice
keys.

Replace the skeleton home content with a path that reaches the Snake screen once a loaded runtime is
available, without redesigning LayaFlutter.open or predict. Device launches and extra platforms stay
later.

## Why this approach

Relative keys left, right, and straight with a short English state match the goal’s closed action
space and avoid boolean-word keys that upstream documents as unsafe. Absolute UP, DOWN, LEFT, RIGHT
keys, used in community demos, were rejected because they reopen the relative-turn rule. Opaque A,
B, C keys were rejected for this slice; they remain a fallback only if a later measured run shows
semantic keys fail. See `00-research.md` prompt options and the closed slice decisions.

Await-gated advancement after predict matches SC-003’s no-step-timer rule. Timer.periodic as a step
clock and a frame Ticker as a step driver were rejected because neither waits for predict. A
decorative Ticker or a one-shot Future.delayed after predict was considered in research and is
rejected for this slice: the Snake screen must contain none of Timer, Future.delayed, or Ticker. See
`00-research.md` step-loop options and the closed slice decisions.

A pure Dart controller with an injectable predict seam lets logic tests prove incomplete-predict
immobility and collision without opening an ONNX session, which aligns with the macOS session
sandbox solution that treats VM flutter test as unsuitable for native session proof. Putting rules
only inside widgets without a testable seam was rejected because the absence-of-timer proof would
then require a real session or brittle widget-only timing.

## Product contract

Behaviour is defined in `04-product-contract.md`. The units below realise R-001 through R-007. This
plan adds no behaviour that file does not state.

## Units

### U1. Pure Dart Snake controller with classic rules

Done when: a pure Dart controller under the example application library owns the board, snake cells,
cardinal heading, food cell, and ended flag; food spawns on a random empty cell; applying a relative
turn then advancing one cell grows the snake when the head lands on food and ends the game when the
next cell is a wall or body; the controller exposes a way to inject both the predict function and a
random source for food placement so tests are deterministic.

Files it may touch: new or existing Dart modules under the example application library that hold
game rules and board state, and unit tests for that controller under the example test tree. No
library package modules under lib/ for rules. No ONNX session open in these tests.

| Scenario                   | Category   | Input                                                                 | Action                                              | Expected outcome                                                            | Covers        |
|----------------------------|------------|-----------------------------------------------------------------------|-----------------------------------------------------|-----------------------------------------------------------------------------|---------------|
| Food on empty cell         | happy path | Board with known empty cells and a fixed random sequence              | Request a food spawn                                | Food cell is one of the empty cells and not a body cell                     | R-001, AE-001 |
| Food refused on body       | edge       | Random sequence that would first pick a body cell, then an empty cell | Request a food spawn                                | Food ends on an empty cell, never on body                                   | R-001         |
| Relative left turn         | happy path | Heading east; choice left; clear cell ahead after turn                | Apply choice and advance one cell                   | Heading becomes north; head moves one cell north                            | R-003, AE-002 |
| Relative right turn        | happy path | Heading east; choice right; clear cell ahead after turn               | Apply choice and advance one cell                   | Heading becomes south; head moves one cell south                            | R-003, AE-002 |
| Relative straight          | happy path | Heading east; choice straight; clear cell ahead                       | Apply choice and advance one cell                   | Heading stays east; head moves one cell east                                | R-003, AE-002 |
| Eat and grow               | happy path | Head about to enter the food cell after the relative turn             | Apply choice and advance                            | Snake length increases by one; new food is placed on a remaining empty cell | R-001, R-003  |
| Wall ends game             | happy path | Head one cell from a wall; choice straight                            | Apply choice and advance, then attempt another step | Game is ended; the second step does not change snake cells                  | R-006, AE-004 |
| Body ends game             | happy path | Next cell after the relative turn is occupied by the snake body       | Apply choice and advance, then attempt another step | Game is ended; the second step does not change snake cells                  | R-006         |
| Food spawn when board full | error      | No empty cells remain                                                 | Request a food spawn                                | Controller signals it cannot place food; it does not place food on the body | R-001         |

### U2. Relative-turn prompt built from board state

Done when: from a live board and heading, the controller (or a small helper it owns under the
example application library) builds one short English state string naming the cardinal heading, head
cell, food cell, and the left, right, and ahead neighbour classifications (empty, wall, body, or
food), and builds one choice question whose id is turn, whose keys are left, right, and straight,
and whose descriptions say each option is a turn relative to the current heading, with no planner
text and no absolute direction keys.

Files it may touch: the same example application library modules as U1, plus unit tests that assert
the state string contents and the choice keys and descriptions for fixed boards.

| Scenario                  | Category   | Input                                                                 | Action                                                    | Expected outcome                                                                                                                          | Covers               |
|---------------------------|------------|-----------------------------------------------------------------------|-----------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|----------------------|
| State names neighbours    | happy path | Fixed board with known heading, head, food, and three neighbour kinds | Build the state string                                    | String includes heading, head, food, and left, right, and ahead classifications                                                           | R-002, AE-005        |
| Choice keys relative      | happy path | Any live board                                                        | Build the choice question                                 | Keys are exactly left, right, and straight; descriptions mention relative turns; no UP, DOWN, LEFT, RIGHT, boolean words, or A, B, C keys | R-002, R-007, AE-005 |
| No planner or shield text | edge       | Any live board                                                        | Inspect the question instructions and option descriptions | No planner narrative and no shield instruction that overrides the model key                                                               | R-007                |

### U3. Await-gated step that advances only after predict

Done when: a step method on the controller awaits the injected predict function, reads the choice
answer for the relative-turn question, applies that relative turn, advances exactly one cell (or
ends on collision), and returns; while that future is incomplete, calling the step or letting fake
time elapse does not change snake cells; completing the future then produces exactly one cell of
progress for that step.

Files it may touch: the example application library controller modules and logic tests under the
example test tree that inject an incomplete future and use fake async time. Those tests must not
open an ONNX session.

| Scenario                        | Category   | Input                                                                           | Action                                                               | Expected outcome                                               | Covers               |
|---------------------------------|------------|---------------------------------------------------------------------------------|----------------------------------------------------------------------|----------------------------------------------------------------|----------------------|
| Incomplete predict holds board  | happy path | Injected predict future left incomplete; known snake cells                      | Start a step and elapse fake time                                    | Snake cells are unchanged                                      | R-004, AE-003        |
| Complete then advance one       | happy path | Same setup; then complete the future with choice straight (or another safe key) | Allow the awaited step to finish                                     | Snake advances exactly one cell according to the relative turn | R-003, R-004, AE-003 |
| No timer in controller step     | edge       | Controller step path under inspection during the incomplete-predict test        | Search for scheduled periodic or delayed work that mutates the board | No board mutation occurs from time alone                       | R-004, R-005         |
| Predict error ends step cleanly | error      | Injected predict that completes with a failure                                  | Run one step                                                         | Board is not advanced and no turn is invented                  | R-004                |

### U4. Snake screen wired to LoadedRuntime.predict without timers

Done when: the example app exposes a Snake screen that constructs the controller with a predict
function that calls the real LoadedRuntime.predict, runs the await-gated step loop, and rebuilds the
board UI from controller state after each finished step; the Snake screen’s Dart sources contain no
Timer, no Future.delayed, and no Ticker; LayaFlutter.open and the predict API shape are not
redesigned.

Files it may touch: example application library UI modules (including replacing the skeleton home
path as needed), example widget or source-inspection tests that assert absence of Timer,
Future.delayed, and Ticker on the Snake screen, and only incidental example wiring needed to obtain
an already-loaded runtime. No changes to the public library predict or open contracts under the
package lib tree except if a compile fix is forced by an unrelated break, which must not alter
behaviour.

| Scenario                      | Category    | Input                                                        | Action                                        | Expected outcome                                                       | Covers              |
|-------------------------------|-------------|--------------------------------------------------------------|-----------------------------------------------|------------------------------------------------------------------------|---------------------|
| Screen awaits real predict    | integration | Loaded runtime available in the example                      | Open the Snake screen and complete one step   | Screen calls LoadedRuntime.predict and redraws after the step finishes | R-002, R-003, R-005 |
| No timer constructs on screen | happy path  | Snake screen Dart sources                                    | Inspect for Timer, Future.delayed, and Ticker | None are present                                                       | R-005, AE-006       |
| Decorative ticker rejected    | error       | A proposed AnimationController or Ticker used only to redraw | Evaluate against this unit                    | It is rejected; redraw stays state-driven after the awaited step       | R-005               |
| Open and predict unchanged    | edge        | Public library open and predict signatures                   | Diff against the closed 0002 API              | No redesign of those entry points for this slice                       | Boundaries          |

## Interfaces and shared decisions

Choice question: one question per step. Its id is the string turn, and that id is the key used to
read LayaAnswer.choice from the predict result. Keys are left, right, and straight. Descriptions
state that each key is a turn relative to the current heading. No boolean-word keys. No absolute UP,
DOWN, LEFT, RIGHT keys. No opaque A, B, C keys in this slice. No planner text. No safety shield
after the answer.

State: one short English string (not a string map for this slice) naming the cardinal heading, the
head cell, the food cell, and the cell immediately left, right, and ahead of the head, each
classified as empty, wall, body, or food.

Relative turn application: left and right rotate the cardinal heading; straight keeps it; then the
head moves one cell in the new heading.

Step loop: await predict, apply choice, advance one cell or end. No Timer, no Future.delayed, no
Ticker anywhere on the Snake screen, including decorative drawing. Redraw by updating Flutter state
after the awaited step.

Controller seam: pure Dart under the example application library. Constructor or factory accepts a
predict function matching the observable shape of LoadedRuntime.predict (state plus question map in,
answers out as a future) and a random source for food. Logic tests inject both. The screen passes a
closure that calls the real LoadedRuntime.predict.

Library API: do not change LayaFlutter.open or LoadedRuntime.predict for this slice.

Error handling: if predict fails, the step does not invent a turn and does not advance. Collision
sets an ended state. A later step attempt while ended does not change snake cells.

Board geometry: one wall rule. Playable cells are column 0 inclusive through width exclusive, and
row 0 inclusive through height exclusive. A next cell outside that range is a wall. The example
screen uses width 12 and height 12. Tests may pass a smaller width and height, and they use the same
outside-is-wall rule. There is no second perimeter model.

Naming: prefer clear English type and file names under example/lib that say Snake and controller;
avoid packing rules into the package lib/ tree.

## Risks

| Risk                                                         | Likelihood | Impact                                                              | Mitigation                                                                                                                                | Trigger that means it happened                                 |
|--------------------------------------------------------------|------------|---------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------|
| Semantic left/right/straight keys play poorly on real boards | Medium     | Example dies quickly though mechanics are correct                   | SC-003 requires correct mechanics and a model-chosen turn each step, not a long survival score; keep keys as decided; do not add a shield | Manual run dies immediately while tests pass                   |
| Implementer adds Future.delayed for pacing or a draw Ticker  | Medium     | SC-003 negative case (timer moves without model) becomes ambiguous  | U4 source inspection forbids Timer, Future.delayed, and Ticker on the Snake screen                                                        | Any of those constructs appear in Snake screen sources         |
| Logic tests accidentally open an ONNX session                | Medium     | Tests fail for sandbox or MissingPluginException unrelated to Snake | Keep predict injected; cite the macOS session solution; never call open from controller unit tests                                        | A Snake logic test creates a session or calls LayaFlutter.open |
| Scope creep into SC-005 or SC-006                            | Low        | Slice never closes                                                  | Contract boundaries; no device launch requirement in criteria                                                                             | Criteria or units demand Android or iOS launch                 |
| Predict failure leaves the UI unclear                        | Low        | User thinks the game hung                                           | Do not invent a turn and do not advance; this slice adds no failure UI                                                                    | Step fails and the board advances or a turn is invented        |

## Rollback

Revert the example application library Snake modules, the Snake screen wiring, and the example tests
in one change. The package library API is unchanged, so rollback does not affect offline predict
callers. No one-way door: the slice adds example-only behaviour and commits no weights.

## Out of scope

Android and iOS launches (SC-005). Extra platforms (SC-006). Redesign of LayaFlutter.open or
LoadedRuntime.predict. Planner text, safety shields, absolute direction keys, boolean-word keys,
opaque A/B/C keys. Measured bake-off of state encodings. Decorative animation tickers and
post-predict delays. Turning the example into a reusable game engine. Host session-load proofs (
already covered by 0002 and the macOS sandbox solution).

## Verification approach

Run dart format and dart analyze on the package and example as required by AGENTS.md. Run the
example’s logic tests for food spawn, relative turns, wall and body collision, incomplete-predict
immobility under fake async time, and prompt shape (keys and state string). Confirm those tests
inject predict and do not open an ONNX session. Inspect or test that Snake screen sources contain no
Timer, Future.delayed, or Ticker. Perform a manual or host run of the example Snake screen when a
local checkpoint is available, without claiming Android or iOS launch. Run python3
tools/lint_wiki.py before closing the plan phase. Paste command output as evidence in verify; do not
claim a check passed without it.
