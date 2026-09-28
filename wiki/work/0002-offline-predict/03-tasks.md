# Tasks: Offline Laya typed decisions in Flutter

## Legend

- `[P]` — may run in a parallel subagent. Only mark a task `[P]` if no other `[P]` task in the same group touches any of the same files.
- Every task cites the criteria it satisfies and the unit (`U1`, `U2`) it completes. A task satisfying no criterion does not belong here.
- Owned files are exclusive. Two tasks never list the same file.

## Groups

Groups run in sequence. No task in this work item is parallel. One implementer runs Group 1 from top to bottom.

### Group 1 — Offline multilingual predict

| # | Task | Satisfies | Files owned | Parallel | Done when |
|---|---|---|---|---|---|
| 1.1 | U1. Prove flutter_onnxruntime can open a session on the multilingual graph on the host, or record a failure that stops the slice | AC-008 | pubspec.yaml, test/host_session_load_test.dart, wiki/work/0002-offline-predict/session-load.md | | Done 2026-09-27: PASS — macOS integration_test opened session; inputs input_ids,attention_mask,marker_pos,marker_mask,qtype; outputs logits,act_logits; evidence in session-load.md |
| 1.2 | U2. Select a multilingual ONNX graph from official scripts/export_onnx.py, or a community file with the same input and output names, and record logit-parity evidence | AC-005, AC-007 | lib/src/onnx_graph.dart | | Done 2026-09-27: lib/src/onnx_graph.dart names mariojcr/laya-onnx multilingual graph + companions; matchesOnnxAgentContract rejects mismatched I/O; no ONNX binary committed |
| 1.3 | U3. Download convaiinnovations/laya-multilingual artifacts once into a caller-chosen directory and reload offline | AC-001, AC-002 | lib/src/checkpoint_store.dart, test/checkpoint_store_test.dart | | Done 2026-09-27: empty cache invokes download and stores artifacts; complete cache skips download when download would throw; incomplete cache with throwing download fails |
| 1.4 | U4. Tokenize one state plus a question map into the five ONNX tensors and shape logits into choice, score, and noul | AC-003 | lib/src/tokenize.dart, lib/src/answers.dart, test/answers_test.dart | | Done 2026-09-27: known logits → choice argmax, expected score, noul side; wrong T disagrees on score level; `flutter test test/answers_test.dart` all passed |
| 1.5 | U5. Public LayaFlutter.open and predict for one state and one question map, offline | AC-003 | lib/laya_flutter.dart, lib/src/library.dart, lib/src/loaded_runtime.dart, test/offline_predict_test.dart, integration_test/offline_predict_test.dart | | Done 2026-09-27: VM `flutter test test/offline_predict_test.dart` 3 passed (empty questions throw; missing cache fails with disabled downloader; complete cache skips download). macOS `flutter test integration_test/offline_predict_test.dart -d macos` passed — predict returned choice/score/noul with probabilities and confidence |
| 1.6 | U6. Frozen English and non-English fixtures, each with state, question map, and Python outputs, compared on the host | AC-004, AC-006 | test/fixtures/parity_fixtures.json, test/host_parity_test.dart, tool/freeze_fixtures.md, integration_test/host_parity_test.dart | | Done 2026-09-27: Python ONNXAgent ran (laya 0.3.20); en choice=green, he choice=red; VM `flutter test test/host_parity_test.dart` 3 passed; macOS `flutter test integration_test/host_parity_test.dart -d macos` passed (both fixtures match; tamper fails; English-only rejected) |

## Serialised files

| File | Owning task |
|---|---|
| pubspec.yaml | 1.1 |
| lib/laya_flutter.dart | 1.5 |
| lib/src/library.dart | 1.5 |

## Test tasks

| # | Covers | Positive case | Negative case |
|---|---|---|---|
| 1.1 | AC-008 | Host session opens on the selected graph | Proceeding without a successful load or a stop record |
| 1.3 | AC-001, AC-002, AC-007 | Empty cache downloads; second load is offline; package contains no weights | Empty cache after first load; second load hits the network; a graph binary committed in the package |
| 1.4 | AC-003 | Known logits become choice, score, and noul | A wrong temperature matches the Python reference |
| 1.5 | AC-003 | Offline predict with one question of each type | Empty question map returns answers; missing checkpoint calls remote inference |
| 1.6 | AC-004, AC-006 | Host parity on English and non-English fixtures | A tampered Python choice label still passes; English-only fixtures are accepted |
