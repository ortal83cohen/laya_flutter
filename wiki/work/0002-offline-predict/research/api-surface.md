# Research: Offline Laya API surface for Flutter

## Question

Which offline Laya features should a Flutter community library expose, and which should stay out of
the finished product?

## Answer

Expose the full offline Python inference surface that a Flutter app can call after a local
checkpoint is on disk: typed `predict` (`choice`, `score`, `noul` with probabilities and
confidence), `Router` plus built-in presets, `predict_batch`, `predict_long`, `predict_shortlist`,
schema `decide`, and prediction hooks. Keep out anything that needs a server, training, or a
non-Flutter host ecosystem (HTTP/`laya-serve`, MCP, fine-tuning and temperature fitting, LangChain,
TileLang CUDA, stuntd-style head training). Snake stays an example that uses a short `choice` call;
it does not define the API.

## Findings

### Goal already locks offline inference and forbids train/serve

- Claim: The finished product downloads a checkpoint once from Hugging Face, then answers typed
  decisions with no network; it must not fine-tune, train, generate text, host an HTTP server, or
  call a remote inference API after the checkpoint is on disk. Quality is argmax parity for choice,
  score, and noul. The preference is the full offline feature set when that set is appropriate on
  device. SC-007 makes the API research the authority for which features ship.
- Evidence: Boundaries and closed assumptions list offline download, no train/serve/remote
  inference, Apache-2.0, and research-chosen offline features with a full-set preference. SC-001
  requires one call returning choice, score, and noul offline. SC-007 requires every in-scope
  feature to have an offline call.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 15–36 and
  39–47.

### Upstream Laya’s primary offline call is typed predict over three primitives

- Claim: Laya evaluates `choice`, `score`, and `noul` over a state in one forward pass. `choice`
  returns a top label, per-option probabilities, and confidence; `score` returns an expected level,
  distribution, and confidence; `noul` returns calibrated P(true). `system_one` is the same path as
  `predict` (empty questions short-circuit without a forward pass).
- Evidence: README quickstart builds `questions` with those three types and calls `router.predict`.
  Decision Primitives table documents outputs. Single-model mode shows `agent.predict` and states
  that empty `predict`/`system_one` returns empty answers without tokenizing.
- Source: `https://github.com/NandhaKishorM/laya/blob/main/README.md` (Quickstart; Decision
  Primitives; Single-Model Mode), consulted 2026-09-27. `https://nandhakishorm.github.io/laya/`,
  consulted 2026-09-27.

### Router and presets are offline and material for non-English and agent-style callers

- Claim: `Router` detects script/language and dispatches among English, multilingual, and
  typed-decisions checkpoints before the forward pass; the English checkpoint can be confidently
  wrong on non-Latin text, so confidence gating cannot replace routing. Built-in presets (`triage`,
  `email`, `guard`, `moderation`, `router`) are ready-made question schemas answered by the same
  offline `predict`.
- Evidence: Route Mode section recommends `Router` as the entry point and shows multilingual
  routing. Benchmark section states English collapses on Khmer at high confidence. CLI and Built-in
  Workflow Presets list the named presets. MCP tools include `laya_preset`.
- Source: `https://github.com/NandhaKishorM/laya/blob/main/README.md` (Quickstart: Route Mode; Why
  Route; Built-in Workflow Presets; Command line; MCP Server), consulted 2026-09-27.

### Batch, long documents, shortlist, decide, and hooks are offline inference, not servers

- Claim: `predict_batch` packs many states with the same questions into shared forward passes.
  `predict_long` windows long states and aggregates. `predict_shortlist` embeds options, keeps top
  `k`, then runs one forward pass (needed when option count blows the head token budget). `decide`
  maps a JSON schema or pydantic model onto Laya questions and projects typed values. Hooks observe
  or rewrite start/end/route/load/evict/error without forking the engine; unset hooks are a no-op.
- Evidence: README sections Batch Mode, Long documents, Honest limits (`predict_shortlist` example),
  Schema-driven decisions, Prediction Hooks. Structured guide lists `decide`,
  `questions_from_json_schema`, and `return_details`. Hooks docs state opt-in behaviour for `Agent`,
  `Router`, and `ONNXAgent`.
