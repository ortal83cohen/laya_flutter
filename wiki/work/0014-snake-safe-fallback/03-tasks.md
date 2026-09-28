# Tasks: Improve model-guided Snake decisions with structured context and logs

## Legend

- `[P]` — may run in a parallel subagent. Only mark a task `[P]` if no other `[P]` task in the same group touches any of the same files.
- Every task cites the criteria it satisfies and the unit (`U1`, `U2`) it completes.

## Groups

### Group 1 — Controller model contract

| # | Task | Satisfies | Files owned | Parallel | Done when |
|---|---|---|---|---|---|
| 1.1 | Extend Snake state/options with candidate, objective, progress and recent-key context, and implement model-owned validation records without any fallback or choice replacement. | AC-001, AC-002, AC-003, AC-004, AC-005, AC-008; U1 | `example/lib/snake_controller.dart` | | Controller behavior is covered by focused positive and negative tests. |
| 1.2 | Update controller tests for prompt facts, legal model ownership, dangerous-choice reporting, invalid/no-answer handling, progress fields, repeated-turn detection and repeatability. | AC-001, AC-002, AC-003, AC-004, AC-005, AC-008; U1 | `example/test/snake_controller_test.dart` | | Tests fail for fallback/substitution and pass for the model-owned contract. |

### Group 2 — Screen diagnostics and loop integration

| # | Task | Satisfies | Files owned | Parallel | Done when |
|---|---|---|---|---|---|
| 2.1 | Print the structured record and preserve the single await-gated loop with no timer or second decision path. | AC-006; U2 | `example/lib/snake_screen.dart` | | Screen has no timer and valid model moves reach a second awaited prediction. |
| 2.2 | Update screen tests for the new log marker, structured fields, continuation and session-free guards. | AC-006, AC-007; U2 | `example/test/snake_screen_test.dart` | | Screen tests cover positive continuation and negative timer/session paths. |

### Group 3 — Documentation

| # | Task | Satisfies | Files owned | Parallel | Done when |
|---|---|---|---|---|---|
| 3.1 | Update the classic Snake note to make model ownership, structured context and diagnostic-only collision reporting explicit; index no new ADR. | AC-001, AC-003, AC-005, AC-006; U1, U2 | `wiki/product/classic-snake-example.md` | | Documentation matches the implementation and the previous no-shield constraint is not contradicted. |

## Serialised files

| File | Owning task |
|---|---|
| `example/lib/snake_controller.dart` | 1.1 |
| `example/test/snake_controller_test.dart` | 1.2 |
| `example/lib/snake_screen.dart` | 2.1 |
| `example/test/snake_screen_test.dart` | 2.2 |
| `wiki/product/classic-snake-example.md` | 3.1 |

## Test tasks

| # | Covers | Positive case | Negative case |
|---|---|---|---|
| T1 | AC-001, AC-002 | Prompt and options expose exact relative output, candidate facts and recent-key context | Old sparse context or absolute/fallback wording fails |
| T2 | AC-003, AC-004 | Model key is applied exactly; invalid/throw leaves state unchanged | Any post-model replacement or invented direction fails |
| T3 | AC-005, AC-008 | Records are complete, repeatable and flag repeated turns without intervening | Missing status/progress/reason or choice replacement fails |
| T4 | AC-006, AC-007 | Screen continues after a valid model move using injected predict | Timer, concurrent loop or native session reference fails |
