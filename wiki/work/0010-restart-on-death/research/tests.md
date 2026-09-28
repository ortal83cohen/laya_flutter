# Research: Death and restart observables in example tests

## Question

How do the existing example tests prove that a wall or body collision sets ended and stops further cell changes, and what observable restart behaviour can a new test assert without calling LayaFlutter.open or creating an ONNX session?

## Answer

Death is already proven only in controller logic tests under `example/test/snake_controller_test.dart`: after a predict-driven step into a wall or own body, `ended` is true, the head stays on the pre-collision cell (not on the wall cell or through the body), and a second `step` leaves `snakeCells` unchanged. No existing widget test asserts death or restart. A new classic-rules test can reuse that same controller surface — inject a predict double, never open a session — and fail both when restart never clears the dead state and when death still lets the live head occupy the wall or keep stepping through the body.

## Findings

### GOAL and prior solution do not define restart tests

- Claim: The product goal requires classic Snake that ends on a wall or own body (SC-003) and does not mention restart after death. The only file under `wiki/solutions/` documents that VM `flutter test` is not a session-load proof (`MissingPluginException`); it does not describe Snake death or restart assertions.
- Evidence: Closed Snake assumption and SC-003 at `wiki/product/GOAL.md:32` and `wiki/product/GOAL.md:43`; solution guidance at `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:23-30`.
- Source: `wiki/product/GOAL.md`; `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`

### Product constraints already fix the classic-rules test harness

- Claim: Classic-rules and await-gate logic tests must inject a predict double and must not call `LayaFlutter.open` or create an ONNX session. VM widget tests that pump the example tree must keep autostart off and must not open a session on mount or on a follow-up frame.
- Evidence: Test and open constraints at `wiki/product/classic-snake-example.md:27-31`.
- Source: `wiki/product/classic-snake-example.md`

### Wall collision test sets ended and freezes cells without entering the wall

- Claim: The wall test builds a `SnakeController` with an injected `_choicePredict('straight')` (no session). Head starts at `(4,1)` on width 5 heading east. After `step()`, `ended` is true, `head` remains `(4,1)` (still in-bounds: `head.col < width`), so the live head does not occupy the out-of-board wall cell. A snapshot of `snakeCells` is taken; a second `step()` must equal that snapshot.
- Evidence: Test body at `example/test/snake_controller_test.dart:150-177`; collision sets `ended` without moving onto the wall cell at `example/lib/snake_controller.dart:205-209`; further `step` returns early when already ended at `example/lib/snake_controller.dart:180-182`.
- Source: `example/test/snake_controller_test.dart`; `example/lib/snake_controller.dart`

### Body collision test sets ended and freezes cells without stepping through the body

- Claim: The body test places head at `(0,1)` heading east into body cell `(1,1)`, injects straight predict, asserts `ended` true and `head` still `(0,1)`, then asserts a further `step` leaves `snakeCells` equal to a frozen copy.
- Evidence: Test body at `example/test/snake_controller_test.dart:179-208`; body check in `_applyChoiceAndAdvance` at `example/lib/snake_controller.dart:207-209`.
- Source: `example/test/snake_controller_test.dart`; `example/lib/snake_controller.dart`

### Predict failure is explicitly not death in the same test file

- Claim: When injected predict throws, cells and heading stay unchanged and `ended` remains false. That separates predict failure from wall/body death for any later restart criterion that keys off `ended`.
- Evidence: Test at `example/test/snake_controller_test.dart:396-410`; controller catch-and-return at `example/lib/snake_controller.dart:189-193`.
- Source: `example/test/snake_controller_test.dart`; `example/lib/snake_controller.dart`

### Controller tests already forbid session-open strings in their own sources

- Claim: A dedicated test asserts that `test/snake_controller_test.dart` and `lib/snake_controller.dart` do not contain contiguous `LayaFlutter.open`, `createSession`, `OnnxRuntime`, or `OrtSession` substrings, and that `step` uses the injected predict double.
- Evidence: Test at `example/test/snake_controller_test.dart:412-471`.
- Source: `example/test/snake_controller_test.dart`

### Widget tests mention autostart and SnakeScreen but never ended or restart

- Claim: `widget_test.dart` pumps idle `ExampleApp` (autostart default off), asserts title `Laya` and absence of `Opening…` after a second `pump`, and uses source scans for production `autostart: true`, no Play Snake, and failure chrome that must not navigate to `SnakeScreen`. It never constructs `SnakeController`, never asserts `ended`, and never asserts restart. `snake_screen_test.dart` only source-scans `snake_screen.dart` for timer/ticker absence and `LoadedRuntime.predict` delegation; it does not pump the screen or mention `ended`.
- Evidence: Idle pump at `example/test/widget_test.dart:7-18`; autostart/source tests at `example/test/widget_test.dart:20-86`; screen source tests at `example/test/snake_screen_test.dart:13-42`.
- Source: `example/test/widget_test.dart`; `example/test/snake_screen_test.dart`

### SnakeScreen exposes ended chrome but requires a LoadedRuntime

- Claim: The screen AppBar title is `Snake — ended` when `_controller.ended` is true, otherwise `Snake`. The step loop stops while `ended` is true. The screen constructs `SnakeController` with `runtime.predict` only; there is no injected predict seam on `SnakeScreen` today, so a VM widget test that mounts the production screen would depend on a real `LoadedRuntime` (session), which product constraints forbid for classic-rules proofs.
- Evidence: Title and loop at `example/lib/snake_screen.dart:57-73` and `example/lib/snake_screen.dart:91-92`; controller wiring at `example/lib/snake_screen.dart:31-39`; classic-rules session ban at `wiki/product/classic-snake-example.md:29`.
- Source: `example/lib/snake_screen.dart`; `wiki/product/classic-snake-example.md`

