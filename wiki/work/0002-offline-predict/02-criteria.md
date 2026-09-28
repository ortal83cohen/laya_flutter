# Acceptance criteria: Offline Laya typed decisions in Flutter

## Frozen

- Frozen at: 2026-09-27
- Frozen by: orchestrator, at the start of implementation

## Criteria

| ID | Traces | Criterion | How it is checked | Negative case |
|---|---|---|---|---|
| AC-001 | R-001 | When the caller-chosen cache directory has no complete multilingual checkpoint and the network is available, the library shall store the Hugging Face artifacts needed for offline ONNX Runtime inference of convaiinnovations/laya-multilingual into that directory | Run a first-load test against an empty temporary cache and assert the required artifacts are present on disk afterward | A first load that leaves the cache empty or that packs those artifacts into the pub package instead of the cache |
| AC-002 | R-002 | When a complete local copy already exists in the cache directory, a later load with the network unavailable shall succeed from disk and shall not perform a download | Complete a first download, disable network for the process or test double, load again from the same directory, and assert no download occurs and the load succeeds | A second load that attempts a Hugging Face fetch, or that fails despite a complete local copy |
| AC-003 | R-003 | When a local multilingual checkpoint is loaded and the network is unavailable, one library call for a single state and a question map containing one choice, one score, and one noul shall return those three answers, and each answer shall include probabilities and a confidence value | Integration test: load from cache, block network, call predict once with that map, assert all three answer types and their probability and confidence fields are present | A call that omits any of the three types, omits probabilities or confidence, throws because the network is blocked, reaches a remote inference API, or returns answers for an empty question map |
| AC-004 | R-004 | When the frozen fixture set is evaluated on the developer host for the same multilingual checkpoint, states, and questions, the library’s choice label, score level, and noul side shall equal the committed Python Laya outputs for every fixture | Host comparison test over every committed fixture; each fixture file includes the state, the question map, and the Python outputs; assert equality on choice label, score level, and noul side | Any fixture that disagrees, a fixture that omits its question map, or a comparison that passes after the committed Python choice label for one fixture is deliberately altered |
| AC-005 | R-005 | When inference runs after a local copy is available, the forward pass shall use ONNX Runtime on a multilingual graph whose inputs and outputs match the upstream ONNX agent contract and whose selection is backed by logit-parity evidence with PyTorch for that graph class | Read the load and predict path and the artifact selection record; confirm ONNX Runtime is used and the graph contract matches; confirm the chosen export’s parity evidence is cited or newly measured | A predict path that uses a different engine, or that loads a graph whose input or output names and shapes do not match the ONNX agent contract |
| AC-006 | R-006 | When the frozen fixture set is inspected, it shall contain at least one short English state and at least one non-English state, and both shall be included in the host parity comparison | Inspect the committed fixtures and the host parity test inputs; assert both language classes are present and executed | A fixture set or parity run that contains only English states, or that lists a non-English state but never compares it |

## Non-functional criteria

| ID | Traces | Criterion | How it is checked | Negative case |
|---|---|---|---|---|
| AC-007 | R-001, R-002 | When the pub package is inspected, it shall not contain checkpoint weight files or ONNX graph binaries for convaiinnovations/laya-multilingual | Search the package tree that is published or committed for those binaries and assert they are absent | A committed or packaged model.safetensors or multilingual ONNX graph inside the package |
| AC-008 | R-005 | When the candidate Flutter ONNX Runtime plugin is exercised on the developer host against the selected multilingual graph, the work item shall record either a successful session load or a failure that stops the slice | Run the host session-load probe or test from the plan’s first unit; keep the pass output or the stop record | Proceeding to public predict or fixture parity without a successful host session load and without a recorded stop |

## Explicitly not required

Snake gameplay, example launches on Android or iOS, and builds for web or other extra platforms.

Router, multi-checkpoint lifecycle, English or typed-decisions downloads, presets, batch predict, long predict, shortlist, schema decide, prediction hooks, and a system_one alias.

Quantized graphs and any claim that a smaller quant preserves argmax parity.

End-to-end argmax parity measured on Android or iOS devices; host comparison is sufficient for this slice.

Peak RAM, wall-clock latency floors, and marketing performance numbers.

## Verdict log

| Round | Date | Verdict | Report |
|---|---|---|---|