- Source: `https://github.com/NandhaKishorM/laya/blob/main/README.md`, consulted 2026-09-27.
  `https://raw.githubusercontent.com/NandhaKishorM/laya/main/docs/structured.md`, consulted
  2026-09-27. `https://nandhakishorm.github.io/laya/hooks/` and
  `https://raw.githubusercontent.com/NandhaKishorM/laya/main/docs/hooks/index.md`, consulted
  2026-09-27.

### Serve, MCP, fine-tune, and calibration fitting are not “offline Flutter library” features

- Claim: `laya-serve` and `examples/server.py` host HTTP APIs. Optional `laya[mcp]` exposes stdio
  MCP tools. Fine-tuning and temperature fitting are training loops that push checkpoints. Shipped
  checkpoints are over-confident; fitting temperatures needs held-out data. LangChain/LangGraph and
  TileLang CUDA extras target Python server/GPU hosts.
- Evidence: Self-Hosting HTTP Server, Try it locally web GUI, MCP Server, Fine-Tuning, Calibration,
  LangChain, GPU Fast Path sections of the README. GOAL forbids hosting a server and training.
- Source: `https://github.com/NandhaKishorM/laya/blob/main/README.md`, consulted 2026-09-27.
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 23–25.

### Community tools that only call offline inference use predict + routing; tools that train or serve sit outside this product

- Claim: `omp-laya-judge` answers `choice`/`bool`/`score` (noul as bool) over `POST /v1/systemone`
  with auto English/multilingual routing, confidence gating, batched question chunks, and Snake/quiz
  demos. `laya-adk-toolkit` exposes `classify`/`score`/`detect` plus `evaluate` for multi-question
  schemas on a preloaded `Router`. `laya-apple` exposes `predict` for `choice`/`score`/`noul` with
  local MLX/ANE and optional Jev-compatible serve. `stuntd` adds a local Jev proxy and trains a head
  on a frozen encoder from labelled traffic — training and HTTP, both outside GOAL.
- Evidence: Each project’s public README describes those surfaces. Upstream README Community Tools
  links the four repositories.
- Source: `https://github.com/NandhaKishorM/laya/blob/main/README.md` (Community Tools), consulted
  2026-09-27. `https://github.com/F0Rextasy/omp-laya-judge/blob/main/README.md`, consulted
  2026-09-27. `https://github.com/Ashfaqbs/laya-adk-toolkit/blob/main/README.md`, consulted
  2026-09-27. `https://github.com/tc3oliver/laya-apple/blob/main/README.md`, consulted 2026-09-27.
  `https://github.com/bladedevoff/stuntd/blob/main/README.md`, consulted 2026-09-27.

### Publisher Flutter packages ship complete offline or domain APIs, not a single demo-sized method

- Claim: `flutter_local_voice_agent` is a full on-device STT/TTS agent (`create`/`start`/
  `interrupt`/`stop`/`dispose`) with explicit HTTPS model preparation then offline reuse, not a
  one-call demo. `webmcp_flutter` exposes a registry of tools, scopes, page semantics, and optional
  browser publication. `flutter_squiggly_text` exposes a full widget surface including named
  presets. The stub `laya_flutter` package today only exports an empty `LayaFlutter` facade.
