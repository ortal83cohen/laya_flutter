# Research: Autostart options for Classic Snake without a play button

## Question

Which approaches let the running example begin Snake with no play button, and which of them keep a widget test from calling LayaFlutter.open when it only pumps the tree?

## Answer

The running example can drop the Play Snake button and still open Snake if session open is started from production entry (`main`) or from an explicit autostart path that the widget test does not enable. Any approach that calls `LayaFlutter.open` merely because the test-pumped widget mounted (including first-frame and unguarded post-frame scheduling) fails the VM idle-pump constraint. Keeping the button would preserve the test but is out of scope for this work item.

## Findings

### Current start path is button-gated; open is not in build

- Claim: `main` runs `ExampleApp` with idle `ExampleHomePage`. `LayaFlutter.open(resolveHostCache())` and navigation to `SnakeScreen` run only inside `_openSnake`, wired to the Play Snake `FilledButton`. Comments state the idle home does not open an ONNX session so VM widget tests can pump the tree safely.
- Evidence: Entry and idle home at `example/lib/main.dart:15-47`; `_openSnake` and button at `example/lib/main.dart:65-117`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`

### Widget test pumps ExampleApp and forbids Opening…

- Claim: `example/test/widget_test.dart` pumps `const ExampleApp()`, expects the Laya title and Play Snake label, and asserts `Opening…` is absent, with a comment that the idle pump must not require or trigger ONNX session open.
- Evidence: Full test at `example/test/widget_test.dart:5-14`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/widget_test.dart`

### Product and prior research forbid open on the pumped idle tree’s first frame

- Claim: `wiki/product/classic-snake-example.md` requires that the idle example home must not open a session until the user starts Snake, and states that opening on first frame breaks VM widget tests that only pump the idle tree. `research/start-gate.md` records that gate catalog (button, idle pump, first-frame forbid) and leaves design alternatives for replacing the button out of its scope.
- Evidence: Test and open constraints at `wiki/product/classic-snake-example.md:27-31`; start-gate answer and forbidden first-frame option at `wiki/work/0005-autostart-snake/research/start-gate.md:7-9` and `wiki/work/0005-autostart-snake/research/start-gate.md:61-68`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md`; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0005-autostart-snake/research/start-gate.md`

### GOAL does not require a play button; work item requires no button

- Claim: `GOAL.md` requires a classic Snake example (SC-003) and that the Snake screen appears on Android and iOS (SC-005). It does not mention an idle home or play button. Work item `0005-autostart-snake` is titled to start Snake without a play button; its decisions keep library APIs and Snake rules closed and require VM widget tests to pump without opening an ONNX session.
- Evidence: Outcome and SC-003/SC-005 at `wiki/product/GOAL.md:15` and `wiki/product/GOAL.md:43-45`; work item title and decisions at `wiki/work/0005-autostart-snake/STATE.yaml:3-4` and `wiki/work/0005-autostart-snake/STATE.yaml:17-21`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0005-autostart-snake/STATE.yaml`

### VM flutter test cannot prove a real ONNX session

- Claim: Host session-open proof belongs on macOS `integration_test`. VM `flutter test` does not register the ONNX plugin and surfaces `MissingPluginException`. That fact motivates keeping pumps free of session open; it does not prescribe a play button.
- Evidence: Guidance at `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-30`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`

### Public open signature (library stays closed)

- Claim: The public open entry is `static Future<LoadedRuntime> open(Directory cache, {CheckpointDownloader? download, Future<OrtSession> Function(String path)? createSession})` on `LayaFlutter`, with the optional parameters marked `@visibleForTesting`. This research does not redesign that API.
- Evidence: Signature at `lib/src/library.dart:25-29`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`

### SnakeScreen needs a LoadedRuntime and starts stepping after mount

- Claim: Reaching `SnakeScreen` implies a session was already opened by the caller. The await-gated step loop starts from `didChangeDependencies`, not from the idle home. Autostart therefore still needs a successful open (or equivalent injected runtime) before this route.
- Evidence: Constructor at `example/lib/snake_screen.dart:13-18`; loop start at `example/lib/snake_screen.dart:43-48`. Catalogued in `wiki/work/0005-autostart-snake/research/start-gate.md:19-23`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart`; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0005-autostart-snake/research/start-gate.md`

### Unguarded mount-time open of the pumped widget breaks the VM test

- Claim: If the widget the test pumps schedules `LayaFlutter.open` from mount lifecycle (`initState`, `didChangeDependencies`, or an unguarded post-frame callback on that same widget) with no test-only skip, the idle pump constraint is violated. The product document names first-frame open as the known break; any automatic open tied to mounting that tree has the same risk class for a test that only pumps it.
- Evidence: First-frame forbid at `wiki/product/classic-snake-example.md:31`; idle-safe comment at `example/lib/main.dart:36-37`; test pump at `example/test/widget_test.dart:8-13`. Exact ordering of `tester.pumpWidget` versus every possible scheduling API beyond first frame is not re-proven here [UNVERIFIED for edge scheduling that never runs during a single pump].
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md`; `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`; `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/widget_test.dart`

