# Acceptance criteria: Improve model-guided Snake decisions with structured context and logs

## Frozen

- Frozen at: 2026-09-28
- Frozen by: main agent

## Criteria

| ID     | Traces | Criterion                                                                                                                                                                                                                                                                                                        | How it is checked                                                                                           | Negative case                                                               |
|--------|--------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| AC-001 | R-001  | The living turn question shall use id `turn`, exactly the keys `left`, `right`, `straight`, and explicit instructions for one exact relative key with no application-side correction.                                                                                                                            | Controller test asserts id/key order and required prompt phrases.                                           | A missing/absolute key or correction instruction fails.                     |
| AC-002 | R-002  | The state and option descriptions passed to predict shall contain heading, head, food, neighbour kinds, Manhattan distance, relative food position, recent model keys, and predicted next cell/kind/distance for each relative key.                                                                              | Capturing predict test asserts all facts for a fixed board and after repeated keys.                         | A state or option map without candidate or recent-key facts fails.          |
| AC-003 | R-003  | A valid relative model key shall be executed exactly as returned, including when it is less direct than another legal key; no block, repair, replacement or fallback may occur.                                                                                                                                  | Controller test returns a legal less-direct key and asserts that exact heading/cells result.                | Any alternate key or heuristic replacement fails.                           |
| AC-004 | R-004  | A missing, non-relative or thrown model result shall be recorded with a reason and shall leave snake cells, heading, food and ended unchanged.                                                                                                                                                                   | Controller tests cover missing, invalid and thrown responses.                                               | Any invented movement or changed state fails.                               |
| AC-005 | R-005  | Each living attempt shall emit one record containing prompt, state, pre-step board facts, objective, progress metric before/after/delta, recent model keys, model choice, attempted cell, validation status, rejection reason when present, repeated-turn diagnostic, probabilities and confidence when present. | Record tests inspect accepted, collision, invalid, repeated and failure records and their serialized shape. | A missing field, progress metric, repeated flag or substitute choice fails. |
| AC-006 | R-006  | The screen shall print structured records and keep one await-gated no-timer loop; valid model moves are the only progress.                                                                                                                                                                                       | Screen source checks plus a widget test with two legal model predictions.                                   | A timer, concurrent loop or progress without a model move fails.            |
| AC-007 | R-007  | Controller and screen logic tests shall use injected predict and shall not open native inference.                                                                                                                                                                                                                | Source guards and session-free tests.                                                                       | Any logic proof opens native inference or relies on a real checkpoint.      |

## Non-functional criteria

| ID     | Traces       | Criterion                                                                                                                                                                | How it is checked                                                                                                                   | Negative case                                                   |
|--------|--------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| AC-008 | R-003, R-005 | For a fixed board and fixed model response, repeated simulation produces the same model-owned outcome and diagnostic status; repeated-turn detection is diagnostic only. | Repeat scripted inputs and compare cells, ended state and records, then assert a repeated pattern does not change the returned key. | Any alternate outcome or post-warning choice replacement fails. |

## Explicitly not required

- Optimal behavior for legal model choices.
- Network, checkpoint, Android, iOS or hosted rendering proof.
- Changes to library inference, tokenizer or model weights.
- Any safety shield, deterministic fallback or post-predict choice replacement.

## Verdict log

| Round | Date | Verdict | Report |
|-------|------|---------|--------|
