# Plan: Use a four-direction Snake checkpoint in the example

## Goal

The runnable example asks a prepared Snake checkpoint for one absolute direction on each step, applies it literally, and exposes a reproducible full-game evaluation path. A missing checkpoint is visible as a setup error.

## Approach

Change the example controller and tests to use the public checkpoint's four option keys and question wording. Match the public state encoder's heading, length, relative food displacement, candidate room and tail fields. Preserve the single awaited model call per step and diagnostic-only collision reporting.

Add a local ONNX opening path to the general runtime entry so the example can select a prepared exported checkpoint directory. The existing default multilingual download path remains available to library callers, while the example requires an explicit Snake checkpoint directory.

Provide a headless evaluation harness and precise setup instructions for the pinned public checkpoint, its pinned source encoder and ONNX export. The harness reports seeded game metrics with the model's raw choices and no safety mask. Until weights are available, only the source, fixture and validation portions can run.

## Why this approach

The public Owais checkpoint has a documented full game and published encoder, whereas the MLX alternative primarily documents held-out decisions. Loading safetensors directly in Flutter would add a second inference engine; the existing ONNX runtime can potentially consume an exported graph. Running the already cached base graph as if it were the tuned model would not answer the user's question.

## Product contract

The behavior is defined by R-001 through R-005 in `04-product-contract.md`.

## Units

### U1. Absolute model decision and matching state

Done when: the real example uses the four absolute choices, matches the published question and state schema, and records the input, unmodified model choice, attempted cell and candidate outcome, distance progress, and accepted, collision, invalid or predict-failure classification for every finished living attempt.

Files it may touch: `example/lib/snake_controller.dart`, `example/lib/snake_screen.dart`, `example/test/snake_controller_test.dart`, `example/test/snake_screen_test.dart`.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Turn north from east | happy path | East-facing head, up answer | Step | Head moves north | R-001, R-002 |
| Reverse into neck | edge | East-facing head, left answer | Step | Body collision is logged and run ends | R-001, R-004 |
| Unknown key | error | Invalid answer | Step | No movement and explicit diagnostic | R-001, R-004 |
| Failed prediction | error | Predictor throws | Step | No movement; input, absent choice and failure classification are recorded | R-004 |
| Accepted move | happy path | Valid safe model answer | Step | Input, raw direction, attempted cell, candidate outcome and progress are recorded | R-004 |

### U2. Explicit local checkpoint selection

Done when: a configured local ONNX bundle opens through the library and the example never silently substitutes the base graph.

Files it may touch: `lib/src/library.dart`, `example/lib/main.dart`, `test/**`, `example/test/**`.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Complete local bundle | integration | ONNX and companions in configured directory | Open | Runtime uses those files | R-003 |
| Missing bundle | error | No configured directory or files | Open | Clear setup error, no base download | R-003 |
| Incompatible bundle | error | Local graph with wrong input/output contract or malformed companions | Open | Explicit compatibility error, no base download | R-003 |

### U3. Full-game evaluation and documentation

Done when: a separate evaluator can report independent seeded games and documentation states which validation remains blocked by unavailable weights.

Files it may touch: `tool/**`, `wiki/product/**`, `wiki/INDEX.md`, `wiki/work/0016-absolute-snake-checkpoint/**`.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Held-out game | happy path | Pinned source and local model | Evaluate | Seeded agreement, food, collision, loop and score metrics | R-005 |
| Missing model | error | No model weights | Evaluate | Explicit missing-checkpoint result; no fabricated metrics | R-005 |

## Interfaces and shared decisions

- The model question id is `move`; keys and descriptions are the four lowercase absolute directions from the public encoder.
- The example selects a local checkpoint directory through `LAYA_SNAKE_CHECKPOINT_DIR` as a Dart define.
- The local bundle consists of an ONNX graph and the matching checkpoint's tokenizer and agent config. The setup note states exact filenames.
- Valid model directions are never rewritten. Collision classification is diagnostic.
- Evaluation uses raw model actions, independent seeds, and separates decision agreement from full-game metrics.

## Risks

| Risk | Likelihood | Impact | Mitigation | Trigger that means it happened |
|---|---|---|---|---|
| Published checkpoint export is incompatible | Medium | High | Keep export external and verify graph names plus parity before use | Export or session check fails |
| State encoding drifts from training | Medium | High | Freeze reference examples against pinned public source | Encoded strings differ |
| Large 40-by-40 board exceeds training distribution | High | Medium | Report local game metrics separately by board size | Model performs poorly on the example |
| Weights unavailable | Certain today | High | Complete static harness and exact setup; report model run as blocked | No pinned local safetensors or ONNX bundle |

## Rollback

Restore the prior example controller and prompt from the preceding commit while retaining this work item as a record. Restore the prior goal wording only if the user explicitly reverses the absolute-direction product decision.

## Out of scope

- Training a new checkpoint, downloading weights without authorization, or shipping weights inside the package.
- Claiming success from publisher numbers or synthetic fixtures.

## Verification approach

Run focused and full Flutter tests, root and example analysis, web build, wiki lint, and evaluator fixture checks. Record whether a real tuned model could be opened and run.
