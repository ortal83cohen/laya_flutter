# Research: Observing a Snake choice record in example logic tests

## Question

How can an example logic test prove that a Snake step recorded its model choice, without calling LayaFlutter.open or creating an ONNX session, and which logging or capture seam already exists in this repository versus a Dart or Flutter developer log?

## Answer

No Dart source in this repository calls `debugPrint`, `dart:developer` `log`, `print`, or a `Logger`. The only test capture seam already used for Snake is constructor injection of `predict` (and `random`), with locals that record what the double received. That pattern proves request shape, not that the controller emitted a choice record after a relative key returned. A logic test in `snake_controller_test.dart` can prove recording only by observing a new in-memory append or callback that `step` performs when it accepts a relative choice, still using an injected predict double and never opening a session. Relying on heading or cell movement alone, or on the predict double’s own return value, does not fail when a step applies a choice but emits no record.

## Findings

### GOAL and prior solution do not define choice-log tests

- Claim: The product goal requires that Snake send the situation to the model each step and turn from the model’s choice (SC-003). It does not require a choice log or a developer-log proof. The only file under `wiki/solutions/` documents that VM `flutter test` is not an ONNX session-load proof; it does not describe capturing Snake choice logs.
- Evidence: SC-003 at `wiki/product/GOAL.md:43`; closed relative-turn assumption at `wiki/product/GOAL.md:32`; sandbox solution guidance at `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:23-30`.
- Source: `wiki/product/GOAL.md`; `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`

### Product constraints already fix the classic-rules harness

- Claim: Classic-rules and await-gate logic tests must inject a predict double and must not call `LayaFlutter.open` or create an ONNX session. Host session proof stays on the macOS integration path.
- Evidence: Test and open constraints at `wiki/product/classic-snake-example.md:27-29`.
- Source: `wiki/product/classic-snake-example.md`

### Repository Dart sources use no developer-log or print APIs

- Claim: A search over all `*.dart` files under the repository root finds no `debugPrint`, no `print(`, no `Logger`, no `import 'dart:developer'`, and no `package:logging` / `package:logger` dependency. Example `pubspec.yaml` has no logging package. Therefore there is no existing log API in production or example code for a test to intercept.
- Evidence: Grep over `**/*.dart` and dependency manifests performed for this research (2026-09-28); example dependencies at `example/pubspec.yaml:9-19`.
- Source: repository Dart tree; `example/pubspec.yaml`

### Existing capture seam is injected predict with local variables

- Claim: `SnakeController` takes a required `SnakePredict predict` and a `random` source. Logic tests pass `_choicePredict`, `_unusedPredict`, or an inline closure. One test already captures what `step` sends into predict by assigning `capturedState` and `capturedQuestions` inside the double, then asserts after `await controller.step()`. Another counts `predictCalls` and source-scans for session-open substrings. That is in-process observation of the inject seam, not interception of stdout or `dart:developer` logs.
- Evidence: Typedef and constructor at `example/lib/snake_controller.dart:42-60` and `example/lib/snake_controller.dart:89-93`; capture-into-locals test at `example/test/snake_controller_test.dart:302-366`; inject-and-no-session test at `example/test/snake_controller_test.dart:412-471`.
- Source: `example/lib/snake_controller.dart`; `example/test/snake_controller_test.dart`

### Predict-double capture alone cannot prove a post-choice record

- Claim: After predict returns, `step` reads `answers['turn']?.choice`, returns early if the key is missing or not relative, otherwise calls `_applyChoiceAndAdvance`. The test double already knows the map it returned. Asserting only that return, or only heading and head cell after a successful step, can pass even if the controller never appends or emits a choice record. The shared proof requirement for this slice is that the check must fail when a step that receives a relative choice emits no record of that choice.
- Evidence: Choice extraction and apply at `example/lib/snake_controller.dart:194-198`; relative-key gate at `example/lib/snake_controller.dart:221-222`; turn-application tests assert heading and head only at `example/test/snake_controller_test.dart:85-120`.
- Source: `example/lib/snake_controller.dart`; `example/test/snake_controller_test.dart`

### Controller has no choice-history field or log callback today

- Claim: Public controller surface today is board size, `predict`, `random`, `heading`, `food`, `ended`, `foodPlacementFailed`, `snakeCells`, and `head`. There is no `lastChoice`, choice list, sink, or logging callback. Grep under `example/` for choice-log / record / callback / sink seams used for model choices finds none beyond predict injection.
- Evidence: Fields and getters at `example/lib/snake_controller.dart:83-114`; `step` body at `example/lib/snake_controller.dart:179-198`.
- Source: `example/lib/snake_controller.dart`

### Screen tests do not observe runtime choice records

- Claim: `snake_screen_test.dart` only reads `lib/snake_screen.dart` source text for timer/ticker absence and `LoadedRuntime.predict` delegation. It never constructs a controller, never injects predict, and never asserts a logged choice. Production `SnakeScreen` wires `runtime.predict` and requires `LoadedRuntime`, so a VM test that mounts that screen is not the classic-rules no-session path.
- Evidence: Source-scan tests at `example/test/snake_screen_test.dart:13-42`; screen predict wiring at `example/lib/snake_screen.dart:31-38`; classic-rules session ban at `wiki/product/classic-snake-example.md:29`.
- Source: `example/test/snake_screen_test.dart`; `example/lib/snake_screen.dart`; `wiki/product/classic-snake-example.md`

