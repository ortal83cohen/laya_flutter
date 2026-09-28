# Research: Classic Snake example

## Question

How should the classic Snake example ask `laya-multilingual` for a relative turn, and how should the board advance one cell only after that answer returns, with no periodic ticker?

## Answer

**Prompt (`research/prompt.md`):** Send one short English `choice` question whose keys are `left`, `right`, and `straight`, each described as a turn relative to the current heading. Put the board in the state as a short English string or a string map: cardinal heading, head and food cells, and the cell immediately left, right, and straight of the head. Do not use absolute `UP`/`DOWN`/`LEFT`/`RIGHT` as the choice keys, and do not use boolean-word keys.

**Step loop (`research/step-loop.md`):** Await `LoadedRuntime.predict`, then turn from the returned choice and advance exactly one cell. Do not schedule `Timer.periodic` or a step `Ticker`. A logic test holds predict incomplete, elapses fake time, and asserts the snake does not move until that future completes.

These are different questions. They do not contradict each other.

## Findings

### Closed product action space is relative turns

- Claim: The example asks for a left turn, a right turn, or straight ahead relative to the current heading. A wall or the snake's own body ends the game, food appears on a random empty cell, and there is no step timer.
- Evidence: Closed assumptions and SC-003.
- Source: `research/prompt.md` and `research/step-loop.md`, both citing `wiki/product/GOAL.md` lines 15–16, 32, and 43.

### Public predict is a Future the example must await

- Claim: `LoadedRuntime.predict` returns `Future<Map<String, LayaAnswer>>`. `state` is a `String` or a `Map` of `String` to `String`. A choice question's criteria are a label-to-description map. `LayaAnswer.choice` is the criteria key at softmax argmax. The library does not schedule game steps.
- Evidence: `predict` signature; `LayaQuestion` and answer shaping.
- Source: `research/prompt.md` and `research/step-loop.md`, citing `lib/src/loaded_runtime.dart` lines 56–63, `lib/src/answers.dart` lines 28–66 and 242–258, `lib/laya_flutter.dart`, and `lib/src/library.dart`.

### Choice keys are rendered verbatim; boolean-word keys are unsafe

- Claim: Each option the model reads is `key` or `key: description`. Upstream says checkpoints can follow `true`/`false` or `yes`/`no` instead of the descriptions. Semantic or opaque labels are the documented alternatives.
- Evidence: `renderOptions`; Honest limits in the Laya README.
- Source: `research/prompt.md`, citing `lib/src/tokenize.dart` lines 120–133 and `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md` lines 970–973, consulted 2026-09-27.

### Community Snake demos use absolute directions

- Claim: omp-laya-judge and laya-mlx ask for `UP`/`DOWN`/`LEFT`/`RIGHT`, often with planner text and a safety shield. That shows short Snake choice calls exist. It does not replace this product's relative-turn rule.
- Evidence: `demo/snake.py` criteria over direction keys; laya-mlx Snake demo docs.
- Source: `research/prompt.md`, citing `https://raw.githubusercontent.com/F0Rextasy/omp-laya-judge/main/demo/snake.py` lines 88–97 and `https://raw.githubusercontent.com/mizorewww/laya-mlx/main/docs/SNAKE_DEMO.md`, consulted 2026-09-27.

### Timer.periodic and Ticker are not predict gates

- Claim: `Timer.periodic` repeats on a `Duration`. A `Ticker` fires once per frame while enabled. Neither waits for `predict`. An async loop can `await` predict, then move one cell, via a recursive async call or `Future.doWhile`.
- Evidence: Flutter API docs for `Timer.periodic`, `Ticker`, `Future`, and `Future.doWhile`.
- Source: `research/step-loop.md`, citing those API pages, consulted 2026-09-27.

### Fake time proves a timer did not move the snake

- Claim: A test can inject a predict future that stays incomplete, elapse fake time or `WidgetTester.pump` a long duration, and assert the snake cells are unchanged. Completing the future then advances one cell.
- Evidence: `FakeAsync.elapse` and `WidgetTester.pump`.
- Source: `research/step-loop.md`, citing the fake_async and WidgetTester docs, consulted 2026-09-27.