### Open-failure UI may remain; no new predict-failure UI; no pacing timers

- Claim: Existing home open-failure text is allowed to stay. Predict-failure UI must not be added. Step pacing must not use a step timer, `Ticker`, or `Future.delayed`.
- Evidence: Open-error display at `example/lib/main.dart:118-125`; predict-failure and no-timer rules at `wiki/product/classic-snake-example.md:21-25`; work-item decisions at `wiki/work/0005-autostart-snake/STATE.yaml:17-21`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md`; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0005-autostart-snake/STATE.yaml`

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Explicit autostart flag on the example root or home (default off; `main` turns it on) | Production constructs the app with autostart enabled so open runs without a button; the widget test keeps pumping the default (no autostart) tree and never calls `LayaFlutter.open` | Small API surface on example widgets; test expectations for Play Snake must change | **Chosen** — meets no-button launch, keeps open-failure UI on the same page, and makes the VM no-open pump an explicit constructor contract rather than environment inference |
| Open in `main` before `runApp`, then show Snake (or a home that only receives an already-loaded runtime) | Session open happens outside the widget tree the test pumps; `widget_test` continues to pump a tree that never calls open | Failure handling moves or splits from today’s home; production entry becomes async; test may cover a thinner tree than production | Viable alternative — strongest separation of open from pump; heavier reshape of entry and error UI |
| Same tree always autostarts; skip open when a test environment signal is set (for example `FLUTTER_TEST`) | Running example opens with no button; under `flutter test` the skip prevents `LayaFlutter.open` | Implicit coupling to harness env; easy to misread later; [UNVERIFIED] whether every future test host sets the same signal | Viable but weaker — works only if the skip is reliable; less explicit than a constructor flag |
| Split roots: production `main` runs an autostart app; tests pump a separate idle shell | Same safety as a flag or open-in-main, via two roots | Two trees to maintain; idle shell can drift from production | Viable — clearer than env detection, costlier than one root with a flag |
| Unguarded open on mount of the pumped widget (initState / first frame / unguarded post-frame) | No button; open starts as soon as `ExampleApp` (or home) mounts | Breaks VM widget tests that only pump that tree | **Rejected** — forbidden by `wiki/product/classic-snake-example.md:31` and work-item decisions |
| Keep Play Snake button as the only start gate | First frame stays idle; open on press | Retains manual start | **Rejected** — work item and shared decision require starting without a play button (`wiki/work/0005-autostart-snake/STATE.yaml:3-4`) |
| Rely on `LayaFlutter.open` test doubles (`download` / `createSession`) while still calling open from the pumped tree | Avoids a real ONNX session but still enters open and can show Opening… | Library test hooks stay for library tests; example widget test currently asserts no Opening…; does not remove the call | **Rejected** for this question — the requirement is that the pump does not open a session (and today’s test forbids Opening…), not that open is stubbed |

## Constraints discovered

- Visible example must start Snake with no play button (`wiki/work/0005-autostart-snake/STATE.yaml:3-4`).
- VM widget tests that pump the example tree must not open a real ONNX session; opening on first frame of the pumped widget is the known break (`wiki/product/classic-snake-example.md:31`; `wiki/work/0005-autostart-snake/STATE.yaml:17-21`).
- VM `flutter test` is unsuitable for native session-load proof (`wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-30`).
- Library `LayaFlutter.open` / predict APIs stay closed; only the example launch UX changes (`wiki/work/0005-autostart-snake/STATE.yaml:17-21`; signature at `lib/src/library.dart:25-29`).
- Snake mechanics, relative turn keys, and the no-timer / no-Ticker / no-`Future.delayed`-for-pacing rule stay closed (`wiki/product/GOAL.md:32`; `wiki/product/classic-snake-example.md:15-25`).
- Existing open-failure text may stay; do not add a new predict-failure UI (`example/lib/main.dart:118-125`; `wiki/product/classic-snake-example.md:21-25`).
- `classic-snake-example.md` still says the idle home must not open until the user starts Snake (`wiki/product/classic-snake-example.md:31`); autostart without a button requires that product wording to be updated in a later document phase, not silently ignored.
- Today’s widget test asserts the Play Snake label (`example/test/widget_test.dart:11`); removing the button requires updating that assertion (already noted as unresolved in `research/start-gate.md`).

## Unresolved

- [UNRESOLVED: Should production autostart reuse the current home Opening… / open-failure chrome, or should `main` open then land directly on SnakeScreen?]
- [UNRESOLVED: Exact wording update for classic-snake-example.md once “user starts Snake” is no longer a button press — deferred open via test-only flag vs production-only main?]
- [UNRESOLVED: If open-in-main is chosen, what minimal tree should widget_test pump so it still guards against accidental session open without asserting a removed Play Snake label?]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/widget_test.dart`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0005-autostart-snake/research/start-gate.md`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0005-autostart-snake/STATE.yaml`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`, consulted 2026-09-27
