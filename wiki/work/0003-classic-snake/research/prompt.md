# Research: Classic Snake prompt for relative turns

## Question

What state text and choice labels should the classic Snake example send to
`convaiinnovations/laya-multilingual` so the model returns a left turn, a right turn, or straight,
relative to the snake's heading?

## Answer

Send one short English `choice` question whose criteria keys are `left`, `right`, and `straight`,
each with a description that says the turn is relative to the current heading. Put the board
situation in `predict`'s state as a short English string or a string map that names the heading in
cardinal words, the head and food cells, and what sits immediately left, right, and straight of the
head. Do not use absolute `UP`/`DOWN`/`LEFT`/`RIGHT` as the three choice keys, and do not use
boolean-word choice keys such as `yes`/`no` or `true`/`false`.

## Findings

### Closed product action space is relative turns

- Claim: The product's classic Snake example must ask the model for a left turn, a right turn, or
  straight ahead relative to the current heading. A wall or the snake's own body ends the game, food
  appears on a random empty cell, and there is no step timer.
- Evidence: Closed assumptions and SC-003 spell that action space and those rules; the example is
  one app, not a game engine.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 26–27, 32–32,
  43–43.

### Public Flutter API already accepts the needed call shape

- Claim: After `LayaFlutter.open`, a caller runs offline `LoadedRuntime.predict(state, questions)`.
  `state` must be a `String` or a `Map` of `String` to `String`. A `choice` question needs
  `instructions` and `criteria` as a map from label to description. The returned `LayaAnswer.choice`
  is the criteria key at softmax argmax.
- Evidence: `predict` documents the state and question shapes; `LayaQuestion` documents choice
  criteria as label → description; shaping sets `choice` to `keys[best]`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/loaded_runtime.dart` lines 56–63;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart` lines 28–49, 57–66,
  197–202, 242–258; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart` lines
  14–58.

### Choice keys are rendered verbatim into the option text

- Claim: For a choice question, each option the model reads is `key` alone when the description is
  empty, otherwise `key: description`, in map-entry order. Therefore the returned label is exactly
  the key string the example must map to a game turn.
- Evidence: `renderOptions` builds that string form; fixture and parity paths already use semantic
  keys such as `red` / `green` / `blue`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart` lines 120–133;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/test/fixtures/parity_fixtures.json` lines 11–18;
  `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md` Honest limits (choice keys
  rendered verbatim), consulted 2026-09-27.

### Upstream honest limit forbids boolean-word choice labels

- Claim: Upstream documents that current checkpoints can follow choice keys such as `true`/`false`
  or `yes`/`no` instead of the option descriptions. Callers should use semantic labels or opaque
  labels such as `A`/`B`, and validate on the checkpoint and states they serve.
- Evidence: Honest limits bullet "Avoid boolean-word labels in `choice` questions."
- Source: `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md` lines 970–973 (
  Honest limits), consulted 2026-09-27.

### Community Snake demos use absolute directions and planner features, not this product's action space

- Claim: Published community Snake demos ask Laya for a distribution over `UP`/`DOWN`/`LEFT`/
  `RIGHT`, with planner-written per-direction descriptions and often a safety shield. That pattern
  is evidence that short semantic choice criteria work for Snake-like calls, but it does not
  redefine this product's closed relative-turn assumption.
- Evidence: omp-laya-judge `demo/snake.py` builds `criteria` over `DIRS` keys and a compact state
  about safe route and food reachability; laya-mlx Snake demo docs state Laya returns probabilities
  over UP, DOWN, LEFT, and RIGHT. Prior API research already treated those demos as caller patterns,
  not the library ceiling.
- Source: `https://raw.githubusercontent.com/F0Rextasy/omp-laya-judge/main/demo/snake.py` lines 1–9,
  88–97; `https://raw.githubusercontent.com/mizorewww/laya-mlx/main/docs/SNAKE_DEMO.md` section "
  What the AI does", consulted 2026-09-27;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0002-offline-predict/research/api-surface.md`
  lines 55–59.

### Recommended state and choice text for this example

- Claim: The example should send a situation that names heading with cardinal words (`north` /
  `east` / `south` / `west`), head and food coordinates, body occupancy as needed, and the immediate
  cell ahead / to the relative left / to the relative right (`empty`, `wall`, `body`, or `food`).
  The single game-driving question should be a `choice` with instructions such as "Choose the next
  turn relative to the snake's current heading." and criteria:
    - `left` → turn left relative to the current heading
    - `right` → turn right relative to the current heading
    - `straight` → keep the current heading
      The game maps the returned key to a new heading, then steps one cell. Extra `score` or `noul`
      questions are optional for demos and are not required by SC-003.