- Evidence: pub.dev package pages document those APIs. Local library is a one-class stub.
- Source: `https://pub.dev/packages/flutter_local_voice_agent`, consulted 2026-09-27.
  `https://pub.dev/packages/webmcp_flutter`, consulted 2026-09-27.
  `https://pub.dev/packages/flutter_squiggly_text`, consulted 2026-09-27.
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/laya_flutter.dart` line 1;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart` lines 1–5;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/pubspec.yaml` lines 1–16.

### Snake and short choice calls are caller patterns, not the library ceiling

- Claim: Upstream and omp-laya-judge use Snake as a demo of short parallel criteria / a short choice
  among moves. GOAL states Snake is one classic example app, not a game engine, and closed
  assumptions say research chooses which offline Python features to expose with a preference for the
  full offline set when appropriate.
- Evidence: omp-laya-judge Snake demo section; GOAL Outcome, Boundaries, and Closed assumptions.
- Source: `https://github.com/F0Rextasy/omp-laya-judge/blob/main/README.md` (Demos), consulted
  2026-09-27. `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 15–16,
  26–27, 32–35.

### Feature scope table for SC-007

| Feature                                                                           | In / out | Reason tied to source                                                                                              |
|-----------------------------------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------|
| `predict` / `system_one` (same offline forward path)                              | **In**   | Core typed call; SC-001; README Single-Model Mode.                                                                 |
| `choice` answers (label, probabilities, confidence)                               | **In**   | Decision primitive; GOAL quality bar; SC-001.                                                                      |
| `score` answers (level, probabilities, confidence)                                | **In**   | Decision primitive; GOAL quality bar; SC-001.                                                                      |
| `noul` answers (P(true), confidence)                                              | **In**   | Decision primitive; GOAL quality bar; SC-001.                                                                      |
| `answer_confidence` / gating fields returned by the model                         | **In**   | README Self-Hosting notes gating on `answer_confidence`; omp-laya-judge gates on it. Offline field on the result.  |
| `Router` (script/language route, `route`, model override, preload/attach/unload)  | **In**   | Offline; required for multilingual safety; community ADK and omp-laya-judge use routing.                           |
| Built-in presets (`triage`, `email`, `guard`, `moderation`, `router`)             | **In**   | Offline question schemas; CLI and README presets; no server.                                                       |
| `predict_batch` / Router `predict_batch`                                          | **In**   | Offline; documented throughput path; omp-laya-judge chunks batches.                                                |
| `predict_long`                                                                    | **In**   | Offline windowed inference; README first-class long-document API.                                                  |
| `predict_shortlist` (+ embed helper when available on-device)                     | **In**   | Offline; documented fix for high-cardinality choice; MCP exposes `laya_shortlist`.                                 |
| Schema `decide` (JSON-schema → questions → typed values, optional details)        | **In**   | Offline projection over `predict`; structured.md; Flutter callers get typed maps without inventing question dicts. |
| Prediction hooks (start/end/error; route/load/evict when Router is used)          | **In**   | Offline extension seam; hooks docs; Dart callbacks can mirror without a server.                                    |
| Loading checkpoint temperatures already in the downloaded config                  | **In**   | Part of offline load; README Calibration clamp at load. Not a separate train API.                                  |
| Fine-tuning / RLCD training / fitting new temperatures                            | **Out**  | Needs training; GOAL forbids train; Fine-Tuning section.                                                           |
| `laya-serve`, playground HTTP, Jev `POST /v1/systemone` server inside the package | **Out**  | Needs a server; GOAL forbids hosting HTTP.                                                                         |
| MCP server (`laya-mcp-server`)                                                    | **Out**  | Needs a server/stdio host process, not an in-app Flutter API.                                                      |
| LangChain / LangGraph integrations                                                | **Out**  | Python host ecosystem; no Flutter caller evidence in publisher packages.                                           |
| TileLang CUDA fast path                                                           | **Out**  | CUDA GPU path; not a mobile Flutter runtime.                                                                       |
| stuntd-style head training / traffic proxy learning                               | **Out**  | Needs training and a proxy server; stuntd README; GOAL forbids both.                                               |
| Remote hosted Laya/Jev/MCP APIs after checkpoint is local                         | **Out**  | Needs network/server; GOAL forbids remote inference after download.                                                |
| Text generation or open Q&A                                                       | **Out**  | Laya does not generate text; GOAL forbids generation.                                                              |

## Options considered

| Option                                                                 | How it works                                                                                                                                      | Cost                                                                   | Why rejected / chosen                                                                                                                                                                                                                                                                                       |
|------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| (1) Predict only: `choice`, `score`, `noul`, probabilities, confidence | One offline forward API matching SC-001’s three answer types                                                                                      | Smallest surface; SC-007 tests stay short                              | Rejected. Drops `Router`, which upstream treats as required for non-English safety, and drops presets that offline agent callers already use. Conflicts with the closed preference for the full offline set when appropriate.                                                                               |
| (2) Predict plus Router and presets                                    | Option 1 plus language/checkpoint routing and built-in question packs                                                                             | Medium surface; covers omp-laya-judge and laya-adk-toolkit happy paths | Rejected as the finished product. Adequate as a minimum viable slice, but leaves offline batch, long documents, shortlist, `decide`, and hooks out despite documented offline APIs and Flutter-relevant callers (multi-state UI, long chat/docs, large label sets, schema-shaped app models, audit/redact). |
| (3) Full offline Python inference surface                              | Option 2 plus `predict_batch`, `predict_long`, `predict_shortlist`, schema `decide`, and hooks; still excludes train/serve/MCP/LangChain/TileLang | Largest SC-007 matrix; more native/runtime work                        | **Chosen.** Matches GOAL’s preference for the full offline feature set when appropriate for a Flutter caller; publisher packages ship complete offline domains rather than demo-sized APIs; every in-scope row above runs after a local checkpoint without a server or training.                            |

## Constraints discovered

- Finished API equals the in-scope list above for SC-007; an unlisted feature must not ship as part
  of this goal check (`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines
  47–47).
