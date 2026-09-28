# Research: Offline Laya predict — runtime, checkpoint, and API

## Question

Which inference runtime, which first Hugging Face checkpoint, and which offline API features belong in the Flutter library so a caller can download once, then get typed decisions (choice, score, noul) offline with Python parity — without inventing a second engine, bundling weights, or shrinking the product to Snake?

## Answer

**Runtime (`research/runtime.md`):** ONNX Runtime is the only compared option with a Laya-supported graph path (`laya[onnx]` / `ONNXAgent`), a verified encoder-plus-head ONNX export of ModernBERT/mmBERT plus the typed decision head, and official coverage of Android, iOS, macOS, Windows, Linux, and browsers. Community Flutter wrappers claim CPU inference on all six Flutter targets. LiteRT/TFLite and ExecuTorch lack a published Laya export or parity evidence; Core ML and MLX cannot satisfy Android.

**First checkpoint (`research/checkpoint.md`):** Download and run `convaiinnovations/laya-multilingual` first. One checkpoint is enough for offline `choice`, `score`, and `noul` on a phone: it is the smallest published weight file of the three, keeps the longer default context and 100+ language coverage that the English root does not, and still answers short English states such as Snake. Do not make all three checkpoints the first-slice download; a later Router-style path that optionally adds English (and only then typed-decisions) is recommended, not required for the first download.

**API surface (`research/api-surface.md`):** Expose the full offline Python inference surface after a local checkpoint is on disk: typed `predict` (`choice`, `score`, `noul` with probabilities and confidence), `Router` plus built-in presets, `predict_batch`, `predict_long`, `predict_shortlist`, schema `decide`, and prediction hooks. Keep out anything that needs a server, training, or a non-Flutter host ecosystem. Snake stays an example that uses a short `choice` call; it does not define the API.

These three conclusions are different horizons (engine vs first download vs finished-product feature list). They are not automatic contradictions. Where a tension appears between “one multilingual download first” and “Router / multi-checkpoint APIs in the finished product,” both positions are retained below under their source files.

## Findings

### Goal locks offline typed decisions, one runtime for required platforms, and research-chosen checkpoint and API

- Claim: Android and iOS are required. macOS, Windows, Linux, and web ship only when one runtime covers them without a second engine. Quality is argmax parity of choice label, score level, and noul side against Python Laya on a frozen fixture set. Weights are a one-time Hugging Face download, then offline; not bundled in the pub package. The library must not fine-tune, train, generate text, host HTTP, or call remote inference after the checkpoint is on disk. Which checkpoints to load and which offline Python features to expose are chosen by research, with a preference for the full offline feature set when that set is appropriate on device. Snake is a classic example app, not a game engine and not the library ceiling. SC-007 makes the API research the authority for which features ship.
- Evidence: Users-and-where-it-runs, boundaries, closed assumptions, SC-001 through SC-007.
- Source: `wiki/product/GOAL.md` (cited in `research/runtime.md`, `research/checkpoint.md`, and `research/api-surface.md`).

### Laya’s graph is a transformers encoder plus a typed decision head; three Hub checkpoints share the same primitives

- Claim: `DecisionModel` loads a Hugging Face encoder via `AutoModel`, adds optional head layers, type embeddings, an option-marker scorer, and an act head. Forward takes `input_ids`, `attention_mask`, `marker_pos`, `marker_mask`, `qtype` and returns `logits` and `act_logits`. Upstream ships three checkpoints — English (`convaiinnovations/laya`, ModernBERT-large, 421M), multilingual (`convaiinnovations/laya-multilingual`, mmBERT-base, 322M), typed-decisions (`convaiinnovations/laya-typed-decisions`, ModernBERT-large, 421M) — each a non-autoregressive decision model for typed `choice`, `score`, and `noul` in a single forward pass. Typed-decisions is not an automatic Router default unless `auto_task_detection=True`.
- Evidence: `DecisionModel` / `build_model` in `laya/common.py`; Hub family checkpoint table; GitHub README checkpoint table; typed-decisions Router note.
- Source: `research/runtime.md` (architecture and forward contract); `research/checkpoint.md` (three checkpoints, same primitives). Upstream paths cited in both: `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/common.py`, `https://huggingface.co/convaiinnovations/laya`, `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md`.

### Encoder ops that matter for export: RoPE, GeGLU, local/sliding attention

