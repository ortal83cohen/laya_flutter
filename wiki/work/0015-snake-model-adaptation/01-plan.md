# Plan: Evaluate and prepare Snake-specific model adaptation

## Goal

The repository will identify the exact base checkpoint used by the example and
provide a repeatable, weight-free evaluation artifact for a future Snake
fine-tune. The artifact will separate train and validation states and measure
model agreement, food progress, collisions and loops. It will report the
current straight-policy baseline honestly while leaving base-model and
fine-tuned-model results unmeasured until real trajectories are supplied.

## Approach

Document checkpoint provenance from the existing Dart constants, cache loader,
example entry point and frozen parity fixture. Treat the configured
`convaiinnovations/laya-multilingual` model as the base under test and keep the
community ONNX graph provenance separate from checkpoint companions.

Add a standard-library Python evaluator and a small JSONL fixture. The evaluator
validates board states, teacher labels and a disjoint train/validation split;
then it scores prediction exports by model name. A built-in straight-ahead
policy gives a reproducible geometric baseline without loading weights. The
fixture is intentionally a plumbing pilot, not a claim that it represents the
full Snake distribution.

Record the external fine-tuning protocol and gates in the research artifact and
product note. The future training run must use the train split, preserve a
held-out validation split, record immutable provenance, and compare base versus
adapted outputs with the same evaluator. No training dependency, checkpoint
weight or GPU workflow is added to the Flutter package in this slice.

## Why this approach

A weight-free evaluator is preferred over adding Python training dependencies to
the package because the project explicitly keeps model weights and training out
of the Flutter library. A hand-written score in a document was rejected because
the fixture and metrics need to be rerunnable. A fine-tuning command in this
repository was rejected because upstream's RLCD notebook requires external
training data and GPU infrastructure, neither of which is present here.

## Product contract

The artifact implements R-001 through R-006 in
`wiki/work/0015-snake-model-adaptation/04-product-contract.md`.

## Units

### U1. Establish checkpoint and training provenance

Done when the repository and upstream sources identify the configured base model,
the ONNX graph/companion split, the absence of local Snake training code and the
external fine-tuning path without claiming an unrun experiment.

Files it may touch: `wiki/work/0015-snake-model-adaptation/00-research.md`,
`wiki/product/snake-model-adaptation.md`, `wiki/INDEX.md`.

| Scenario              | Category   | Input                                    | Action                       | Expected outcome                                                             | Covers |
|-----------------------|------------|------------------------------------------|------------------------------|------------------------------------------------------------------------------|--------|
| Current provenance    | happy path | Source constants and cache loader        | Read the documented path     | Base id and graph source are stated separately                               | R-001  |
| Training availability | edge       | Repository and upstream source inventory | Inspect for training support | No local training is claimed; upstream notebook is named as external support | R-002  |

### U2. Create a weight-free evaluation fixture and scorer

Done when the fixture has disjoint train/validation ids and the evaluator can
validate it, score the straight baseline and score future prediction exports by
model name.

Files it may touch: `tool/snake_eval.py`,
`tool/snake_eval_fixture.jsonl`,
`wiki/work/0015-snake-model-adaptation/evidence/baseline-straight.json`.

| Scenario              | Category    | Input                                         | Action                      | Expected outcome                                        | Covers |
|-----------------------|-------------|-----------------------------------------------|-----------------------------|---------------------------------------------------------|--------|
| Fixture validation    | happy path  | JSONL with 8 train and 4 validation rows      | Run the evaluator           | Split and labels validate                               | R-003  |
| Baseline score        | integration | Valid fixture                                 | Run straight-policy scoring | Metrics are printed and match the checked-in evidence   | R-004  |
| Prediction comparison | integration | Complete prediction export for validation ids | Run scorer by model         | Base and fine-tuned rows receive the same metric schema | R-005  |
| Invalid fixture       | error       | Duplicate id or overlapping split id          | Run evaluator               | Non-zero error identifies the invalid row               | R-003  |

### U3. Define the adaptation experiment and gates

Done when the product note states the oracle/teacher label policy, train/validation
split, base versus fine-tuned comparison, metrics and success gates, and clearly
separates local evidence from unrun training.

Files it may touch: `wiki/product/snake-model-adaptation.md`,
`wiki/INDEX.md`.

| Scenario             | Category   | Input                               | Action                | Expected outcome                                                  | Covers       |
|----------------------|------------|-------------------------------------|-----------------------|-------------------------------------------------------------------|--------------|
| Experiment protocol  | happy path | Future train and validation exports | Read the product note | Provenance, metrics and threshold gates are defined               | R-006        |
| No-training boundary | edge       | Current checkout                    | Read evidence status  | No adapted checkpoint or training result is presented as complete | R-002, R-006 |

## Interfaces and shared decisions

- The fixture uses exact relative keys and a geometric teacher label for pilot
  plumbing; it is not a replacement game controller or safety shield.
- The evaluator accepts prediction rows keyed by fixture id and grouped by a
  `model` field. `loop_detected` is optional for one-step rows and required for
  meaningful loop-rate reporting.
- Baseline metrics are labelled `baseline_straight`; they are not base-model
  metrics. The fine-tuned result is `[UNMEASURED]` until a real run supplies
  prediction rows.
- The game continues to execute only the model's choice; this slice adds no
  fallback, blocking or choice replacement.

## Risks

| Risk                                         | Likelihood | Impact | Mitigation                                                                             | Trigger that means it happened                                  |
|----------------------------------------------|------------|--------|----------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| Tiny pilot is mistaken for product evidence  | Medium     | High   | Label the fixture as plumbing-only and require a larger held-out trajectory set        | A report presents 4-row baseline as checkpoint quality          |
| Teacher labels encode a hidden safety shield | Low        | Medium | Keep teacher labels in offline evaluation and document the geometric rule              | Runtime code imports the evaluator or changes model-owned moves |
| Train/validation leakage                     | Low        | High   | Enforce unique ids and both split values in the evaluator                              | Duplicate or missing split row is accepted                      |
| Training result cannot be reproduced         | Medium     | High   | Require base revision, dataset hash, seed and calibration split in future run manifest | A fine-tuned report omits provenance                            |

## Rollback

Remove the evaluator, fixture, evidence snapshot and product-note section. No
runtime, model cache or public API is changed and no data migration is needed.

## Out of scope

- Running GPU training, downloading a fine-tuned checkpoint or publishing one.
- Changing the configured base checkpoint or ONNX runtime.
- Adding a game-time shield, fallback, block or direction replacement.
- Claiming the multilingual base model is Snake-trained or that the prompt fix
  establishes fine-tuned quality.

## Verification approach

Run the evaluator on the fixture and on an intentionally invalid temporary
fixture, inspect the exact baseline evidence, run Python syntax compilation,
and run Dart analyzer for the already-touched example code. The normal Flutter
test command and example build remain separate gates; report the installed SDK
version boundary precisely.
