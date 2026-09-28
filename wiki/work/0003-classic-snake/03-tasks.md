# Tasks: Classic Snake example driven by offline Laya predict

## Legend

- `[P]` — may run in a parallel subagent. Only mark a task `[P]` if no other `[P]` task in the same group touches any of the same files.
- Every task cites the criteria it satisfies and the unit (`U1`, `U2`) it completes. A task satisfying no criterion does not belong here.
- Owned files are exclusive. Two tasks never list the same file.

## Groups

Groups run in sequence. No task in this work item is parallel. U1, U2, and U3 share the controller modules, so they are one task. U4 starts only after that task is closed.

### Group 1 — Classic rules, prompt, and await-gated step

| # | Task | Satisfies | Files owned | Parallel | Done when |
|---|---|---|---|---|---|
| 1.1 | U1, U2, U3. Pure Dart Snake controller: food on an empty cell, relative turns, wall and body end, English state string, choice question id turn, and a step that advances one cell only after the injected predict future completes | AC-001, AC-002, AC-003, AC-004, AC-006, AC-007, AC-008 | example/lib/snake_controller.dart, example/test/snake_controller_test.dart | | Closed: controller + 15 logic tests green via `cd example && flutter test test/snake_controller_test.dart`; package `flutter test` green |

### Group 2 — Snake screen

| # | Task | Satisfies | Files owned | Parallel | Done when |
|---|---|---|---|---|---|
| 2.1 | U4. Snake screen calls LoadedRuntime.predict, redraws after the awaited step, and contains no Timer, Future.delayed, or Ticker | AC-005, AC-009 | example/lib/main.dart, example/lib/snake_screen.dart, example/test/widget_test.dart, example/test/snake_screen_test.dart | | Closed: Snake screen + source-inspection tests; `cd example && flutter test` 18 passed; package `flutter test` 18 passed; format/analyze clean |

## Serialised files

| File | Owning task |
|---|---|
| example/lib/snake_controller.dart | 1.1 |
| example/lib/main.dart | 2.1 |

## Test tasks

| # | Covers | Positive case | Negative case |
|---|---|---|---|
| 1.1 | AC-001 | Fixed random source places food on an empty cell | Food lands on a body cell, or a full board places food without signalling failure |
| 1.1 | AC-002, AC-007 | Keys are left, right, and straight with relative-turn descriptions; state string names heading, head, food, and three neighbour classes; question id is turn | Absolute, boolean, or A/B/C keys; planner or shield text; a string-map state |
| 1.1 | AC-003 | East plus left, right, and straight each move one cell on the new heading | More than one cell, or left treated as west regardless of heading |
| 1.1 | AC-004 | Incomplete predict leaves cells unchanged; completion advances one cell | Cells change before completion, or one completion moves more than one cell |
| 1.1 | AC-006 | Wall and body set ended; a further step does not change cells | Head occupies the wall as live play, or stepping continues after body collision |
| 1.1 | AC-008 | Tests inject predict and a random source | A logic test calls LayaFlutter.open or creates an ONNX session |
| 2.1 | AC-005 | Snake screen sources have no Timer, Future.delayed, or Ticker | Any of those constructs, including an AnimationController ticker |
| 2.1 | AC-009 | The screen predict closure calls LoadedRuntime.predict | Turns chosen from a local table with no predict call |

## Defect-fix note (impl-review-01)

1.1 Done when cells that addressed F-001 (step-captured predict state/questions), F-002 (step-captured instructions without planner/shield), and F-003 (step uses inject double; source scan for session-open needles) were closed in `example/test/snake_controller_test.dart`.

2.1 Done when cell that addressed the no-spin loop (stop further steps when a step returns, game not ended, snake cells unchanged) was closed in `example/lib/snake_screen.dart`.
