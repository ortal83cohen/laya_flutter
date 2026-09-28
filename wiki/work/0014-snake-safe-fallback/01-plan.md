# Plan: Improve model-guided Snake decisions with structured context and logs

## Goal

After this slice, the model will remain the only source of Snake direction, but
it will receive a compact structured choice question and richer one-step board
context: food distance, relative food position, recent model keys, and the
predicted result of each relative turn. Every attempt will produce a structured
diagnostic record that shows the model input, returned key, objective, progress
metric and collision/validity classification. No
fallback, blocking rule or replacement decision will be introduced.

## Approach

Extend the example controller at the point where it already builds the state and
turn question. Keep the typed choice API, id and relative keys. Add food-relative
facts to the state and dynamic candidate descriptions to the choice options so
the model can compare the actual next cell, cell kind and distance to food for
each possible turn. State the execution contract plainly: one exact relative key
is returned and the application executes that key as returned.

Expand the existing choice record rather than creating a parallel logger. It will
retain the full question and state and add pre-step board facts, the candidate
cell, a validation status and a reason for missing/invalid/wall/body outcomes.
The screen will serialize the record in one structured diagnostic entry while
keeping the current await-gated, no-timer loop. Valid model choices continue to
advance or collide under classic rules; invalid or unavailable choices remain
stationary and are not replaced.

Update controller and screen tests with injected predict doubles covering exact
prompt/context fields, legal model ownership, dangerous-but-executed choices,
invalid/no-answer handling, repeated-turn detection, full records, and logging. Update the Snake product
note to make model ownership absolute and diagnostics non-intervening; no safety
fallback ADR is added.

## Why this approach

Adding candidate facts to the model input is preferred over a deterministic
fallback because the latest product decision requires the model to own every
direction. A post-model shield or heuristic was rejected because it would make
the observed game differ from the model's decision. Absolute directions and a
new JSON parser were rejected because they would reopen the closed relative-turn
API; the typed choice map already gives the model a structured output boundary.
Logging after the attempted move was chosen over a screen-only observer because
the controller owns the exact state and collision classification.

## Product contract

The units implement R-001 through R-007 in
`wiki/work/0014-snake-safe-fallback/04-product-contract.md`.

## Units

### U1. Define the structured model input and model-owned execution

Done when the controller question and state expose the candidate facts, and a
valid returned relative key is executed exactly as returned with no fallback or
replacement.

Files it may touch: `example/lib/snake_controller.dart`,
`example/test/snake_controller_test.dart`.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Structured relative output contract | happy path | A living board with food and recent keys | Build question and state | Id/key order, exact-key instruction, distance, food side, recent keys and per-key candidate facts are present | R-001, R-002 |
| Legal model move owns direction | happy path | Predict returns a legal key while another is closer to food | Run one step | The returned key is applied, not replaced by a heuristic | R-003 |
| Dangerous model move is observed | edge | Predict returns a key whose next cell is a wall or body | Run one step | The returned key is executed under classic collision rules and the record classifies the result | R-003, R-005 |
| Invalid output | error | Predict returns `up` or omits `turn` | Run one step | The result is recorded and the board remains unchanged; no direction is invented | R-004 |
| Predict failure | error | Predict throws | Run one step | Failure is recorded and the board remains unchanged | R-004 |

### U2. Emit and consume structured step diagnostics

Done when every living attempt produces one record with complete prompt, state,
board facts, model answer, attempted cell, validation status and reason, and the
screen prints it while preserving the single await-gated loop.

Files it may touch: `example/lib/snake_controller.dart`,
`example/lib/snake_screen.dart`, `example/test/snake_controller_test.dart`,
`example/test/snake_screen_test.dart`.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Structured accepted record | integration | Predict returns a legal key | Complete one step with a record callback | Record contains pre-step board facts, objective, progress before/after/delta, model key, attempted cell and answer metadata | R-005 |
| Structured collision record | integration | Predict returns a wall/body-bound key | Complete one step with a record callback | Record names the attempted cell and collision status, with no substitute key | R-005 |
| Repeated-turn regression | integration | Predict returns a repeated or alternating relative-key sequence | Capture the state before the later prediction and inspect records | Recent keys and progress facts are present; a repeated-pattern flag is reported without changing the model choice | R-002, R-005 |
| Await-gated continuation | integration | Predict returns legal keys twice | Run the screen loop with predict override | At least two awaited predictions occur; no timer or concurrent loop is introduced | R-006 |
| Session-free proof | edge | All controller/screen scenarios | Run VM tests | Tests use injected predict only and do not open native inference | R-007 |

## Interfaces and shared decisions

- The only model question remains `turn` with ordered keys `left`, `right`,
  `straight`.
- The record exposes the original model key and no applied fallback key. The
  existing `choice` field remains the model-key alias for example callers.
- The objective is `reach food while avoiding walls and body`; the progress
  metric is Manhattan distance to food, with delta defined as before minus
  after. Recent model keys are limited to the last four decisions.
- A repeated-turn diagnostic is true for three identical recent keys or a
  four-key alternating pattern. It is reporting only and never selects a key.
- Valid choices mutate the board exactly once under current collision rules.
- Invalid/missing/throw outcomes emit a reason and do not mutate the board.
- The controller never calls predict twice for one step and never chooses a
  direction independently of the model.

## Risks

| Risk | Likelihood | Impact | Mitigation | Trigger that means it happened |
|---|---|---|---|---|
| Context becomes too verbose or ambiguous | Medium | Medium model-quality regression | Keep facts compact, candidate keyed and test exact required fields | Prompt test cannot find one candidate's next cell/kind/distance |
| A heuristic replacement sneaks into collision handling | Low | Critical contract violation | Add negative test with a wall-bound model key and assert no alternate key is applied | Record shows any applied key different from valid model key |
| Existing log consumers lose the model key | Medium | Medium diagnostics regression | Keep `choice` and include it in structured output | Existing choice-log assertion cannot find model key |
| Invalid output causes a tight loop | Medium | High CPU/log flood | Preserve screen stop-on-unchanged behavior and test a failure path | Screen issues a second step after no movement/no end |
| Repetition flag becomes an intervention | Low | Critical contract violation | Test repeated keys only affect diagnostics and the next state context | Applied key differs from the model key after a warning |

## Rollback

Revert the controller context/record changes, screen log marker change, tests and
the product-note paragraph. The library and checkpoint files remain untouched;
rollback has no data migration or external state.

## Out of scope

- Re-training, fine-tuning or changing the Laya checkpoint.
- Changing the public library inference API or tokenizer.
- Any deterministic fallback, safety shield, collision prevention or direction
  replacement after predict.
- Proving that the model makes optimal legal choices on every board.
- Android/iOS device launch proof, hosted deployment or a full-screen visual
  walkthrough.

## Verification approach

Run focused example controller and screen tests, then format touched Dart files
and run the repository analyzer. Run deterministic simulations with scripted
model answers and assert that valid answers are the only direction changes,
dangerous valid answers collide under classic rules, and invalid answers do not
move. Check the wiki linter and inspect the final diff for unrelated changes.
Report any Flutter SDK cache failure as a verification boundary rather than a
false pass.
