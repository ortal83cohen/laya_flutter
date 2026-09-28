# Research: Log every Snake model choice with the state that produced it

## Question

What should one example Snake step record, and how can a logic test prove the record exists, so a
person running the example can see why the model picked left, right, or straight — including when it
did not move toward food or away from a wall — without changing the prompt, the relative-turn rules,
or adding a timer?

## Answer

After a successful predict, the controller already holds the English state the model saw, the turn
key, and that answer’s probabilities and confidence. The running example should print one line per
finished step with those fields. Logic tests prove the record through an injected in-memory
callback, the same style as the existing predict double, and must not open an ONNX session. A step
that receives a relative key and emits no record fails that test. A predict failure or a missing or
non-relative key is recorded as no choice, with the pre-step state and a reason, and still does not
invent a turn or advance.

## Findings

### The English state already shows Ahead and food

- Claim: `buildStateString` names the heading, the head cell, the food cell or `none`, and Left,
  Right, and Ahead as wall, body, food, or empty. A reader of that string can see `Ahead wall` and
  can see that food is not the ahead cell.
- Evidence: State builder and neighbour classification.
- Source: `example/lib/snake_controller.dart` lines 143–157 and 278–288. Stream:
  `wiki/work/0008-snake-choice-log/research/step-record.md`.

### A successful step already has the key, probabilities, and confidence

- Claim: `step` awaits predict and reads `answers['turn']?.choice`. The turn question’s criteria
  keys are `left`, `right`, and `straight`. A choice answer carries a `probabilities` map and a
  `confidence` value. The controller uses only the choice string today.
- Evidence: Step body, turn criteria, and `LayaAnswer.choice` fields.
- Source: `example/lib/snake_controller.dart` lines 160–171 and 179–198; `lib/src/answers.dart`
  lines 55–66 and 93–112. Stream: `wiki/work/0008-snake-choice-log/research/step-record.md`.

### The screen never sees the answer

- Claim: `SnakeScreen` awaits `step` and redraws cells. It does not read state text, choice, or
  probabilities. The record has to be produced where the answer is already in hand.
- Evidence: Predict wiring and the step loop.
- Source: `example/lib/snake_screen.dart` lines 32–38 and 57–73. Stream:
  `wiki/work/0008-snake-choice-log/research/step-record.md`.

### No developer-log API exists in this repository

- Claim: No Dart source calls `debugPrint`, `print`, `dart:developer` `log`, or a `Logger`. Example
  tests observe Snake by injecting `predict` and capturing locals. That proves the request, not that
  a choice was recorded after the answer returned.
- Evidence: Repository search recorded in the test-capture stream; capture test and controller
  surface.
- Source: `wiki/work/0008-snake-choice-log/research/test-capture.md`;
  `example/test/snake_controller_test.dart` lines 302–366; `example/lib/snake_controller.dart` lines
  42–114.

### Board movement is not proof of a record

- Claim: Asserting heading or cells after a relative choice can pass even if nothing was recorded.
  The check must fail when a relative choice is accepted and no record is emitted.
- Evidence: Choice application versus board-only tests.
- Source: `example/lib/snake_controller.dart` lines 194–198;
  `example/test/snake_controller_test.dart` lines 85–120. Stream:
  `wiki/work/0008-snake-choice-log/research/test-capture.md`.

### Closed product rules stay closed

- Claim: Relative keys, the English state and `turn` prompt, the ban on a step timer, and the ban on
  a shield that overrides the model stay closed. The library open and predict API stays closed.
  Logging does not advance a goal success check. Restart-on-death is a separate work item,
  `0010-restart-on-death`.
- Evidence: GOAL closed assumptions and SC-003; classic Snake prompt and timer constraints; the
  library API freeze sentence; the restart work item’s title.
- Source: `wiki/product/GOAL.md` lines 28–32 and 43; `wiki/product/classic-snake-example.md` lines
  15–25 and line 39; `wiki/work/0010-restart-on-death/STATE.yaml` lines 1–5.

## Options considered

| Option                                                                   | How it works                                                                | Cost                                                                                                                  | Why rejected / chosen                                                                                                                              |
|--------------------------------------------------------------------------|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| Record pre-step English state, choice key, probabilities, and confidence | Emit that set from the step that already holds it                           | One line per finished step; no library change                                                                         | **Chosen.** Answers whether straight won, by how much, while the state said Ahead wall or food was elsewhere. Confidence is already on the answer. |
| Infer the reason only from the board after the move                      | Reconstruct neighbours from later geometry                                  | Loses the probabilities and the exact state the model saw                                                             | **Rejected.**                                                                                                                                      |
| Prove the record only by capturing `debugPrint` or `print`               | Zone or `debugPrint` override in tests                                      | New harness; no existing call to intercept                                                                            | **Rejected as the test seam.**                                                                                                                     |
| Prove the record with an injected in-memory callback                     | Same inject style as predict; test list grows only when a record is emitted | One optional example callback                                                                                         | **Chosen for tests.**                                                                                                                              |
| Print each record on the running example console                         | The screen passes a callback that writes one debug line                     | A person running the app can read every choice                                                                        | **Chosen for the running example**, in addition to the test callback. The user asked for logs they can read.                                       |
| Stay silent when predict fails or the key is not relative                | Only successful relative keys are recorded                                  | A stall with no move looks like a missing log                                                                         | **Rejected.** Record a no-choice line with the pre-step state and a reason. Still do not invent a turn or advance.                                 |
| Return the record from the step instead of a callback                    | `step` yields the record and the screen and tests read that return value    | Changes the step’s result type that the screen and existing tests already await as a finished attempt with no payload | **Rejected.** An optional callback leaves today’s step result unchanged when no listener is supplied.                                              |

## Constraints discovered

- Prompt wording, relative keys, collision rules, and the no-timer rule stay unchanged.
- No safety shield. The log describes the model’s choice. It does not replace it.
- Classic-rules tests inject predict and do not open a session. The sandbox solution is why a VM
  test is not a session-load proof (`wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`).
- The pre-step state string is the state the model saw, including a choice that then ends the game
  on a wall.
- `0010-restart-on-death` is out of scope.

## Parent decisions that close the research gaps

These were left unresolved by the streams. They are decided here so the plan does not invent them.

- The record fields are the pre-step English state, the choice key when one was accepted, the
  probability map, and confidence. A no-choice record has the pre-step state, an absent choice, and
  a reason of predict failure or a missing or non-relative key.
- Tests observe an injected callback that receives one record per finished attempt. The running
  Snake screen passes a callback that prints one debug line per record. Omitting the callback
  records nothing and does not change play, so existing tests that do not inject it stay quiet.
- Screen-widget observation of the log is not required. The logic test is the proof.

## Unresolved

- None. The stream files still list their own open items; this merge closes them with the parent
  decisions above.

## Sources

- `wiki/work/0008-snake-choice-log/research/step-record.md`, consulted 2026-09-28
- `wiki/work/0008-snake-choice-log/research/test-capture.md`, consulted 2026-09-28
- `wiki/product/GOAL.md`, consulted 2026-09-28
- `wiki/product/classic-snake-example.md`, consulted 2026-09-28
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-28
- `example/lib/snake_controller.dart`, consulted 2026-09-28
- `example/lib/snake_screen.dart`, consulted 2026-09-28
- `example/test/snake_controller_test.dart`, consulted 2026-09-28
- `lib/src/answers.dart`, consulted 2026-09-28