- Claim: ModernBERT uses rotary positional embeddings (RoPE), GeGLU activations, and local-global alternating attention. Laya’s loader remaps transformers-5 `rope_parameters` for `full_attention` and `sliding_attention` onto `global_rope_theta` / `local_rope_theta` so mmBERT’s sliding RoPE base is not silently wrong. The decision head itself is standard `nn.TransformerEncoderLayer` plus linear scorers, not a second encoder stack with custom RoPE.
- Evidence: ModernBERT model card; Laya `_apply_rope_config`; `DecisionModel.__init__` head construction; mmBERT built on ModernBERT architecture.
- Source: `research/runtime.md`.

### Published Hub safetensors sizes, params, and context differ by checkpoint

- Claim: Exact Hub file sizes and parameter totals for the three checkpoints (Hugging Face tree and model APIs, 2026-09-27):

| Checkpoint | Hub id / path | Params (HF `safetensors.total`) | `model.safetensors` bytes | Tokenizer `tokenizer.json` bytes | Default `max_len` in `rl_agent_config.json` | Upstream context summary |
|---|---|---|---|---|---|---|
| English | `convaiinnovations/laya` (repo root) | 421,293,830 | 842,609,210 (~803.6 MiB) | 3,583,228 (~3.4 MiB) | 512 | ModernBERT-large, context 512 |
| Multilingual | `convaiinnovations/laya-multilingual` (also `laya` subfolder `multilingual/`) | 321,908,998 | 643,835,514 (~614.0 MiB) | 34,363,188 (~32.8 MiB) | 1024 | mmBERT-base, 1024 (up to 8,192) |
| Typed-decisions | `convaiinnovations/laya-typed-decisions` (also `laya` subfolder `typed-decisions/`) | 421,293,830 | 842,609,220 (~803.6 MiB) | 3,583,228 (~3.4 MiB) | 1024 | ModernBERT-large, context 1024 |

  Hub card prose rounds English load to “~808 MB” and multilingual to “~647 MB”. Encoder configs for all three list `max_position_embeddings`: 8192. Weight-plus-tokenizer totals for one copy of each are about 846 MB (English), 678 MB (multilingual), and 846 MB (typed-decisions); all three sum to about 2.37 GB.
- Evidence: Hugging Face recursive tree `size` / LFS; model API `safetensors.total`; raw `rl_agent_config.json` and `encoder/config.json`; Hub single-model mode prose.
- Source: `research/checkpoint.md` (full table and totals); `research/runtime.md` (English `model.safetensors` 842,609,210 bytes, Hub ~421M mostly F16, card English ≈ 808 MB and multilingual ≈ 647 MB — same official Hub artifacts, download-baseline note only).

### Official Hub checkpoint repos publish safetensors, not ONNX; community ONNX graphs exist elsewhere

- Claim (official Hub, `research/checkpoint.md`): The published siblings for the family root and the two standalone repos list `model.safetensors`, tokenizer files, encoder config, and `rl_agent_config.json`. No `.onnx` file appears in those listings. The Hub card still names optional Python extra `laya[onnx]`, which is a runtime packaging note, not a published ONNX artifact on the Hub paths inspected there.
- Claim (community exports, `research/runtime.md`): Separate community Hugging Face repos publish ONNX graphs. `mariojcr/laya-onnx` exports english (`laya.onnx`, ModernBERT-large, 1,688,711,336 bytes F32), multilingual (`laya-multilingual.onnx`, mmBERT-base, 1,290,466,290 bytes F32), and typed-decisions; card states max |Δ logits| = 1.8e-6 vs PyTorch under ONNX Runtime 1.29 CPU. `receptron/laya-onnx` reports max logit difference ≈ 1e-5 for the English graph with the same five inputs. `yehor-oleksiuk/laya-english-onnx` reports a different I/O contract and 100% argmax agreement of an int8 graph vs its own fp32 ONNX — secondary int8 evidence, not the `ONNXAgent` contract.
- Explicit distinction: Absence of ONNX beside the official safetensors checkpoints is not the same fact as absence of any ONNX artifact; community ONNX files are different artifacts from official Hub weights.
- Evidence: Sibling / tree listings for the three official model ids; HF API trees and parity sections on community repos.
- Source: `research/checkpoint.md` (official Hub listings); `research/runtime.md` (community ONNX exports and sizes).

### Upstream `laya[onnx]` / `ONNXAgent` define the ONNX I/O and answer decoding; official `main` also ships an exporter

