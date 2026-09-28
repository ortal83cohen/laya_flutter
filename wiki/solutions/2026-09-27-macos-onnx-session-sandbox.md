---
id: solution-2026-09-27-macos-onnx-session-sandbox
title: "macOS ONNX session proof needs integration_test and a sandbox cache exception"
status: active
owner: unassigned
last_verified: 2026-09-27
applies_to: ["integration_test/**", "macos/Runner/**", "test/**"]
summary: Prove flutter_onnxruntime session load with macOS integration_test; VM flutter test cannot register the plugin, and the sandbox blocks ~/.cache until DebugProfile.entitlements allows it.
---

# macOS ONNX session proof needs integration_test and a sandbox cache exception

- Track: knowledge
- Work item: 0002-offline-predict
- Written: 2026-09-27

## Context

The first unit of offline predict had to prove that `flutter_onnxruntime` can open a session on the multilingual Laya graph on the developer host. The graph lives under `$HOME/.cache/laya_flutter/`. Two failures looked like product defects before the harness was understood.

## Guidance

Use macOS `integration_test` for any native session-open proof:

```bash
export LAYA_ONNX_PATH="$HOME/.cache/laya_flutter/onnx/multilingual/laya-multilingual.onnx"
flutter test integration_test/host_session_load_test.dart -d macos
```

Do not treat VM `flutter test` as a session-load proof. The plugin is not registered there and surfaces `MissingPluginException`.

If the integration run fails with `SESSION_CREATION_FAILED` and system error number 1 while the sandbox stays enabled, add a temporary read-only absolute-path exception for the cache directory in `macos/Runner/DebugProfile.entitlements`. Leave Release entitlements unchanged unless a release host probe needs the same path.

## Why this matters

The final library code can look healthy while every VM session test fails for plugin registration, and a correct macOS integration test can still fail with errno 1 for sandbox policy. Neither signal is visible from the Dart API surface alone.

## When to apply

Whenever a later slice must prove ONNX Runtime session load or host parity against a graph stored under the developer cache on macOS.

## Examples

Work item evidence: `wiki/work/0002-offline-predict/session-load.md` (VM MissingPluginException, then sandbox errno 1, then PASS after the DebugProfile exception).