### The example is still a skeleton

- Claim: `example/lib/main.dart` has no Snake board, no predict call, and no timer. The macOS sandbox solution does not prescribe Snake control.
- Evidence: Example home page; solution summary.
- Source: `research/step-loop.md`, citing `example/lib/main.dart` lines 10–50 and `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Relative keys `left` / `right` / `straight` plus a short English state | One choice question; the returned key is the relative turn | Three short options | **Chosen** (`research/prompt.md`). Matches the closed action space and avoids boolean-word keys. |
| Absolute keys `UP` / `DOWN` / `LEFT` / `RIGHT` | Model ranks screen directions; demos often add a shield | Four options plus planner text | **Rejected** (`research/prompt.md`). Reopens the relative-turn rule. |
| Opaque keys `A` / `B` / `C` | Descriptions carry the turn meaning | Extra key-to-turn table | **Rejected as the default** (`research/prompt.md`). Fallback only if a measured run shows the semantic keys fail. |
| Await-gated async step loop | Await predict, then move one cell. No periodic timer, no step ticker | Step rate equals model latency | **Chosen** (`research/step-loop.md`). |
| `Timer.periodic` as the step clock | Move or start predict on an interval | Arcade cadence | **Rejected** (`research/step-loop.md`). It is a step timer. |
| Frame `Ticker` as the step driver | Advance on animation frames | Smooth clock | **Rejected** (`research/step-loop.md`). It is a periodic ticker. |

## Constraints discovered

- Relative left, right, and straight are closed (`wiki/product/GOAL.md` line 32).
- Choice keys must not be boolean words (Laya README Honest limits, consulted 2026-09-27).
- State is a string or a string map (`lib/src/loaded_runtime.dart` lines 58–59).
- One cell advances only after predict completes (`research/step-loop.md`).
- The absence-of-timer proof is a logic test and must not require a real ONNX session (`research/step-loop.md`, citing the macOS session solution).
- This slice does not redesign `predict` (`wiki/work/0003-classic-snake/STATE.yaml`).

## Unresolved

- [UNRESOLVED: whether a measured `laya-multilingual` run prefers prose state, a JSON string map, relative food offsets, or absolute coordinates for the same relative-turn question.] (`research/prompt.md`)
- [UNRESOLVED: whether opaque `A`/`B`/`C` keys beat semantic `left`/`right`/`straight` on Snake board states for this checkpoint.] (`research/prompt.md`)
- [UNRESOLVED: whether planner-enriched per-option descriptions are required for a long surviving run, given community demos claim unassisted greedy choice scores poorly, while SC-003 only requires correct classic mechanics and a model-chosen turn each step.] (`research/prompt.md`)
- [UNRESOLVED: whether a decorative UI `Ticker` or `AnimationController` (for drawing only, never calling the step mutator) is allowed, or whether SC-003's "absence of a periodic ticker" requires zero tickers in the Snake screen.] (`research/step-loop.md`)
- [UNRESOLVED: whether an optional minimum visual delay after predict (a one-shot `Future.delayed` or non-periodic `Timer`) is compatible with "no step timer", or whether any timer-based pacing after predict fails SC-003.] (`research/step-loop.md`)
- [UNRESOLVED: exact package layout of the injectable predict seam (pure Dart controller under `example/lib` versus a thin wrapper) — both can await the same public `predict` Future.] (`research/step-loop.md`)

## Sources

- `research/prompt.md` and `research/step-loop.md`, consulted 2026-09-27.
- Sources listed in those two files, consulted 2026-09-27.

## Provenance

- Prompt findings, the three prompt options, and the first three unresolved items: `research/prompt.md`.
- Step-loop findings, the three loop options, and the last three unresolved items: `research/step-loop.md`.
- Shared API and goal claims are collapsed to one entry citing both files.
