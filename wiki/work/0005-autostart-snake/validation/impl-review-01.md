# Implementation review — round 01

- Work item: 0005-autostart-snake
- Reviewed artifact: uncommitted `example/lib/main.dart`, `example/test/widget_test.dart` (staged as
  new files; repository has no `HEAD` yet; `git diff` against the working tree was empty because
  both paths match the index)
- Reviewer: impl-validator
- Date: 2026-09-27

## Verdict

**FAIL**

AC-005’s negative case “mounting the default tree schedules open” is not established: removing the
autostart guard still leaves the example widget suite green while a second pump shows the opening
label.

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
in `example/lib/main.dart` or `example/test/widget_test.dart`.

Negative-case probes (each change restored before the next; final suite green again):

1. **AC-001 — Play Snake reintroduced** (`example/lib/main.dart` body): `autostart path` failed with
   `autostart path must not present a Play Snake control`.
2. **AC-001 — production entry without `autostart: true`**: `production entry` failed with
   `production entry must construct the root with autostart on`.
3. **AC-001 — opening label string removed** (`Opening…` → `Loading…`): `autostart path` failed with
   `existing opening label must remain`.
4. **AC-002 — catch uses wrong failure text / mentions navigation**: `autostart path` failed with
   `existing open-failure text must remain` (wrong text) and, in a separate probe with failure text
   kept but `Navigator`/`SnakeScreen` in the catch body, failed with
   `open failure must not navigate to Snake`.
5. **AC-003 — force `_opening = true`**: idle widget test failed expecting `Opening…` absent.
6. **AC-003 — flip idle assertion to `findsOneWidget`**: idle widget test failed (0 found).
7. **AC-004 — remove `Laya` titles**: idle widget test failed expecting `Laya`.
8. **AC-004 — add `expect(find.text('Play Snake'), findsOneWidget)`**: idle widget test failed (0
   found).
9. **AC-005 — default `autostart` constructor defaults flipped to `true`**: suite failed on
   `ExampleApp autostart must default off` (source test); idle single-pump test alone still passed.
10. **AC-005 — remove `!widget.autostart` guard so default-off still schedules open** (critical):

```text
# didChangeDependencies ignores widget.autostart; only _autostartScheduled gates
$ cd example && flutter test test/widget_test.dart
00:00 +3: All tests passed!

# separate probe after same break:
pump1 Opening=0
pump2 Opening=1
```

Restored green run after all probes:

```text
$ cd example && flutter test test/widget_test.dart
00:00 +3: All tests passed!
$ dart analyze --fatal-infos --fatal-warnings
Analyzing laya_flutter...
No issues found!
```

## Per-criterion results

| Criterion | Result | Evidence (file:line)                                                                                                                                                                                                                                                                       | Negative case exercised                                                                                  |
|-----------|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| AC-001    | pass   | `example/lib/main.dart:16` (`runApp(...autostart: true)`); `:80-87` (autostart schedules open); `:95-108` (`_opening` then navigate to `SnakeScreen`); `:139-141` (`Opening…`); no `Play Snake` in file. Covered by `example/test/widget_test.dart:17-34` and `:37-83`.                    | yes — Play Snake insert, entry without autostart, Opening… removed; each failed the matching source test |
| AC-002    | pass   | `example/lib/main.dart:111-116` (catch sets `Could not open runtime:`); catch has no `Navigator`/`SnakeScreen`. Covered by `example/test/widget_test.dart:50-82`.                                                                                                                          | yes — wrong failure text and catch-body navigation markers each failed `autostart path`                  |
| AC-003    | pass   | `example/test/widget_test.dart:10-14` pumps default `ExampleApp`, asserts `Opening…` absent; VM run completed without native ONNX.                                                                                                                                                         | yes — `_opening = true` and flipped `findsOneWidget` assertion each failed idle test                     |
| AC-004    | pass   | `example/test/widget_test.dart:12` finds `Laya`; no assertion that `Play Snake` is present; `example/lib/main.dart:129,136` still show `Laya`.                                                                                                                                             | yes — removing `Laya` failed idle test; requiring `Play Snake` present failed idle test                  |
| AC-005    | fail   | Implementation default-off is at `example/lib/main.dart:43,63` and guard at `:80-82`. Idle pump at `example/test/widget_test.dart:10-14` only asserts label absence after one pump. Removing the autostart guard left the full suite green while pump2 showed `Opening…` (open scheduled). | no — “schedules open” with autostart off does not fail the suite (see F-001)                             |
| AC-006    | pass   | This review used `flutter test` in `example/` for AC-003–AC-005 idle/source contracts and did not treat that run as host ONNX session-load proof (aligned with AC-001 inspect / host launch for session success).                                                                          | yes — meta: treating VM green as session-load proof would violate the criterion; this review does not    |

## Findings

### F-001 — Default-off suite does not fail when open is still scheduled

- Severity: BLOCKER
- Location: `example/test/widget_test.dart:7-15` (idle pump contract); behaviour under test gated at
  `example/lib/main.dart:80-87`
- Criterion affected: AC-005
- Observation: With `!widget.autostart` removed from `didChangeDependencies`, `const ExampleApp()`
  still schedules `_openSnake` after the first frame. `flutter test test/widget_test.dart` stayed
  fully green. A follow-up probe showed `Opening…` count 0 after one pump and 1 after a second pump.
  The source check that defaults are `false` does not catch this class of defect.
- Why it matters: AC-005’s negative case requires that mounting the default tree must not schedule
  open. That wrong behaviour currently has no failing test, so the criterion is not established.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| F-001   | implement        |
