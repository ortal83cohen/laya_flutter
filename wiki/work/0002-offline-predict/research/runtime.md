# Research: Offline Laya inference runtime for Flutter

## Question

Which single inference runtime can execute Laya's encoder-plus-decision-head on Android and iOS so that choice labels, score levels, and noul sides match a Python Laya forward pass, and does that same runtime also cover macOS, Windows, Linux, and web without a second engine?

## Answer

**ONNX Runtime** is the only compared option with a Laya-supported graph path (`laya[onnx]` / `ONNXAgent`), a verified encoder-plus-head ONNX export of ModernBERT/mmBERT plus the typed decision head, and official coverage of Android, iOS, macOS, Windows, Linux, and browsers. Community Flutter wrappers of that same engine (`flutter_onnxruntime` and similar) claim CPU inference on all six Flutter targets. LiteRT/TFLite and ExecuTorch can cover those platforms in principle, but neither has a published Laya export or parity evidence. Core ML and MLX cannot satisfy Android. Extra platforms this one runtime covers without a second engine: **macOS, Windows, Linux, and web**.

## Findings

### Goal requires one runtime for mobile, optional extras only if that same engine covers them

- Claim: Android and iOS are required. macOS, Windows, Linux, and web ship only when one runtime covers them without a second engine. Quality is argmax parity of choice label, score level, and noul side against Python Laya on a frozen fixture set. Snake is later; this slice is offline typed decisions.
- Evidence: Users-and-where-it-runs, closed assumptions, SC-002 and SC-006.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 17–35 and 39–46.

### Laya's graph is a transformers encoder (ModernBERT or mmBERT) plus a small typed decision head

- Claim: `DecisionModel` loads a Hugging Face encoder via `AutoModel`, adds optional `TransformerEncoder` head layers, type embeddings, an option-marker scorer, and an act head. Forward takes `input_ids`, `attention_mask`, `marker_pos`, `marker_mask`, `qtype` and returns `logits` and `act_logits`. Checkpoints are ModernBERT-large (English / typed-decisions, 421M) or mmBERT-base (multilingual, 322M).
- Evidence: `DecisionModel` and `build_model` in `laya/common.py`; model card architecture and checkpoint table.
- Source: `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/common.py` (`DecisionModel`, `build_model`, `_apply_rope_config`), consulted 2026-09-27. `https://huggingface.co/convaiinnovations/laya` (Architecture; checkpoint table), consulted 2026-09-27.

### Encoder ops that matter for export: RoPE, GeGLU, local/sliding attention

- Claim: ModernBERT uses rotary positional embeddings (RoPE), GeGLU activations, and local-global alternating attention. Laya's loader remaps transformers-5 `rope_parameters` for `full_attention` and `sliding_attention` onto `global_rope_theta` / `local_rope_theta` so mmBERT's sliding RoPE base is not silently wrong. The decision head itself is standard `nn.TransformerEncoderLayer` plus linear scorers, not a second encoder stack with custom RoPE.
- Evidence: ModernBERT model card Training/Architecture bullets; Laya `_apply_rope_config` docstring and mapping; `DecisionModel.__init__` head construction.
- Source: `https://huggingface.co/answerdotai/ModernBERT-large` (Model Summary; Training), consulted 2026-09-27. `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/common.py` (`_apply_rope_config`, `DecisionModel`), consulted 2026-09-27. mmBERT is described as built on the ModernBERT architecture: `https://huggingface.co/jhu-clsp/mmBERT-base`, consulted 2026-09-27.

### Upstream `laya[onnx]` loads an ONNX graph of that same forward contract

- Claim: Optional dependency `onnx = ["onnx", "onnxruntime"]` exists. `ONNXAgent` opens an `.onnx` with ONNX Runtime, feeds the same five tensors as `DecisionModel.forward`, reads `logits` and `act_logits`, then applies the same temperature / softmax / answer shaping as the PyTorch agent (choice via `argmax`, score as expected level, noul as `p[1]`). Missing graph raises with “Please run export_onnx.py first.”
- Evidence: `pyproject.toml` optional-dependencies; `ONNXAgent.__init__` and `_infer` session I/O and answer decoding.
- Source: `https://raw.githubusercontent.com/NandhaKishorM/laya/main/pyproject.toml`, consulted 2026-09-27. `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/onnx_agent.py`, consulted 2026-09-27. README lists `laya[onnx]` among optional extras: `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md` (Installation), consulted 2026-09-27.

