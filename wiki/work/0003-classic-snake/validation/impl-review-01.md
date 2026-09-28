# Implementation review — round 01

- Work item: 0003-classic-snake
- Reviewed artifact: uncommitted / staged example Snake tree (`example/lib/snake_controller.dart`, `example/lib/snake_screen.dart`, `example/lib/main.dart`, `example/test/snake_controller_test.dart`, `example/test/snake_screen_test.dart`, `example/test/widget_test.dart`); git HEAD unavailable in this checkout
- Reviewer: impl-validator
- Date: 2026-09-27

## Verdict

**FAIL**

Three criteria are not established by a failing negative case: AC-002 and AC-007 only assert prompt builders in isolation (so `step` can diverge and the suite stays green), and AC-008’s dedicated test is a rubber-stamp that still passes when a session-open signal is introduced.

## Verification performed

Format:

```text
$ dart format --output=none --set-exit-if-changed lib example/lib
Formatted 10 files (0 changed) in 0.03 seconds.
FORMAT_EXIT=0
```

Analyze:

```text
$ dart analyze --fatal-infos --fatal-warnings
Analyzing laya_flutter...
No issues found!
ANALYZE_EXIT=0
```

Example tests:

```text
$ cd example && flutter test
00:00 +0: loading .../example/test/widget_test.dart
...
00:00 +18: All tests passed!
EXAMPLE_TEST_EXIT=0
```

Package tests:

```text
$ flutter test
00:00 +0: loading .../test/answers_test.dart
...
00:00 +18: All tests passed!
PACKAGE_TEST_EXIT=0
```

Wiki lint:

```text
$ python3 tools/lint_wiki.py
lint_wiki: clean (0 warning(s)).
LINT_EXIT=0
```

Deliberate negative probes (each change restored afterward; final tree matches pre-probe backups; `cd example && flutter test` again 18 passed):

| Probe | Result |
|---|---|
| AC-001 force `spawnFood` onto body | FAIL at `snake_controller_test.dart:31` |
| AC-001 full board without signalling failure | FAIL at `snake_controller_test.dart:76` |
| AC-002 absolute UP/DOWN/LEFT/RIGHT keys in builder | FAIL at `snake_controller_test.dart:249` |
| AC-002 omit fields from `buildStateString` | FAIL at `snake_controller_test.dart:231` |
| AC-002 `step` sends Map state / absolute keys while builders unchanged | suite stayed green (15/15 controller tests) |
| AC-003 ignore choice / absolute left=west | FAIL at `snake_controller_test.dart:92` |
| AC-004 advance before await completes | FAIL at `snake_controller_test.dart:316` |
| AC-004 double advance on one completion | FAIL at `snake_controller_test.dart:321` |
| AC-005 add `Timer` in `snake_screen.dart` | FAIL at `snake_screen_test.dart:17` |
| AC-006 live wall/body occupation | FAIL at `snake_controller_test.dart:167` and `:201` |
| AC-007 planner/shield text in builder | FAIL at `snake_controller_test.dart:294` |
| AC-007 `step` sends planner instructions while builder unchanged | suite stayed green |
| AC-007 remap `left`→`straight` after predict | FAIL at `snake_controller_test.dart:92` (via turn test) |
| AC-008 reference `LayaFlutter.open` / fake `openedSession` in the AC-008 test | still PASS |
| AC-009 remove `runtime.predict` delegation | FAIL at `snake_screen_test.dart:33` |

## Per-criterion results

| Criterion | Result | Evidence (file:line) | Negative case exercised |
|---|---|---|---|
| AC-001 | pass | `example/lib/snake_controller.dart:121-141`; tests `example/test/snake_controller_test.dart:10-80` | yes — body spawn and no-empty failure probes fail as required |
| AC-002 | fail | Builders covered at `example/test/snake_controller_test.dart:211-281`; `step` request at `example/lib/snake_controller.dart:183-190` is never asserted | no — Map/absolute request via `step` with builders left intact leaves the suite green |
| AC-003 | pass | `example/lib/snake_controller.dart:201-218`, `:224-252`; tests `example/test/snake_controller_test.dart:84-119` | yes — ignore-key and absolute-left probes fail |
| AC-004 | pass | `example/lib/snake_controller.dart:179-198`; test `example/test/snake_controller_test.dart:303-326` | yes — early advance and double-advance probes fail |
| AC-005 | pass | `example/lib/snake_screen.dart` (no Timer/Future.delayed/Ticker/AnimationController); test `example/test/snake_screen_test.dart:13-21` | yes — inserting `Timer` into `snake_screen.dart` fails the inspection test |
| AC-006 | pass | `example/lib/snake_controller.dart:207-209`, `:180-182`; tests `example/test/snake_controller_test.dart:148-207` | yes — live wall/body probes fail `ended` assertions |
| AC-007 | fail | Builder-only checks at `example/test/snake_controller_test.dart:283-299`; `step` question assembly at `example/lib/snake_controller.dart:183-187` | no — planner/shield instructions sent only from `step` leave the suite green |
| AC-008 | fail | Rubber-stamp test `example/test/snake_controller_test.dart:344-358`; inject doubles elsewhere e.g. `:85-87`, `:308-310` | no — introducing an open signal into the AC-008 test still passes |
| AC-009 | pass | `example/lib/snake_screen.dart:32-38`; test `example/test/snake_screen_test.dart:24-42` | yes — local turn table without `runtime.predict` fails the inspection test |

## Findings

### F-001 — AC-002 not tied to what `step` sends to predict

- Severity: BLOCKER
- Location: `example/test/snake_controller_test.dart:211`
- Criterion affected: AC-002
- Observation: U2 prompt tests call `buildStateString` and `buildTurnQuestion` only. Deliberately changing `SnakeController.step` to pass a `Map` state and/or absolute UP/DOWN/LEFT/RIGHT criteria while leaving those builders unchanged keeps all controller tests green. The criterion requires the model request built when a step runs, including the negative of a string-map state.
- Why it matters: The green suite does not establish AC-002 for the path that actually calls predict.

### F-002 — AC-007 not tied to the question text `step` sends

- Severity: BLOCKER
- Location: `example/test/snake_controller_test.dart:283`
- Criterion affected: AC-007
- Observation: Planner/shield assertions inspect `buildTurnQuestion()` only. Deliberately making `step` send instructions that include plan-multi-step and safety-shield override language, while leaving `buildTurnQuestion` unchanged, leaves the suite green.
- Why it matters: AC-007 is about the step’s question text; a builder-only check is not a failing negative for the step path.

### F-003 — AC-008 test is a rubber-stamp with no failing negative

- Severity: BLOCKER
- Location: `example/test/snake_controller_test.dart:344`
- Criterion affected: AC-008
- Observation: The test named for AC-008 never calls `step`, only asserts `predictCalls == 0` before any predict, and comments that `LayaFlutter.open` is absent. Referencing `LayaFlutter.open` or asserting a fake `openedSession == true` inside that test still yields PASS. No automated case fails when a Snake logic test opens or signals a session.
- Why it matters: That is test gaming relative to AC-008’s negative case; the criterion is not established by a case that fails when wrong.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| F-001 | implement |
| F-002 | implement |
| F-003 | implement |