- No training, no hosted HTTP inside the library, no remote inference after the checkpoint is on
  disk (`GOAL.md` lines 23–25).
- Quality bar remains argmax parity for choice, score, and noul — not soft distribution matching or
  ECE claims (`GOAL.md` lines 31–31; README Where Jev leads / Calibration).
- Snake must not shrink the API to a single short `choice` (`GOAL.md` lines 26–27, 35–35;
  omp-laya-judge Snake is a demo).
- Package licence Apache-2.0 (`GOAL.md` line 33; `pubspec.yaml` does not yet declare
  licence — [UNVERIFIED: pubspec will declare Apache-2.0 to match GOAL]).
- Current package is a stub facade only (`lib/src/library.dart` lines 1–5); no public predict API
  exists yet.
- `noul` default `false`/`true` labels can bias answers; laya-adk-toolkit avoids native `noul` for
  detect via two-option `choice` (
  `https://github.com/Ashfaqbs/laya-adk-toolkit/blob/main/README.md`). The library should still
  expose `noul` because GOAL and upstream do, but callers may need the documented `labels` override.
- Mobile memory and latency for multi-checkpoint Router preload, batch size, and long windows are
  not measured in this research stream (runtime/checkpoint research owns those).

## Unresolved

- [UNRESOLVED: whether Dart should expose
  `system_one` as a named alias or only document it as identical to `predict`.]
- [UNRESOLVED: whether preset helpers ship as frozen question maps in Dart or are loaded from a small asset table — both are offline; packaging choice is deferred.]
- [UNRESOLVED: whether
  `predict_shortlist`’s default embedder can run fully on the chosen mobile runtime without a second model; upstream uses the answering checkpoint’s encoder.]
- [UNRESOLVED: exact Dart callback shape for hooks (sync-only vs async) relative to Flutter’s isolate model.]
- [UNRESOLVED: which subset of Router lifecycle (`preload`, `max_loaded`, `attach`,
  `unload`) is required on first ship versus later — all are offline, but memory policy is runtime research.]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-27.
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/laya_flutter.dart`,
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`,
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/pubspec.yaml`, consulted 2026-09-27.
- `https://github.com/NandhaKishorM/laya/blob/main/README.md` and
  `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md`, consulted 2026-09-27.
- `https://nandhakishorm.github.io/laya/`, `https://nandhakishorm.github.io/laya/hooks/`, consulted
  2026-09-27.
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/docs/structured.md`,
  `https://raw.githubusercontent.com/NandhaKishorM/laya/main/docs/hooks/index.md`,
  `https://raw.githubusercontent.com/NandhaKishorM/laya/main/docs/.nav.yml`, consulted 2026-09-27.
- `https://github.com/F0Rextasy/omp-laya-judge/blob/main/README.md`, consulted 2026-09-27.
- `https://github.com/Ashfaqbs/laya-adk-toolkit/blob/main/README.md`, consulted 2026-09-27.
- `https://github.com/tc3oliver/laya-apple/blob/main/README.md`, consulted 2026-09-27.
- `https://github.com/bladedevoff/stuntd/blob/main/README.md`, consulted 2026-09-27.
- `https://pub.dev/packages/webmcp_flutter`, `https://pub.dev/packages/flutter_local_voice_agent`,
  `https://pub.dev/packages/flutter_squiggly_text`, consulted 2026-09-27.
- `wiki/solutions/`: does not exist; no prior solution cited.
