# Research: What one finished Snake step already knows for a choice log

## Question

What does one finished example Snake step already know that a developer log can record so a reader
can see why the model picked left, right, or straight — including the English state, the chosen key,
and the per-key probabilities — without changing the prompt, the relative-turn rules, or adding a
timer?

## Answer

After a successful `predict` inside `SnakeController.step`, the example already holds the full
English state string sent to the model, the `turn` choice key (`left` / `right` / `straight`), and
that answer’s per-key `probabilities` map. Logging those three values is enough for a reader to see
that straight won while Ahead was wall, and that food was not in the ahead cell, because those facts
are already spelled in the state string. The step today keeps only the choice string for the move
and discards the rest; nothing new is needed from the model or the library API.

## Findings

### Closed assumptions forbid changing the prompt surface, relative keys, or adding a timer

- Claim: Snake already uses relative left / right / straight, has no step timer, and the short
  English state plus choice id `turn` are a fixed prompt contract. A shield that overrides the model
  is rejected. This slice must not reopen those.
- Evidence: GOAL closed assumptions and SC-003; classic-snake-example product note; shared decisions
  for work item 0008.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 28–32, 43–43;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md` lines
  15–25.

### Prior solutions do not answer this logging question

- Claim: The only solutions entry concerns macOS ONNX session load and sandbox cache exceptions. It
  does not define a Snake step record or developer choice log.
- Evidence: Solution summary and guidance are about `integration_test` and entitlements.
- Source:
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`
  lines 1–40.

### The English state string already names Ahead occupancy and food

- Claim: `buildStateString` returns one short English line with heading name, head cell, food cell
  or `none`, and neighbour classifications for Left, Right, and Ahead as `wall`, `body`, `food`, or
  `empty`. A reader of that string can see `Ahead wall` and can see that food is not ahead when
  Ahead is not `food` (food may still appear as a separate `Food (col,row)` clause elsewhere on the
  board).
- Evidence: State builder and `_classify` implementation.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines
  143–157, 278–288.

### A finished successful step already has the chosen key and per-key probabilities

- Claim: `step` builds that state string, awaits `predict`, then reads `answers['turn']?.choice`.
  The library’s choice answer also carries `probabilities` keyed by the same criteria labels and a
  `confidence` value. For the turn question those keys are `left`, `right`, and `straight`. The
  controller currently uses only the choice string and does not retain or print the probabilities.
- Evidence: `step` locals and early returns; `LayaAnswer.choice` fields; turn criteria keys; test
  double that already supplies a three-key probability map.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines
  160–198; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart` lines 55–66,
  108–112, 242–258;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/snake_controller_test.dart` lines
  479–489.

### The screen never sees the model answer fields

- Claim: `SnakeScreen` wires `runtime.predict` into the controller and only awaits `step`, then
  redraws cells. It does not read state text, choice, or probabilities. Any developer-visible record
  must therefore come from data available inside the controller step (or an equivalent seam that
  still uses the same predict result), not from the board widget.
- Evidence: Predict closure and `_runSteps` await `step` then `setState` only.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart` lines
  32–38, 57–73, 88–108.

### Minimal record that answers the reader questions without new model input

- Claim: For a step that obtains a relative turn key, recording (1) the `state` string already built
  for that predict, (2) the chosen `turn` key, and (3) `answers['turn'].probabilities` lets a reader
  judge whether `straight` won while the state said `Ahead wall`, and whether food was not in the
  ahead cell, without changing prompt wording, choice keys, collision rules, or adding a timer or
  shield.
- Evidence: State string content (finding above) plus choice and probabilities already returned by
  shaping; GOAL forbids a timer-driven step.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines
  143–198; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart` lines 253–258;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 32–32, 43–43.

### Failed or incomplete steps know less than a successful choice

- Claim: On predict throw, missing `turn` answer, or a non-relative choice key, `step` returns
  without advancing and without applying a turn. In those paths there is either no answer map or no
  usable choice; probabilities may be absent. A log of “why the model picked” applies only when a
  relative key was obtained; board-only observation after a no-move return cannot invent
  probabilities.
- Evidence: Catch and null / non-relative early returns leave cells unchanged; screen stops further
  steps when cells do not change and the game is not ended.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart` lines
  189–197; `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart` lines
  67–72; `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md`
  lines 21–25.

## Options considered

| Option                                                                                                                     | How it works                                                                                                                                 | Cost                                                                                                           | Why rejected / chosen                                                                                                                                                                                                   |
|----------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Log the three values already local after a successful predict: English `state`, `turn` choice key, and `probabilities` map | Emit or retain that triple from inside `step` (or an equivalent example-only seam) without changing `buildStateString` / `buildTurnQuestion` | One developer-visible record per successful model choice; no library API change                                | **Chosen.** Matches the question’s required fields; Ahead wall and food-not-ahead are already readable from the state string; probabilities explain the win among left / right / straight.                              |
| Infer “why” only from the board after the move (heading, cells, food) plus the applied key                                 | Reconstruct neighbour labels from post-step geometry; never keep the answer map                                                              | No probability data; cannot show that straight won while Ahead was wall unless the pre-step state is also kept | **Rejected.** Loses per-key probabilities and risks reading post-move cells instead of the pre-step English state the model saw.                                                                                        |
| Add a second structured neighbour / food payload beside the English state                                                  | Duplicate Ahead / Left / Right / Food as typed fields for the log                                                                            | Extra example surface; still must keep choice and probabilities                                                | **Rejected for the minimal record.** Useful only if prose parsing of the state string is considered insufficient; the shared decision already treats the English state as enough to tell Ahead wall and food-not-ahead. |

## Constraints discovered

- Relative turn keys and the fixed prompt contract (`turn` + English state) stay closed (
  `wiki/product/GOAL.md` line 32; `wiki/product/classic-snake-example.md` lines 15–19).
- No step timer, decorative ticker, or pacing delay (`wiki/product/GOAL.md` line 32, 43;
  `wiki/product/classic-snake-example.md` lines 21–23).
- No safety shield that overrides the model (`wiki/product/classic-snake-example.md` lines 15–17).
- Library open / predict API stays closed; the record is example-side observation of an existing
  `LayaAnswer` (`wiki/product/classic-snake-example.md` line 35; `lib/src/answers.dart` lines 55–66,
  108–112).
- Work item 0007-restart-on-death is out of scope for this record’s design (shared decision for
  0008).
- Confidence is already on `LayaAnswer` but is not required to answer “which key won and what the
  board said” (`lib/src/answers.dart` lines 111–112).

## Unresolved

- [UNRESOLVED: Whether the developer-visible sink should be `debugPrint`,
  `dart:developer` log, an in-memory list on the controller, or another example-only channel — emission and test capture are outside this research boundary.]
- [UNRESOLVED: Whether a failed or incomplete predict should emit a distinct “no choice” record that includes only the pre-built state string, or stay silent.]
- [UNRESOLVED: Whether
  `confidence` should be included in the default record alongside the three required fields.]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/classic-snake-example.md`, consulted
  2026-09-28
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`,
consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_controller.dart`, consulted
  2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/snake_screen.dart`, consulted
  2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/answers.dart`, consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/test/snake_controller_test.dart`,
  consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/templates/00-research.md`, consulted
  2026-09-28
