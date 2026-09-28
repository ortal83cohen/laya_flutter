# Research: Start the example Snake game without a play button

## Question

How does the example start Classic Snake today, and which approach starts it with no play button while a VM widget test that only pumps the example tree still does not open an ONNX session?

## Answer

The example opens on an idle home. Session open and navigation to Snake run only after Play Snake is pressed. The running example can drop that button if production turns on an explicit autostart path and the widget test keeps pumping the default tree that does not autostart. Opening a session because the pumped widget mounted is rejected. The Play Snake label is a check of the current button, not a goal requirement, so the widget test must change with the button. Production reuses the existing opening and open-failure text, then shows Snake. The product note that the idle home waits for the user to start Snake is updated so the lasting rule is: the tree a VM widget test pumps does not open a session.

## Findings

### Idle home is the app entry; open is button-gated

- Claim: `main` runs `ExampleApp`, whose home is `ExampleHomePage`. That page does not open a session in `build`. `LayaFlutter.open` and navigation to `SnakeScreen` run inside the handler the Play Snake button invokes.
- Evidence: Entry at `example/lib/main.dart:15-16`; idle-home comment and home at `example/lib/main.dart:36-47`; open handler and button at `example/lib/main.dart:65-117`.
- Source: `example/lib/main.dart`. Stream: `wiki/work/0005-autostart-snake/research/start-gate.md`.

### Snake starts stepping only after a runtime exists

- Claim: `SnakeScreen` requires an already loaded runtime and starts its await-gated step loop from `didChangeDependencies`. Reaching that screen means the caller already opened a session.
- Evidence: Constructor at `example/lib/snake_screen.dart:13-18`; loop start at `example/lib/snake_screen.dart:43-48`.
- Source: `example/lib/snake_screen.dart`. Stream: `wiki/work/0005-autostart-snake/research/start-gate.md`.

### The widget test pumps the idle tree and expects the button

- Claim: The example widget test pumps `ExampleApp`, expects the Laya title and the Play Snake label, and asserts the opening label is absent so the idle pump does not open a session.
- Evidence: Full test at `example/test/widget_test.dart:5-14`.
- Source: `example/test/widget_test.dart`. Stream: `wiki/work/0005-autostart-snake/research/start-gate.md`.

### Screen source tests do not gate launch

- Claim: The Snake screen source tests check for timer and ticker absence and for predict delegation. They do not pump the home or press Play Snake.
- Evidence: Tests at `example/test/snake_screen_test.dart:5-42`.
- Source: `example/test/snake_screen_test.dart`. Stream: `wiki/work/0005-autostart-snake/research/start-gate.md`.

### The first-frame forbid is a product note, not a goal check

- Claim: `wiki/product/classic-snake-example.md` says the idle example home must not open a session until the user starts Snake, and that opening on the first frame breaks VM widget tests that only pump the idle tree. `GOAL.md` requires classic Snake (SC-003) and that the Snake screen appears on Android and iOS (SC-005). It does not mention an idle home, a play button, or deferring session open. The frozen 0003 criteria forbid logic tests from calling open. They do not require a play button.
- Evidence: Constraints at `wiki/product/classic-snake-example.md:27-31`; outcome and checks at `wiki/product/GOAL.md:15` and `wiki/product/GOAL.md:43-45`; AC-008 at `wiki/work/0003-classic-snake/02-criteria.md:24`.
- Source: `wiki/product/classic-snake-example.md`, `wiki/product/GOAL.md`, `wiki/work/0003-classic-snake/02-criteria.md`. Stream: `wiki/work/0005-autostart-snake/research/start-gate.md`.

### VM tests cannot prove a real session

- Claim: Host session-open proof belongs on macOS integration tests. VM `flutter test` does not register the ONNX plugin and surfaces `MissingPluginException`. That is why the pumped tree must not open a session. It does not require a play button.
- Evidence: Guidance at `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-30`.
- Source: `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`.

### Public open stays closed

- Claim: The public open entry is a static future on `LayaFlutter` that takes a cache directory and optional test-only download and session-factory parameters. This slice does not change that signature.
- Evidence: Signature at `lib/src/library.dart:25-29`.
- Source: `lib/src/library.dart`. Stream: `wiki/work/0005-autostart-snake/research/autostart-options.md`.