### Official GitHub tree consumers ONNX but does not ship the exporter

- Claim: The NandhaKishorM/laya `main` tree includes `laya/onnx_agent.py` and `scripts/export_onnx.py`. That script calls `torch.onnx.export` with input names `input_ids`, `attention_mask`, `marker_pos`, `marker_mask`, `qtype` and output names `logits`, `act_logits`. Community `mariojcr/laya-onnx` also publishes a dynamo export with dynamic axes; it is not the only matching exporter. An earlier draft of this finding said the tree had no exporter; that sentence was wrong and is withdrawn.
- Evidence: `https://raw.githubusercontent.com/NandhaKishorM/laya/main/scripts/export_onnx.py` lines 43–51 and 63–71, consulted 2026-09-27; `mariojcr/laya-onnx` export script.
- Source: `https://api.github.com/repos/NandhaKishorM/laya/git/trees/main?recursive=1`, consulted 2026-09-27. `https://huggingface.co/mariojcr/laya-onnx` and `https://huggingface.co/mariojcr/laya-onnx/raw/main/export_onnx.py`, consulted 2026-09-27.

### Published ONNX exports include ModernBERT and mmBERT and report logit parity

- Claim: `mariojcr/laya-onnx` exports english (`laya.onnx`, ModernBERT-large, 1 688 711 336 bytes F32), multilingual (`laya-multilingual.onnx`, mmBERT-base, 1 290 466 290 bytes F32), and typed-decisions. The card states max |Δ logits| = 1.8e-6 vs PyTorch on the README example and a second batch shape, under ONNX Runtime 1.29 CPU. The export script aborts if max |Δlogits| exceeds 1e-3 on two shapes. `receptron/laya-onnx` reports max logit difference ≈ 1e-5 for the English graph with the same five inputs. `yehor-oleksiuk/laya-english-onnx` reports a different I/O contract and 100% argmax agreement of an int8 graph vs its own fp32 ONNX on 120 samples — useful as secondary int8 evidence, not as the `ONNXAgent` contract.
- Evidence: HF API tree sizes; model-card Parity sections; export script verification gate; yehor README Files / Calibration sections.
- Source: `https://huggingface.co/api/models/mariojcr/laya-onnx/tree/main/english` and `.../multilingual`, consulted 2026-09-27. `https://huggingface.co/mariojcr/laya-onnx`, consulted 2026-09-27. `https://huggingface.co/mariojcr/laya-onnx/raw/main/export_onnx.py`, consulted 2026-09-27. `https://huggingface.co/receptron/laya-onnx`, consulted 2026-09-27. `https://huggingface.co/yehor-oleksiuk/laya-english-onnx/raw/main/README.md`, consulted 2026-09-27.

### PyTorch checkpoint weight sizes (download baseline, not the ONNX file)

- Claim: Official English `model.safetensors` is 842 609 210 bytes. Hub metadata reports ~421M parameters mostly F16. HF model card single-model load notes English ≈ 808 MB and multilingual ≈ 647 MB download sizes.
- Evidence: HF tree `size` for `model.safetensors`; `safetensors.total` / F16 count on the model API; model-card single-model comments.
- Source: `https://huggingface.co/api/models/convaiinnovations/laya/tree/main`, consulted 2026-09-27. `https://huggingface.co/api/models/convaiinnovations/laya`, consulted 2026-09-27. `https://huggingface.co/convaiinnovations/laya` (Single-Model Mode), consulted 2026-09-27.

### ONNX Runtime officially covers Android, iOS, desktop, and web

