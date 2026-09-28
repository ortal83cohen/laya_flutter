# Implementation review — round 02

- Work item: 0003-classic-snake
- Reviewed artifact: current `example/lib` and `example/test` Snake tree (`example/lib/snake_controller.dart`, `example/lib/snake_screen.dart`, `example/lib/main.dart`, `example/test/snake_controller_test.dart`, `example/test/snake_screen_test.dart`, `example/test/widget_test.dart`)
- Reviewer: impl-validator
- Date: 2026-09-27

## Verdict

**PASS**

Every acceptance criterion has a green positive path and a deliberately broken negative that fails the suite; the three round-01 blockers (step request untied to builders, step question untied to builders, AC-008 rubber-stamp) now fail when re-probed.

## Verification performed

Analyze:

```text
$ dart analyze --fatal-infos --fatal-warnings
Analyzing laya_flutter...
No issues found!
ANALYZE_EXIT=0
```

Format (supporting check):

```text
$ dart format --output=none --set-exit-if-changed lib example/lib
Formatted 10 files (0 changed) in 0.02 seconds.
FORMAT_EXIT=0
```

Package tests:

```text
$ flutter test
00:00 +0: loading .../test/answers_test.dart
...
00:00 +18: All tests passed!
PACKAGE_TEST_EXIT=0
```

Example tests:

```text
$ cd example && flutter test
00:00 +0: loading .../example/test/widget_test.dart
...
00:00 +19: All tests passed!
EXAMPLE_TEST_EXIT=0
```

Wiki lint:

```text
$ python3 tools/lint_wiki.py
lint_wiki: clean (0 warning(s)).
LINT_EXIT=0
```

Deliberate negative probes (each change restored afterward; final `cd example && flutter test` again 19 passed; tree matched pre-probe backups):

| Probe | Result |
|---|---|
| AC-001 force `spawnFood` onto body | FAIL — `U1 food spawn places food on an empty cell, never on body`; `refuses body then lands on empty` |
| AC-001 full board without signalling failure | FAIL — `signals failure when the board has no empty cell` |
| AC-002 absolute UP/DOWN/LEFT/RIGHT keys in builder | FAIL — builder key test and step-capture test |
| AC-002 omit fields from `buildStateString` | FAIL — state-string test and step-capture test |
| AC-002 `step` sends Map state / absolute keys while builders unchanged (round-01 recurrence) | FAIL — `step passes English state and relative turn question into predict` (was green in round 01) |
| AC-003 absolute left=west regardless of heading | FAIL — `east plus left becomes north` |
| AC-004 advance before await completes (and double advance on completion) | FAIL — await-gate and turn tests |
| AC-005 add `Timer` in `snake_screen.dart` | FAIL — `snake_screen_test.dart` AC-005 at line 17 |
| AC-006 live wall/body occupation | FAIL — wall and body collision tests (`ended` expected true) |
| AC-007 planner/shield text in builder | FAIL — planner builder test and step-capture test |
| AC-007 `step` sends planner instructions while builder unchanged (round-01 recurrence) | FAIL — step-capture test only (was green in round 01) |
| AC-007 remap `left`→`straight` after predict | FAIL — `east plus left becomes north` |
| AC-008 contiguous `LayaFlutter.open` comment in the AC-008 test (round-01 recurrence) | FAIL — `logic tests inject predict and never open a session` (was green in round 01) |
| AC-008 add `openedSession = true` assert alongside real checks | suite stayed green (18/18 on controller+screen files) — not a session-open signal; contiguous open string is the failing negative |
| AC-009 remove `runtime.predict` delegation | FAIL — `snake_screen_test.dart` AC-009 |

## Per-criterion results

| Criterion | Result | Evidence (file:line) | Negative case exercised |
|---|---|---|---|
| AC-001 | pass | `example/lib/snake_controller.dart:121-141`; tests `example/test/snake_controller_test.dart:10-81` | yes — body spawn and silent full-board probes fail |
| AC-002 | pass | Step request asserted at `example/test/snake_controller_test.dart:302-367`; builders at `:212-282`; assembly at `example/lib/snake_controller.dart:183-190` | yes — Map/absolute via `step` with builders intact now fails the step-capture test |
| AC-003 | pass | `example/lib/snake_controller.dart:201-252`; tests `example/test/snake_controller_test.dart:84-120` | yes — absolute-left and post-predict remap probes fail |
| AC-004 | pass | `example/lib/snake_controller.dart:179-198`; test `example/test/snake_controller_test.dart:370-394` | yes — early-advance probe fails await-gate assertions |
| AC-005 | pass | `example/lib/snake_screen.dart` (no Timer/Future.delayed/Ticker/AnimationController); test `example/test/snake_screen_test.dart:13-21` | yes — inserting `Timer` fails the inspection test |
| AC-006 | pass | `example/lib/snake_controller.dart:180-182`, `:207-209`; tests `example/test/snake_controller_test.dart:149-208` | yes — live wall/body probes fail `ended` |
| AC-007 | pass | Step question text at `example/test/snake_controller_test.dart:358-365`; builder at `:284-300`; no post-answer remap in `example/lib/snake_controller.dart:194-198` | yes — planner via `step` with builder intact fails step-capture; remap fails turn test |
| AC-008 | pass | Injected double + step at `example/test/snake_controller_test.dart:412-426`; source scan for session-open names at `:428-470` | yes — contiguous `LayaFlutter.open` in that test fails the source scan |
| AC-009 | pass | `example/lib/snake_screen.dart:32-38`; test `example/test/snake_screen_test.dart:24-42` | yes — local turn table without `runtime.predict` fails |

## Findings

None.

## Recurrence check

- Previous round: `wiki/work/0003-classic-snake/validation/impl-review-01.md`
- Recurring findings: none — round-01 F-001 (AC-002), F-002 (AC-007), and F-003 (AC-008) were re-probed with the same defect shapes; each now fails the suite instead of staying green
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| (none) | — |
