# Acceptance criteria: Log every Snake model choice with the state that produced it

## Frozen

- Frozen at: 2026-09-28
- Frozen by: orchestrator

## Criteria

| ID | Traces | Criterion | How it is checked | Negative case |
|---|---|---|---|---|
| AC-001 | R-001 | When a living step finishes with an accepted relative turn key and a choice-record callback is present, the system shall deliver exactly one success record containing the pre-step English state string, that key, the turn answer's probability map, and that answer's confidence. | Controller test with injected predict returning a relative turn and a capturing callback; assert one record with those four fields; no session opened. | Zero records, more than one record, wrong key, state that is not the pre-step string, or probabilities or confidence that do not match the turn answer. |
| AC-002 | R-001 | When that success step applies a valid relative turn, snake cells shall change under today's movement rules after the record is delivered. | Same harness; assert cells differ from the pre-step layout after the step when the choice does not end the run. | Cells stay unchanged despite an accepted non-colliding relative turn, or cells change when no relative key was accepted. |
| AC-003 | R-002 | When a living step's predict throws and a choice-record callback is present, the system shall deliver exactly one no-choice record with the pre-step English state, an absent choice, and a predict-failure reason, and shall leave snake cells, heading, and food unchanged. | Controller test with injected predict that throws and a capturing callback; assert one no-choice record and unchanged cells, heading, and food. | No record, a success record with a fabricated key, or any change to cells, heading, or food. |
| AC-004 | R-002 | When a living step finishes with a missing or non-relative turn key and a choice-record callback is present, the system shall deliver exactly one no-choice record with the pre-step English state, an absent choice, and a missing-or-non-relative reason, and shall leave snake cells unchanged. | Controller test with injected predict returning a missing or non-relative turn choice; assert one no-choice record and unchanged cells. | No record, a success record that invents left/right/straight, or cells that advance. |
| AC-005 | R-003 | When no choice-record callback is supplied and predict returns a valid relative turn, the step shall change snake cells under today's rules and shall deliver no choice record. | Controller constructed without a callback; step with valid relative predict; assert cells change and there is no callback list to grow. | Play stalls despite a valid relative key, or a record is emitted without a callback having been supplied. |
| AC-006 | R-004 | When the running Classic Snake screen drives await-gated steps, it shall pass a choice-record callback that writes one debug line per delivered record. | Review the Snake screen wiring: a callback is passed that writes one debug line per record. | The screen omits the callback, or writes no line when a record is delivered. |
| AC-007 | R-005 | When a logic test proves the log for an accepted relative key, the check shall observe the injected callback and shall fail if that key is accepted and no record is delivered for the attempt. | Controller logic test asserts callback growth for a relative key and includes a negative assertion path that fails when emission is absent; the test opens no ONNX session. | The suite only asserts board geometry after a relative choice, or the proof path opens a session, or a missing record still passes. |

## Non-functional criteria

| ID | Traces | Criterion | How it is checked | Negative case |
|---|---|---|---|---|
| AC-008 | R-005 | When verifying the choice log for this slice, VM tests shall inject predict and the choice-record callback, shall not open an ONNX session, and shall not be treated as host session-load proof. | Confirm controller log proofs use injected predict, complete without a native session, and make no session-load claim. | A reviewer treats a green VM test as proof that an ONNX session loaded, or a proof path opens a session. |

## Explicitly not required

- Advancing SC-001 through SC-007; goal_check stays null.
- Screen widget tests that assert the log.
- On-screen log chrome.
- Changes to library open or predict.
- Changes to prompt wording, relative turn keys, or collision rules.
- A step timer, ticker, or delayed future for pacing.
- A safety shield that overrides the model.
- Restart-on-death (work item 0010).
- Capturing print or debugPrint as the required test seam.
- Reopening or changing the macOS ONNX session sandbox solution.

## Verdict log

| Round | Date | Verdict | Report |
|---|---|---|---|