- Claim: ONNX Runtime documents mobile packages for Android and iOS, install paths for Windows/Linux/macOS, and ONNX Runtime Web for browsers (WebAssembly CPU across major browsers; WebGPU/WebGL/WebNN with browser limits). The product site states it runs on Linux, Windows, Mac, iOS, Android, and web browsers.
- Evidence: Mobile tutorial package list; install guide web/mobile sections; ORT Web supported-versions table; home-page Cross-Platform claim.
- Source: `https://onnxruntime.ai/docs/tutorials/mobile/`, consulted 2026-09-27. `https://onnxruntime.ai/docs/install/`, consulted 2026-09-27. `https://onnxruntime.ai/docs/get-started/with-javascript/web.html`, consulted 2026-09-27. `https://onnxruntime.ai/`, consulted 2026-09-27.

### Flutter access to ONNX Runtime is via community plugins, not a Microsoft Flutter package

- Claim: No Microsoft-published Flutter binding appears in the official mobile language list (Java/Kotlin, C/C++, Objective-C, MAUI C#). `flutter_onnxruntime` on pub.dev wraps ONNX Runtime 1.23.0 and marks CPU inference complete for Android, iOS, Linux, macOS, Windows, and Web. Other community packages exist with overlapping native platforms.
- Evidence: ORT mobile language list; pub.dev implementation-status table for `flutter_onnxruntime`.
- Source: `https://onnxruntime.ai/docs/tutorials/mobile/`, consulted 2026-09-27. `https://pub.dev/packages/flutter_onnxruntime`, consulted 2026-09-27.

### LiteRT / TFLite: multi-platform engine, no Laya export or parity evidence

- Claim: Google LiteRT runs on Android, iOS/macOS, Web, Linux, Windows, and IoT, with a PyTorch→LiteRT converter (`litert-torch`) that requires `torch.export`-compliant models. Community `flutter_litert` claims bundled runtimes for Android, iOS, macOS, Windows, Linux, and web. No Laya `.tflite` / LiteRT artifact, exporter, or logit/argmax parity report was found in the official Laya repo, model card, or the ONNX community exports consulted. Official iOS Swift LiteRT packaging is still pre-release (nightly CocoaPod; SPM in progress), which weakens a Flutter-iOS story that depends on that stack.
- Evidence: LiteRT overview platform and conversion tables; flutter_litert metadata; absence of TFLite paths in Laya package tree and HF siblings; iOS distribution note on the overview page.
- Source: `https://developers.google.com/edge/litert/overview`, consulted 2026-09-27. `https://developers.google.com/edge/litert/models/convert_pytorch`, consulted 2026-09-27. `https://pub.dev/packages/flutter_litert`, consulted 2026-09-27. `https://api.github.com/repos/NandhaKishorM/laya/git/trees/main?recursive=1` and `https://huggingface.co/api/models/convaiinnovations/laya`, consulted 2026-09-27.

### ExecuTorch: multi-platform engine, no Laya `.pte` or parity evidence

- Claim: ExecuTorch documents Android (AAR / XNNPACK and others) and iOS/macOS runtimes, and describes export via `torch.export` into `.pte`. Community `executorch_flutter` claims Android, iOS, macOS, Windows, Linux, and Web. No Laya `.pte`, export recipe, or numeric parity against Python Laya was found. Whether ModernBERT/mmBERT local-global attention and Laya's dynamic `n`/`L`/`k` axes export cleanly to ExecuTorch for this head remains unshown.
- Evidence: Official Android and “how it works” docs; pub.dev platform table; no ExecuTorch artifacts in Laya tree or HF model siblings.
- Source: `https://docs.pytorch.org/executorch/stable/using-executorch-android.html`, consulted 2026-09-27. `https://docs.pytorch.org/executorch/stable/using-executorch-ios.html`, consulted 2026-09-27. `https://docs.pytorch.org/executorch/stable/intro-how-it-works.html`, consulted 2026-09-27. `https://pub.dev/packages/executorch_flutter`, consulted 2026-09-27.

### Core ML and MLX fail the Android requirement (rejected for this question)

- Claim: Core ML is Apple's on-device framework. MLX is documented as an Apple silicon array framework. Neither is a single engine that also runs Android, so neither can be the one runtime for this product's required platforms.
- Evidence: Apple Core ML documentation hub; MLX homepage device framing.
- Source: `https://developer.apple.com/documentation/coreml`, consulted 2026-09-27. `https://ml-explore.github.io/mlx/build/html/index.html`, consulted 2026-09-27.

### Answer decoding that SC-002 cares about lives outside the graph

- Claim: After logits, Python/`ONNXAgent` divide by temperature, softmax, then set `choice` to `keys[argmax(p)]`, `score` to the expected level `sum(i * p_i)`, and `noul` to `p[1]` (true). Matching the Python Laya forward pass for SC-002 therefore needs both a faithful graph and the same post-processing and tokenization (`build_sequence` / `collate_items`). Logit parity at ~1e-5–1e-6 is strong evidence that argmax and expected-score will match for the verified samples; it is not itself a frozen Flutter fixture run.
- Evidence: `ONNXAgent._infer` answer branches; `build_sequence` / `collate_items` in `common.py`.
- Source: `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/onnx_agent.py`, consulted 2026-09-27. `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/common.py`, consulted 2026-09-27. Goal SC-002: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` lines 41–42.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| ONNX Runtime via upstream `laya[onnx]` / `ONNXAgent` | Export encoder+head to one ONNX graph (`torch.onnx` dynamo path); run with ORT; decode answers in host language mirroring `ONNXAgent`. Flutter uses a community ORT plugin. | F32 ONNX graphs ~1.29–1.69 GB per checkpoint (english 1 688 711 336 B; multilingual 1 290 466 290 B) vs ~843 MB fp16 safetensors; community Flutter binding maintenance; need to re-run or adopt a verified export. | **Chosen.** Only option with an upstream consumer, published successful exports of ModernBERT and mmBERT plus the decision head, measured logit parity, and one engine that officially includes Android, iOS, desktop, and web. |
| LiteRT / TFLite | Convert PyTorch with `litert-torch` to `.tflite`; run LiteRT / `flutter_litert`. | Conversion and op-support work unknown for this architecture; no published Laya artifact; iOS Swift runtime still pre-release per Google docs. | **Rejected** for this slice: no Laya export or parity evidence. Platform story is plausible but unproven for this model. |
| ExecuTorch | `torch.export` → `.pte`; run ExecuTorch / `executorch_flutter`. | New export pipeline; no Laya `.pte`; dynamic marker/`k` shapes and ModernBERT attention unproven here. | **Rejected** for this slice: multi-platform Flutter story exists, but zero Laya-specific export or numeric parity. |
| Core ML (Apple) | Convert to `.mlmodel` / `.mlpackage`; run on iOS/macOS. | Apple-only; second engine still needed for Android. | **Rejected:** cannot cover required Android with the same runtime. |
| MLX | Run on Apple silicon via MLX. | Apple-silicon-oriented; not an Android+iOS+desktop+web single engine. | **Rejected:** fails the shared “one runtime / Android required” constraint. |

## Constraints discovered

- Android and iOS are mandatory; desktop and web may be named only if the chosen runtime covers them without a second engine (`wiki/product/GOAL.md`).
- Quality bar is decision parity with Python Laya (choice label, score level, noul side), not latency marketing numbers (`wiki/product/GOAL.md`).
- Weights are a one-time Hugging Face download, then offline; not bundled in the pub package (`wiki/product/GOAL.md`).
- Upstream Laya already defines the ONNX I/O contract and answer decoding; Flutter must reproduce tokenization and temperature post-processing, not invent a new head.
- Official Laya `main` ships `scripts/export_onnx.py` with the ONNX agent input and output names (consulted 2026-09-27). A community export is usable only when it matches that contract.
- F32 ONNX graphs are roughly 1.3–1.7 GB per checkpoint — larger than the fp16 safetensors — which constrains phone and especially web memory budgets even when the runtime supports the platform.
- Microsoft does not publish a Flutter ORT package; Flutter integration depends on community wrappers of the same ORT binaries/WASM build.
- Community ONNX graphs that use a different I/O layout than `ONNXAgent` (for example yehor's `type_ids` / `lengths` / `n_opts`) are not drop-in for the upstream path.

## Unresolved

- [UNRESOLVED: Has anyone run a frozen fixture set through ORT on Android and iOS (and desktop/web) and compared choice / score / noul to Python Laya end-to-end, beyond the Python ORT logit checks on community export cards?]
- [UNRESOLVED: Which Flutter ORT plugin version and ORT build (full vs mobile custom ops) actually load the ~1.3–1.7 GB ModernBERT/mmBERT Laya graphs with the ops those exports emit?]
- [UNRESOLVED: Is a smaller ORT-compatible quant (fp16 or int8) available that preserves SC-002 argmax parity on the chosen checkpoint, or must the product ship F32?]
- [UNRESOLVED: Does web ORT (WASM) practically load and run a multi-gigabyte Laya graph in real browsers under Flutter web, or should web be named as covered by the engine but deferred for device limits?]
- [UNRESOLVED: Would a first-party LiteRT or ExecuTorch export of `DecisionModel` succeed with dynamic `n`/`L`/`k` and ModernBERT local-global attention if someone invested the conversion work?]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-27.
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md`, consulted 2026-09-27.
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/pyproject.toml`, consulted 2026-09-27.
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/onnx_agent.py`, consulted 2026-09-27.
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/common.py`, consulted 2026-09-27.
- `https://api.github.com/repos/NandhaKishorM/laya/git/trees/main?recursive=1`, consulted 2026-09-27.
- `https://huggingface.co/convaiinnovations/laya`, consulted 2026-09-27.
- `https://huggingface.co/api/models/convaiinnovations/laya`, consulted 2026-09-27.
- `https://huggingface.co/api/models/convaiinnovations/laya/tree/main`, consulted 2026-09-27.
- `https://huggingface.co/answerdotai/ModernBERT-large`, consulted 2026-09-27.
- `https://huggingface.co/jhu-clsp/mmBERT-base`, consulted 2026-09-27.
- `https://huggingface.co/mariojcr/laya-onnx`, consulted 2026-09-27.
- `https://huggingface.co/mariojcr/laya-onnx/raw/main/export_onnx.py`, consulted 2026-09-27.
- `https://huggingface.co/api/models/mariojcr/laya-onnx/tree/main/english`, consulted 2026-09-27.
- `https://huggingface.co/api/models/mariojcr/laya-onnx/tree/main/multilingual`, consulted 2026-09-27.
- `https://huggingface.co/receptron/laya-onnx`, consulted 2026-09-27.
- `https://huggingface.co/yehor-oleksiuk/laya-english-onnx/raw/main/README.md`, consulted 2026-09-27.
- `https://onnxruntime.ai/`, consulted 2026-09-27.
- `https://onnxruntime.ai/docs/install/`, consulted 2026-09-27.
- `https://onnxruntime.ai/docs/tutorials/mobile/`, consulted 2026-09-27.
- `https://onnxruntime.ai/docs/get-started/with-javascript/web.html`, consulted 2026-09-27.
- `https://pub.dev/packages/flutter_onnxruntime`, consulted 2026-09-27.
- `https://developers.google.com/edge/litert/overview`, consulted 2026-09-27.
- `https://developers.google.com/edge/litert/models/convert_pytorch`, consulted 2026-09-27.
- `https://pub.dev/packages/flutter_litert`, consulted 2026-09-27.
- `https://docs.pytorch.org/executorch/stable/intro-how-it-works.html`, consulted 2026-09-27.
- `https://docs.pytorch.org/executorch/stable/using-executorch-android.html`, consulted 2026-09-27.
- `https://docs.pytorch.org/executorch/stable/using-executorch-ios.html`, consulted 2026-09-27.
- `https://pub.dev/packages/executorch_flutter`, consulted 2026-09-27.
- `https://developer.apple.com/documentation/coreml`, consulted 2026-09-27.
- `https://ml-explore.github.io/mlx/build/html/index.html`, consulted 2026-09-27.
- `https://nandhakishorm.github.io/laya/`, consulted 2026-09-27.