- Claim: Optional dependency `onnx = ["onnx", "onnxruntime"]` exists. `ONNXAgent` opens an `.onnx` with ONNX Runtime, feeds the same five tensors as `DecisionModel.forward`, reads `logits` and `act_logits`, then applies temperature / softmax / answer shaping (choice via `argmax`, score as expected level, noul as `p[1]`). The NandhaKishorM/laya `main` tree includes `laya/onnx_agent.py` and `scripts/export_onnx.py`. That exporter calls `torch.onnx.export` with input names `input_ids`, `attention_mask`, `marker_pos`, `marker_mask`, `qtype` and output names `logits`, `act_logits`. Community `mariojcr/laya-onnx` also publishes a dynamo export with dynamic axes for batch, length, and option count; it is an additional artifact, not the only matching exporter. Community graphs with a different I/O layout than `ONNXAgent` (for example yehor’s `type_ids` / `lengths` / `n_opts`) are not drop-in for the upstream path.
- Evidence: `pyproject.toml`; `ONNXAgent`; `https://raw.githubusercontent.com/NandhaKishorM/laya/main/scripts/export_onnx.py` lines 43–51 and 63–71, consulted 2026-09-27; `mariojcr/laya-onnx` export script.
- Source: `research/runtime.md` for the ONNXAgent contract and the community export; research-review-01 correction for the in-tree exporter, re-checked against the raw script on 2026-09-27. The earlier sentence in `research/runtime.md` that said the tree had no `export_onnx.py` is superseded by that check.

### Answer decoding that SC-002 cares about lives outside the graph

- Claim: After logits, Python/`ONNXAgent` divide by temperature, softmax, then set `choice` to `keys[argmax(p)]`, `score` to the expected level `sum(i * p_i)`, and `noul` to `p[1]` (true). Matching the Python Laya forward pass for SC-002 needs both a faithful graph and the same post-processing and tokenization (`build_sequence` / `collate_items`). Logit parity at ~1e-5–1e-6 is strong evidence that argmax and expected-score will match for the verified samples; it is not itself a frozen Flutter fixture run.
- Evidence: `ONNXAgent._infer`; `build_sequence` / `collate_items`; Goal SC-002.
- Source: `research/runtime.md`.

### ONNX Runtime covers Android, iOS, desktop, and web; Flutter access is via community plugins

- Claim: ONNX Runtime documents mobile packages for Android and iOS, install paths for Windows/Linux/macOS, and ONNX Runtime Web for browsers. No Microsoft-published Flutter binding appears in the official mobile language list. `flutter_onnxruntime` on pub.dev wraps ONNX Runtime 1.23.0 and marks CPU inference complete for Android, iOS, Linux, macOS, Windows, and Web. F32 ONNX graphs are roughly 1.3–1.7 GB per checkpoint — larger than the fp16 safetensors — which constrains phone and especially web memory budgets even when the runtime supports the platform.
- Evidence: ORT mobile/install/web docs; pub.dev implementation-status table; community ONNX byte sizes.
- Source: `research/runtime.md`.

### LiteRT / ExecuTorch / Core ML / MLX are not chosen as the single Laya Flutter engine in this research

- Claim: LiteRT and ExecuTorch have multi-platform Flutter stories in principle, but no Laya `.tflite` / `.pte` export or logit/argmax parity report was found. Official iOS Swift LiteRT packaging is still pre-release. Core ML and MLX are Apple-oriented and cannot be the one runtime that also covers required Android.
- Evidence: LiteRT / ExecuTorch / Core ML / MLX docs; pub.dev packages; absence of Laya artifacts in official tree and HF siblings consulted.
- Source: `research/runtime.md`.

### First phone download: multilingual only; English and typed-decisions are later / optional (checkpoint horizon)

