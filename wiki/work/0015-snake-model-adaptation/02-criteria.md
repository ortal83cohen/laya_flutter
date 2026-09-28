# Acceptance criteria: Evaluate and prepare Snake-specific model adaptation

## Frozen

- Frozen at: 2026-09-28
- Frozen by: main agent

## Criteria

| ID     | Traces | Criterion                                                                                                                                                                                                                              | How it is checked                                                                             | Negative case                                                                        |
|--------|--------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| AC-001 | R-001  | The repository documentation shall identify `convaiinnovations/laya-multilingual` as the configured companion checkpoint and distinguish it from the accepted community ONNX graph.                                                    | Read constants, cache loader and provenance document.                                         | A Snake fine-tune or a single Hub id for both artifacts is claimed without evidence. |
| AC-002 | R-002  | The slice shall state that no Snake training run or adapted checkpoint exists in the checkout, while naming upstream fine-tuning support as external and unexecuted.                                                                   | Research and product note inspection.                                                         | Training or fine-tuned metrics are presented as achieved.                            |
| AC-003 | R-003  | The evaluator shall reject duplicate ids, missing train/validation splits, invalid board states and colliding teacher labels.                                                                                                          | Run valid fixture and an invalid temporary fixture.                                           | Invalid data exits successfully or silently drops rows.                              |
| AC-004 | R-004  | The evaluator shall score the straight-policy baseline on the validation split with choice accuracy, teacher agreement, collision rate, food-reached rate, mean progress delta and an explicit loop-rate limitation for one-step rows. | Run `python3 tool/snake_eval.py --fixture tool/snake_eval_fixture.jsonl --baseline-straight`. | Baseline output omits a metric or implies it measures the Laya checkpoint.           |
| AC-005 | R-005  | The evaluator shall accept future prediction exports grouped by model and produce the same comparison metric schema for base and fine-tuned outputs.                                                                                   | Run with a small complete prediction export.                                                  | Missing ids, duplicate predictions or unknown fixture ids are accepted.              |
| AC-006 | R-006  | The experiment protocol shall define oracle labels, train/validation separation, base/fine-tuned comparison, food/collision/loop/agreement metrics and pilot success gates, while preserving model-only game decisions.                | Read the product note and work artifact.                                                      | A runtime shield/fallback or unrun training claim appears in the protocol.           |

## Non-functional criteria

| ID     | Traces       | Criterion                                                                                                        | How it is checked                                                        | Negative case                                              |
|--------|--------------|------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|------------------------------------------------------------|
| AC-007 | R-003, R-004 | The evaluator shall run with Python standard library only and shall not require model weights or network access. | Run it with the local fixture in an environment without model arguments. | It imports a training framework or downloads a checkpoint. |

## Explicitly not required

- A fine-tuned checkpoint or GPU training result.
- Android/iOS model-quality or device-launch proof.
- A claim that the 12-row pilot predicts production Snake behavior.

## Verdict log

| Round | Date | Verdict | Report |
|-------|------|---------|--------|
