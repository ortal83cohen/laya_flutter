# Implementation review — round 02

- Work item: 0005-autostart-snake
- Reviewed artifact: uncommitted `example/lib/main.dart`, `example/test/widget_test.dart`
- Reviewer: impl-validator
- Date: 2026-09-27

## Verdict

**PASS**

All six acceptance criteria hold; AC-005’s negative case now fails the idle widget test when the
autostart guard is removed (second pump shows `Opening…`), so F-001 from round 01 does not recur.

## Verification performed

Repository root analyze:

```text
$ dart analyze --fatal-infos --fatal-warnings
Analyzing laya_flutter...
No issues found!
```

Example package tests (restored tree):

```text
$ cd example && flutter test test/widget_test.dart
00:00 +0: loading .../example/test/widget_test.dart
00:00 +0: idle example home shows Laya without opening a session
00:00 +1: production entry enables autostart without open before runApp
00:00 +2: autostart path has no play button and reuses open chrome
00:00 +3: All tests passed!
```

Gaming / leftovers scan on the reviewed files: no `skip`, `@Skip`, mocks, `TODO`, or debug `print`
in `example/lib/main.dart` or `example/test/widget_test.dart`. Idle test now includes a second
`pump()` before asserting `Opening…` absent (`example/test/widget_test.dart:10-17`).

Negative-case probes (each change restored before the next; final suite green again):

1. **AC-001 — Play Snake reintroduced** (`example/lib/main.dart` body): `autostart path` failed with
   `autostart path must not present a Play Snake control`.
2. **AC-001 — production entry without `autostart: true`**: `production entry` failed with
   `production entry must construct the root with autostart on`.
3. **AC-002 — catch failure text replaced** (`Could not open runtime:` → `Predict failed:`):
   `autostart path` failed with `existing open-failure text must remain`.
4. **AC-004 — remove `Laya` titles**: idle widget test failed expecting `Laya`.
5. **AC-005 / F-001 recurrence probe — remove `!widget.autostart` guard** so default-off still
   schedules open:

```text
# didChangeDependencies ignores widget.autostart; only _autostartScheduled gates
$ cd example && flutter test test/widget_test.dart --name 'idle example home'
00:00 +0: idle example home shows Laya without opening a session
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════
The following TestFailure was thrown running a test:
Expected: no matching candidates
  Actual: _TextWidgetFinder:<Found 1 widget with text "Opening…": [
            Text("Opening…", dependencies: [DefaultSelectionStyle, DefaultTextStyle, MediaQuery]),
          ]>
   Which: means one was found but none were expected
...
  file:///.../example/test/widget_test.dart line 17
The test description was:
  idle example home shows Laya without opening a session
00:00 +0 -1: Some tests failed.
```

Restored green run after all probes:

```text
$ cd example && flutter test test/widget_test.dart
00:00 +0: idle example home shows Laya without opening a session
00:00 +1: production entry enables autostart without open before runApp
00:00 +2: autostart path has no play button and reuses open chrome
00:00 +3: All tests passed!
$ dart analyze --fatal-infos --fatal-warnings
Analyzing laya_flutter...
No issues found!
```

Tree left restored: `example/lib/main.dart` guard intact at line 80 (
`!widget.autostart || _autostartScheduled`); no accidental package-root leftovers from probing.

## Per-criterion results

| Criterion | Result | Evidence (file:line)                                                                                                                                                                                                                                                    | Negative case exercised                                                                               |
|-----------|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| AC-001    | pass   | `example/lib/main.dart:16` (`runApp(...autostart: true)`); `:80-87` (autostart schedules open); `:95-108` (`_opening` then navigate to `SnakeScreen`); `:139-141` (`Opening…`); no `Play Snake` in file. Covered by `example/test/widget_test.dart:20-37` and `:40-86`. | yes — Play Snake insert and entry without autostart each failed the matching source test              |
| AC-002    | pass   | `example/lib/main.dart:111-116` (catch sets `Could not open runtime:`); catch has no `Navigator`/`SnakeScreen`. Covered by `example/test/widget_test.dart:64-85`.                                                                                                       | yes — wrong failure text failed `autostart path` with `existing open-failure text must remain`        |
| AC-003    | pass   | `example/test/widget_test.dart:10-17` pumps default `ExampleApp`, second frame, asserts `Opening…` absent; VM run completed without native ONNX.                                                                                                                        | yes — same idle test fails when open is scheduled (AC-005 guard-removal probe shows `Opening…`)       |
| AC-004    | pass   | `example/test/widget_test.dart:15` finds `Laya`; no assertion that `Play Snake` is present; `example/lib/main.dart:129,136` still show `Laya`.                                                                                                                          | yes — removing `Laya` failed idle test                                                                |
| AC-005    | pass   | Default-off at `example/lib/main.dart:43,63`; guard at `:80-82`. Idle contract at `example/test/widget_test.dart:10-17` pumps twice and requires `Opening…` absent. Removing the autostart guard failed that test (Found 1 `Opening…`).                                 | yes — “schedules open” with autostart off fails the idle test (see probe above)                       |
| AC-006    | pass   | This review used `flutter test` in `example/` for AC-003–AC-005 idle/source contracts and did not treat that run as host ONNX session-load proof (aligned with AC-001 inspect / host launch for session success).                                                       | yes — meta: treating VM green as session-load proof would violate the criterion; this review does not |

## Findings

None.

## Recurrence check

- Previous round: `wiki/work/0005-autostart-snake/validation/impl-review-01.md`
- Recurring findings: none — F-001 (idle suite stayed green with autostart guard removed while a
  second pump showed `Opening…`) does **not** recur; the same guard-removal probe now fails the idle
  widget test at `example/test/widget_test.dart:17`
- Oscillating: no
- Escalation: not recommended

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| (none)  | —                |