- Claim: Relative to English, multilingual is smaller on disk for weights, default-context-longer, faster on upstream T4 batch tables, and covers 100+ languages. Upstream still answers English through it; the multilingual card says it is weaker on English than the English checkpoint and documents a measured position bias on ordinal `score` (including English), advising the English checkpoint for English `score` when that quality matters. English is the Hub default for Latin-script English and stronger on upstream English suites, but collapses outside English and does not add decision primitives. Typed-decisions is a specialist fine-tune for four workflows (0.766 accuracy on that benchmark vs 0.362 / 0.342 for base English / multilingual), English-only, same ModernBERT-large class size, not the silent Router default. For the first offline download: one multilingual local load; optionally download English (and only if needed typed-decisions) later. Shipping more than one checkpoint on a phone is storage-realistic; upstream lazy `Router()` keeps two checkpoints resident (`english` and `multilingual`) by default; requiring all three as the first download adds ~846 MB for a specialist Router does not auto-select. [UNVERIFIED: peak RAM and wall-clock latency for any of these checkpoints under a mobile Flutter runtime on specific Android or iOS devices.]
- Evidence: Multilingual / English / typed-decisions cards; family routing tables; Production Preload & Memory; byte sizes from tree API.
- Source: `research/checkpoint.md`.
- Horizon note: This is the first-download recommendation. It does not by itself reject a finished-product Router API (see API findings below).

### Finished API: full offline Python inference surface; train/serve/host ecosystems out (API horizon)

- Claim: In-scope offline features: `predict` / `system_one` (same forward path); `choice` / `score` / `noul` answers with probabilities and confidence; `answer_confidence` / gating fields; `Router` (script/language route, override, preload/attach/unload); built-in presets (`triage`, `email`, `guard`, `moderation`, `router`); `predict_batch`; `predict_long`; `predict_shortlist` (+ embed helper when available on-device); schema `decide`; prediction hooks; loading checkpoint temperatures already in the downloaded config. Out of scope: fine-tuning / RLCD / fitting new temperatures; `laya-serve` / playground HTTP / Jev server inside the package; MCP server; LangChain / LangGraph; TileLang CUDA; stuntd-style head training / traffic proxy; remote hosted APIs after checkpoint is local; text generation or open Q&A. Community tools that only call offline inference use predict + routing; tools that train or serve sit outside this product. Publisher Flutter packages ship complete offline or domain APIs, not a single demo-sized method. The stub `laya_flutter` package today only exports an empty `LayaFlutter` facade. `noul` default `false`/`true` labels can bias answers; laya-adk-toolkit avoids native `noul` for detect via two-option `choice` — the library should still expose `noul` because GOAL and upstream do, but callers may need the documented `labels` override. [UNVERIFIED: pubspec will declare Apache-2.0 to match GOAL].
- Evidence: Upstream README sections; structured.md; hooks docs; community tool READMEs; publisher pub.dev packages; local stub; GOAL SC-001 / SC-007.
- Source: `research/api-surface.md`.
- Horizon note: This is the finished-product feature list for SC-007. It is a different horizon from “first checkpoint download = multilingual only” in `research/checkpoint.md`.

### Horizon tension (not silently resolved): first download vs finished Router / multi-checkpoint APIs

- Position A (`research/checkpoint.md`): First phone download is multilingual only; Router across checkpoints is the recommended long-term shape, not the first download; all three as the first-slice set is rejected.
- Position B (`research/api-surface.md`): `Router` and multi-checkpoint lifecycle APIs are **In** for the finished product; a “predict only” surface was rejected because it drops Router, which upstream treats as required for non-English safety; option “predict plus Router and presets” was rejected as the finished product for leaving batch/long/shortlist/decide/hooks out.
- Mark: **Disagreement of scope horizon, not of engine choice.** Checkpoint research answers which weights to download first; API research answers which caller-facing features the finished library exposes. Do not collapse these into a single “Router in / out” verdict in this merge.

### Apache-2.0 weights match the package licence assumption

- Claim: Hub cards for all three checkpoints declare `license: apache-2.0`. The product goal already closes that the package code is Apache-2.0, the same licence as the Laya weights. [UNVERIFIED: pubspec will declare Apache-2.0 to match GOAL] (from API stream).
- Evidence: Model card YAML / API `cardData.license`; goal closed assumptions; pubspec note in API stream.
- Source: `research/checkpoint.md`; `research/api-surface.md`.

## Options considered

