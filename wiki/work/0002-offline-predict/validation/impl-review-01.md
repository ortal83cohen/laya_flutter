# Implementation review — round 01

- Work item: 0002-offline-predict
- Reviewed artifact: current working tree (`lib/`, `test/`, `integration_test/`, `pubspec.yaml`,
  `tool/freeze_fixtures.md`, `macos/Runner/DebugProfile.entitlements`); git HEAD unavailable in this
  checkout
- Reviewer: impl-validator
- Date: 2026-09-27

## Verdict

**PASS**

Every frozen criterion AC-001 through AC-008 is met by the current tree: VM and macOS host checks
pass with pasted evidence, required negative cases exist and fail when the behaviour is wrong, and
no blockers were found.

## Verification performed

Format:

```text
$ dart format --output=none --set-exit-if-changed lib example/lib
Formatted 8 files (0 changed) in 0.03 seconds.
FORMAT_EXIT=0
```

Analyze:

```text
$ dart analyze --fatal-infos --fatal-warnings
Analyzing laya_flutter...
No issues found!
ANALYZE_EXIT=0
```

VM tests:

```text
$ flutter test
00:00 +0: loading /Users/ortalcohen/Documents/GitHub/laya_flutter/test/answers_test.dart
00:00 +0: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/answers_test.dart: known logits become choice label, expected score, and noul side
00:00 +1: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/answers_test.dart: wrong temperature disagrees with reference temperature score level
00:00 +2: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/answers_test.dart: shaping omits a question when it has no logits
00:00 +3: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/answers_test.dart: empty question map yields no answers and no tensors
00:00 +4: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/answers_test.dart: tokenize packs one state and questions into five ONNX tensors
00:00 +5: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/host_parity_test.dart: fixture set includes English and non-English with question maps
00:00 +6: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/host_parity_test.dart: English-only fixture set is rejected
00:00 +7: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/host_parity_test.dart: tampered committed choice label fails label comparison
00:00 +8: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/offline_predict_test.dart: empty question list throws and does not invent answers
00:00 +9: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/offline_predict_test.dart: missing local checkpoint fails without calling remote inference
00:00 +10: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/offline_predict_test.dart: complete cache with disabled network does not invoke the downloader
00:00 +11: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/checkpoint_store_test.dart: required artifact list excludes model.safetensors
00:00 +12: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/checkpoint_store_test.dart: first call on empty directory invokes download and stores artifacts
00:00 +13: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/checkpoint_store_test.dart: second call with complete directory skips download even when it would throw
00:00 +14: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/checkpoint_store_test.dart: incomplete directory fails when download throws and does not report success
00:00 +15: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/checkpoint_store_test.dart: download that leaves cache incomplete fails after download
00:00 +16: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/widget_test.dart: library facade can be constructed
00:00 +17: /Users/ortalcohen/Documents/GitHub/laya_flutter/test/host_session_load_test.dart: multilingual Laya ONNX graph is present with expected size
00:00 +18: All tests passed!
FLUTTER_TEST_EXIT=0
```

Host graph constraint (not re-downloaded):

```text
$ wc -c "$HOME/.cache/laya_flutter/onnx/multilingual/laya-multilingual.onnx"
 1290466290 /Users/ortalcohen/.cache/laya_flutter/onnx/multilingual/laya-multilingual.onnx
```

macOS integration — session load (AC-008 / AC-005 I/O):

```text
$ export LAYA_ONNX_PATH="$HOME/.cache/laya_flutter/onnx/multilingual/laya-multilingual.onnx"
$ flutter test integration_test/host_session_load_test.dart -d macos
00:00 +0: loading /Users/ortalcohen/Documents/GitHub/laya_flutter/integration_test/host_session_load_test.dart
Building macOS application...
✓ Built build/macos/Build/Products/Debug/laya_flutter.app
Failed to foreground app; open returned 1
00:00 +0: flutter_onnxruntime opens a session on the multilingual Laya graph
00:01 +1: (tearDownAll)
00:01 +1: All tests passed!
SESSION_EXIT=0
```

macOS integration — offline predict (AC-003):

```text
$ export LAYA_CACHE_DIR="$HOME/.cache/laya_flutter"
$ flutter test integration_test/offline_predict_test.dart -d macos
00:00 +0: loading /Users/ortalcohen/Documents/GitHub/laya_flutter/integration_test/offline_predict_test.dart
Building macOS application...
✓ Built build/macos/Build/Products/Debug/laya_flutter.app
Failed to foreground app; open returned 1
00:00 +0: offline predict returns choice, score, and noul with probabilities
00:02 +1: (tearDownAll)
00:02 +1: All tests passed!
OFFLINE_EXIT=0
```

macOS integration — host parity (AC-004 / AC-006):