### Observables a new no-session restart test can already name

- Claim: Without calling `LayaFlutter.open` or creating an ONNX session, a classic-rules test can observe at least: `ended`, `head`, `snakeCells`, `heading`, and whether a later `step` with an injected predict double changes cells again. Combined with the existing death pattern, that set can fail if (a) after a claimed restart the game stays ended forever (`ended` stays true and further steps never move cells), or (b) death still places a live head on the wall cell or advances through body cells before or instead of ending. Widget-only observables today add AppBar title text `Snake` / `Snake — ended`, but only if a test can mount a screen without a real session — which the production `SnakeScreen` constructor does not allow.
- Evidence: Public ended/cells/head surface at `example/lib/snake_controller.dart:104-114`; death-and-freeze asserts at `example/test/snake_controller_test.dart:168-176` and `example/test/snake_controller_test.dart:202-207`; screen title at `example/lib/snake_screen.dart:92`; `SnakeScreen` requires `LoadedRuntime` at `example/lib/snake_screen.dart:15`.
- Source: `example/lib/snake_controller.dart`; `example/test/snake_controller_test.dart`; `example/lib/snake_screen.dart`

### No restart control or post-death recovery exists in the example yet

- Claim: Grep of example Dart sources shows no `restart` or `reset` API and no user control that clears `ended`. After death the screen loop exits; the title can show ended, but nothing in the current tree resumes play.
- Evidence: `ended` field and early return at `example/lib/snake_controller.dart:104-105` and `example/lib/snake_controller.dart:180-182`; loop condition `while (mounted && !_controller.ended)` at `example/lib/snake_screen.dart:58`; no restart matches under `example/` in the search performed for this research (controller, screen, tests, main).
- Source: `example/lib/snake_controller.dart`; `example/lib/snake_screen.dart`

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Controller-only classic-rules test (extend U1 collisions) | Construct `SnakeController` with `_choicePredict` / scripted random; drive wall or body death; assert existing `ended` + frozen cells + head not on wall/body cell; then exercise whatever restart path the product adds and assert `ended` is cleared and a later injected `step` changes cells again | Low: same harness as `snake_controller_test.dart`; no session; matches product classic-rules rule | Chosen for logic proof: already the only place death is proven; can fail “ended forever” and “live head on wall / through body” with existing fields |
| Widget test of production `SnakeScreen` | Pump `SnakeScreen(runtime: …)`, wait for death, assert AppBar `Snake — ended`, then assert restart chrome | High: constructor requires `LoadedRuntime`; VM open is forbidden and fails per sandbox solution; not a classic-rules proof | Rejected for death/restart logic: couples proof to session; conflicts with `classic-snake-example.md` and shared “no open on mount” decision |
| Idle `ExampleApp` widget / source scan (current `widget_test` shape) | Pump home or scan `main.dart` / `snake_screen.dart` strings for restart labels | Low harness cost, zero behavioural proof of cells or `ended` | Rejected as sole proof: existing widget tests already use this shape for autostart and never observe collision or cell freeze |

## Constraints discovered

- Classic-rules proofs inject a predict double and must not call `LayaFlutter.open` or create an ONNX session (`wiki/product/classic-snake-example.md:29`).
- VM widget pumps of the example must keep autostart off and must not schedule open on mount or a follow-up frame (`wiki/product/classic-snake-example.md:31`; idle pump at `example/test/widget_test.dart:7-17`).
- Death means wall or own body; predict failure must leave `ended` false (`example/test/snake_controller_test.dart:396-410`; GOAL closed assumption at `wiki/product/GOAL.md:32`).
- Wall death must not leave a live head on the out-of-board cell; existing wall test asserts head stays at `(4,1)` with `col < width` (`example/test/snake_controller_test.dart:168-170`).
- Body death must not advance the head into the body cell; existing body test asserts head stays at `(0,1)` (`example/test/snake_controller_test.dart:202-203`).
- After `ended`, further `step` is a no-op on cells (`example/lib/snake_controller.dart:180-182`; freeze asserts at `example/test/snake_controller_test.dart:172-176` and `example/test/snake_controller_test.dart:205-207`).
- Production `SnakeScreen` has no predict-injection constructor parameter (`example/lib/snake_screen.dart:15-38`).
- No restart/reset surface exists in the example today; only death chrome and loop stop (`example/lib/snake_screen.dart:58`, `example/lib/snake_screen.dart:92`).

## Unresolved

- [UNRESOLVED: What user-visible or test-callable restart action will clear death, given none exists in the example today?]
- [UNRESOLVED: After restart, which exact initial snake, heading, and food placement must a test require, beyond “not ended forever” and “not live on wall / through body”?]
- [UNRESOLVED: Will any widget-level restart chrome be required in this slice, or is controller-only classic-rules proof sufficient for the product contract?]

## Sources

- `wiki/product/GOAL.md` — consulted 2026-09-28
- `wiki/product/classic-snake-example.md` — consulted 2026-09-28
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` — consulted 2026-09-28
- `example/test/snake_controller_test.dart` — consulted 2026-09-28
- `example/test/widget_test.dart` — consulted 2026-09-28
- `example/test/snake_screen_test.dart` — consulted 2026-09-28
- `example/lib/snake_controller.dart` — consulted 2026-09-28
- `example/lib/snake_screen.dart` — consulted 2026-09-28
- `wiki/templates/00-research.md` — consulted 2026-09-28
- `wiki/work/0005-autostart-snake/research/start-gate.md` — consulted 2026-09-28 (format reference only)
