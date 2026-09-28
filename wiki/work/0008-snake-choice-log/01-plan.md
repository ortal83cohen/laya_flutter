# Plan: Log every Snake model choice with the state that produced it

## Goal

After each finished Classic Snake step attempt, an optional callback can receive one record of what
the model saw and chose — or why no relative choice was taken — so a person running the example can
read one debug line per attempt, and a session-free logic test can prove the record exists by
watching that callback.

## Approach

Extend the example Snake controller so each living step that reaches a finished predict attempt can
notify an optional choice-record callback. The callback is supplied at construction, in the same
inject style as the existing predict seam. When the callback is omitted, the step path records
nothing and play matches today's outcome for the same predict result.

On a successful relative key, deliver one success record built from values the step already holds:
the pre-step English state string, the accepted left/right/straight key, the probability map from
the turn answer, and that answer's confidence. Then apply the turn and advance under today's rules,
including ending on wall or body when that is the outcome.

On predict throw, or when the turn choice is missing or not a relative key, deliver one no-choice
record with the pre-step state, an absent choice, and a reason that distinguishes predict failure
from a missing or non-relative key. Do not invent a turn and do not change cells, heading, or food.
Still do not add predict-failure UI.

Wire the running Snake screen to pass a callback that writes one debug line per record. Do not add
on-screen log chrome. Do not change library open or predict. Do not change prompt wording, relative
keys, collision rules, timers, or add a shield. Do not implement restart-on-death.

Prove the log with controller logic tests that inject predict and a capturing callback, never open a
session, and fail when a relative key is accepted and no record arrives. Screen widget tests of the
log are not required for this slice.

## Why this approach

Research and the parent decisions chose recording the pre-step English state, choice key,
probabilities, and confidence from the step that already holds the answer. Inferring a reason only
from post-move board geometry was rejected because it loses probabilities and the exact state the
model saw. Proving the record by capturing print or debugPrint was rejected as the test seam because
the repository has no such calls today and board-only assertions can pass with no record. An
injected in-memory callback was chosen for tests; the running screen additionally prints one debug
line per record so a person can read every choice. Staying silent on predict failure or a bad key
was rejected because a stall with no move would look like a missing log; a no-choice record with
state and reason is required, still without inventing a turn or advancing. See
wiki/work/0008-snake-choice-log/00-research.md. The macOS ONNX sandbox solution is not reopened;
logic proofs inject predict and do not open a session.

## Product contract

Units realise R-001 through R-005 in wiki/work/0008-snake-choice-log/04-product-contract.md. This
plan adds no behaviour that contract does not state.

## Units

### U1. Success record on an accepted relative turn

Done when: a living step that accepts left, right, or straight, with a choice-record callback
present, delivers exactly one success record before or as part of finishing that attempt, containing
the pre-step English state string, the accepted key, the turn answer's probability map, and that
answer's confidence; the step then applies the turn under today's movement and collision rules.

Files it may touch: example Snake controller; a small example-local record type if one is introduced
for the callback payload.

| Scenario                                   | Category   | Input                                                                                               | Action                                           | Expected outcome                                                                                                                             | Covers        |
|--------------------------------------------|------------|-----------------------------------------------------------------------------------------------------|--------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| Straight success record                    | happy path | Living run; callback present; predict returns turn straight with known probabilities and confidence | One step                                         | Exactly one success record with pre-step state, choice straight, those probabilities, and that confidence; cells advance under today's rules | R-001, AE-001 |
| Left or right success record               | happy path | Living run; callback present; predict returns left or right                                         | One step                                         | One success record with that key and the turn answer's probabilities and confidence                                                          | R-001         |
| Record uses pre-step state                 | edge       | Living run where the accepted choice then ends on a wall                                            | One step                                         | Record state matches the English string from before predict; ended follows today's collision rules                                           | R-001         |
| Relative accept without record fails proof | edge       | Living run; callback present; relative key accepted                                                 | One step with a harness that would omit emission | Test that requires a record fails when none is delivered                                                                                     | R-005, AE-001 |

