# Research: Improve model-guided Snake decisions with structured context and logs

## Scope

This slice responds to the latest user direction: every direction must come
from the model. The system may expose candidate facts and report unsafe output,
but it must not block, repair, replace or fall back from the model's choice. It
advances SC-003 without changing the relative action space.

## Findings

| Question | Evidence | Finding |
|---|---|---|
| Where is the movement loop? | `example/lib/snake_screen.dart:91-119` awaits `SnakeController.step`, redraws, stops on an unchanged living board, and replaces an ended controller. | The controller must remain await-gated. A valid model move can end on a wall/body; an invalid or missing result must be recorded without inventing movement. |
| How is the model answer represented? | `example/lib/snake_controller.dart:313-363` reads `answers['turn']?.choice`; `lib/src/answers.dart:55-66, 91-112` defines a typed choice answer with a string key, probabilities, and confidence. | The typed choice question is the structured output boundary. The example must keep the returned key as the sole direction authority. |
| What makes a model decision unsafe? | `example/lib/snake_controller.dart:373-391` computes the next cell and marks the run ended when `_isWall` or `_isBody` is true. | A log can classify a returned relative key as wall-bound or body-bound after the model has chosen it. The controller must not substitute another key. |
| What does the current log expose? | `example/lib/snake_controller.dart:61-125` records prompt text, state, choice, probabilities and confidence; `example/lib/snake_screen.dart:61-65` prints it with marker `0013`. | The log lacks pre-step head/heading/food, attempted cell, validation status and rejection reason. The record should serialize these fields together with the full model input. |
| What prompt contract is already present? | `wiki/product/classic-snake-example.md:15-29` fixes relative keys and says missing/invalid output does not advance; `example/lib/snake_controller.dart:276-303` uses id `turn` and keys `left`, `right`, `straight`. | Preserve the relative action space and no-invented-move behavior, while adding candidate-by-candidate context and explicit exact-key instructions. |
| What test seam is available? | `example/test/snake_controller_test.dart:1017-1060` supplies an injected `SnakePredict`, random source, initial snake and food. | Prompt, unsafe-choice, invalid-choice and logging behavior can be tested without opening an ONNX session. |

## Decision inputs

- Keep the choice id `turn` and relative keys `left`, `right`, and `straight`.
- Give the model the current board, food distance and relative food position,
  plus the predicted next cell, cell kind and distance-to-food for each key.
- Give the model the recent relative keys and an explicit objective plus a
  measurable progress value, so a repeated-turn pattern is visible in the next
  decision context.
- State explicitly that the application executes exactly the returned relative
  key and does not correct it. The typed answer remains one of the known keys;
  no JSON parser or second decision-maker is introduced.
- On a valid model key, execute exactly that key under today's classic rules.
  A wall/body result ends the run as it does today and the log identifies it.
- On a missing, non-relative or thrown result, record the reason and leave the
  board unchanged. Do not synthesize a direction.
- Emit one structured record after every living attempt, including prompt,
  state, board facts, raw model key, attempted cell, validation status and
  answer probabilities/confidence when present. Include the objective,
  progress-before/after/delta and a repeated-turn diagnostic flag.

## Unresolved or unverified

- [UNVERIFIED: Better context will improve a particular downloaded checkpoint's
  choice quality on every possible board. Local simulation proves the prompt,
  execution and logging contract, not model quality.]
- [UNVERIFIED: Android or iOS device rendering is available in this checkout.]

## Sources consulted

- `wiki/product/GOAL.md`, read 2026-09-28.
- `wiki/product/classic-snake-example.md`, read 2026-09-28.
- `example/lib/snake_controller.dart`, read 2026-09-28.
- `example/lib/snake_screen.dart`, read 2026-09-28.
- `lib/src/answers.dart`, read 2026-09-28.
- `example/test/snake_controller_test.dart`, read 2026-09-28.