### Flutter can capture print or debugPrint, but that is not a repository seam

- Claim: Outside this repository, Flutter’s own test helpers can capture `print` via a `ZoneSpecification` print override, and tests can reassign the `debugPrint` callback or use `TestWidgetsFlutterBinding.debugPrintOverride`. Those are viable observation mechanisms if production code starts calling `print` or `debugPrint`. They are not used anywhere in this repository’s example or package tests today.
- Evidence: Flutter foundation capture helper at `https://github.com/flutter/flutter/blob/master/packages/flutter/test/foundation/capture_output.dart` (consulted 2026-09-28); `debugPrintOverride` API at `https://api.flutter.dev/flutter/flutter_test/TestWidgetsFlutterBinding/debugPrintOverride.html` (consulted 2026-09-28); absence of those APIs in this repo’s Dart sources as claimed above.
- Source: Flutter SDK documentation and source; repository Dart tree

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Injectable in-memory record sink or callback on `SnakeController`, asserted in `snake_controller_test.dart` | Constructor (or similar) injects a list/callback the way `predict` and `random` are injected; after a relative choice is accepted, `step` appends one record; the test injects predict, runs `step`, and `expect`s the list grew with that choice (and fails if empty) | Low: same VM logic-test harness; no session; structured asserts; matches existing inject pattern | Chosen: only observation style already used in this repo; can fail when a relative choice is applied but no record is appended; does not require Zone or Flutter binding |
| Emit via `debugPrint` / `print` and capture with Zone or `debugPrint` override | Controller prints a line when a relative choice is accepted; test runs under a print-capturing zone or reassigns `debugPrint`, then matches strings | Medium: new harness not present in repo; brittle string matching; `print`/`debugPrint` unused today | Rejected as primary seam: no existing production log call to intercept; introduces a capture style foreign to `snake_controller_test.dart` |
| Emit via `dart:developer` `log` and listen in tests | Controller calls `developer.log`; test attaches a log listener or inspects timeline | Higher: no `dart:developer` usage or listener helpers in repo; listener APIs are less direct than an injected list for classic-rules tests | Rejected: no existing seam; heavier than constructor injection for a logic proof |
| Assert only heading / head / cells after `_choicePredict` | Existing AC-003-style asserts that the board turned from the returned key | Low harness cost | Rejected as sole proof: can pass without any choice record being emitted, which violates the shared “must fail if no record” decision |
| Rely on the predict double’s return value as the “record” | Test knows it returned `'left'` and asserts that | Zero new surface | Rejected: proves the double’s own fixture, not that the controller recorded the choice after receiving it |

## Constraints discovered

- Classic-rules proofs inject predict and must not call `LayaFlutter.open` or create an ONNX session (`wiki/product/classic-snake-example.md:29`; existing enforce test at `example/test/snake_controller_test.dart:412-471`).
- This slice does not change the prompt, relative-turn keys, or add a timer or safety shield (shared decisions; relative keys and English state already fixed at `example/lib/snake_controller.dart:143-171` and `wiki/product/classic-snake-example.md:15-19`).
- The proof must fail if a step that receives a relative choice emits no record of that choice (shared decision; current board-only asserts at `example/test/snake_controller_test.dart:85-120` do not enforce that).
- Work item `0007-restart-on-death` is separate; restart behaviour is out of scope here (`wiki/work/0008-snake-choice-log/STATE.yaml` title and shared decisions).
- No developer-log or print API exists in repository Dart sources today; the established observation pattern is inject-and-capture locals (`example/test/snake_controller_test.dart:302-366`).
- Field list of a choice record is owned by another research stream; this stream only names how a test observes that a record was emitted.

## Unresolved

- [UNRESOLVED: Exact name and constructor shape of the injectable record seam (callback vs mutable list vs optional logger typedef), once product chooses to add one.]
- [UNRESOLVED: Whether a production `debugPrint`/`print` line is still desired for human console reading in addition to the in-memory seam a logic test can assert.]
- [UNRESOLVED: Whether any screen-level or widget-test observation of the same record is required, given `snake_screen_test.dart` today only source-scans.]

## Sources

- `wiki/product/GOAL.md` — consulted 2026-09-28
- `wiki/product/classic-snake-example.md` — consulted 2026-09-28
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` — consulted 2026-09-28
- `example/lib/snake_controller.dart` — consulted 2026-09-28
- `example/test/snake_controller_test.dart` — consulted 2026-09-28
- `example/test/snake_screen_test.dart` — consulted 2026-09-28
- `example/lib/snake_screen.dart` — consulted 2026-09-28
- `example/pubspec.yaml` — consulted 2026-09-28
- `wiki/work/0008-snake-choice-log/STATE.yaml` — consulted 2026-09-28
- `https://api.flutter.dev/flutter/flutter_test/TestWidgetsFlutterBinding/debugPrintOverride.html` — consulted 2026-09-28
- `https://github.com/flutter/flutter/blob/master/packages/flutter/test/foundation/capture_output.dart` — consulted 2026-09-28