### Runtime options (`research/runtime.md`)

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| ONNX Runtime via upstream `laya[onnx]` / `ONNXAgent` | Export encoder+head to one ONNX graph with official `scripts/export_onnx.py` (`torch.onnx.export`, not dynamo), or a community dynamo export that uses the same input and output names; run with ORT; decode answers in the host language mirroring `ONNXAgent`. Flutter uses a community ORT plugin. | F32 ONNX graphs ~1.29–1.69 GB per checkpoint vs ~843 MB fp16 safetensors; community Flutter binding maintenance; need to re-run or adopt a verified export. | **Chosen** (runtime stream). Only option with an upstream consumer, published successful exports of ModernBERT and mmBERT plus the decision head, measured logit parity, and one engine that officially includes Android, iOS, desktop, and web. |
| LiteRT / TFLite | Convert PyTorch with `litert-torch` to `.tflite`; run LiteRT / `flutter_litert`. | Conversion and op-support work unknown; no published Laya artifact; iOS Swift runtime still pre-release per Google docs. | **Rejected** for this slice: no Laya export or parity evidence. |
| ExecuTorch | `torch.export` → `.pte`; run ExecuTorch / `executorch_flutter`. | New export pipeline; no Laya `.pte`; dynamic marker/`k` shapes and ModernBERT attention unproven here. | **Rejected** for this slice: zero Laya-specific export or numeric parity. |
| Core ML (Apple) | Convert to `.mlmodel` / `.mlpackage`; run on iOS/macOS. | Apple-only; second engine still needed for Android. | **Rejected:** cannot cover required Android with the same runtime. |
| MLX | Run on Apple silicon via MLX. | Apple-silicon-oriented; not an Android+iOS+desktop+web single engine. | **Rejected:** fails the shared “one runtime / Android required” constraint. |

### First-checkpoint options (`research/checkpoint.md`)

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Multilingual only (`convaiinnovations/laya-multilingual`) | One HF download of mmBERT-base Laya; offline `predict` returns choice, score, and noul for any supported language including short English | ~644 MB weights + ~34 MB tokenizer on disk; default 1024 context (8192 opt-in); weaker English / English-score behaviour than the English checkpoint per upstream | **Chosen** for the first phone download (checkpoint stream). |
| English only (`convaiinnovations/laya`) | One HF download of ModernBERT-large Laya; best upstream English routing target; same three primitives | ~843 MB weights + ~3.4 MB tokenizer; default 512 context; no usable non-English coverage | **Rejected as the first required download.** Remains the best optional second download for a Router-like English path. |
| All three (english + multilingual + typed-decisions) | Mirror full Python `Router(preload=True)` surface on device | ~2.37 GB weights+tokenizers; three builds if kept hot; typed-decisions unused unless explicitly selected | **Rejected as the first-slice set.** Full three-way residency is an optional later expansion, not the first download. |

### API-surface options (`research/api-surface.md`)

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| (1) Predict only: `choice`, `score`, `noul`, probabilities, confidence | One offline forward API matching SC-001’s three answer types | Smallest surface; SC-007 tests stay short | **Rejected** (API stream). Drops `Router` and presets; conflicts with closed preference for the full offline set when appropriate. |
| (2) Predict plus Router and presets | Option 1 plus language/checkpoint routing and built-in question packs | Medium surface; covers omp-laya-judge and laya-adk-toolkit happy paths | **Rejected as the finished product** (API stream). Adequate as a minimum viable slice, but leaves batch, long documents, shortlist, `decide`, and hooks out. |
| (3) Full offline Python inference surface | Option 2 plus `predict_batch`, `predict_long`, `predict_shortlist`, schema `decide`, and hooks; still excludes train/serve/MCP/LangChain/TileLang | Largest SC-007 matrix; more native/runtime work | **Chosen** (API stream). Matches GOAL’s preference for the full offline feature set when appropriate for a Flutter caller. |

## Constraints discovered