### U2. No-choice record on predict failure or bad key

Done when: a living step that stops because predict throws, or because the turn choice is missing or
not left/right/straight, with a callback present, delivers exactly one no-choice record with the
pre-step English state, an absent choice, and a reason naming predict failure or a missing or
non-relative key; snake cells, heading, and food are unchanged on that step.

Files it may touch: example Snake controller; the example-local record type if shared with U1.

| Scenario                           | Category | Input                                                                | Action   | Expected outcome                                                                                                | Covers        |
|------------------------------------|----------|----------------------------------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------|---------------|
| Predict throw records no-choice    | error    | Living run; callback present; predict throws                         | One step | One no-choice record with pre-step state, absent choice, predict-failure reason; cells, heading, food unchanged | R-002, AE-002 |
| Missing key records no-choice      | error    | Living run; callback present; answers omit turn choice               | One step | One no-choice record with missing-or-non-relative reason; cells unchanged                                       | R-002, AE-003 |
| Non-relative key records no-choice | error    | Living run; callback present; turn choice is not left/right/straight | One step | One no-choice record with missing-or-non-relative reason; cells unchanged                                       | R-002, AE-003 |
| No invented turn on failure        | edge     | Same failure cases                                                   | One step | ended stays false from that stop alone; no relative turn is applied                                             | R-002         |

### U3. Optional callback and screen debug line

Done when: omitting the choice-record callback yields no records and leaves play matching today's
outcome for the same predict result; the running Snake screen passes a callback that writes one
debug line per delivered record; library open and predict, prompt wording, relative keys, collision
rules, and the no-timer rule stay unchanged; no shield is added.

Files it may touch: example Snake controller constructor and fields; example Snake screen;
optionally example main only if construction of the screen must pass nothing extra beyond what the
screen owns.

| Scenario                          | Category    | Input                                                             | Action                                     | Expected outcome                                                   | Covers        |
|-----------------------------------|-------------|-------------------------------------------------------------------|--------------------------------------------|--------------------------------------------------------------------|---------------|
| No callback stays silent          | happy path  | Controller built without callback; valid relative predict         | One step                                   | Play advances as today; no record is delivered because none can be | R-003, AE-004 |
| No callback on failure            | edge        | Controller without callback; predict throws                       | One step                                   | Cells unchanged; no record; no new failure UI                      | R-003         |
| Screen prints one line per record | integration | Running Snake screen with loaded runtime                          | Finish one or more steps that emit records | One debug line written per record                                  | R-004, AE-005 |
| Closed surfaces unchanged         | edge        | Diff of prompt builder, relative keys, collision, timers, library | Review                                     | No change to those surfaces; no shield                             | Boundaries    |

### U4. Session-free logic proof of the log

Done when: example controller tests inject a predict double and a capturing callback, assert success
and no-choice records, assert silence when the callback is omitted, open no ONNX session, and
include a case that fails when a relative key is accepted without a delivered record; screen widget
tests of the log are not required.

Files it may touch: example Snake controller tests.

| Scenario                              | Category   | Input                                                      | Action                     | Expected outcome                                               | Covers               |
|---------------------------------------|------------|------------------------------------------------------------|----------------------------|----------------------------------------------------------------|----------------------|
| Success record asserted in logic test | happy path | Injected predict returns relative turn; capturing callback | One step                   | Callback received the success record fields; no session opened | R-001, R-005, AE-001 |
| No-choice on throw asserted           | error      | Injected predict throws; capturing callback                | One step                   | No-choice record and unchanged cells; no session               | R-002, R-005, AE-002 |
| No-choice on bad key asserted         | error      | Injected predict returns missing or non-relative key       | One step                   | No-choice record and unchanged cells; no session               | R-002, R-005, AE-003 |
| Omitted callback stays quiet          | happy path | No callback; valid relative predict                        | One step                   | Cells change as today; test has no record list growth          | R-003, AE-004        |
| Missing emission fails the test       | edge       | Relative key accepted but record not delivered             | Run the negative assertion | The test fails                                                 | R-005                |

