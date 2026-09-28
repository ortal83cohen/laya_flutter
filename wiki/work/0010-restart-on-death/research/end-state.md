# Research: End-state transitions after Snake death

## Question

When the example Snake game ends because the head's next cell is a wall or the snake's own body,
which controller fields and screen loop state change, and which of those fields a brand-new game
would have to restore to the values a freshly constructed controller has?

## Answer

Death sets only `SnakeController.ended` to true and leaves snake cells, heading, food, and
`foodPlacementFailed` untouched; the screen step loop then exits because `ended` is true while
`_loopStarted` stays true. A brand-new game matching a freshly constructed controller must bring
play state back to constructor defaults (`ended` false, default three-cell snake, heading east, a
new food placement from `spawnFood`) and must start stepping again, because the existing `_runSteps`
while-loop has already finished and will not resume on its own.

## Findings

### Closed goal: wall or own body ends the game; no step timer

- Claim: The product goal's closed Snake assumptions state that a wall or the snake's own body ends
  the game, food appears on a random empty cell, the model chooses a relative left/right/straight
  turn, and there is no step timer. SC-003 restates ending on a wall or own body. Predict failure
  and a missing choice are outside that death definition (shared decision for this work item).
- Evidence: Closed assumptions name wall/body end, random empty food, relative turns, and no step
  timer. SC-003 row names collision end and absence of a periodic ticker.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 32 and 43.

### Prior solution does not answer restart-after-death

- Claim: The only file under `wiki/solutions/` covers macOS ONNX session-load harness and sandbox
  cache entitlements. It does not describe Snake end-state fields or restart.
- Evidence: Summary and guidance are about `integration_test` and sandbox paths, not Snake board
  state.
- Source:
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`
  lines 8–32.

### Death is decided only in `_applyChoiceAndAdvance` after a valid turn choice

- Claim: `step` returns immediately when `ended` is already true. Otherwise it awaits predict; on
  catch, missing `turn` choice, or a non-relative key, it returns without setting `ended` and
  without advancing. Only after a valid relative choice does `_applyChoiceAndAdvance` run. There,
  the next cell in the rotated heading is a wall or a body cell if and only if `_isWall(next)` or
  `_isBody(next)`; then `ended` is set to true and the method returns without mutating `_snake`,
  `heading`, or `food`.
- Evidence: Early return when already ended at `example/lib/snake_controller.dart` lines 180–182;
  predict catch and missing/invalid choice returns at lines 191–197; collision branch sets only
  `ended` and returns at lines 205–210; successful path updates heading and snake only after that
  check at lines 211–218.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines
  179–218.

### Controller fields that change on death versus fields that do not

- Claim: The only controller field written on the death path is `ended` (false by field initializer,
  set true on wall/body). On that path `_snake`, `heading`, `food`, and `foodPlacementFailed` are
  not assigned. Width, height, `predict`, and `random` are constructor parameters and are not
  mutated by death. After death, further `step` calls are no-ops while `ended` remains true.
- Evidence: `ended` default and comment at lines 104–105; death assignment at lines 207–209;
  successful mutations of heading/snake/food only on the non-death branch at lines 211–218; `step`
  guards at lines 180–182 and 202–204; immutable-style finals for width/height/predict/random at
  lines 83–93.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines
  83–105 and 179–218.

### Freshly constructed controller values the screen uses today

- Claim: `SnakeScreen` constructs one `SnakeController` in `initState` with width 80, height 80, a
  new `math.Random()`, and a predict closure over `widget.runtime`. It does not pass `initialSnake`,
  `initialHeading`, or `initialFood`, so the constructor defaults apply: heading east; snake cells
  `(2,0)`, `(1,0)`, `(0,0)` head-first; food from `spawnFood()` (which clears `foodPlacementFailed`
  then samples until an empty cell or fails); `ended` remains false. Those are the play-state values
  a "fresh" game must match when using the same screen wiring.
- Evidence: Screen construction at `example/lib/snake_screen.dart` lines 29–39; constructor defaults
  and initializer list at `example/lib/snake_controller.dart` lines 56–80; `ended` and
  `foodPlacementFailed` defaults at lines 104–108; `spawnFood` clearing and placement at lines
  121–140.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart` lines
  29–39; `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines
  56–80 and 104–140.

### After any play then death, play fields usually differ from constructor defaults even though death itself only flips
`ended`

- Claim: A living step that does not die updates `heading` and `_snake` (and may call `spawnFood`).
  Death then only sets `ended`. Therefore an ended controller almost always still holds the last
  living snake and heading, not the default east three-cell start, and still holds whatever `food` (
  and possibly `foodPlacementFailed`) the last living placement left. Matching a freshly constructed
  controller therefore requires restoring those play fields as well as clearing `ended`, not only
  clearing `ended`.
- Evidence: Living advance mutates heading and snake (and food via `spawnFood` when eating) at
  `example/lib/snake_controller.dart` lines 211–218; death leaves those untouched at lines 207–209;
  constructor defaults at lines 62–80.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines
  62–80 and 207–218.

### Screen loop state on death: while exits; `_loopStarted` stays true

- Claim: The step loop starts once: `didChangeDependencies` sets `_loopStarted` to true and calls
  `_runSteps` only when `_loopStarted` was false. `_runSteps` loops while
  `mounted && !_controller.ended`, awaits `step`, then `setState`. When death sets `ended`, the next
  while check fails and the function returns. The same-cells early return (predict failure or
  missing choice without ending) is a different exit: it requires `!_controller.ended` and unchanged
  cells. Death does not reset `_loopStarted` or replace `_controller`. The AppBar title reads
  `_controller.ended` and shows "Snake — ended" after the post-step `setState`.
- Evidence: One-shot loop start at `example/lib/snake_screen.dart` lines 43–48; while and post-step
  logic at lines 58–73; title binding at lines 91–93; `_loopStarted` and `_controller` fields at
  lines 25–26.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart` lines
  25–26, 43–48, 58–73, and 91–93.

