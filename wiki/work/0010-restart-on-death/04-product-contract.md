# Product contract: Restart the example Snake game when the snake dies

## Advances

none

## Actors

| ID    | Actor                                    | What they are trying to do                                                                            |
|-------|------------------------------------------|-------------------------------------------------------------------------------------------------------|
| A-001 | Person watching the Classic Snake screen | Keep seeing play after the snake dies, without pressing a control                                     |
| A-002 | VM test runner                           | Prove death and new-run behaviour with an injected predict double and without opening an ONNX session |

## Requirements

| ID    | Requirement                                                                                                                                                                                                                                                                                                         |
|-------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | When a valid relative step would place the head on a wall cell or on the snake's own body, the current run shall end without placing the head on that cell and without changing the snake cells, heading, or food on that step; a further step while that run is still ended shall leave the snake cells unchanged. |
| R-002 | When the current run has ended because of a wall or own-body collision, the Snake screen shall start a new run by a separate action with no user control and without a timer, delayed future, or ticker.                                                                                                            |
| R-003 | When that new-run action has completed, play shall match a fresh construction: ended is false; snake cells are (2,0), (1,0), (0,0) head-first; heading is east; food occupies an empty cell. The food cell need not match the previous game's food cell.                                                            |
| R-004 | When the new run has started, the Snake screen shall run await-gated steps again using the already-loaded runtime, shall not call open again, and shall not run two step loops together.                                                                                                                            |
| R-005 | When a step stops because predict fails or the choice is missing or not a relative turn, the system shall not start a new run from that stop alone.                                                                                                                                                                 |
| R-006 | When play is resting after a death restart, the title shall be Snake; the ended title shall not be the resting state.                                                                                                                                                                                               |

## Flows

| ID    | Flow                                                                                                                                                                                                                                                                         | Covers                     |
|-------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------|
| F-001 | A living step hits a wall or own body: the current run ends with the head still on the pre-collision cell; cells, heading, and food are unchanged on that step; a further step while still ended does not move cells.                                                        | R-001                      |
| F-002 | After that ended run, the screen invokes the new-run action with no user gesture and no paced delay; play matches fresh construction; await-gated steps resume on the already-loaded runtime; open is not called again; only one step loop runs; the resting title is Snake. | R-002, R-003, R-004, R-006 |
| F-003 | A step stops on predict failure or a missing or non-relative choice: ended is not set by that stop alone, and no new-run action runs from that stop alone.                                                                                                                   | R-005                      |

## Acceptance examples

| ID     | Example                                                                                                                                                                                                                                                                                                                                          | Covers              |
|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| AE-001 | A controller driven with an injected predict double that steers into a wall ends the run with the head on the pre-collision cell; a further step leaves cells unchanged; after the new-run action, ended is false, cells are (2,0), (1,0), (0,0) head-first, heading is east, food is on an empty cell, and a later step can change cells again. | R-001, R-003        |
| AE-002 | The same harness for own-body collision shows the same end-then-restore pattern.                                                                                                                                                                                                                                                                 | R-001, R-003        |
| AE-003 | After wall or body death on the screen path, the screen invokes the new-run action and continues await-gated steps without calling open and without a timer, delayed future, or ticker; the resting title is Snake.                                                                                                                              | R-002, R-004, R-006 |
| AE-004 | A predict-failure step leaves ended false and does not invoke the new-run action.                                                                                                                                                                                                                                                                | R-005               |

## Boundaries

- This slice does not change library open or predict.
- This slice does not add a play or restart button.
- This slice does not change relative turn keys or Classic Snake relative-turn rules.
- This slice does not pace death with a timer, delayed future, or ticker.
- This slice does not call open again to restart; the loaded runtime is reused.
- This slice does not treat predict failure as death or as a restart trigger.
- This slice does not require pumping the production Snake screen with a real ONNX session for
  proof.
- This slice does not advance SC-001 through SC-007; goal_check stays null.
- Host session-load proof remains outside VM flutter test (macOS integration path from the sandbox
  solution).

## Assumptions

- Constructor replacement on the screen is the product mechanism for a new run: the ended controller
  is replaced by a newly constructed controller that matches today's screen construction defaults,
  reusing the already-loaded runtime's predict and allowing reuse of the existing random source.
- The new-run action is separate from the collision step that sets ended; collision semantics stay
  as they are today.
- Matching constructor defaults for snake, heading, ended, and empty-cell food is sufficient;
  bit-identical food to the previous game is not required.
- Clearing or resetting a one-shot loop flag is an implementation detail; the observable rule is
  that await-gated steps run again and two loops do not run together.
- The ended title may appear briefly or not at all between death and the new run; it is not the
  resting state after restart.

## Resolve before planning

(none)
