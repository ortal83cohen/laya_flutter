# Product contract: Offline Laya typed decisions in Flutter

## Advances

SC-002 (with SC-001 and SC-004 inseparable in this slice)

## Actors

| ID    | Actor                                      | What they are trying to do                                                                    |
|-------|--------------------------------------------|-----------------------------------------------------------------------------------------------|
| A-001 | Flutter app developer                      | Call the library once a local checkpoint exists and receive typed decisions without a network |
| A-002 | Library caller (test or app)               | Download the first checkpoint once from Hugging Face, then reuse the on-disk copy             |
| A-003 | Verification harness on the developer host | Compare library answers to a committed Python Laya run on the same frozen fixtures            |

## Requirements

| ID    | Requirement                                                                                                                                                                                                                                                                                                                                                       |
|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | When no local copy of the first checkpoint exists and the network is available, the library shall obtain `convaiinnovations/laya-multilingual` (and any companion artifacts required to run that checkpoint under ONNX Runtime) from Hugging Face into a caller-chosen local location                                                                             |
| R-002 | When a complete local copy already exists at that location, a later run shall load from disk and shall not download again even when the network is unavailable                                                                                                                                                                                                    |
| R-003 | When a local checkpoint is loaded and the network is unavailable, one library call for a single state and a caller-supplied question map shall return a choice answer, a score answer, and a noul answer, each including probabilities and a confidence value. The map in that call contains one question of each type. An empty question map shall fail the call |
| R-004 | When the frozen fixture set is evaluated on the developer host against the same checkpoint, state, and questions, the library’s choice label, score level, and noul side shall match the committed Python Laya outputs for every fixture                                                                                                                          |
| R-005 | Inference after the local copy is available shall run through ONNX Runtime using a graph whose published evidence is logit parity with PyTorch for the multilingual Laya export that matches the upstream ONNX agent input and output contract                                                                                                                    |
| R-006 | The frozen fixture set shall include at least one short English state and at least one non-English state                                                                                                                                                                                                                                                          |

## Flows

| ID    | Flow                                                                                                                                                                                                                                   | Covers       |
|-------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| F-001 | First run: the caller points the library at an empty cache location; the library downloads the multilingual checkpoint artifacts from Hugging Face; a later run with the network blocked loads that copy and does not fetch again      | R-001, R-002 |
| F-002 | Offline predict: with the local copy loaded and the network unavailable, the caller submits one state and a question map with one choice, one score, and one noul; the library returns those answers with probabilities and confidence | R-003, R-005 |
| F-003 | Host parity: the harness runs every frozen fixture (English and non-English) through the library and compares choice label, score level, and noul side to the committed Python outputs                                                 | R-004, R-006 |

## Acceptance examples

| ID     | Example                                                                                                                                                                                                                     | Covers       |
|--------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| AE-001 | Cache directory empty; first run completes a Hugging Face download of the multilingual artifacts; second run with network disabled loads the same directory and performs no download                                        | R-001, R-002 |
| AE-002 | Network disabled; local multilingual checkpoint loaded; one predict call for a single state and a question map with one choice, one score, and one noul returns those three answers, each with probabilities and confidence | R-003        |
| AE-003 | On the developer host, every committed fixture’s library choice label, score level, and noul side equal the committed Python Laya values for the same checkpoint, state, and questions                                      | R-004        |
| AE-004 | The frozen set contains a short English state and a non-English state; both appear in the host parity comparison                                                                                                            | R-006        |

## Boundaries

This slice does not ship Snake, does not require example launches on Android or iOS, and does not
require web.

This slice does not download the English or typed-decisions checkpoints and does not expose a Router
or multi-checkpoint lifecycle.

This slice does not expose presets, batch predict, long predict, shortlist, schema decide,
prediction hooks, or a system_one alias.

This slice does not introduce quantization. Whether a smaller quantized graph preserves argmax
parity remains unresolved and out of scope.

This slice does not claim end-to-end argmax parity on Android or iOS devices; host fixture
comparison is the quality bar here.

This slice does not fine-tune, train, generate text, host HTTP, or call remote inference after the
checkpoint is on disk.

Weights and ONNX graphs are not packed inside the pub package.

## Assumptions

Quality means the choice label, the score level, and the noul side (the slot with the higher
probability) match Python Laya on the frozen fixtures.

Weights arrive by a one-time Hugging Face download; later runs use the local copy.

The first checkpoint is `convaiinnovations/laya-multilingual` only.

The engine is ONNX Runtime. The preferred graph is one produced by official scripts/export_onnx.py,
whose input names are input_ids, attention_mask, marker_pos, marker_mask, and qtype, and whose
outputs are logits and act_logits. A community export is acceptable only when it uses that same
contract. Official Hub listings publish safetensors; absence of ONNX beside those listings is not
treated as absence of any ONNX artifact.

The caller passes questions with the state. Each question has a caller-chosen id, a type of choice,
score, or noul, instructions, and criteria. Choice criteria map a label to a description. Score
criteria are an ordered list of level descriptions. Noul criteria, when present, describe the false
side and the true side. The public entry stays LayaFlutter. open takes the cache directory. predict
on the loaded runtime takes the state and the question map.

`flutter_onnxruntime` is the candidate Flutter wrapper to verify for loading the multilingual graph.
This contract does not assert that it has already loaded a Laya graph.

Including both an English and a non-English fixture in this slice’s frozen set is a slice decision
to exercise the multilingual checkpoint’s coverage; it does not close the open product question
about the long-term fixture language mix.

Package code remains Apache-2.0, matching the Laya weights licence.

## Resolve before planning