### Fields a new game must match for constructor-equivalent play state

- Claim: Relative to a freshly constructed controller as the screen builds it, a new game must match
  at least: `ended == false`; snake cells equal to the default three cells (or an explicit
  `initialSnake` if one were passed, which the screen does not); `heading == CardinalHeading.east` (
  screen omits `initialHeading`); `food` equal to a successful `spawnFood` result for the reset
  body (or an explicit `initialFood`, which the screen does not pass); and `foodPlacementFailed`
  consistent with that placement (false when food was placed). Width, height, and the predict
  closure can stay as on the current instance if the same board and runtime are reused; `random` may
  be a new `Random()` (as in a new screen construction) or the same instance — both are valid
  constructor inputs, but a new construction today always allocates a new `Random()`. Independently
  of controller fields, the screen must run a step loop again after death: `_loopStarted` remains
  true and `_runSteps` has exited, so constructor-matching controller state alone does not resume
  play.
- Evidence: Defaults and fields cited above; `_loopStarted` never cleared after line 46; `_runSteps`
  while condition at lines 58–59.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines
  56–108; `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart` lines
  29–39, 43–48, and 58–73.

## Options considered

| Option                                                                                                                                                                                                                                        | How it works                                                                                                                          | Cost                                                                                                                                                                                                                                                      | Why rejected / chosen                                                                                                                                                                                                                         |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Reconstruct a new `SnakeController` with the same width, height, and predict wiring the screen uses today (new or same `Random`), then point the screen at it and start `_runSteps` again                                                     | Matches constructor defaults for snake, heading, `ended`, and a new `spawnFood` in one construction path; replaces the ended instance | Requires the screen to hold a replaceable controller reference and to invoke the step loop after the first `_loopStarted` gate                                                                                                                            | **Favoured for "match freshly constructed".** The constructor is the only existing place that establishes the full default play state (`example/lib/snake_controller.dart` lines 56–80); death leaves no other reset path in these two files. |
| Keep the same controller instance and set play fields back to the same values the constructor would have produced (`ended` false, default snake cells, heading east, `spawnFood` for food/`foodPlacementFailed`), then call `_runSteps` again | Avoids allocating a new controller; still must rewrite every play field that diverged during the previous game, not only `ended`      | Same observable board/loop outcome if every default is matched; `_snake` is a private list mutated only inside the controller today, so field-by-field restore is not expressible from the screen without new controller surface (out of scope to design) | **Viable meaning of restore, not favoured as the definition of "freshly constructed".** It can match constructor values, but equivalence is manual and easy to miss fields that living steps changed before death.                            |

## Constraints discovered

- Death means wall or own body only; predict failure or missing choice must not be treated as
  death (`wiki/product/GOAL.md` line 32; shared decision; `snake_controller.dart` lines 191–197 vs
  207–209; `snake_screen.dart` lines 69–71).
- Library open and predict stay closed; there is no step timer (`wiki/product/GOAL.md` line 32;
  shared decision).
- Clearing `ended` alone is not enough for a constructor-equivalent new game: snake, heading, and
  food usually still reflect the previous living state (`snake_controller.dart` lines 207–218 vs
  62–80).
- After death the screen loop has exited with `_loopStarted` still true; constructor-matching
  controller state does not by itself resume stepping (`snake_screen.dart` lines 43–48 and 58–59).
- A play button is out of scope for the user's restart-after-death request (shared decision).

## Unresolved

- [UNRESOLVED: Whether a new game should allocate a new `math.Random()` (as
  `initState` does today) or reuse the existing
  `random` instance when restoring constructor-equivalent play state.]
- [UNRESOLVED: Whether food after restore must be bit-identical to some recorded constructor spawn, or only "a valid empty-cell placement" as
  `spawnFood` produces.]
- [UNRESOLVED: Whether `_loopStarted` should ever be cleared, or whether a second
  `_runSteps` invocation while
  `_loopStarted` remains true is the intended way to resume after death.]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-28.
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`,
consulted 2026-09-28.
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart`, consulted
  2026-09-28.
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart`, consulted
  2026-09-28.
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/templates/00-research.md`, consulted
  2026-09-28.
