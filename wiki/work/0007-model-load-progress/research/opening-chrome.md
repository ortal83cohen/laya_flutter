# Research: Opening chrome and room for load-progress UI

## Question

Where does the example show Opening… while LayaFlutter.open is in progress, which tests lock that chrome, and where can an additional English label "Loading the model" plus a progress meter be shown without breaking those locks?

## Answer

Opening… is rendered only on `ExampleHomePage` while the private `_opening` flag is true, which covers the await of `LayaFlutter.open` before navigation to Snake. The locks are the example widget test’s idle absence of Opening…, its source scan that Opening… and the open-failure prefix must remain, and the frozen 0005 acceptance criteria that reuse that opening chrome. The safe place for "Loading the model" and a progress meter is as additional siblings inside the same `_opening` body branch, without removing or renaming Opening… and without changing when `_opening` becomes true on the default-off tree.

## Findings

### Opening… lives on the example home under `_opening`

- Claim: `_ExampleHomePageState` keeps `_opening`. `_openSnake` returns early if already opening, then `setState` sets `_opening` to true and clears `_error`, awaits `LayaFlutter.open(await resolveExampleCache())`, pushes `SnakeScreen` on success, sets `_error` with prefix `Could not open runtime:` on failure, and in `finally` sets `_opening` back to false when still mounted. The body `Column` shows `const Text('Opening…')` only when `_opening` is true.
- Evidence: Flag and open path at `example/lib/main.dart:89-141`; conditional chrome at `example/lib/main.dart:157-160`; failure text at `example/lib/main.dart:129-133`.
- Source: `example/lib/main.dart`

### Production entry schedules that path; default construction does not

- Claim: Production `main` constructs `ExampleApp(autostart: true)`. `ExampleApp` and `ExampleHomePage` default `autostart` to false. When `autostart` is true, `didChangeDependencies` schedules a single post-frame call to `_openSnake`. When false, that schedule does not run, so a bare mount stays idle and does not enter the Opening… branch.
- Evidence: Entry at `example/lib/main.dart:16-18`; defaults at `example/lib/main.dart:59` and `example/lib/main.dart:79`; schedule guard at `example/lib/main.dart:93-104`.
- Source: `example/lib/main.dart`

### Widget tests lock Opening… presence in source and absence when idle

- Claim: The idle widget test pumps `const ExampleApp()`, pumps a second frame, expects `Laya` present, and expects `Opening…` absent so the idle pump must not open a session. A separate source test requires `lib/main.dart` to contain the substring `Opening…`, the failure prefix `Could not open runtime:`, navigation to `SnakeScreen` after success, no `Play Snake`, production `autostart: true`, default `this.autostart = false`, and no await before `runApp`. The catch-block scan forbids navigating to Snake on open failure.
- Evidence: Idle pump at `example/test/widget_test.dart:7-18`; production entry scan at `example/test/widget_test.dart:20-38`; autostart chrome scan at `example/test/widget_test.dart:40-86`.
- Source: `example/test/widget_test.dart`

### Frozen 0005 criteria treat Opening… as the required opening label

- Claim: AC-001 requires that production launch not show a play button and that the existing opening label appear while open is in progress before Snake. AC-002 requires existing open-failure text and no Snake on failure. AC-003 through AC-005 require that a single widget-test pump of the default root not show the opening label, show Laya, and not open a session on mount. Explicit non-requirements include goal_check null and no library open or predict changes for that slice.
- Evidence: Criteria table at `wiki/work/0005-autostart-snake/02-criteria.md:10-16`; non-requirements at `wiki/work/0005-autostart-snake/02-criteria.md:24-35`.
- Source: `wiki/work/0005-autostart-snake/02-criteria.md`

### Product note forbids idle open and keeps session proof off the VM home pump

- Claim: The classic Snake product note states that production starts Snake with no play button via autostart, that the VM widget-test tree uses default autostart off and must not open a session on mount or a follow-up frame, and that host session proof stays on the macOS integration path from the sandbox solution. Snake rules and the closed “no step timer” GOAL assumption are unchanged by home chrome.
- Evidence: Test and open constraints at `wiki/product/classic-snake-example.md:31-35`; no step timer at `wiki/product/GOAL.md:32`; sandbox VM guidance at `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:23-30`.
- Source: `wiki/product/classic-snake-example.md`; `wiki/product/GOAL.md`; `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`

### No progress meter exists in the example today

