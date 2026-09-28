# Log the full Snake prompt and the model answer

Device logs showed the state string and the chosen key, and hid the instruction sentence and the
three option texts the model actually scores. Each choice record now prints those lines, then the
answer. The screen prefix is `build-marker 0013` so this binary is distinct from `0012`.

## Files

`example/lib/snake_controller.dart` builds the printed prompt. `example/lib/snake_screen.dart` bumps
the console prefix.

The proof lives in `example/test/snake_controller_test.dart`.

## Qualifying conditions

1. Two production files: the choice-record text, and the screen prefix that identifies the binary.
   No other production file.
2. No new dependency.
3. No library export, route, or schema change. `SnakeChoiceRecord` gains `instructions` and
   `options` so the console line can show the scored text. Callers outside the example do not
   construct it.
4. No data model, migration, or stored data change.
5. No security, privacy, authentication, authorisation, or payment surface.

## Proof

`choice log AC-001/AC-002: relative success delivers one record then moves cells` failed to compile
while `SnakeChoiceRecord` had no `instructions` or `options` getter. After `step` stored the turn
instructions and option map and `toString` printed them, the choice-log group passed, including the
screen prefix `build-marker 0013`.

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

## Instruction sentence

The logged question still used `Choose the best safe turn toward the food.` Device logs showed the
model answering `right` while another option was labeled Best. The living turn instructions are now
exactly: The snake is hungry. Choose one relative turn toward the food. A turn into a wall is a
failure; do not choose it. Option text no longer ranks a key: left is `Turn left.`, right is
`Turn right.`, straight is `Go straight.`. The turn instructions explain that this is Snake, how
columns and rows map, what a heading is, and what left, right, and straight do. The state string
reports board size, facing, head, food, the three neighbour cells, and snake cells from head to
tail. The screen prefix stays `build-marker 0013`.

Proof: `U2 prompt turn instructions name hunger and wall failure` failed on the old sentence (
`Actual: Choose the best safe turn toward the food.`), then passed after `buildTurnQuestion` stored
the new one.

`flutter test test/snake_controller_test.dart --name "choice log"` in `example/`, before the
instruction change:

```
00:00 +10: All tests passed!
```

Exit code 0.

`flutter test test/snake_controller_test.dart --name "turn instructions name hunger|choice log"` in
`example/`, after the instruction change:

```
00:00 +11: All tests passed!
```

Exit code 0.

`dart format lib example/lib example/test/snake_controller_test.dart`,
`dart analyze --fatal-infos --fatal-warnings`, and `python3 tools/lint_wiki.py` were re-run after
the instruction change: format changed 0 files, analyze reported no issues, and the linter printed
`lint_wiki: clean (0 warning(s)).` Each exited 0.
