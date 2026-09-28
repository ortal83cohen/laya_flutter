# Acceptance criteria: Restart the example Snake game when the snake dies

## Frozen

- Frozen at: 2026-09-28
- Frozen by: orchestrator, at the start of implementation

## Criteria

| ID     | Traces       | Criterion                                                                                                                                                                                               | How it is checked                                                                                                                                                         | Negative case                                                                                                             |
|--------|--------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| AC-001 | R-001        | When a valid relative step would place the head on a wall cell, the current run shall end with the head still on the pre-collision cell and with snake cells, heading, and food unchanged on that step. | Controller test with an injected predict double that steers into a wall; assert ended, head cell, and unchanged cells, heading, and food on that step; no session opened. | The head occupies the wall cell, or cells, heading, or food change on the collision step, or ended stays false.           |
| AC-002 | R-001        | When a valid relative step would place the head on the snake's own body, the current run shall end with the head still on the pre-collision cell and with snake cells unchanged on that step.           | Controller test with an injected predict double that steers into the body; assert ended and unchanged cells on that step; no session opened.                              | The head advances onto a body cell, or cells change on the collision step, or ended stays false.                          |
| AC-003 | R-001        | When the current run is still ended after a wall or body collision and the new-run action has not run, a further step shall leave the snake cells unchanged.                                            | After collision end, call step again before new-run; assert cells unchanged.                                                                                              | A further step while still ended changes cells.                                                                           |
| AC-004 | R-003        | When the new-run action runs after a wall or body end, play shall show ended false, snake cells (2,0), (1,0), (0,0) head-first, heading east, and food on an empty cell.                                | After collision end, invoke new-run (constructor replacement); assert those observables; food need not match the previous food cell.                                      | ended stays true, cells are not the default three-cell start, heading is not east, or food is on an occupied cell.        |
| AC-005 | R-003        | When a valid relative turn is predicted after the new-run action, a step shall change the snake cells from the default start layout.                                                                    | After new-run, inject a valid relative choice and step; assert cells differ from (2,0), (1,0), (0,0).                                                                     | A post-new-run step leaves cells unchanged despite a valid relative choice, or cells already moved before new-run.        |
| AC-006 | R-002, R-004 | When the Snake screen observes a wall or body end, it shall invoke the new-run action with no user control, continue await-gated steps, and not call open again.                                        | Session-free screen-level check: after death, new-run runs and the step loop continues; open is not invoked; no ONNX session is required.                                 | The screen stays on the ended controller without new-run, calls open again, or requires a real session to prove the path. |
| AC-007 | R-002        | When the Snake screen restarts after death, it shall not use a timer, delayed future, or ticker for that death or restart path.                                                                         | Review the Snake screen sources for absence of timer, delayed future, and ticker on the death and restart path; behaviour shows immediate new-run without paced delay.    | Death or restart is paced by a timer, delayed future, or ticker.                                                          |
| AC-008 | R-004        | When await-gated steps resume after new-run, two step loops shall not run together.                                                                                                                     | Screen-level check or review that restart starts steps only once; no concurrent second loop.                                                                              | Two concurrent await-gated step loops are active after restart.                                                           |
| AC-009 | R-006        | When play is resting after a death restart, the title shall be Snake and shall not remain the ended title.                                                                                              | After new-run on the screen path, observe the title is Snake.                                                                                                             | The resting title after restart is the ended title, or another non-Snake title.                                           |
| AC-010 | R-005        | When a step stops because predict fails or the choice is missing or not a relative turn, the system shall not start a new run from that stop alone and shall not set ended from that stop alone.        | Controller or screen check with injected predict failure (or missing or non-relative choice); assert ended false and new-run not invoked.                                 | Predict failure sets ended, or invokes new-run, or both.                                                                  |

## Non-functional criteria

| ID     | Traces              | Criterion                                                                                                                                                               | How it is checked                                                                                                             | Negative case                                                                                            |
|--------|---------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| AC-011 | R-001, R-003, R-004 | When verifying death and new-run for this slice, VM tests shall inject predict and shall not open an ONNX session, and shall not be treated as host session-load proof. | Confirm controller and screen proofs use injected predict, complete without a native session, and make no session-load claim. | A reviewer treats a green VM test as proof that an ONNX session loaded, or a proof path opens a session. |

## Explicitly not required

- Advancing SC-001 through SC-007; goal_check stays null.
- A play or restart button.
- Changes to library open or predict.
- Changes to relative turn keys.
- Bit-identical food to the previous game after new-run.
- A paced death pause or death animation.
- Pumping production SnakeScreen with a real ONNX session.
- In-place clear of fields on the ended controller instance.
- Reopening or changing the macOS ONNX session sandbox solution.

## Verdict log

| Round | Date | Verdict | Report |
|-------|------|---------|--------|
