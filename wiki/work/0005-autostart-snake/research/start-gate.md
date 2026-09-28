# Research: Start gate for Classic Snake in the example

## Question

What code, widgets, and tests gate the start of the example Snake game, and which documents forbid
opening a session on the first frame?

## Answer

The example starts on an idle `ExampleHomePage`; `LayaFlutter.open` and navigation to `SnakeScreen`
run only after the user presses Play Snake. VM widget tests pump that idle tree and expect the
button label without an Opening state. The product document that forbids opening a session until the
user starts Snake, and that names first-frame open as breaking idle VM pumps, is
`wiki/product/classic-snake-example.md`; `GOAL.md` and the frozen 0003 home-or-button criteria do
not restate that first-frame rule.

## Findings

### Idle home is the app entry; open is button-gated

- Claim: `main` runs `ExampleApp`, whose `MaterialApp.home` is `ExampleHomePage`. That page is
  documented and implemented as idle: it does not open an ONNX session in `build`. Session open
  happens in `_openSnake`, which the Play Snake `FilledButton` invokes when `_opening` is false.
  `_openSnake` awaits `LayaFlutter.open(resolveHostCache())`, then pushes
  `SnakeScreen(runtime: runtime)`, and closes the runtime after the route pops.
- Evidence: Entry at `example/lib/main.dart:15-16`; idle-home comment and
  `home: const ExampleHomePage()` at `example/lib/main.dart:36-47`; `_openSnake` and button at
  `example/lib/main.dart:65-117`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`

### SnakeScreen assumes a loaded runtime and starts stepping after mount

- Claim: `SnakeScreen` requires a `LoadedRuntime` constructor argument. It builds `SnakeController`
  with a predict closure that calls `runtime.predict`. The await-gated step loop starts once from
  `didChangeDependencies`, not from the idle home. Reaching this widget therefore implies a session
  was already opened by the caller (today, `_openSnake`).
- Evidence: Constructor and field at `example/lib/snake_screen.dart:13-18`; controller and predict
  closure at `example/lib/snake_screen.dart:29-39`; loop start at
  `example/lib/snake_screen.dart:43-48`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart`

### Widget test encodes idle pump without session open

- Claim: `example/test/widget_test.dart` pumps `ExampleApp`, expects the title Laya and the Play
  Snake control, and asserts Opening… is absent, with a comment that the idle pump must not require
  or trigger ONNX session open. That test therefore gates (and documents) the current start UX: idle
  home plus button label, no open on first pump.
- Evidence: Full test at `example/test/widget_test.dart:5-14`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/widget_test.dart`

### Snake screen source tests do not gate launch UX

- Claim: `snake_screen_test.dart` only inspects `lib/snake_screen.dart` source for timer/ticker
  absence (AC-005) and for `LoadedRuntime` / `runtime.predict` delegation (AC-009). It does not pump
  the home, press Play Snake, or assert session-open timing.
- Evidence: Source reader and AC-005/AC-009 tests at `example/test/snake_screen_test.dart:5-42`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/snake_screen_test.dart`

### Product document forbids session open until the user starts Snake

- Claim: `wiki/product/classic-snake-example.md` states that the idle example home must not open a
  session until the user starts Snake, and that opening on the first frame breaks VM widget tests
  that only pump the idle tree. The same section also forbids classic-rules and await-gate logic
  tests from calling `LayaFlutter.open` or creating an ONNX session.
- Evidence: Test and open constraints at `wiki/product/classic-snake-example.md:27-31`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md`

### GOAL does not forbid first-frame session open

- Claim: `wiki/product/GOAL.md` requires a classic Snake example whose next step waits for the
  model (SC-003) and that the Snake example runs on Android and iOS with the Snake screen
  appearing (SC-005). It does not mention an idle home, a play button, or deferring session open
  past the first frame.
- Evidence: Outcome at `wiki/product/GOAL.md:15`; closed Snake assumptions at
  `wiki/product/GOAL.md:32`; SC-003 and SC-005 at `wiki/product/GOAL.md:43-45`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`

