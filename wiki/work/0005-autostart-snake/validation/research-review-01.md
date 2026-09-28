# Research review — round 01

- Work item: 0005-autostart-snake
- Reviewed artifact: `wiki/work/0005-autostart-snake/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-27

## Verdict

**PASS**

Cited primary sources support the current button-gated start path, the VM no-session pump constraint, the GOAL/AC-008 scope (no play-button requirement), and the chosen explicit-autostart-flag approach; options are compared; stream unresolved items are closed in Constraints without burying a plan-affecting open question.

## Verification performed

Opened `00-research.md`, then opened both child streams and every primary source the artifact names. Confirmed local line content with a Python spot-check.

```text
$ python3 - <<'PY'
# spot-check cited local lines contain the claimed substrings
OK: example/lib/main.dart:15-16 contains ['runApp', 'ExampleApp']
OK: example/lib/main.dart:36-47 contains ['idle home', 'ExampleHomePage', 'does not open']
OK: example/lib/main.dart:65-117 contains ['LayaFlutter.open', 'Play Snake', 'SnakeScreen']
OK: example/lib/snake_screen.dart:13-18 contains ['LoadedRuntime', 'required this.runtime']
OK: example/lib/snake_screen.dart:43-48 contains ['didChangeDependencies', '_runSteps']
OK: example/test/widget_test.dart:5-14 contains ['ExampleApp', 'Play Snake', 'Opening…']
OK: example/test/snake_screen_test.dart:5-42 contains ['Timer', 'Future.delayed', 'Ticker', 'runtime.predict']
OK: wiki/product/classic-snake-example.md:27-31 contains ['must not open a session', 'first frame', 'VM widget tests']
OK: wiki/product/GOAL.md:15 contains ['classic Snake', 'next step waits']
OK: wiki/product/GOAL.md:32 contains ['no step timer', 'left turn']
OK: wiki/product/GOAL.md:43-45 contains ['SC-003', 'SC-005', 'Snake screen']
OK: wiki/work/0003-classic-snake/02-criteria.md:24 contains ['AC-008', 'LayaFlutter.open', 'ONNX']
OK: wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:23-30 contains ['integration_test', 'MissingPluginException', 'flutter test']
OK: lib/src/library.dart:25-29 contains ['static Future<LoadedRuntime> open', 'CheckpointDownloader', 'createSession']
GOAL mentions 'idle home' / 'play button' / 'Play Snake' / 'first frame': False
STATE.yaml contains 'Library open and predict stay closed': True
PY
```

Spot-checks that supported the artifact (not findings): idle home and Play Snake handler in `example/lib/main.dart`; widget test idle pump and Opening… absence; SnakeScreen runtime-required constructor and `didChangeDependencies` loop start; product first-frame forbid at `classic-snake-example.md:31`; GOAL SC-003/SC-005 silent on idle home and play button; AC-008 logic-test open ban only; VM `MissingPluginException` guidance in the macOS ONNX solution; open signature shape in `lib/src/library.dart`; mount-time open risk class marked `[UNVERIFIED]` for edge scheduling that never runs on a single pump; seven options compared with a chosen flag path.

## Per-criterion results

Research review — acceptance-criteria table not applicable.

| Criterion | Result | Evidence (file:line) | Negative case exercised |
|---|---|---|---|
| n/a | n/a | research artifact review, not impl | n/a |

## Findings

### F-001 — “Slice does not change open signature” cites signature lines, not the work-item decision

- Severity: NIT
- Location: `wiki/work/0005-autostart-snake/00-research.md:51`
- Criterion affected: none
- Observation: The finding claims both the public `LayaFlutter.open` signature shape and that “this slice does not change that signature,” with Evidence only at `lib/src/library.dart:25-29`. Those lines establish the current signature; they do not state a slice boundary. The closed-API decision lives in `wiki/work/0005-autostart-snake/STATE.yaml` (also cited by `research/autostart-options.md`). The same evidence pointer is reused under Constraints at `00-research.md:78`. The constraint content is still true when checked against `STATE.yaml`.
- Why it matters: Bibliographic only; a plan that keeps library open and predict closed is still the work-item decision, not an inference from the signature file alone.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| (no blockers) | — |
