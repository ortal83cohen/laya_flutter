# Plan: Offline Laya typed decisions in Flutter

## Goal

A Flutter caller can download the multilingual Laya checkpoint once from Hugging Face, then, with no
network, obtain choice, score, and noul answers (with probabilities and confidence) for one state.
On the developer host, those answers match a committed Python Laya run on a frozen fixture set that
includes a short English state and one non-English state. Inference runs under ONNX Runtime on a
graph with published logit parity to PyTorch for the multilingual export that matches the upstream
ONNX agent contract.

## Approach

Prove the candidate Flutter ONNX Runtime wrapper can open a session on the multilingual graph on the
developer host before building the public API around it. The candidate named by research is the pub
package flutter_onnxruntime. The first unit’s done state is either recorded evidence of a successful
session load on the host, or a recorded failure that stops this slice. No plugin method names are
prescribed here; the implementer uses whatever API that package documents after the load proof
succeeds.

Produce the multilingual graph with the official in-tree exporter at scripts/export_onnx.py on
NandhaKishorM/laya main, which names the five inputs input_ids, attention_mask, marker_pos,
marker_mask, and qtype, and the outputs logits and act_logits. A community export is acceptable only
when it uses that same contract and carries logit-parity evidence. Do not treat the official Hub’s
safetensors-only listing as a blocker, and do not treat a community repo as the only exporter. Pair
that graph with the tokenizer and temperature configuration that belong to
convaiinnovations/laya-multilingual so decoding matches Python.

Expose a one-time Hugging Face download into a caller-chosen local directory, then load from that
directory with the network unavailable. Expose one offline predict for a single state plus a
caller-supplied question map. The map must be able to hold one choice question, one score question,
and one noul question in the same call. The call returns the three typed answers with probabilities
and confidence, after tokenization and post-processing that mirror the upstream ONNX agent (
temperature, softmax, choice by argmax over option keys, score as expected level, noul as the
probability of the true side).

Commit a frozen fixture set with the state, the full question map, and the Python reference outputs
for each case. Include a short English state so the multilingual path is checked on the short-state
shape the product later uses in Snake, and one non-English state so the first checkpoint’s language
coverage is exercised in the parity gate. Run the comparison on the developer host only. The
question map in every fixture is the same map the library call receives.

## Why this approach

ONNX Runtime is the research-chosen engine: it is the only compared option with an upstream ONNX
consumer, published ModernBERT and mmBERT plus decision-head exports, measured logit parity, and one
engine that covers the required mobile platforms. LiteRT and ExecuTorch lack Laya export and parity
evidence. Core ML and MLX cannot cover Android with the same runtime. See `00-research.md` runtime
options.

Multilingual only is the research-chosen first download: smaller weights than English, longer
default context, and 100+ language coverage, while still answering short English states.
English-only as the first required download was rejected for collapsing outside English. All three
checkpoints as the first-slice set was rejected for storage and unused specialist weight. English
and typed-decisions remain later optional paths; Router is a later slice. See `00-research.md`
checkpoint options.

Predict-only for this slice (choice, score, noul, probabilities, confidence, plus download) advances
SC-002 with SC-001 and SC-004 inseparable. The finished-product API list in research (Router,
presets, batch, long, shortlist, decide, hooks) is a different horizon and stays out of this
contract. Quantization stays out because smaller argmax-safe quants are unresolved. Web is not
required because web practicality is unresolved.

Including both English and non-English fixtures in this frozen set is a slice decision: the
checkpoint under test is multilingual, so a parity gate that only uses English would under-test the
reason that checkpoint was chosen first, while omitting English would leave the short-state path
that later Snake relies on unchecked until a later slice. This does not close the open product
question about the long-term fixture language mix.

## Product contract

Behaviour is defined in `04-product-contract.md`. The units below realise R-001 through R-006. This
plan adds no behaviour that file does not state.

## Units

### U1. Host session load of the multilingual graph

Done when: the candidate plugin flutter_onnxruntime has been exercised on the developer host against
a multilingual Laya ONNX graph that matches the upstream ONNX agent contract, and the work item
records either a successful session load with enough evidence for later units to proceed, or a
failure that stops this slice without inventing another binding. No claim is made that the plugin
has already loaded a Laya graph before this unit runs. Device (Android or iOS) load is not required
here.

