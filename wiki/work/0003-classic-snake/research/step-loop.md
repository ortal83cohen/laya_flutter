# Research: Classic Snake step loop gated on predict

## Question

How can the Flutter example advance classic Snake by one cell only after `LoadedRuntime.predict` returns, with no periodic ticker, and how can a test show that a timer does not move the snake?

## Answer

Drive each step with an async loop that awaits `LoadedRuntime.predict`, then turns from the returned choice and advances exactly one cell; do not schedule `Timer.periodic` or a step `Ticker`. Prove the negative case with a logic test that holds predict incomplete, elapses fake time (or pumps a long `Duration`), and asserts the snake position is unchanged until the predict future completes.

## Findings

### SC-003 and the closed goal forbid a step timer

- Claim: The product outcome is a classic Snake whose next step waits for the model. Closed assumptions state there is no step timer. SC-003 requires the example to send the situation to the model on every step, turn from the model's choice, not advance on a timer, and end on wall or self-collision. The check method names logic tests for spawn, collision, and the absence of a periodic ticker. The negative case is that a timer moves the snake without a model result.
- Evidence: Outcome sentence; closed assumption on classic Snake and no step timer; SC-003 row including check method and negative case.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 15–16, 32–32, and 43–43.

### Public predict is already a Future; the example must await it before moving

- Claim: After `LayaFlutter.open`, callers run offline inference through `LoadedRuntime.predict`, which returns `Future<Map<String, LayaAnswer>>`. A choice answer exposes the selected option key on `LayaAnswer.choice`. The public barrel re-exports that API from `lib/laya_flutter.dart`. Nothing in the library schedules game steps; the example owns when to call predict and when to mutate board state.
- Evidence: `predict` signature and return type; `LayaAnswer.choice` field; barrel export of `src/library.dart` (which exports `LoadedRuntime`).
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/loaded_runtime.dart` lines 56–63; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart` lines 55–64 and 93–94; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/laya_flutter.dart` lines 1–8; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart` lines 11–12 and 14–28.

### Timer.periodic and Ticker both fire on time or frames, not on predict completion

- Claim: `Timer.periodic` invokes its callback repeatedly on a `Duration` interval until cancelled. A `Ticker` calls its callback once per animation frame while enabled. Neither API waits for an application `Future` such as `predict`; both are time- or frame-driven. Using either to advance the snake cell would implement the SC-003 negative case unless the callback refused to move until predict completed — and even then SC-003 still asks logic tests to show the absence of a periodic ticker.
- Evidence: Official constructor docs for periodic timers; Ticker class overview (callback once per frame when enabled).
- Source: `https://api.flutter.dev/flutter/dart-async/Timer/Timer.periodic.html`, consulted 2026-09-27. `https://api.flutter.dev/flutter/scheduler/Ticker-class.html`, consulted 2026-09-27.

### Dart Futures support an await-gated loop without a step clock

- Claim: An `async` function can `await` another `Future` and resume only when that future completes; while awaiting, the isolate is not blocked. `Future.doWhile` repeats an asynchronous action until the action returns `false`. Those primitives are enough to express: build state → await predict → apply left/right/straight → advance one cell → stop on death, without creating a periodic timer for steps. Flutter's own animation docs show the same await pattern for sequencing work that returns futures (there, `TickerFuture` from `AnimationController`), which confirms Future chaining is the supported non-polling control style — for Snake steps the awaited future is `predict`, not a controller tick.
- Evidence: Future class asynchronous programming section (`async`/`await`); `Future.doWhile` static method; AnimationController docs describing awaiting successive futures.
- Source: `https://api.flutter.dev/flutter/dart-async/Future-class.html`, consulted 2026-09-27. `https://api.flutter.dev/flutter/animation/AnimationController-class.html`, consulted 2026-09-27.

### Fake time and WidgetTester.pump can prove a timer did not move the snake

- Claim: `FakeAsync` runs test code in a zone where timers and other time-based asynchrony advance only when the test calls `elapse`. It exposes `periodicTimerCount` and `pendingTimers`. Widget tests typically run in a FakeAsync zone; `WidgetTester.pump` with a `Duration` advances that fake time and triggers a frame. A logic test can inject a predict implementation that returns an unfinished `Completer` future, start the game loop, elapse a long duration (or `pump` many seconds), assert the snake cells are unchanged and optionally that `periodicTimerCount` is zero, then complete the completer with a fixed choice and flush microtasks / pump again to assert a single-cell advance. That matches SC-003's negative case and its "absence of a periodic ticker" check method.
- Evidence: FakeAsync class description and `elapse` / `periodicTimerCount`; WidgetTester overview (FakeAsync zone) and `pump([Duration?])`.
- Source: `https://pub.dev/documentation/fake_async/latest/fake_async/FakeAsync-class.html`, consulted 2026-09-27. `https://api.flutter.dev/flutter/package-fake_async_fake_async/fakeAsync.html`, consulted 2026-09-27. `https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html`, consulted 2026-09-27. `https://api.flutter.dev/flutter/flutter_test/WidgetTester/pump.html`, consulted 2026-09-27. `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` line 43.

