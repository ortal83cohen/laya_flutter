# Implementation review — round 01

- Work item: 0016-absolute-snake-checkpoint
- Reviewed artifact: current staged, unstaged, and untracked implementation files against `HEAD` `637a8c3`; final evaluator inspected after its 40-by-40/no-starvation edit
- Reviewer: Codex (independent blind implementation validator)
- Date: 2026-09-28

## Verdict

**CONDITIONAL**

The local behavior and negative cases satisfy the frozen criteria in the checks available here, but public-checkpoint prompt parity and an actual pinned-source/model game remain [UNVERIFIED] because no checkpoint run was performed; AC-005's explicit unavailable branch was verified instead.

## Verification performed

- `git status --short --untracked-files=all` showed staged and unstaged application/library changes, the untracked `example/test/snake_controller_test.dart` and `tool/snake_absolute_eval.py`, and no pre-existing `impl-review-01.md`. The reviewed tree includes the later missing-configuration widget change and evaluator edit. No other source or wiki file was edited by this reviewer.
- `git diff --no-ext-diff --check HEAD` exited 0 with empty output.
- `git ls-files -co --exclude-standard | rg -i '\.(onnx|safetensors|pt|pth|bin|gguf|ckpt|pb|tflite|weights)$' || true` exited 0 with empty output. This covers tracked and non-ignored untracked filenames, not ignored local caches.
- `/Users/ortalcohen/fvm/versions/3.47.3/bin/cache/dart-sdk/bin/dart format --output=none --set-exit-if-changed lib example/lib` exited 0:

  ```text
  Formatted 10 files (0 changed) in 0.03 seconds.
  ```

- `/Users/ortalcohen/fvm/versions/3.47.3/bin/cache/dart-sdk/bin/dart analyze --fatal-infos --fatal-warnings` exited 0:

  ```text
  Analyzing laya_flutter...
  No issues found!
  ```

- From `example/`, `fvm flutter test test/snake_controller_test.dart test/snake_screen_test.dart test/widget_test.dart -r expanded` exited 0. The exact final output line was:

  ```text
  00:01 +29: All tests passed!
  ```

  The run exercised literal reverse/body and wall collisions, invalid/missing answers, prediction failure, exact local prompt fixture, await gating, restart, and the added empty-bundle setup widget case. Its earlier sandbox attempt exited 1 before tests with:

  ```text
  /Users/ortalcohen/fvm/versions/3.47.3/bin/internal/update_engine_version.sh: line 71: /Users/ortalcohen/fvm/versions/3.47.3/bin/cache/engine.stamp.tmp.3960: Operation not permitted
  /Users/ortalcohen/fvm/versions/3.47.3/bin/internal/update_engine_version.sh: line 78: /Users/ortalcohen/fvm/versions/3.47.3/bin/cache/engine.realm: Operation not permitted
  ```

- From the repository root, `fvm flutter test test/offline_predict_test.dart -r expanded` initially exited 1 before test execution:

  ```text
  Failed to get the install name of LocalFile: '/Users/ortalcohen/Documents/GitHub/laya_flutter/build/native_assets/macos/libtokenizers_ffi.dylib':
  error: /Applications/Xcode 2.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/otool-classic: can't open file: /Users/ortalcohen/Documents/GitHub/laya_flutter/build/native_assets/macos/libtokenizers_ffi.dylib (No such file or directory)
  ```

  The native asset was present at the next read-only check; the identical command was rerun and exited 0:

  ```text
  00:00 +0: loading /Users/ortalcohen/Documents/GitHub/laya_flutter/test/offline_predict_test.dart
  00:00 +0: empty question list throws and does not invent answers
  00:00 +1: missing local checkpoint fails without calling remote inference
  00:00 +2: complete cache with disabled network does not invoke the downloader
  00:00 +3: local bundle reports missing files without opening a session
  00:00 +4: local bundle rejects malformed companions before session open
  00:00 +5: local bundle uses its graph and rejects incompatible names
  00:00 +6: real example requires a compile-time local Snake bundle
  00:00 +7: All tests passed!
  ```

- After the final evaluator edit, `python3 -B -c 'import ast, pathlib; ast.parse(pathlib.Path("tool/snake_absolute_eval.py").read_text()); print("snake_absolute_eval.py syntax OK")'` exited 0:

  ```text
  snake_absolute_eval.py syntax OK
  ```