Files it may touch: package dependency manifests, a host-only probe or test under the package test
tree, and a short note under this work item folder recording the load result if the failure case
must stop the slice.

| Scenario           | Category   | Input                                                                      | Action                                                | Expected outcome                                                             | Covers |
|--------------------|------------|----------------------------------------------------------------------------|-------------------------------------------------------|------------------------------------------------------------------------------|--------|
| Host load succeeds | happy path | Multilingual ONNX graph on disk; flutter_onnxruntime on the developer host | Attempt to create an inference session for that graph | Session opens; later units may proceed                                       | R-005  |
| Host load fails    | error      | Same graph and candidate plugin                                            | Attempt to create an inference session                | Failure is recorded and the slice stops; no alternate plugin API is invented | R-005  |

### U2. Runnable multilingual ONNX artifact with ONNX agent contract

Done when: the project has a concrete source for a multilingual ONNX graph whose inputs and outputs
match the upstream ONNX agent contract (input names input_ids, attention_mask, marker_pos,
marker_mask, qtype; outputs logits and act_logits), with published or newly measured logit-parity
evidence against PyTorch for that graph class, and the download path in later units knows which
Hugging Face artifacts to fetch. Prefer a graph produced by the official scripts/export_onnx.py. A
community export is acceptable only when its input and output names match that contract. Official
Hub safetensors remain the identity of the checkpoint family; they are not required to contain the
ONNX file themselves.

Files it may touch: download and cache helpers under the library source tree, documentation comments
in those helpers naming the artifact source, and test fixtures that reference the graph path after
download. No ONNX weights are committed into the pub package.

| Scenario                | Category   | Input                                                                                                                                             | Action                                                         | Expected outcome                                                | Covers |
|-------------------------|------------|---------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------|-----------------------------------------------------------------|--------|
| Adopt matching export   | happy path | Multilingual ONNX produced by official scripts/export_onnx.py, or a community file with the same input and output names and logit-parity evidence | Select it as the runtime graph for the multilingual checkpoint | Later predict uses that graph; package does not bundle the file | R-005  |
| Incompatible I/O layout | error      | An ONNX file whose inputs or outputs do not match the ONNX agent contract                                                                         | Evaluate it as a candidate                                     | It is rejected; it is not used as the runtime graph             | R-005  |

### U3. One-time Hugging Face download and local reuse

Done when: a caller can point the library at a cache directory, obtain the multilingual artifacts
needed for offline ONNX Runtime inference from Hugging Face on the first successful run, and on a
later run with the network unavailable load that complete copy without downloading again.

Files it may touch: library modules responsible for download and local load, public entry points
that accept a cache location, and tests that use a temporary cache directory.

| Scenario                 | Category   | Input                                               | Action                                              | Expected outcome                                                               | Covers        |
|--------------------------|------------|-----------------------------------------------------|-----------------------------------------------------|--------------------------------------------------------------------------------|---------------|
| First download           | happy path | Empty cache directory; network available            | Request a local load of the multilingual checkpoint | Artifacts are stored under the cache directory                                 | R-001, AE-001 |
| Second run offline       | happy path | Complete cache from the first run; network disabled | Request a local load again                          | Load succeeds from disk; no download occurs                                    | R-002, AE-001 |
| Incomplete cache offline | error      | Cache missing a required artifact; network disabled | Request a local load                                | The call fails without claiming success and without inventing a network bypass | R-002         |

### U4. Tokenization and answer decoding parity with the ONNX agent

Done when: preparing a single state for the graph and turning logits into choice, score, and noul (
including probabilities and confidence) follows the same observable rules as the upstream ONNX agent
and the Python Laya answer shaping described in research: temperature, softmax, choice as the option
key at argmax, score as the expected level, noul as the probability of the true side. Implementation
language is Dart inside this package; behaviour is defined by parity with Python on the fixtures,
not by copying Python file layout.

Files it may touch: library modules for sequence building, collation into the five tensors,
temperature application, and answer shaping, plus unit tests that feed known logits or short
sequences where practical.

