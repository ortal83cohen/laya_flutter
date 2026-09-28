# Tasks: Log every Snake model choice with the state that produced it

## Legend

- `[P]` — may run in a parallel subagent. Only mark a task `[P]` if no other `[P]` task in the same group touches any of the same files.
- Every task cites the criteria it satisfies and the unit (`U1`, `U2`) it completes. A task satisfying no criterion does not belong here.
- Owned files are exclusive. Two tasks never list the same file.

## Groups

Groups run in sequence. This work item has one group and one task, because the controller, the screen callback, and the logic tests share the same record contract.

### Group 1 — Choice record

| # | Task | Satisfies | Files owned | Parallel | Done when |
|---|---|---|---|---|---|
| 1.1 | U1, U2, U3, U4. Add the optional choice-record callback and record type, emit one success or no-choice record per finished living step, wire the Snake screen to print one debug line per record, and prove it with session-free controller tests. | AC-001, AC-002, AC-003, AC-004, AC-005, AC-006, AC-007, AC-008 | example/lib/snake_controller.dart, example/lib/snake_screen.dart, example/test/snake_controller_test.dart | | DONE. Controller tests cover success records, no-choice records, silence when the callback is omitted, and a failure when a relative key produces no record. The screen passes a one-line debug callback. No library file changes. |

## Serialised files

| File | Owning task |
|---|---|
| example/lib/snake_controller.dart | 1.1 |
| example/lib/snake_screen.dart | 1.1 |
| example/test/snake_controller_test.dart | 1.1 |

## Test tasks

| # | Covers | Positive case | Negative case |
|---|---|---|---|
| 1.1a | AC-001, AC-002, AC-007 | Injected relative predict and a capturing callback yield one success record with pre-step state, key, probabilities, and confidence, then cells move when the turn does not collide. | Zero records, a wrong key, or cells that stay put on a non-colliding turn fails. |
| 1.1b | AC-003, AC-004 | Predict throw, missing key, and a non-relative key each yield one no-choice record and leave cells unchanged. | A fabricated turn or a cell change fails. |
| 1.1c | AC-005 | No callback and a valid relative predict still moves the snake and delivers no record. | A stall, or a record with no callback, fails. |
| 1.1d | AC-006, AC-008 | Screen source passes a debug-line callback. Tests inject predict and do not open a session. | A screen with no callback, or a test that calls open, fails. |
