# Product contract: Evaluate and prepare Snake-specific model adaptation

## Advances

SC-003

## Requirements

| ID    | Requirement                                                                                                                                                                                                       |
|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | The project shall document the exact base checkpoint and separate its companion files from the accepted ONNX graph.                                                                                               |
| R-002 | The project shall distinguish existing local evidence from an unrun Snake fine-tuning experiment and shall not claim an adapted checkpoint exists.                                                                |
| R-003 | A runnable evaluator shall validate a labelled fixture with disjoint train and validation splits and reject malformed or colliding teacher examples.                                                              |
| R-004 | The evaluator shall produce baseline metrics for a deterministic straight-ahead policy: choice accuracy/teacher agreement, food-reached rate, collision rate, mean Manhattan progress delta and loop-rate status. |
| R-005 | The evaluator shall compare complete base and fine-tuned prediction exports using the same validation metric schema.                                                                                              |
| R-006 | The experiment protocol shall define geometric teacher labels, split discipline, provenance, base versus fine-tuned comparison, success gates and the rule that game-time direction remains model-owned.          |

## Boundaries

- No training, checkpoint download, publication or GPU job runs in this slice.
- No game-time shield, fallback, blocking or direction replacement is added.
- The pilot fixture is measurement plumbing, not a product-quality dataset.
