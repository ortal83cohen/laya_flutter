# Product contract: Improve model-guided Snake decisions with structured context and logs

## Advances

SC-003

## Actors

| ID    | Actor                            | What they are trying to do                                                                            |
|-------|----------------------------------|-------------------------------------------------------------------------------------------------------|
| A-001 | Person running the Snake example | See the model receive enough board context to choose a legal move toward food.                        |
| A-002 | Developer reading device logs    | Identify the board state, food target, model decision, attempted cell and any unsafe result.          |
| A-003 | VM logic-test runner             | Prove prompt, execution and logging behavior with an injected predict function and no native session. |

## Requirements

| ID    | Requirement                                                                                                                                                                                                                                                                                                                                                                   |
|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | The living turn question shall retain id `turn`, keys `left`, `right`, and `straight`, and instruct the model to return exactly one relative key using the supplied board and candidate facts.                                                                                                                                                                                |
| R-002 | The state and option descriptions sent to predict shall include heading, head, food, neighbour classifications, Manhattan food distance, relative food position, recent model keys, and the predicted next cell/kind/distance for each relative key.                                                                                                                          |
| R-003 | When predict returns a valid relative key, the controller shall execute exactly that key under the existing classic movement and collision rules. It shall not block, repair, replace or fall back from the choice.                                                                                                                                                           |
| R-004 | When predict returns a missing, non-relative or thrown result, the controller shall record the reason and leave snake cells, heading, food and ended unchanged. It shall not invent a direction.                                                                                                                                                                              |
| R-005 | After every living attempt, a choice record shall contain the pre-step heading, head, food, state, full question instructions and options, objective, progress metric with before/after/delta values, recent model keys, model choice, attempted cell, validation status, rejection reason when present, repeated-turn diagnostic, and probabilities/confidence when present. |
| R-006 | The running screen shall print each choice record as one structured diagnostic log entry and shall keep the existing await-gated, no-timer loop. A valid model move remains the only way a step advances.                                                                                                                                                                     |
| R-007 | Logic tests for this slice shall inject predict and shall not open native inference.                                                                                                                                                                                                                                                                                          |

## Flows

| ID    | Flow                                                                                                                                                                          | Covers       |
|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| F-001 | Build the enriched state and structured relative-choice question, then call predict once for the living step.                                                                 | R-001, R-002 |
| F-002 | Validate only for classification, then execute the returned valid relative key exactly; wall/body collision follows today's rules.                                            | R-003        |
| F-003 | Record missing, non-relative and thrown outcomes without inventing movement.                                                                                                  | R-004, R-005 |
| F-004 | Emit one structured record describing the model result, attempted movement, objective, progress metric and repeated-turn diagnostic, then redraw only after the awaited step. | R-005, R-006 |
| F-005 | Exercise all decision paths through injected predict doubles.                                                                                                                 | R-007        |

## Acceptance examples

| ID     | Example                                                                                                                                                                       | Covers       |
|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| AE-001 | Predict returns `left` while left would enter the north wall; the controller executes left, ends the run under classic rules, and records the wall-bound result.              | R-003, R-005 |
| AE-002 | Predict returns `up`; the controller records an invalid model choice and leaves the board unchanged.                                                                          | R-004, R-005 |
| AE-003 | Predict returns `straight` while right would be closer to food; straight is applied and the record shows that the model choice was not replaced.                              | R-003, R-005 |
| AE-004 | Predict throws; the controller records predict failure and leaves cells, heading, food and ended unchanged.                                                                   | R-004, R-005 |
| AE-005 | The screen receives a valid model move; its single await-gated loop reaches the next prediction without a timer or a concurrent loop.                                         | R-006        |
| AE-006 | After repeated model keys, the next captured state contains recent keys, objective and progress facts, and the record marks the repeated pattern without changing the choice. | R-002, R-005 |
| AE-007 | Controller tests inspect prompt, state, execution and records while using an injected predict closure; no native session is opened.                                           | R-007        |

## Boundaries

- The library `LayaFlutter.open` and `LoadedRuntime.predict` APIs remain unchanged.
- The example keeps relative actions, the `turn` question id, and classic wall/body collision rules.
- No timer, delay, ticker, UI restart button, safety shield, fallback, absolute direction key or
  second inference engine is added.
- The model's valid returned key is the only direction authority. The
  controller may classify the result after the choice but may not prevent or
  replace it.
- This slice does not claim that a particular checkpoint will choose optimal
  moves; it improves the information and observability around that choice.
- Device launch and Android/iOS visual proof remain external verification gates
  and are not implied by VM tests.

## Assumptions

- Manhattan distance is the sum of absolute column and row differences from a
  cell to food.
- A returned key is valid only when it is exactly `left`, `right` or
  `straight`; other values are not directions and do not cause movement.
