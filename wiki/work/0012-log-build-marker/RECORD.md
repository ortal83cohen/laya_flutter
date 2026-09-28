# Prefix Snake choice logs with a build marker

Device logs of `SnakeChoiceRecord` could not show whether the running binary was the latest build. Each console line from the Snake screen now starts with `build-marker 0012`.

## File

`example/lib/snake_screen.dart`

The proof lives in `example/test/snake_controller_test.dart`.

## Qualifying conditions

1. One production file changed: the Snake screen's debug line.
2. No new dependency.
3. No public interface, exported symbol, route, or schema change. `SnakeChoiceRecord.toString` is unchanged.
4. No data model, migration, or stored data change.
5. No security, privacy, authentication, authorisation, or payment surface.

## Proof

`choice log AC-006/AC-008: screen wires debugPrint callback; tests open no session` failed while the screen still printed `record.toString()` alone (`Expected: true`, `Actual: <false>`, reason `console line must carry the current build marker`). After the screen prefixed `build-marker 0012`, the same test passed.

## Checks

`dart format lib example/lib example/test/snake_controller_test.dart`:

```
Formatted 11 files (0 changed) in 0.04 seconds.
```

Exit code 0.

`dart analyze --fatal-infos --fatal-warnings`:

```
Analyzing laya_flutter...
No issues found!
```

Exit code 0.

`flutter test test/snake_controller_test.dart --name "screen wires debugPrint"` in `example/`:

```
00:00 +1: All tests passed!
```

Exit code 0.

`flutter test` in `example/` still fails one pre-existing case, `omitted initial snake starts at the board center, heading east`: the controller is constructed at width 60 and height 60 and the test expects head `(40,40)`. That expectation is outside this log prefix. The marker test above is the proof for this change.