| Scenario               | Category   | Input                                                         | Action                                   | Expected outcome                                                                                                | Covers |
|------------------------|------------|---------------------------------------------------------------|------------------------------------------|-----------------------------------------------------------------------------------------------------------------|--------|
| Choice from logits     | happy path | Softmax probabilities over option keys after temperature      | Derive the choice answer                 | The chosen label is the key at the maximum probability; probabilities and confidence are present                | R-003  |
| Score and noul shaping | happy path | Score-level probabilities and two-sided noul probabilities    | Derive score and noul answers            | Score is the expected level; noul side is the higher-probability slot; probabilities and confidence are present | R-003  |
| Wrong temperature      | error      | Deliberately different temperature than the checkpoint config | Compare to Python reference on a fixture | Choice label, score level, or noul side disagrees, proving temperature is part of the parity contract           | R-004  |

### U5. Offline single-state predict

Done when: with a local multilingual checkpoint loaded and the network unavailable, one public
predict call for a single state and a caller-supplied question map returns choice, score, and noul
answers, each including probabilities and a confidence value, using ONNX Runtime for the forward
pass. The question map in that call contains one question of each type.

Files it may touch: the public library facade and the modules that wire load, tokenize, run, and
decode into that one call, plus integration tests under the package test tree.

| Scenario                   | Category   | Input                                                                                                         | Action         | Expected outcome                                                                                                      | Covers        |
|----------------------------|------------|---------------------------------------------------------------------------------------------------------------|----------------|-----------------------------------------------------------------------------------------------------------------------|---------------|
| Three answer types offline | happy path | Local checkpoint loaded; network disabled; one state; a question map with one choice, one score, and one noul | Invoke predict | Response includes choice, score, and noul, each with probabilities and confidence, keyed by the caller’s question ids | R-003, AE-002 |
| Missing questions          | error      | Local checkpoint loaded; network disabled; one state; an empty question map                                   | Invoke predict | The call fails and does not return invented answers                                                                   | R-003         |
| Missing local checkpoint   | error      | No complete local copy; network disabled; one state and a non-empty question map                              | Invoke predict | The call fails; it does not reach a remote inference API                                                              | R-003         |

### U6. Frozen fixtures and host argmax parity

Done when: a committed fixture set includes at least one short English state and one non-English
state. Each fixture commits the state, the full question map (one choice, one score, and one noul,
with instructions and criteria), and the Python Laya outputs for choice label, score level, and noul
side for the multilingual checkpoint. A host-side comparison runs the library on that same state and
question map and matches those outputs for every fixture. Android and iOS device parity are not
claimed.

Files it may touch: fixture data under the package test or tool tree, a small generator or
documented procedure that produced the Python references (not necessarily checked into the library
public API), and the host comparison test.

| Scenario           | Category   | Input                                                                                                         | Action                                                                                     | Expected outcome                                                  | Covers                       |
|--------------------|------------|---------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------|-------------------------------------------------------------------|------------------------------|
| Full fixture match | happy path | Frozen set with English and non-English states, each carrying its question map; local multilingual checkpoint | Run host comparison of library vs committed Python outputs on the same state and questions | Every fixture matches on choice label, score level, and noul side | R-004, R-006, AE-003, AE-004 |
| Tampered reference | error      | A fixture whose committed Python choice label is altered                                                      | Run the same comparison                                                                    | The comparison fails for that fixture                             | R-004                        |
| English-only set   | error      | A proposed fixture set with no non-English state                                                              | Check against this unit’s done state                                                       | The set is incomplete for this slice                              | R-006                        |

## Interfaces and shared decisions

Checkpoint identity for this slice: Hugging Face id convaiinnovations/laya-multilingual only. No
English or typed-decisions download. No Router.

Runtime: ONNX Runtime via the verified candidate from U1. Quantization is out of scope. Web is not a
required target for this slice.

Graph contract: inputs and outputs must match the upstream ONNX agent forward contract (five tensors
in; logits and act_logits out). Graphs with a different I/O layout are rejected even if they claim
Laya lineage.

Predict inputs: the caller passes one state and one question map in the same call. The state is
either a single text string or a map from field name to text. Each question has an id chosen by the
caller, a type of choice, score, or noul, an instructions string, and criteria. Choice criteria map
each option label to a description. Score criteria are an ordered list of level descriptions from
low to high. Noul criteria, when present, describe the false side and the true side. An empty
question map is an error. The frozen fixtures store this same map beside the state and the Python
outputs.

