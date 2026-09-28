# Implementation review — round 01

- Work item: 0010-restart-on-death
- Reviewed artifact: uncommitted working tree `example/lib/snake_controller.dart`, `example/lib/snake_screen.dart`, `example/test/snake_controller_test.dart`, `example/test/snake_screen_test.dart` (repository has no commits yet; reviewed staged+unstaged contents)
- Reviewer: impl-validator
- Date: 2026-09-28

## Verdict

**PASS**

All eleven acceptance criteria hold with green format, analyze, and example VM tests; deliberate wrong-behaviour probes for wall freeze, further-step-while-ended, screen new-run, restart title, and predict-failure ending each failed the matching assertions, then the tree was restored to green.

## Verification performed

```text
$ dart format --set-exit-if-changed lib example/lib example/test
Formatted 13 files (0 changed) in 0.06 seconds.
EXIT:0

$ dart analyze --fatal-infos --fatal-warnings
Analyzing laya_flutter...
No issues found!
EXIT:0

$ cd example && flutter test
...
00:04 +39: All tests passed!
EXIT:0
```

Gaming / leftovers scan on the reviewed files: no `skip`, `@Skip`, pending tests, or `TODO` on the death/restart path. Screen uses `debugPrint` for choice records (existing observability seam, not a death/restart pacing hook). No `Timer`, `Future.delayed`, or `Ticker` in `example/lib/snake_screen.dart`.

Negative-case probes (each change restored before the next; final suite green again):

1. **AC-001 — advance onto wall** (`_applyChoiceAndAdvance` sets `ended` then still advances): wall collision test failed expecting head `(4,1)`, actual `(5,1)` at `example/test/snake_controller_test.dart:172`.
2. **AC-003 — further step while ended mutates cells** (`step` inserts a cell when `ended`): wall test failed cells-unchanged assertion at `example/test/snake_controller_test.dart:191`.
3. **AC-006 — remove new-run on death** (`return` instead of `setState(_startNewRun)`): screen death test failed `predictCalls >= 2` (actual `1`) at `example/test/snake_screen_test.dart:124`.
4. **AC-009 — title always ended** (`title: Text('Snake — ended')`): screen death test failed expecting `Snake` at `example/test/snake_screen_test.dart:125`.
5. **AC-010 — predict failure sets `ended`**: controller test failed expecting `ended` false at `example/test/snake_controller_test.dart:346`.

Restored green run after all probes:

```text
$ cd example && flutter test
00:04 +39: All tests passed!
```

Tree left restored: collision early-return and `setState(_startNewRun)` intact; title still `_controller.ended ? 'Snake — ended' : 'Snake'`.

## Per-criterion results

| Criterion | Result | Evidence (file:line) | Negative case exercised |
|---|---|---|---|
| AC-001 | pass | `example/lib/snake_controller.dart:297-299` (wall/body sets `ended` without advancing); wall test `example/test/snake_controller_test.dart:150-193` asserts ended, head `(4,1)`, cells/heading/food unchanged; injected predict only. | yes — wall-advance probe failed head assertion at `:172` |
| AC-002 | pass | Same collision path `:297-299`; body test `example/test/snake_controller_test.dart:195-235` asserts ended, head `(0,1)`, cells unchanged. | yes — same wall-advance-style defect would fail body cells/head asserts at `:219-221` (body path shares `_applyChoiceAndAdvance`) |
| AC-003 | pass | `example/lib/snake_controller.dart:241-243` early return when ended; further-step asserts at `example/test/snake_controller_test.dart:187-192` and `:231-234`. | yes — mutate-while-ended probe failed cells assert at `:191` |
| AC-004 | pass | Constructor defaults `example/lib/snake_controller.dart:121-127`, `ended` false `:164`; new-run group `example/test/snake_controller_test.dart:245-334` restores `(2,0),(1,0),(0,0)`, east, food not on body. | yes — skipping new-run leaves ended/frozen (`:267-271`); wrong defaults would fail `:285-289` / `:326-330` |
| AC-005 | pass | Post-new-run step at `example/test/snake_controller_test.dart:291-293` and `:332-333` asserts cells leave default start. | yes — cells-already-default-before-new-run blocked by `:271` / `:317`; no-move after new-run would fail `:292` / `:333` |
| AC-006 | pass | `example/lib/snake_screen.dart:90-117` (`_startNewRun` then continue same loop); widget test `example/test/snake_screen_test.dart:96-129` with `predictOverride` and `LoadedRuntime.validationOnly()`; session-open source scan `:69-94`. | yes — remove-new-run probe failed `predictCalls >= 2` at `:124` |
| AC-007 | pass | Source review `example/lib/snake_screen.dart` (no Timer / Future.delayed / Ticker); death path `:115-116` immediate `setState(_startNewRun)`; tests `example/test/snake_screen_test.dart:30-38` and `:155-161`. | yes — inserting `Timer` / `Future.delayed` / `Ticker` would fail `:34-36` |
| AC-008 | pass | Single `_runSteps()` call site guarded by `_loopStarted` at `example/lib/snake_screen.dart:76-78`; death continues inside same method `:90-117`; source check `example/test/snake_screen_test.dart:155-158`. | yes — a second `_runSteps();` call site would fail length `1` at `:158` |
| AC-009 | pass | Title `example/lib/snake_screen.dart:136`; after restart widget test `example/test/snake_screen_test.dart:125-126` finds `Snake`, not `Snake — ended`. | yes — always-ended title probe failed `:125` |
| AC-010 | pass | Predict catch leaves `ended` false `example/lib/snake_controller.dart:252-259`; screen stop without new-run `example/lib/snake_screen.dart:104-107`; controller `example/test/snake_controller_test.dart:336-348`; screen `example/test/snake_screen_test.dart:132-152`; missing/non-relative also leave `ended` false (`:655-714`). | yes — predict-failure sets `ended` probe failed `:346` |
| AC-011 | pass | Controller and screen death/restart proofs inject predict / `predictOverride`; `validationOnly` used; no `LayaFlutter.open` / session create in screen or its tests (`example/test/snake_screen_test.dart:69-94`). This review treats the green VM suite as session-free proof only, not host session-load. | yes — meta: opening a session in these proofs would fail the open-source scan; this review does not claim ONNX load |

## Findings

None.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no
- Escalation: not recommended

## Routing

| Finding | Belongs to phase |
|---|---|
| (none) | — |