- Evidence: GOAL requires relative left / right / straight; the Flutter API returns the choice key;
  upstream forbids boolean-word keys and renders keys verbatim; short English states already work on
  the multilingual checkpoint in the frozen fixtures.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 32–32, 43–43;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart` lines 242–258;
  `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md` lines 970–973;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/test/fixtures/parity_fixtures.json` lines 7–18.

### Prior solution does not answer this prompt question

- Claim: The only solutions entry on 2026-09-27 concerns macOS ONNX session load and sandbox cache
  exceptions. It does not prescribe Snake state text or choice labels.
- Evidence: Solution summary and guidance are about `integration_test` and entitlements.
- Source:
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`
  lines 1–40.

## Options considered

| Option                                                                                                                                       | How it works                                                                                                                | Cost                                                                                       | Why rejected / chosen                                                                                                                                                                                                          |
|----------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Relative semantic keys (`left` / `right` / `straight`) plus short English or string-map state with cardinal heading and immediate cell facts | One `choice` question; returned key is applied as a relative turn; state avoids putting the turn words only in boolean keys | Three short option strings; no planner or shield required by SC-003                        | **Chosen.** Matches the closed relative-turn assumption, avoids boolean-word keys, and maps 1:1 from `LayaAnswer.choice` to the game step.                                                                                     |
| Absolute cardinal keys (`UP` / `DOWN` / `LEFT` / `RIGHT`) with planner descriptions, as in omp-laya-judge / laya-mlx                         | Model ranks screen directions; caller often adds a safety shield and planner features in state and criteria                 | Four options; usually needs planner text and shield logic for the demos' reported survival | **Rejected for this product's action labels.** Useful as evidence that short Snake-related choice calls work, but it reopens the closed relative-turn assumption.                                                              |
| Opaque keys (`A` / `B` / `C`) whose descriptions alone carry left / right / straight meaning                                                 | Same three relative actions; keys are opaque so the model cannot follow a turn word in the key                              | Needs a fixed key→turn table in the example; logs are harder to read                       | **Rejected as the default.** Valid fallback if a measured run shows label-following on `left`/`right`/`straight`, but upstream already allows semantic labels when validated, and the product wording names those three turns. |

## Constraints discovered

- Action space is closed: relative left / right / straight only (`wiki/product/GOAL.md` line 32).
- Choice keys must not be boolean words (`true`/`false`, `yes`/`no`) because they are rendered
  verbatim and can dominate descriptions (
  `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md` Honest limits, consulted
  2026-09-27).
- `criteria` for choice must be a label→description map; the library returns the key, not the
  description (`lib/src/answers.dart` lines 47–49, 242–258; `lib/src/tokenize.dart` lines 120–133).
- State must be a `String` or `Map` of `String` to `String` (`lib/src/loaded_runtime.dart` lines
  58–59; `lib/src/tokenize.dart` lines 98–108).
- Do not redesign the library API for Snake; Snake is an example that uses a short `choice` call (
  `wiki/work/0003-classic-snake/STATE.yaml` lines 20–21;
  `wiki/work/0002-offline-predict/research/api-surface.md` lines 55–59).
- Three options sit in the `choice:3-5` temperature bucket path already used by the English parity
  fixture's three-color choice (`lib/src/answers.dart` lines 127–139;
  `test/fixtures/parity_fixtures.json` lines 11–18).

## Unresolved

- [UNRESOLVED: whether a measured
  `laya-multilingual` run prefers prose state, a JSON string map, relative food offsets, or absolute coordinates for the same relative-turn question.]
- [UNRESOLVED: whether opaque `A`/`B`/`C` keys beat semantic `left`/`right`/
  `straight` on Snake board states for this checkpoint.]
- [UNRESOLVED: whether planner-enriched per-option descriptions are required for a long surviving run, given community demos claim unassisted greedy choice scores poorly, while SC-003 only requires correct classic mechanics and a model-chosen turn each step.]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`,
consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/loaded_runtime.dart`, consulted
  2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/test/fixtures/parity_fixtures.json`, consulted
  2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0002-offline-predict/research/api-surface.md`,
consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0003-classic-snake/STATE.yaml`,
  consulted 2026-09-27
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md`, consulted 2026-09-27
- `https://raw.githubusercontent.com/F0Rextasy/omp-laya-judge/main/demo/snake.py`, consulted
  2026-09-27
- `https://raw.githubusercontent.com/mizorewww/laya-mlx/main/docs/SNAKE_DEMO.md`, consulted
  2026-09-27