```text
$ export LAYA_CACHE_DIR="$HOME/.cache/laya_flutter"
$ flutter test integration_test/host_parity_test.dart -d macos
00:00 +0: loading /Users/ortalcohen/Documents/GitHub/laya_flutter/integration_test/host_parity_test.dart
Building macOS application...
✓ Built build/macos/Build/Products/Debug/laya_flutter.app
Failed to foreground app; open returned 1
00:00 +0: host Dart predict matches committed Python outputs on every fixture
00:02 +1: (tearDownAll)
00:02 +1: All tests passed!
PARITY_EXIT=0
```

Package binary absence (AC-007):

```text
$ find . -path ./build -prune -o -path ./.dart_tool -prune -o \( -name '*.onnx' -o -name 'model.safetensors' -o -name '*.safetensors' \) -print
(no output)

$ git ls-files '*.onnx' '*.safetensors' 'model.safetensors'
(no output)

$ git check-ignore -v .dart_tool/laya_cache/multilingual/laya-multilingual.onnx
.gitignore:31:/.dart_tool/	.dart_tool/laya_cache/multilingual/laya-multilingual.onnx
```

Ad-hoc negative probe for ONNX agent I/O helper (AC-005; not left in the tree):

```text
$ flutter test /tmp/onnx_contract_probe_test.dart
00:00 +0: wrong I/O names fail contract
00:00 +1: All tests passed!
PROBE_EXIT=0
```

## Per-criterion results

| Criterion | Result | Evidence (file:line)                                                                                                                                                                                                                                               | Negative case exercised                                                                                                                                                                                    |
|-----------|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AC-001    | pass   | `test/checkpoint_store_test.dart:65-92` (empty cache → download → four artifacts on disk); real fetcher `lib/src/library.dart:68-108`                                                                                                                              | yes — `test/checkpoint_store_test.dart:132-144` incomplete download fails; `test/checkpoint_store_test.dart:48-61` excludes `model.safetensors`                                                            |
| AC-002    | pass   | `test/checkpoint_store_test.dart:95-110` second load skips download when download would throw; `test/offline_predict_test.dart:63-102` complete cache + disabled network does not invoke downloader                                                                | yes — `test/checkpoint_store_test.dart:112-130` incomplete cache with throwing download fails and stays incomplete                                                                                         |
| AC-003    | pass   | `integration_test/offline_predict_test.dart:23-86` macOS predict returns choice, score, noul with probabilities and confidence (command output above)                                                                                                              | yes — `test/offline_predict_test.dart:8-26` empty questions throw; `test/offline_predict_test.dart:28-61` missing checkpoint with disabled network fails without remote inference                          |
| AC-004    | pass   | `integration_test/host_parity_test.dart:180-230` every fixture choice label, score level, noul side equals committed Python (command output above); fixtures `test/fixtures/parity_fixtures.json:1-89`                                                             | yes — `integration_test/host_parity_test.dart:232-250` and `test/host_parity_test.dart:110-131` tampered Python choice label does not match                                                                |
| AC-005    | pass   | Engine: `lib/src/library.dart:45-47` `OnnxRuntime().createSession`; predict forward: `lib/src/loaded_runtime.dart:84-136`; contract + logit-parity citation: `lib/src/onnx_graph.dart:1-48`; host I/O assert: `integration_test/host_session_load_test.dart:33-45` | yes — session-load expects exact agent I/O names (wrong graph fails); ad-hoc probe showed `matchesOnnxAgentContract` false on wrong names; predict rejects mismatch at `lib/src/loaded_runtime.dart:84-88` |
| AC-006    | pass   | Fixtures `test/fixtures/parity_fixtures.json:7-12` (`en_short`) and `:48-50` (`he_short`); VM inspect `test/host_parity_test.dart:65-91`; both executed in `integration_test/host_parity_test.dart:198-230`                                                        | yes — `test/host_parity_test.dart:93-108` English-only set rejected by `hasEnglishAndNonEnglish`                                                                                                           |
| AC-007    | pass   | Search of published/committed tree (commands above); required list excludes safetensors `lib/src/checkpoint_store.dart:43-52`; `tool/freeze_fixtures.md:50-53`                                                                                                     | yes — any committed `*.onnx` / `model.safetensors` would appear in `find` / `git ls-files`; none present                                                                                                   |
| AC-008    | pass   | Re-run `integration_test/host_session_load_test.dart` PASS (output above); recorded stop-or-pass artifact `wiki/work/0002-offline-predict/session-load.md:1-45`                                                                                                    | yes — session-load.md records prior VM `MissingPluginException` and sandbox EPERM; work item did not proceed without a successful host session load                                                        |

## Findings

No findings.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| (none)  | —                |