### Mount-time open of the pumped widget fails the VM constraint

- Claim: If the widget the test pumps schedules session open from mount with no skip, the idle-pump constraint is violated. Exact ordering of a single pump versus every scheduling API beyond the first frame was not re-proven.
- Evidence: First-frame forbid at `wiki/product/classic-snake-example.md:31`; idle comment at `example/lib/main.dart:36-37`; test pump at `example/test/widget_test.dart:8-13`. Edge scheduling that never runs during a single pump is [UNVERIFIED].
- Source: `wiki/product/classic-snake-example.md`, `example/lib/main.dart`, `example/test/widget_test.dart`. Stream: `wiki/work/0005-autostart-snake/research/autostart-options.md`.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Explicit autostart flag, default off; production entry turns it on | The running app opens and then shows Snake with no button. The widget test pumps the default tree and never opens a session. Opening and open-failure text stay on that page. | Small surface on the example root. The Play Snake assertion must change. | **Chosen.** No button in the running app. The VM no-open pump is an explicit constructor contract. |
| Open in the process entry before the widget tree, then show Snake | Session open sits outside the tree the test pumps. | Failure handling splits from the home. The entry becomes asynchronous. | Rejected for this slice. Heavier than a flag, and the existing opening and error text already live on the home. |
| Always autostart, and skip open when a test harness signal is set | The running app opens with no button. Tests rely on an environment signal. | Implicit coupling to the harness. Whether every future host sets the same signal is [UNVERIFIED]. | Rejected. Less explicit than a constructor flag. |
| Two roots: production autostarts, tests pump a separate idle shell | Same safety as a flag, via two trees. | Two trees can drift. | Rejected. Costlier than one root with a flag. |
| Unguarded open when the pumped widget mounts | No button. Open starts as soon as the tested tree mounts. | Breaks VM widget tests that only pump that tree. | Rejected. Forbidden by `wiki/product/classic-snake-example.md:31`. |
| Keep the Play Snake button | First frame stays idle. Open happens on press. | The user must press a button. | Rejected. The request is to start with no button. |
| Call open from the pumped tree but stub the session | Avoids a real session while still entering open. | The current test forbids the opening label, and the requirement is that the pump does not open a session. | Rejected. |

## Constraints discovered

- The running example starts Snake with no play button.
- The tree a VM widget test pumps does not open an ONNX session. Opening because that tree mounted is the known break (`wiki/product/classic-snake-example.md:31`).
- VM `flutter test` is not the proof of a native session (`wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`).
- Library open and predict stay closed (`lib/src/library.dart:25-29`).
- Snake rules, relative turns, and the ban on a step timer, ticker, or delayed future for pacing stay closed (`wiki/product/GOAL.md:32`, `wiki/product/classic-snake-example.md:15-25`).
- Existing open-failure text may stay. This slice adds no predict-failure UI (`example/lib/main.dart:118-125`).
- The Play Snake label assertion checks today's button. It is not a goal requirement (`wiki/product/GOAL.md:43-45`). It changes with the button.
- Production reuses the existing opening and open-failure text, then shows Snake. That closes the chrome question left open by `research/autostart-options.md`.
- The product note is updated so the lasting rule is the VM pump, not a user button. That closes the wording question left open by both streams.

## Unresolved

- None. The three questions left open by the streams are decided in Constraints discovered, from the cited goal text, the product note, and the chosen option.

## Sources

- `wiki/work/0005-autostart-snake/research/start-gate.md`, consulted 2026-09-27
- `wiki/work/0005-autostart-snake/research/autostart-options.md`, consulted 2026-09-27
- `example/lib/main.dart`, consulted 2026-09-27
- `example/lib/snake_screen.dart`, consulted 2026-09-27
- `example/test/widget_test.dart`, consulted 2026-09-27
- `example/test/snake_screen_test.dart`, consulted 2026-09-27
- `wiki/product/classic-snake-example.md`, consulted 2026-09-27
- `wiki/product/GOAL.md`, consulted 2026-09-27
- `wiki/work/0003-classic-snake/02-criteria.md`, consulted 2026-09-27
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-27
- `lib/src/library.dart`, consulted 2026-09-27