- Android and iOS are mandatory; desktop and web may be named only if the chosen runtime covers them without a second engine (`wiki/product/GOAL.md`; all three streams).
- Quality bar is decision parity with Python Laya (choice label, score level, noul side), not latency marketing numbers or soft distribution / ECE claims (`wiki/product/GOAL.md`; all three streams).
- Weights are a one-time Hugging Face download, then offline; not bundled in the pub package (`wiki/product/GOAL.md`; all three streams).
- Upstream Laya already defines the ONNX I/O contract and answer decoding; Flutter must reproduce tokenization and temperature post-processing (`research/runtime.md`).
- Official Laya `main` ships `scripts/export_onnx.py` with the ONNX agent input and output names (`https://raw.githubusercontent.com/NandhaKishorM/laya/main/scripts/export_onnx.py`, consulted 2026-09-27). A community export remains usable only when it matches that same contract.
- Official Hub checkpoint listings (as of 2026-09-27) have no `.onnx` beside safetensors; that fact does not erase community ONNX repos (`research/checkpoint.md` vs `research/runtime.md` — different artifacts).
- F32 ONNX graphs are roughly 1.3–1.7 GB per checkpoint — larger than fp16 safetensors — constraining phone and web memory (`research/runtime.md`).
- Microsoft does not publish a Flutter ORT package; Flutter integration depends on community wrappers (`research/runtime.md`).
- All three published checkpoints expose `choice`, `score`, and `noul`; typed-decisions does not add a fourth primitive (`research/checkpoint.md`).
- Multilingual is smaller and broader, but upstream documents weaker English suites and English `score` position bias; English remains the better companion checkpoint if English score quality becomes a product requirement beyond parity fixtures (`research/checkpoint.md`).
- Upstream lazy Router keeps at most two checkpoints hot by default (`english` + `multilingual`) (`research/checkpoint.md`).
- Licence of the published weights is Apache-2.0, matching the closed package-licence assumption (`research/checkpoint.md`; `research/api-surface.md`).
- Finished API equals the in-scope list in the API stream for SC-007; an unlisted feature must not ship as part of this goal check (`research/api-surface.md`).
- No training, no hosted HTTP inside the library, no remote inference after the checkpoint is on disk (`research/api-surface.md`).
- Snake must not shrink the API or the first checkpoint set to a single short `choice` (`research/checkpoint.md`; `research/api-surface.md`).
- Current package is a stub facade only; no public predict API exists yet (`research/api-surface.md`).
- Mobile memory and latency for multi-checkpoint Router preload, batch size, and long windows were not measured in the API stream (runtime/checkpoint research owns those) (`research/api-surface.md`).

## Unresolved

