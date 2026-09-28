---
id: offline-multilingual-onnx
title: Offline multilingual ONNX constraints
status: active
owner: unassigned
last_verified: 2026-09-27
applies_to: ["lib/**", "integration_test/**", "macos/**", "test/**"]
summary: Host harness, sandbox, and graph-provenance constraints for offline multilingual Laya ONNX that a casual read of the public API does not reveal.
---

# Offline multilingual ONNX constraints

Facts that stay true after the 0002-offline-predict slice and that an agent will miss if it only skims the public entry types.

## Host session proof

VM `flutter test` does not register `flutter_onnxruntime`. A session-open proof must use `integration_test` on macOS (`flutter test integration_test/... -d macos`). The VM suite may still assert cache layout, decode shaping, and fixture metadata without opening a native session.

## macOS sandbox and the host cache

The macOS debug runner keeps the app sandbox. Reading a graph under `$HOME/.cache/laya_flutter/` fails with session-creation errno 1 until `macos/Runner/DebugProfile.entitlements` grants a read-only absolute-path exception for that directory. Release entitlements stay unchanged. Callers that keep weights only inside the app-writable cache avoid this exception; host probes that reuse the developer cache need it.

## Graph provenance

The accepted runtime graph is the community multilingual ONNX (`mariojcr/laya-onnx` → `multilingual/laya-multilingual.onnx`) whose input and output names match the upstream ONNX agent contract. Official Hub `convaiinnovations/laya-multilingual` publishes safetensors, not that ONNX file; companions (tokenizer and agent config) still come from the official checkpoint id. The preferred producer for a replacement graph is upstream `scripts/export_onnx.py`; a community file is acceptable only when it keeps that same I/O contract and cited logit-parity evidence.

## Deliberate omissions in this slice

Android and iOS device launches, Router and multi-checkpoint lifecycle, English or typed-decisions downloads, presets, batch or long predict, quantization, and end-to-end device argmax claims remain out of scope for the offline-predict slice. Host fixture parity is the quality bar that exists today. Classic Snake gameplay lives under the example app and is covered separately in [classic-snake-example.md](classic-snake-example.md).