### Example today has no Snake loop; prior solution does not answer this question

- Claim: The example app is still a skeleton home page with no Snake board, no predict call, and no timer. The only file under `wiki/solutions/` documents macOS ONNX session-load harness constraints and does not prescribe Snake step control.
- Evidence: `example/lib/main.dart` builds `SkeletonHomePage` only; solution summary is about `integration_test` and sandbox entitlements.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart` lines 10–50; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` lines 1–44.

### Closed Snake rules stay outside this stream

- Claim: Walls kill, self-collision kills, food spawns on a random empty cell, and the model chooses left, right, or straight relative to heading. Those rules are closed in the goal and are not reopened here. Predict's API shape is closed by work item 0002 and is not redesigned.
- Evidence: Closed assumptions; work item decision that the library predict API from 0002 is closed.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 32–32; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0003-classic-snake/STATE.yaml` lines 17–21.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Await-gated async step loop | While alive: encode board → `await runtime.predict(...)` → read choice → turn relative to heading → move one cell → resolve food/collision → `setState` / notify. Loop via recursive async call or `Future.doWhile`. No `Timer.periodic`, no step `Ticker`. | One injectable predict seam for tests; step rate equals model latency; UI must tolerate slow/variable steps | **Chosen.** Matches SC-003 and the closed "no step timer" rule: the snake cannot advance until predict returns, and there is no periodic ticker to assert away. |
| `Timer.periodic` (or delayed `Timer`) as the step clock | On each interval, either move immediately or start predict and move when it completes | Familiar arcade cadence; easy to tune interval | **Rejected.** Implements a step timer. If the callback moves without awaiting predict, it is exactly SC-003's negative case. If it only kicks predict, a periodic ticker still exists, conflicting with the check method that requires proving absence of a periodic ticker. |
| Frame `Ticker` / `AnimationController` step driver | Advance or sample steps on animation frames; optionally sample predict results when ready | Smooth UI clock; couples game logic to vsync | **Rejected.** A `Ticker` is a periodic per-frame callback while active (`Ticker` docs). That is time/frame-driven progress, not predict-gated progress, and SC-003's check method names absence of a periodic ticker. |

## Constraints discovered

- Each board advance of one cell must happen only after a completed `predict` for that step (`GOAL.md` SC-003; `loaded_runtime.dart` lines 56–63).
- No step timer and no periodic ticker for advancement (`GOAL.md` lines 32–32 and 43–43; `Timer.periodic` and `Ticker` docs).
- Relative turn choices (left / right / straight) and classic death/food rules are fixed; this research does not choose prompt wording or redesign predict (`GOAL.md` line 32; `STATE.yaml` lines 17–21).
- Tests for the timer negative case need a fake or injectable predict that can stay incomplete while fake time elapses (`FakeAsync` / `WidgetTester.pump` docs).
- Host ONNX session proofs remain an `integration_test` concern on macOS (`wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`); the step-loop absence-of-timer proof is logic-level and must not require a real session.
- The example currently has no Snake implementation to attach the loop to (`example/lib/main.dart` lines 10–50).

## Unresolved

- [UNRESOLVED: whether a decorative UI `Ticker` or `AnimationController` (for drawing only, never calling the step mutator) is allowed, or whether SC-003's "absence of a periodic ticker" requires zero tickers in the Snake screen.]
- [UNRESOLVED: whether an optional minimum visual delay after predict (a one-shot `Future.delayed` or non-periodic `Timer`) is compatible with "no step timer", or whether any timer-based pacing after predict fails SC-003.]
- [UNRESOLVED: exact package layout of the injectable predict seam (pure Dart controller under `example/lib` versus a thin wrapper) — both can await the same public `predict` Future.]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-27.
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/laya_flutter.dart`, `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`, `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/loaded_runtime.dart`, `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart`, consulted 2026-09-27.
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`, consulted 2026-09-27.
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0003-classic-snake/STATE.yaml`, consulted 2026-09-27.
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-27.
- `https://api.flutter.dev/flutter/dart-async/Timer/Timer.periodic.html`, consulted 2026-09-27.
- `https://api.flutter.dev/flutter/scheduler/Ticker-class.html`, consulted 2026-09-27.
- `https://api.flutter.dev/flutter/dart-async/Future-class.html`, consulted 2026-09-27.
- `https://api.flutter.dev/flutter/animation/AnimationController-class.html`, consulted 2026-09-27.
- `https://pub.dev/documentation/fake_async/latest/fake_async/FakeAsync-class.html`, consulted 2026-09-27.
- `https://api.flutter.dev/flutter/package-fake_async_fake_async/fakeAsync.html`, consulted 2026-09-27.
- `https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html`, consulted 2026-09-27.
- `https://api.flutter.dev/flutter/flutter_test/WidgetTester/pump.html`, consulted 2026-09-27.