- Claim: Under `example/`, there is no `ProgressIndicator`, `LinearProgressIndicator`, or `CircularProgressIndicator` usage. Any meter is new UI on the home open path, not an existing widget to extend.
- Evidence: Search over `example/**` for those identifiers returned no matches (this research run, 2026-09-28).
- Source: repository search under `example/`

### Shared slice decisions already fix the new label and keep Opening…

- Claim: For this work item the visible English label to add is exactly "Loading the model", it appears on the example home while runtime open is in progress, the existing string Opening… must remain because `example/test/widget_test.dart` requires it, and `goal_check` for this slice is null.
- Evidence: Work-item `goal_check: null` at `wiki/work/0007-model-load-progress/STATE.yaml:21`; Opening… source lock at `example/test/widget_test.dart:48-52`; home open chrome at `example/lib/main.dart:157-160`. Shared decisions were supplied in the research prompt and are not reopened here.
- Source: `wiki/work/0007-model-load-progress/STATE.yaml`; `example/test/widget_test.dart`; `example/lib/main.dart`

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| A. Add "Loading the model" and a progress meter as siblings inside the existing `if (_opening)` column branch, keep `Text('Opening…')` unchanged | Same `_opening` gate that already wraps the await of `LayaFlutter.open`; idle default-off pump still shows neither Opening… nor the new chrome | Small example-only UI edit; source scan for Opening… still passes; idle absence still passes if `_opening` stays false on default mount | **Chosen** — satisfies the fixed label and home placement without renaming or removing the locked Opening… string |
| B. Replace Opening… with "Loading the model" (or show only the new label) | Single status string while open runs | Breaks `source.contains('Opening…')` and AC-001’s “existing opening label” wording | **Rejected** — shared decision and `example/test/widget_test.dart:48-52` require Opening… to remain |
| C. Full-screen Stack / modal overlay while `_opening`, while still keeping a `Text('Opening…')` somewhere in the tree for the source scan | Overlay can host the new label and meter; Opening… kept only to satisfy the substring lock | Higher layout churn; risk of hiding Opening… from finders if a later widget test looks for it during open; still must not schedule open on the idle tree | **Rejected** for this question — viable but unnecessary when the column branch already is the open chrome surface |

## Constraints discovered

- Opening… must remain as a literal string in `example/lib/main.dart` (`example/test/widget_test.dart:48-52`; AC-001 at `wiki/work/0005-autostart-snake/02-criteria.md:12`).
- Idle `const ExampleApp()` after a second pump must not show Opening… (`example/test/widget_test.dart:7-18`; AC-003/AC-005 at `wiki/work/0005-autostart-snake/02-criteria.md:14-16`). Any new chrome gated on `_opening` inherits that idle absence.
- Open-failure prefix `Could not open runtime:` and non-navigation on catch remain locked (`example/test/widget_test.dart:53-85`; AC-002).
- Production entry must keep synchronous `runApp` with `autostart: true` and default-off constructors (`example/test/widget_test.dart:20-38`).
- VM home pump is not session-load proof; scheduling open from the default tree breaks VM tests (`wiki/product/classic-snake-example.md:31-35`; `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:23-30`).
- This research must not change library signatures beyond naming that constraint; ONNX session progress APIs and download byte counts are out of boundary. A meter can still be shown as UI chrome while `_opening` is true without those APIs ([UNVERIFIED: whether a later stream will feed determinate fraction into the meter or leave it indeterminate]).
- GOAL closed assumptions stay closed: no Snake step timer; weights stay out of the package (`wiki/product/GOAL.md:25-32`). This slice’s `goal_check` is null (`wiki/work/0007-model-load-progress/STATE.yaml:21`).

## Unresolved

- [UNRESOLVED: Whether a future widget or source test will assert the exact string "Loading the model" or the presence of a progress meter — none does today.]
- [UNRESOLVED: Whether the progress meter should be determinate or indeterminate once another stream supplies progress values — out of this stream’s boundary.]
- [UNRESOLVED: Whether accessibility or localization rules beyond the fixed English string will constrain the meter widget choice.]

## Sources

- `wiki/product/GOAL.md`, consulted 2026-09-28
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-28
- `example/lib/main.dart`, consulted 2026-09-28
- `example/test/widget_test.dart`, consulted 2026-09-28
- `wiki/work/0005-autostart-snake/02-criteria.md`, consulted 2026-09-28
- `wiki/product/classic-snake-example.md`, consulted 2026-09-28
- `wiki/work/0007-model-load-progress/STATE.yaml`, consulted 2026-09-28
- `wiki/templates/00-research.md`, consulted 2026-09-28
