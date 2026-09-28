# Tasks: Restart the example Snake game when the snake dies

## Legend

- `[P]` — may run in a parallel subagent. Only mark a task `[P]` if no other `[P]` task in the same
  group touches any of the same files.
- Every task cites the criteria it satisfies and the unit (`U1`, `U2`) it completes. A task
  satisfying no criterion does not belong here.
- Owned files are exclusive. Two tasks never list the same file.

## Groups

Groups run in sequence. This work item is one group because the controller, the screen, and their
tests share the new-run action.

### Group 1 — Restart after death

| #   | Task                                                                                                                                                                                                                                                                                                                                                                           | Satisfies                                  | Files owned                                                                  | Parallel | Done when                                                                                                                                                                                     | Status |
|-----|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------|------------------------------------------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|
| 1.1 | Keep collision as the end of the current run only: wall and body set ended, the head stays off the wall and off the body cell, and a further step before new-run does not change cells.                                                                                                                                                                                        | AC-001, AC-002, AC-003, U1                 | example/lib/snake_controller.dart, example/test/snake_controller_test.dart   |          | Those three criteria fail if the head occupies the wall or body, or if a further step while still ended moves cells.                                                                          | done   |
| 1.2 | Add the new-run action as constructor replacement: ended false, cells (2,0), (1,0), (0,0) head-first, heading east, food on an empty cell, then a later valid step can move cells. Reuse the existing random source. Do not fold restore into the collision step.                                                                                                              | AC-004, AC-005, U2                         | example/lib/snake_controller.dart, example/test/snake_controller_test.dart   |          | A test that skips the new-run action still sees ended true and frozen cells. A test that runs new-run then a valid step sees cells change.                                                    | done   |
| 1.3 | After wall or body death, the screen invokes new-run with no button, no timer, no second open, and one await-gated loop. The controller field is assignable. Production omits the predict override and still calls the loaded runtime's predict. The resting title is Snake. Predict failure does not start a new run. Board size stays the screen's current eighty by eighty. | AC-006, AC-007, AC-008, AC-009, AC-010, U3 | example/lib/snake_screen.dart, example/test/snake_screen_test.dart           |          | Screen sources still contain no Timer, Future.delayed, or Ticker. A session-free screen test shows new-run and a continued loop after death, and shows that predict failure does not restart. | done   |
| 1.4 | Session-free proof for the controller and the screen: injected predict only, no LayaFlutter.open and no ONNX session.                                                                                                                                                                                                                                                          | AC-011, U4                                 | example/test/snake_controller_test.dart, example/test/snake_screen_test.dart |          | A test fails if the proof path contains an open or session call, and the death-then-restart tests do not open a session.                                                                      | done   |

## Serialised files

| File                                    | Owning task                       |
|-----------------------------------------|-----------------------------------|
| example/lib/snake_controller.dart       | 1.1 then 1.2, same owner          |
| example/lib/snake_screen.dart           | 1.3                               |
| example/test/snake_controller_test.dart | 1.1 then 1.2 then 1.4, same owner |
| example/test/snake_screen_test.dart     | 1.3 then 1.4, same owner          |

No task is marked `[P]`. One implementer owns the group.

## Test tasks

| #   | Covers                                 | Positive case                                                                                     | Negative case                                                               |
|-----|----------------------------------------|---------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| 1.1 | AC-001, AC-002, AC-003                 | Wall and body end with the head on the pre-collision cell; a further step leaves cells unchanged. | Head on the wall or body cell, or cells move while still ended.             |
| 1.2 | AC-004, AC-005                         | New-run restores the default snake, east heading, empty-cell food, and a later step moves cells.  | Skipping new-run leaves ended true; food on a body cell fails.              |
| 1.3 | AC-006, AC-007, AC-008, AC-009, AC-010 | Screen restarts after death, title returns to Snake, one loop, no timer.                          | Predict failure does not restart; a timer or a second open fails the check. |
| 1.4 | AC-011                                 | Predict double only.                                                                              | Open or session creation in the proof path.                                 |