Answer fields returned by predict: choice, score, and noul, keyed by the caller’s question ids. Each
includes the answer value appropriate to its type, the probability distribution used to form it, and
a confidence value. Noul side is the slot with the higher probability, matching the goal’s closed
quality bar.

Download: caller supplies a local directory. First successful run fills it from Hugging Face. Later
runs with a complete copy do not download. Required artifacts are whatever U2 selected for offline
ONNX Runtime inference plus the tokenizer and config needed for decoding parity. Nothing of that is
packed into the pub package.

Host vs device: parity and session-load evidence for this slice are on the developer host. Device
launches and SC-005 through SC-006 wait for later slices.

Fixture languages: the frozen set for this slice includes a short English state and one non-English
state, for the reasons in Why this approach.

Error handling: missing or incomplete local artifacts fail the load or predict call without calling
remote inference. A U1 session-load failure stops the slice and is escalated; it is not papered over
with a second invented binding.

Naming: the existing library type LayaFlutter stays the public entry. A method named open takes the
cache directory and returns the loaded runtime, downloading on the first successful call and loading
from disk after that. A method named predict on that loaded runtime takes the state and the question
map. Plugin method names inside flutter_onnxruntime stay unfrozen. Internal modules may be split as
needed inside the files each unit may touch.

## Risks

| Risk                                                                                    | Likelihood | Impact                                    | Mitigation                                                                                                  | Trigger that means it happened                                                      |
|-----------------------------------------------------------------------------------------|------------|-------------------------------------------|-------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| flutter_onnxruntime cannot load the multilingual graph (ops, ORT build, or size)        | High       | Slice cannot proceed to predict or parity | U1 is a hard gate; record failure and stop; escalate rather than invent a binding                           | Host session creation fails for the selected graph                                  |
| Community export I/O does not match the ONNX agent contract                             | Medium     | Wasted download or silent wrong tensors   | U2 rejects incompatible layouts; only matching contracts proceed                                            | Graph inputs or outputs differ from the five-tensor plus logits/act_logits contract |
| Host parity fails after logit-parity graphs because tokenization or temperature differs | Medium     | SC-002 not newly checkable                | U4 and U6 treat Python outputs as authority; fix Dart shaping, not the fixtures                             | Any frozen fixture disagrees on choice, score level, or noul side                   |
| F32 ONNX size (~1.3 GB) makes host CI or developer machines impractical                 | Medium     | Tests skipped or flaky                    | Keep artifacts out of the package; document cache requirements; do not silently shrink via unverified quant | Host tests cannot obtain or load the graph in the verification environment          |
| Scope creep into Router, presets, Snake, or device launches                             | Medium     | Slice never closes                        | Contract boundaries and Out of scope below                                                                  | A unit adds behaviour not listed in R-001 through R-006                             |

## Rollback

Revert the library modules, dependency on the Flutter ONNX Runtime candidate, download helpers,
fixtures, and public predict entry points in one change. Cached downloads on developer machines are
local and can be deleted; they are not in git. No weights are committed, so rolling back does not
require scrubbing large binaries from history.

One-way door: none for the default path. If U1 fails, stopping the slice is the rollback of the
engine choice for Flutter until a human decides the next binding. Do not escalate a one-way door for
adopting a community ONNX URL: that choice is reversible by pointing the download at another
matching export or a project-produced graph.

## Out of scope

Snake example and SC-003. Android and iOS example launches (SC-005). Extra platforms and web
practicality (SC-006 and unresolved web). Finished API surface beyond single-state predict and
download: Router, presets, batch, long, shortlist, schema decide, hooks, system_one alias (SC-007
remainder). English and typed-decisions downloads. Quantization. Peak RAM and latency marketing
numbers. Claiming device-side argmax parity.

## Verification approach

Run the project format and analyze commands from AGENTS.md. Run the host tests for session load (
U1), download then offline reload (U3), offline predict shape (U5), and fixture parity (U6). Paste
command output as evidence. For negatives: incomplete cache offline must fail; predict without a
local checkpoint must fail; a tampered Python reference must fail the comparison; an English-only
fixture set must be rejected by the U6 done check. Do not claim Android or iOS parity. Run
`python3 tools/lint_wiki.py` before closing the plan phase.
