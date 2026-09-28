# Session load (U1 / AC-008)

## Verdict

**PASS.** `flutter_onnxruntime` opened a host session on the multilingual Laya graph via macOS
`integration_test`.

## Graph

- Source: `mariojcr/laya-onnx` → `multilingual/laya-multilingual.onnx`
- Path: `/Users/ortalcohen/.cache/laya_flutter/onnx/multilingual/laya-multilingual.onnx`
- Size: `1290466290` bytes (not re-downloaded)
- Not committed; stored outside the package tree

## Session I/O (asserted)

- Inputs: `input_ids`, `attention_mask`, `marker_pos`, `marker_mask`, `qtype`
- Outputs: `logits`, `act_logits`

## Attempt that passed

Sandbox was left enabled. `macos/Runner/DebugProfile.entitlements` gained a temporary absolute-path
read-only exception for `/Users/ortalcohen/.cache/laya_flutter/` (Release entitlements unchanged).

```bash
export LAYA_ONNX_PATH="$HOME/.cache/laya_flutter/onnx/multilingual/laya-multilingual.onnx"
flutter test integration_test/host_session_load_test.dart -d macos
```

## Pasted flutter test output

```
00:00 +0: loading /Users/ortalcohen/Documents/GitHub/laya_flutter/integration_test/host_session_load_test.dart
Building macOS application...                                   
✓ Built build/macos/Build/Products/Debug/laya_flutter.app
Failed to foreground app; open returned 1
00:00 +0: flutter_onnxruntime opens a session on the multilingual Laya graph
00:01 +1: (tearDownAll)
00:01 +1: All tests passed!
```

## Prior attempts (superseded)

1. VM `flutter test`: `MissingPluginException` (plugin not registered).
2. macOS integration without cache entitlement: `SESSION_CREATION_FAILED` / system error number 1 (
   EPERM under app sandbox).

Recorded: 2026-09-27
