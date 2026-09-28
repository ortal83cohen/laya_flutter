# Product contract: Log every Snake model choice with the state that produced it

## Advances

none

## Actors

| ID    | Actor                                    | What they are trying to do                                                                                                                   |
|-------|------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| A-001 | Person running the Classic Snake example | Read, on the console, why each step chose left, right, or straight — including when that choice did not move toward food or away from a wall |
| A-002 | VM logic-test runner                     | Prove each finished step emits a record through an injected callback, without opening an ONNX session                                        |

## Requirements

| ID    | Requirement                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | When a living step finishes with an accepted relative turn key (left, right, or straight) and a choice-record callback is present, the system shall deliver exactly one record for that attempt containing the pre-step English state string, that accepted key, the probability map from the turn answer, and that answer's confidence.                                                                                                                                      |
| R-002 | When a living step finishes because predict throws, or because the turn choice is missing or is not left, right, or straight, and a choice-record callback is present, the system shall deliver exactly one no-choice record for that attempt containing the pre-step English state string, an absent choice, and a reason that names predict failure or a missing or non-relative key; that step shall not invent a turn and shall not change snake cells, heading, or food. |
| R-003 | When no choice-record callback is supplied, a finished step shall deliver no choice record and shall leave snake cells, heading, food, and ended matching the same step outcome that would occur today for the same predict result.                                                                                                                                                                                                                                           |
| R-004 | When the running Classic Snake screen drives await-gated steps, it shall pass a choice-record callback that writes one debug line per delivered record so a person watching the console can read every finished attempt.                                                                                                                                                                                                                                                      |
| R-005 | When a logic test proves the log, it shall observe records only through the injected choice-record callback, shall not open an ONNX session, and shall fail if a relative key is accepted and no record is delivered for that attempt.                                                                                                                                                                                                                                        |

## Flows

| ID    | Flow                                                                                                                                                                                                                                     | Covers |
|-------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------|
| F-001 | Living step with a valid relative turn and a callback: build pre-step English state, await predict, accept left/right/straight, deliver one success record with state, key, probabilities, and confidence, then apply the turn as today. | R-001  |
| F-002 | Living step with predict throw or missing or non-relative key and a callback: deliver one no-choice record with pre-step state, absent choice, and reason; do not invent a turn; do not advance.                                         | R-002  |
| F-003 | Living step with no callback: same play outcome as today for that predict result; no record is delivered.                                                                                                                                | R-003  |
| F-004 | Running Snake screen supplies a callback that prints one debug line per record while steps run.                                                                                                                                          | R-004  |
| F-005 | Logic test injects a callback and a predict double, asserts records, and opens no session; a step that accepts a relative key with no record fails the test.                                                                             | R-005  |

## Acceptance examples

| ID     | Example                                                                                                                                                                                                                                                                                                              | Covers       |
|--------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| AE-001 | A controller with an injected predict that returns turn straight, and an injected callback list, finishes one step: the list gains one record whose state is the pre-step English string, whose choice is straight, and whose probabilities and confidence match the turn answer; cells advance under today's rules. | R-001, R-005 |
| AE-002 | The same harness with predict throwing delivers one no-choice record with the pre-step state and a predict-failure reason; cells, heading, and food are unchanged.                                                                                                                                                   | R-002, R-005 |
| AE-003 | The same harness with a missing or non-relative turn key delivers one no-choice record with the pre-step state and a missing-or-non-relative reason; cells are unchanged.                                                                                                                                            | R-002, R-005 |
| AE-004 | The same controller constructed without a callback, with a valid relative predict, advances play and leaves the callback list empty because none was supplied.                                                                                                                                                       | R-003        |
| AE-005 | The running Snake screen wires a callback that prints one debug line per record; a person watching the console sees one line per finished attempt.                                                                                                                                                                   | R-004        |

## Boundaries

- This slice does not change library open or predict.
- This slice does not change prompt wording, the English state builder contract, relative turn keys,
  collision rules, or the ban on a step timer, ticker, or delayed future for pacing.
- This slice does not add a safety shield that overrides the model's choice.
- This slice does not require screen widget tests that assert the log; logic tests are the proof.
- This slice does not implement restart-on-death (work item 0010).
- This slice does not advance SC-001 through SC-007; goal_check stays null.
- Host session-load proof remains outside VM flutter test (macOS integration path from the sandbox
  solution).

## Assumptions

- The pre-step English state string is the string built before predict for that step, including when
  the accepted choice later ends the run on a wall or body.
- A success record carries probabilities and confidence from the turn answer already returned by
  predict; a no-choice record does not invent those fields.
- Omitting the callback keeps existing tests quiet and leaves play behaviour unchanged for the same
  predict outcome.
- One debug line per record on the running screen is enough for a person to read; on-screen chrome
  for the log is not required.
- Work item 0010 remains a separate slice; this slice neither depends on nor implements automatic
  restart after death.

## Resolve before planning

(none)