## Interfaces and shared decisions

- Callback: optional choice-record callback on the Snake controller constructor, same inject style
  as predict. When null or omitted, record nothing and do not change play.
- Payload naming in words: one record type for both outcomes. A success record carries pre-step
  state string, accepted choice key, probability map, and confidence. A no-choice record carries
  pre-step state string, absent choice, and a reason. Do not invent probabilities or confidence on a
  no-choice record.
- Reasons: two distinguishable reason values — predict failure versus missing or non-relative key.
  Do not invent further reason taxonomies in this slice.
- Emission timing: deliver exactly one record per finished living-step attempt that reaches a
  predict outcome (success or the failure cases above). An early return because the run is already
  ended delivers no new record.
- Screen: the Snake screen passes a callback that writes one debug line per record. Format is free
  as long as a person can read state, choice or absence, and on success the probabilities and
  confidence. No on-screen log chrome.
- Library: do not change open or predict under the package library sources.
- Closed classic rules: do not change prompt wording, English state builder meaning, relative keys,
  collision rules, or introduce a timer, ticker, or delayed future for pacing. Do not add a shield
  that overrides the model.
- Proof: logic tests inject predict and the callback; they must not open a session. Screen widget
  tests of the log are not required. Board-only assertions are not sufficient proof that a record
  was emitted.
- Goal: advances none; goal_check stays null.
- Out of band: work item 0010 restart-on-death is not implemented here.

## Risks

| Risk                                                | Likelihood | Impact                                                | Mitigation                                                                                                   | Trigger that means it happened                                   |
|-----------------------------------------------------|------------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|
| Board-only tests are treated as proof of the log    | Medium     | Slice looks done while records are never emitted      | Require callback observation; keep a negative case that fails when a relative key is accepted with no record | Green tests assert only heading or cells after a relative choice |
| Logging only on success leaves stalls unexplained   | Medium     | Person cannot tell predict failure from a missing log | Always emit a no-choice record when callback is present and the step stops without a relative key            | Predict failure or bad key produces no callback invocation       |
| Callback side effects change play                   | Low        | Existing silent tests or racey steps                  | Callback is notification only; play path must not depend on callback return values                           | Omitting or no-oping the callback changes cells or ended         |
| Logic test opens a session                          | Medium     | MissingPluginException or sandbox false failure       | Inject predict; never call open in these tests; cite sandbox solution as out of scope                        | Test fails with MissingPluginException or claims session load    |
| Scope creep into restart-on-death or prompt changes | Low        | Reopens closed assumptions                            | Keep 0010 and prompt/collision/timer surfaces out of the diff                                                | Diff changes restart, prompt text, relative keys, or timers      |

## Rollback

Revert the example Snake controller, Snake screen callback wiring, any example-local record type,
and the related controller tests. Previous behaviour returns: steps apply relative turns or stop
without inventing a turn, and nothing is recorded. No data migration and no one-way door. Library
sources are untouched, so rollback stays inside the example.

## Out of scope

- Any change under the package library sources, including open and predict.
- Changes to prompt wording, English state meaning, relative turn keys, or collision rules.
- A step timer, ticker, or delayed future for pacing.
- A safety shield that overrides the model.
- On-screen log chrome or screen widget tests that assert the log.
- Restart-on-death (work item 0010).
- Advancing SC-001 through SC-007; goal_check remains null.
- Reopening or changing the macOS ONNX session sandbox solution.
- Using print or debugPrint capture as the required test seam.

## Verification approach

Run the example Snake controller tests with an injected predict double and a capturing choice-record
callback: success records for relative keys, no-choice records for predict throw and for missing or
non-relative keys, silence when the callback is omitted, unchanged cells on failure, and a negative
case that fails when a relative key is accepted with no record. Confirm by review that those tests
open no ONNX session, that the Snake screen wires a one-line debug callback, and that library
sources, prompt wording, relative keys, collision rules, and timer bans are untouched. Do not treat
VM flutter test as session-load proof. Do not require a screen widget test of the log for this
slice.