### 0003 contract and criteria forbid session open in logic tests, not a home button

- Claim: For requirements that mention home, button, or session open: `04-product-contract.md` actor
  A-002 and the Assumptions paragraph require that logic tests prove Snake mechanics without opening
  an ONNX session. `02-criteria.md` AC-008 freezes that for classic-rules and await-gate logic
  tests (inject predict; no `LayaFlutter.open`). Neither file requires an idle home, a Play Snake
  button, or forbids opening a session on the example app’s first frame.
- Evidence: A-002 at `wiki/work/0003-classic-snake/04-product-contract.md:12`; Assumptions at
  `wiki/work/0003-classic-snake/04-product-contract.md:69`; AC-008 at
  `wiki/work/0003-classic-snake/02-criteria.md:24`.
- Source:
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0003-classic-snake/04-product-contract.md`,
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0003-classic-snake/02-criteria.md`

### Solutions constrain VM session proofs, not example launch UX

- Claim: The only file under `wiki/solutions/` documents that VM `flutter test` cannot register the
  ONNX plugin (`MissingPluginException`) and that host session-load proof belongs on macOS
  `integration_test`. That supports keeping idle widget pumps free of session open; it does not
  prescribe a play button.
- Evidence: Summary and guidance at `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-30`.
- Source:
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`

## Options considered

| Option                                                                                          | How it works                                                                | Cost                                               | Why rejected / chosen                                                                          |
|-------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|----------------------------------------------------|------------------------------------------------------------------------------------------------|
| Current gate: idle `ExampleHomePage` + Play Snake calling `LayaFlutter.open` then `SnakeScreen` | First frame builds home only; open and navigate on button press             | Manual start; widget test asserts button label     | **Observed status quo** in `example/lib/main.dart` and `example/test/widget_test.dart`         |
| Open session on the example’s first frame                                                       | `ExampleApp` or home `initState`/`build` would call open before user action | Breaks idle VM widget pumps per product constraint | **Forbidden today** by `wiki/product/classic-snake-example.md:31`; not a viable current option |

Design alternatives for replacing the button were out of scope for this research stream (shared
decision: record the VM no-session pump constraint; do not treat it as a reason to keep a button).

## Constraints discovered

- VM widget tests must still be able to pump an example tree without opening an ONNX session (
  `wiki/product/classic-snake-example.md:31`; `example/lib/main.dart:36-37`;
  `example/test/widget_test.dart:5-13`).
- VM `flutter test` is unsuitable for native session-load proof; plugin registration fails there (
  `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-30`).
- Classic-rules and await-gate logic tests must inject predict and must not call
  `LayaFlutter.open` (`wiki/work/0003-classic-snake/02-criteria.md:24`;
  `wiki/product/classic-snake-example.md:29`).
- This slice is example launch UX only; `LayaFlutter.open` and `predict` stay closed (work item
  `wiki/work/0005-autostart-snake/STATE.yaml` decisions).
- Snake rules, relative turn keys, and the no-timer rule stay closed (`wiki/product/GOAL.md:32`;
  `wiki/product/classic-snake-example.md:15-25`).

## Unresolved

- [UNRESOLVED: Is the widget test’s assertion that the Play Snake label exists a lasting product requirement, or only a check of the current button-gated home?]
- [UNRESOLVED: Should a future launch UX that omits the button still satisfy classic-snake-example.md by some other deferred-open signal, as long as the first pumped frame opens no session?]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`,
consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart`, consulted
  2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/widget_test.dart`, consulted
  2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/snake_screen_test.dart`, consulted
  2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md`, consulted
  2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0003-classic-snake/04-product-contract.md`,
consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0003-classic-snake/02-criteria.md`,
  consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0005-autostart-snake/STATE.yaml`,
  consulted 2026-09-27
