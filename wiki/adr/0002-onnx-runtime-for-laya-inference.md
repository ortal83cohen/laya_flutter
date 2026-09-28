---
id: adr-0002-onnx-runtime-for-laya-inference
title: "ADR 0002: Use ONNX Runtime for offline Laya inference"
status: active
owner: unassigned
last_verified: 2026-09-27
applies_to: ["lib/**", "pubspec.yaml", "integration_test/**"]
summary: Offline Laya inference runs on ONNX Runtime, not LiteRT or ExecuTorch, so Flutter can reuse the upstream ONNX agent graph contract.
---

# ADR 0002: Use ONNX Runtime for offline Laya inference

- Status: accepted
- Date: 2026-09-27
- Deciders: work item 0002-offline-predict research and plan validation

## Context and problem statement

Which single on-device inference engine should execute Laya's encoder-plus-decision-head in Flutter so choice, score, and noul answers can match Python Laya, while still covering Android and iOS?

## Decision drivers

- A published Laya graph path and measured logit parity with PyTorch.
- One engine that covers the required mobile platforms without a second runtime.
- Alignment with upstream `laya[onnx]` / `ONNXAgent` input and output names.
- Avoid inventing a new export pipeline for this slice.

## Considered options

### ONNX Runtime via a community Flutter wrapper

Export or adopt an ONNX graph that matches the ONNX agent contract; run it with ONNX Runtime; decode answers in Dart the same way `ONNXAgent` does after logits.

### LiteRT / TFLite

Convert the PyTorch `DecisionModel` with a LiteRT converter and run through a Flutter LiteRT binding.

### ExecuTorch

Export to `.pte` and run through a Flutter ExecuTorch binding.

## Decision outcome

Chosen option: ONNX Runtime via `flutter_onnxruntime`.

It is the only compared option with an upstream consumer, published ModernBERT/mmBERT-plus-head exports, measured logit parity, and official coverage of Android, iOS, desktop, and web. LiteRT and ExecuTorch can cover those platforms in principle, but neither had a published Laya artifact or parity evidence when this decision was made. Core ML and MLX were not viable because they cannot satisfy Android with the same engine.

## Consequences

- Positive: Flutter reuses the ONNX agent I/O contract and community graphs that already report logit parity; one engine story for SC-006 extras.
- Negative: F32 ONNX graphs are larger than fp16 safetensors; Flutter depends on a community ORT plugin; quantized graphs remain unresolved.

## Confirmation

Compliance is verified by these commands from the repository root:

```bash
grep -E 'flutter_litert|executorch' pubspec.yaml; test $? -eq 1
grep -E 'flutter_onnxruntime:' pubspec.yaml
rg -n 'OnnxRuntime\(\)\.createSession' lib/
```

The first must find no match (exit status 1). The second must print the `flutter_onnxruntime` dependency line. The third must show session creation on the load path.

A violation is a LiteRT or ExecuTorch inference dependency in `pubspec.yaml`, or a load/predict path that opens a session without `OnnxRuntime().createSession`.

## Pros and cons of the options

### ONNX Runtime

- Good: upstream graph contract, published exports, parity numbers, multi-platform ORT.
- Bad: large F32 files; community Flutter wrapper maintenance.

### LiteRT / TFLite

- Good: multi-platform story and Flutter bindings exist.
- Bad: no Laya export or parity evidence; iOS Swift packaging was still pre-release in the research window.

### ExecuTorch

- Good: multi-platform Flutter story exists.
- Bad: no Laya `.pte` or numeric parity; dynamic marker shapes unproven for this head.

## More information

- `wiki/work/0002-offline-predict/research/runtime.md`
- `wiki/product/offline-multilingual-onnx.md`
- Upstream `scripts/export_onnx.py` and `laya/onnx_agent.py` on NandhaKishorM/laya
