# Research: Evaluate and prepare Snake-specific model adaptation

## Question

Is the running example using a Snake-specialized checkpoint, does this
repository contain a training path, and what is the smallest reproducible
experiment we can add without claiming that training ran?

## Verified current path

| Claim                              | Evidence                                                                                                           | Result                                                                                                                                                                                                            |
|------------------------------------|--------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Companion checkpoint id            | `lib/src/onnx_graph.dart:21-23`, `lib/src/checkpoint_store.dart:25-27`, and `test/fixtures/parity_fixtures.json:2` | The configured companion checkpoint is `convaiinnovations/laya-multilingual`.                                                                                                                                     |
| Runtime graph                      | `lib/src/onnx_graph.dart:24-32` and `tool/freeze_fixtures.md:10-23`                                                | The app accepts `mariojcr/laya-onnx/multilingual/laya-multilingual.onnx`; companions come from the multilingual checkpoint.                                                                                       |
| Example loading                    | `example/lib/main.dart:105-121`                                                                                    | The example opens the existing cache through `LayaFlutter.open`; no model-selection or fine-tuned-checkpoint switch exists.                                                                                       |
| Training code in this repository   | `rg` inventory over the repository on 2026-09-28                                                                   | No training, fine-tuning, Snake dataset builder, or model adaptation script exists. Existing fixtures are runtime parity fixtures, not Snake labels.                                                              |
| Snake-specific checkpoint evidence | `wiki/work/0002-offline-predict/research/checkpoint.md` and current Hub card                                       | The configured model is a general multilingual Laya checkpoint. **[UNVERIFIED]** No hidden training history can be inferred from a model id alone; no Snake-specialized checkpoint is referenced by this project. |
| Upstream adaptation support        | Official upstream README and fine-tuning notebook                                                                  | Upstream provides a general RLCD fine-tuning notebook that builds data, trains, calibrates and evaluates, but it is not a Snake run and has not been run for this project.                                        |

## Minimal reproducible artifact added in this slice

- `tool/snake_eval_fixture.jsonl` contains 8 `train` and 4 `validation` board
  states, exact relative keys, and transparent geometric teacher reasons.
- `tool/snake_eval.py` validates the split and scores supplied model decisions.
  It reports choice accuracy/teacher agreement, collision rate, food-reached
  rate, mean Manhattan progress delta and loop rate when trajectory predictions
  provide `loop_detected`.
- `wiki/work/0015-snake-model-adaptation/evidence/baseline-straight.json` records
  the reproducible validation result for a simple straight-ahead policy. This
  is a policy baseline, not a measurement of the current multilingual model.

## Experiment protocol

1. Freeze the fixture and keep train/validation ids disjoint. Do not use
   validation labels to construct training examples or tune prompts.
2. Record a base-checkpoint trajectory export using the current
   `convaiinnovations/laya-multilingual` runtime. Each row needs the fixture id,
   returned choice, attempted-cell outcome, food-reached result, progress delta,
   and loop flag from the same run.
3. Train a separate Snake-adapted checkpoint outside this Flutter repository
   using the upstream fine-tuning path and the train split only. Record the
   immutable base revision, dataset hash, question wording, seed, calibration
   data split and exported checkpoint id.
4. Run the adapted checkpoint on the untouched validation split and compare it
   with the base checkpoint and straight policy using the same evaluator.

## Metrics and pilot gates

The required report has one row for each of `straight-policy`, `base-model`,
and `snake-finetuned`: choice accuracy / teacher agreement, food-reached rate,
collision rate, mean progress delta and loop rate. The pilot is successful only
if the fine-tuned model improves validation choice agreement by at least 0.10
absolute over the base model, does not increase collision rate, improves or
matches food-reached rate, and reduces loop rate on the trajectory split. These
are proposed experiment gates, not achieved results.

The local baseline run is intentionally narrow: 4 validation rows, straight
policy, 0.75 choice agreement, 0.00 collision rate, 0.00 food-reached rate and
0.50 mean progress delta; loop rate is not measured because it is a one-step
fixture. It must not be presented as base-model performance.

## Unresolved

- [UNRESOLVED: A GPU-capable environment and the upstream training dependencies
  are not available in this repository checkout, so no Snake fine-tuning run
  or adapted checkpoint exists yet.]
- [UNRESOLVED: The 12-row pilot fixture is sufficient to validate plumbing, not
  to support a product-quality claim; a larger procedurally generated dataset
  and held-out trajectories are required before shipping a checkpoint.]

## Sources

- `lib/src/onnx_graph.dart`, `lib/src/checkpoint_store.dart`,
  `example/lib/main.dart`, `tool/freeze_fixtures.md`, and
  `test/fixtures/parity_fixtures.json`, consulted 2026-09-28.
- [Upstream Laya README](https://github.com/NandhaKishorM/laya), consulted
  2026-09-28: fine-tuning is an external RLCD notebook workflow and published
  checkpoints are not evidence of this project's Snake training.
- [Laya multilingual model card](https://huggingface.co/convaiinnovations/laya-multilingual),
  consulted 2026-09-28: general multilingual typed-decision checkpoint and its
  documented intended use.
- [Upstream evaluation guide](https://github.com/NandhaKishorM/laya/blob/main/docs/evals.md),
  consulted 2026-09-28: labelled JSONL evaluation and comparison workflow.
