# Product contract: Classic Snake example driven by offline Laya predict

## Advances

SC-003

## Actors

| ID    | Actor                | What they are trying to do                                                                                                        |
|-------|----------------------|-----------------------------------------------------------------------------------------------------------------------------------|
| A-001 | Example app user     | Play classic Snake whose next cell waits for the model’s relative turn                                                            |
| A-002 | Logic test harness   | Prove spawn, collision, relative turns, and that the board does not move until predict completes, without opening an ONNX session |
| A-003 | Example Snake screen | Call the already-loaded offline predict path for each step and redraw after that step finishes                                    |

## Requirements

| ID    | Requirement                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|-------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | When the example needs a food cell, food shall appear on a random empty board cell and shall not appear on any cell occupied by the snake                                                                                                                                                                                                                                                                                                   |
| R-002 | When a step begins, the example shall send the board situation to the model as one choice question whose option keys are left, right, and straight, each described as a turn relative to the snake’s current heading, and whose state is one short English string that names the cardinal heading, the head cell, the food cell, and the cell immediately left, right, and ahead of the head, each classified as empty, wall, body, or food |
| R-003 | When the model’s choice for that step is available, the snake shall apply that choice as a turn relative to the current heading and then advance exactly one cell                                                                                                                                                                                                                                                                           |
| R-004 | When predict for the current step has not completed, the snake’s cells shall remain unchanged; the board shall advance one cell only after that predict completes                                                                                                                                                                                                                                                                           |
| R-005 | The Snake screen shall contain no Timer, no Future.delayed, and no Ticker, including for decorative drawing; redraw shall happen by updating state after the awaited step                                                                                                                                                                                                                                                                   |
| R-006 | When the head’s next cell is a wall or a cell occupied by the snake’s own body, the game shall end and the snake shall not continue stepping                                                                                                                                                                                                                                                                                                |
| R-007 | The example shall not add planner text and shall not apply a safety shield that overrides or filters the model’s chosen turn                                                                                                                                                                                                                                                                                                                |

## Flows

| ID    | Flow                                                                                                                                                                                       | Covers                     |
|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------|
| F-001 | Play step: the screen builds the short English state and the relative-turn choice question, awaits predict, turns from the returned key, advances one cell, and redraws from the new state | R-002, R-003, R-004, R-005 |
| F-002 | Eat and grow: the head lands on food; the snake grows; a new food cell is chosen at random among empty cells                                                                               | R-001, R-003               |
| F-003 | Collision end: the chosen relative turn would move the head into a wall or into the body; the game ends and no further cell advance occurs                                                 | R-006                      |
| F-004 | Incomplete predict: a test holds predict unfinished, lets fake time pass, and observes that the snake cells are unchanged until the future completes                                       | R-004, R-005               |

## Acceptance examples

| ID     | Example                                                                                                                                                                                  | Covers |
|--------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|
| AE-001 | Food is requested while several cells are empty and some are body; the spawned food cell is one of the empty cells and is never a body cell                                              | R-001  |
| AE-002 | Heading is east; the model returns left; the snake’s new heading is north and the head moves one cell north                                                                              | R-003  |
| AE-003 | Predict is held incomplete; fake time elapses; snake cells are unchanged; completing predict then advances exactly one cell                                                              | R-004  |
| AE-004 | Head is one cell from a wall and the model returns straight; the game ends and the snake does not occupy the wall cell as a continuing play position                                     | R-006  |
| AE-005 | The step’s choice keys are left, right, and straight with relative-turn descriptions; the state string names heading, head, food, and the three forward-facing neighbour classifications | R-002  |
| AE-006 | Source of the Snake screen is inspected; there is no Timer, Future.delayed, or Ticker construction                                                                                       | R-005  |

## Boundaries

This slice advances SC-003 only. It does not require Android or iOS launches (SC-005) and does not
require extra platforms (SC-006).

This slice does not redesign LayaFlutter.open or LoadedRuntime.predict. It calls the existing
offline predict path from the example screen.

This slice does not claim a measured bake-off of state encodings or choice-key styles. Slice
decisions fix the prompt and loop for this example; they do not assert that this encoding wins a
benchmark.

This slice does not add planner-enriched option text, a post-model safety shield, absolute
UP/DOWN/LEFT/RIGHT choice keys, boolean-word keys, or opaque A/B/C keys.

This slice does not introduce a step timer, a one-shot delay after predict for pacing, or a
decorative animation ticker on the Snake screen.

This slice does not turn the example into a reusable game engine.

## Assumptions

Snake is classic: a wall or the snake’s own body ends the game; food appears on a random empty cell;
the model chooses a left turn, a right turn, or straight ahead relative to the current heading;
there is no step timer.

Choice keys are left, right, and straight. Descriptions say the turn is relative to the current
heading.

State is one short English string naming the cardinal heading, the head cell, the food cell, and the
cell immediately left, right, and ahead (empty, wall, body, or food).

Game rules live in a pure Dart controller under the example application library. Logic tests inject
a predict function that can stay incomplete. The example screen calls the real
LoadedRuntime.predict. Logic tests must not open an ONNX session.

The public predict API from work item 0002 remains closed for this slice.

## Resolve before planning

None. The slice decisions in the work item brief close the research unresolved list for this slice
only.