- After the final evaluator edit, `python3 -B tool/snake_absolute_eval.py --source-dir /private/tmp/0016-no-source --model-dir /private/tmp/0016-no-model --games 2` exited 2, with no metrics or full-game label:

  ```text
  EVALUATION_UNAVAILABLE: model directory does not exist: /private/tmp/0016-no-model
  ```

- A read-only `python3 -B -` in-memory fixture imported `tool/snake_absolute_eval.py`, supplied a two-step synthetic `Game` and choice-only `Agent`, called `play_game` for seeds `2000000000` and `2000000001`, and called `report` on those game outcomes. It then passed a decision-only row (`{"choice": "right"}`) to `report`. The exact output was:

  ```text
  {"aggregate": {"collision_game_rate": 1.0, "collisions": 2, "food_reach_game_rate": 1.0, "food_reached": 2, "game_count": 2, "games_reaching_food": 2, "loop_games": 0, "loop_rate": 0.0, "mean_score": 1.0, "reverse_choices": 0, "steps": 4, "teacher_agreement_rate": 1.0, "teacher_agreements": 4, "terminations": {"wall": 2}, "total_score": 2}, "board_size": 40, "kind": "full_model_controlled_games", "seeds": [2000000000, 2000000001]}
  decision-only row rejected: 'steps'
  ```

  This tests the harness counters and decision-row negative case only. It is not pinned-source, checkpoint, Python/Flutter parity, or gameplay-quality evidence.

## Per-criterion results

| Criterion | Result | Evidence (file:line) | Negative case exercised |
|---|---|---|---|
| AC-001 | PASS | `example/lib/snake_controller.dart:405-453`, `example/lib/snake_controller.dart:464-481`; literal reverse collision test `example/test/snake_controller_test.dart:79-98` | Yes — `left` from east targets the neck, remains the recorded raw choice, and ends as body collision. |
| AC-002 | CONDITIONAL | Four ordered keys/descriptions and `move` question at `example/lib/snake_controller.dart:299-320`; state/dispatch fixture at `example/test/snake_controller_test.dart:162-232` | Yes locally — the fixture rejects `straight` and asserts room/tail facts. Exact agreement with the external public encoder is [UNVERIFIED] under the permitted sources. |
| AC-003 | PASS | `example/lib/main.dart:101-121`; local-only opener and file/graph checks `lib/src/library.dart:68-145`; negative tests `test/offline_predict_test.dart:108-250` | Yes — absent/malformed bundle fails before session creation, and the example calls no base opener. |
| AC-004 | PASS | JSON record fields `example/lib/snake_controller.dart:86-170`; one record for failure/invalid/valid outcome `example/lib/snake_controller.dart:348-453`; assertions `example/test/snake_controller_test.dart:79-120` and `example/test/snake_controller_test.dart:235-301` | Yes — reverse and wall choices retain raw key and unsafe attempted cell; invalid and thrown predictions classify without movement. |
| AC-005 | CONDITIONAL | Seeded game loop and counters `tool/snake_absolute_eval.py:140-180`; per-game/aggregate report `tool/snake_absolute_eval.py:183-224`; 40-by-40 default and unavailable exit `tool/snake_absolute_eval.py:227-267` | Yes for available checks — absent model emits only `EVALUATION_UNAVAILABLE`; synthetic complete-game outcomes aggregate while a decision-only row is rejected. Real pinned-source/weight execution is [UNVERIFIED]. |
| AC-006 | PASS | Awaited prediction `example/lib/snake_controller.dart:331-350`; single screen loop `example/lib/snake_screen.dart:74-119`; setup message `example/lib/main.dart:101-112`; widget test `example/test/widget_test.dart:7-24` | Yes — pending prediction does not move on clock, and empty launch configuration shows setup guidance without opening base. |
| AC-007 | PASS | `tool/snake_absolute_eval.py:45-58` contains file sizes/digests, not model contents; repository-wide Git filename inventory above | Yes — tracked and non-ignored untracked inventory found no model weight or ONNX binary filename. |

## Findings

No implementation defect was established by the permitted evidence. The conditional verdict records the explicit missing-model and external-contract verification boundary, not a claim of a failed criterion.

## Recurrence check

- Previous round: none — first implementation round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| None | Not applicable |