- [UNRESOLVED: Has anyone run a frozen fixture set through ORT on Android and iOS (and desktop/web) and compared choice / score / noul to Python Laya end-to-end, beyond the Python ORT logit checks on community export cards?] (`research/runtime.md`)
- [UNRESOLVED: Which Flutter ORT plugin version and ORT build (full vs mobile custom ops) actually load the ~1.3–1.7 GB ModernBERT/mmBERT Laya graphs with the ops those exports emit?] (`research/runtime.md`)
- [UNRESOLVED: Is a smaller ORT-compatible quant (fp16 or int8) available that preserves SC-002 argmax parity on the chosen checkpoint, or must the product ship F32?] (`research/runtime.md`)
- [UNRESOLVED: Does web ORT (WASM) practically load and run a multi-gigabyte Laya graph in real browsers under Flutter web, or should web be named as covered by the engine but deferred for device limits?] (`research/runtime.md`)
- [UNRESOLVED: Would a first-party LiteRT or ExecuTorch export of `DecisionModel` succeed with dynamic `n`/`L`/`k` and ModernBERT local-global attention if someone invested the conversion work?] (`research/runtime.md`)
- [UNRESOLVED: measured peak RAM, load time, and per-step latency for `laya-multilingual` (and optional English) under the yet-to-be-chosen Flutter mobile runtime on representative Android and iOS devices.] (`research/checkpoint.md`)
- [UNRESOLVED: whether the first frozen fixture set should include non-English states, which would strengthen multilingual as the parity anchor, or English-only states, which would make an English companion download more urgent for score quality.] (`research/checkpoint.md`)
- [UNRESOLVED: whether any caller-facing product requirement will need the four typed-decisions workflows soon enough to justify a third on-device download.] (`research/checkpoint.md`)
- [UNRESOLVED: whether Dart should expose `system_one` as a named alias or only document it as identical to `predict`.] (`research/api-surface.md`)
- [UNRESOLVED: whether preset helpers ship as frozen question maps in Dart or are loaded from a small asset table — both are offline; packaging choice is deferred.] (`research/api-surface.md`)
- [UNRESOLVED: whether `predict_shortlist`’s default embedder can run fully on the chosen mobile runtime without a second model; upstream uses the answering checkpoint’s encoder.] (`research/api-surface.md`)
- [UNRESOLVED: exact Dart callback shape for hooks (sync-only vs async) relative to Flutter’s isolate model.] (`research/api-surface.md`)
- [UNRESOLVED: which subset of Router lifecycle (`preload`, `max_loaded`, `attach`, `unload`) is required on first ship versus later — all are offline, but memory policy is runtime research.] (`research/api-surface.md`)

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-27 (all three streams).
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md` and `https://github.com/NandhaKishorM/laya/blob/main/README.md`, consulted 2026-09-27.
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/pyproject.toml`, consulted 2026-09-27.
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/onnx_agent.py`, consulted 2026-09-27.
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/common.py`, consulted 2026-09-27.
- `https://api.github.com/repos/NandhaKishorM/laya/git/trees/main?recursive=1`, consulted 2026-09-27.
- `https://huggingface.co/convaiinnovations/laya` and Hub APIs / trees / raw configs for root, `multilingual/`, `typed-decisions/`, consulted 2026-09-27.
- `https://huggingface.co/convaiinnovations/laya-multilingual`, consulted 2026-09-27.
- `https://huggingface.co/convaiinnovations/laya-typed-decisions`, consulted 2026-09-27.
- `https://huggingface.co/answerdotai/ModernBERT-large`, consulted 2026-09-27.
- `https://huggingface.co/jhu-clsp/mmBERT-base`, consulted 2026-09-27.
- `https://huggingface.co/mariojcr/laya-onnx` and export script / tree APIs, consulted 2026-09-27.
- `https://huggingface.co/receptron/laya-onnx`, consulted 2026-09-27.
- `https://huggingface.co/yehor-oleksiuk/laya-english-onnx/raw/main/README.md`, consulted 2026-09-27.
- `https://onnxruntime.ai/` and ORT install / mobile / web docs, consulted 2026-09-27.
- `https://pub.dev/packages/flutter_onnxruntime`, `flutter_litert`, `executorch_flutter`, consulted 2026-09-27.
- `https://developers.google.com/edge/litert/overview` and convert_pytorch, consulted 2026-09-27.
- `https://docs.pytorch.org/executorch/stable/` (intro, Android, iOS), consulted 2026-09-27.
- `https://developer.apple.com/documentation/coreml`, consulted 2026-09-27.
- `https://ml-explore.github.io/mlx/build/html/index.html`, consulted 2026-09-27.
- `https://nandhakishorm.github.io/laya/` and hooks docs; `docs/structured.md`, `docs/hooks/index.md`, consulted 2026-09-27.
- Community tools: omp-laya-judge, laya-adk-toolkit, laya-apple, stuntd READMEs, consulted 2026-09-27.
- Publisher packages: `flutter_local_voice_agent`, `webmcp_flutter`, `flutter_squiggly_text` on pub.dev, consulted 2026-09-27.
- Local stub: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/laya_flutter.dart`, `lib/src/library.dart`, `pubspec.yaml`, consulted 2026-09-27.
- `wiki/solutions/`: does not exist; no prior solution cited (`research/checkpoint.md`; `research/api-surface.md`).

## Provenance

| Section | Contributing input(s) |
|---|---|
| Question | Combined from `research/runtime.md`, `research/checkpoint.md`, `research/api-surface.md` |
| Answer — Runtime | `research/runtime.md` |
| Answer — First checkpoint | `research/checkpoint.md` |
| Answer — API surface | `research/api-surface.md` |
| Findings — Goal locks… | All three (deduplicated) |
| Findings — Graph + three checkpoints | `research/runtime.md` + `research/checkpoint.md` (deduplicated) |
| Findings — Encoder ops | `research/runtime.md` |
| Findings — Hub safetensors sizes | `research/checkpoint.md` (primary table) + `research/runtime.md` (English/card download baseline; deduplicated) |
| Findings — Official Hub no ONNX vs community ONNX | `research/checkpoint.md` + `research/runtime.md` (kept as distinct artifacts) |
| Findings — `laya[onnx]` / exporter gap | `research/runtime.md` |
| Findings — Answer decoding outside graph | `research/runtime.md` |
| Findings — ORT + Flutter plugins | `research/runtime.md` |
| Findings — LiteRT / ExecuTorch / Core ML / MLX | `research/runtime.md` |
| Findings — First phone download (multilingual) | `research/checkpoint.md` |
| Findings — Finished API surface | `research/api-surface.md` |
| Findings — Horizon tension (first download vs Router API) | Explicit merge of `research/checkpoint.md` vs `research/api-surface.md` |
| Findings — Apache-2.0 | `research/checkpoint.md` + `research/api-surface.md` (deduplicated; UNVERIFIED pubspec marker from API retained) |
| Options considered — Runtime | `research/runtime.md` |
| Options considered — Checkpoint | `research/checkpoint.md` |
| Options considered — API | `research/api-surface.md` |
| Constraints discovered | All three (deduplicated; artifact distinction retained) |
| Unresolved | All markers from all three inputs (none dropped) |
| Sources | Union of all three inputs |
