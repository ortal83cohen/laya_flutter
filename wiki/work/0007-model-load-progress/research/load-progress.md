# Research: Numeric progress during LayaFlutter.open

## Question

During the example’s `LayaFlutter.open` wait (including minutes spent on Opening… when a complete 1290466290-byte ONNX file is already in the app cache, then `OnnxRuntime.createSession`), can the app read a numeric progress fraction from the library download, from `flutter_onnxruntime` session creation, or from neither? What are viable ways to drive a progress meter on the example home without a fake timer percentage?

## Answer

Neither path exposes a numeric progress fraction today. On a complete cache the Hugging Face download is skipped entirely, so the long Opening… wait is almost certainly the opaque `createSession` platform call; that call returns only when the session exists and has no progress API in `flutter_onnxruntime` 1.8.5 or in upstream ONNX Runtime session load. The honest meter for that dominant wait is an indeterminate indicator (or discrete real phase labels), not a continuous percentage. A download-byte fraction is only possible if the library’s HTTP pipe is instrumented, and it still does not cover the observed complete-cache session-load minutes.

## Findings

### Open is ensureLocal then a single createSession await

- Claim: `LayaFlutter.open` awaits `CheckpointStore.ensureLocal()`, then awaits `OnnxRuntime().createSession(onnxPath)` (or a test override), then builds `LoadedRuntime`. There is no progress parameter or callback on the public `open` signature.
- Evidence: `open` body runs `await store.ensureLocal()` then `await sessionFactory(onnxPath)` with default `(String path) => OnnxRuntime().createSession(path)`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart:25-58`.

### Complete cache skips download; expected ONNX size is 1290466290

- Claim: When every required artifact is present and the ONNX length equals `CheckpointStore.expectedOnnxBytes` (1290466290), `ensureLocal` returns without calling the downloader. `downloadMultilingualCheckpoint` also skips the ONNX fetch when `_onnxReady` is true.
- Evidence: `ensureLocal` short-circuits on `isComplete()`; `_onnxReady` checks `file.length() == CheckpointStore.expectedOnnxBytes`; download skips when ready.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/checkpoint_store.dart:31-32,64-67`; `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart:72-91,110-113`.

### Library download has no progress fraction today

- Claim: `_downloadHfFile` issues an HTTP GET, requires status 200, then `await response.pipe(sink)` into a `.partial` file and renames. It does not read `contentLength`, does not count transferred bytes, and does not invoke any progress callback. No `progress` / `onProgress` symbols exist under `lib/`.
- Evidence: pipe-only body at `_downloadHfFile`; repo-wide grep under `lib/` for progress APIs returned no matches (this research run).
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart:149-186`.

### Host-copy path is also an unprogressed File.copy

- Claim: When the app cache ONNX is not ready but a complete host copy exists under `$HOME/.cache/laya_flutter/...`, the library copies with `hostCopy.copy(onnxDest.path)` and does not report copy progress.
- Evidence: branch at `downloadMultilingualCheckpoint` after `_findHostOnnxCopy`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart:75-84,115-131`.

### flutter_onnxruntime 1.8.5 createSession is a single method-channel Future with no progress

- Claim: `OnnxRuntime.createSession` awaits `FlutterOnnxruntimePlatform.instance.createSession` once and returns `OrtSession.fromMap(result)`. The method-channel implementation invokes `'createSession'` with `modelPath` and `sessionOptions` only. `OrtSessionOptions` exposes only `intraOpNumThreads`, `interOpNumThreads`, `providers`, `useArena`, and `deviceId` — no progress field.
- Evidence: Dart API and options map; method channel args.
- Source: `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/lib/src/onnxruntime.dart:23-30`; `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/lib/src/flutter_onnxruntime_method_channel.dart:24-41`; `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/lib/src/ort_session.dart:91-114`.

### Android plugin createSession is blocking until OrtEnvironment.createSession returns

- Claim: On Android, the plugin’s `"createSession"` handler configures `OrtSession.SessionOptions`, then calls `ortEnvironment.createSession(modelPath, ortSessionOptions)` and only then `result.success` with session id and I/O names. No intermediate Flutter events are sent during load.
- Evidence: Kotlin handler success path after `createSession`.
- Source: `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/android/src/main/kotlin/com/masicai/flutteronnxruntime/FlutterOnnxruntimePlugin.kt:212-323`.

### Upstream ONNX Runtime has no session-load progress fraction API

- Claim: A core-runtime feature request for model-loading progress or a callback remains open; maintainers did not ship a load-progress API and instead suggested hiding load time or loading on another thread. C# `SessionOptions` documents load cancellation (`SetLoadCancellationFlag`) but not a progress fraction.
- Evidence: GitHub issue #17796 (open feature request, 2023-10-05; maintainer reply same day); SessionOptions load-cancellation docs in the C# binding.
- Source: https://github.com/microsoft/onnxruntime/issues/17796 ; https://github.com/microsoft/onnxruntime/blob/main/csharp/src/Microsoft.ML.OnnxRuntime/SessionOptions.shared.cs (consulted 2026-09-28).

### Example home awaits open as one boolean Opening… gate

- Claim: The example sets `_opening = true`, awaits `LayaFlutter.open(await resolveExampleCache())`, then navigates to `SnakeScreen`. While opening it shows the text `Opening…` only — no progress value. Shared slice decisions rename that label to exactly `Loading the model` (product decision for this work item, not yet in source at research time).
- Evidence: `_openSnake` and build branch for `_opening`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart:107-160`.

### Observed complete-cache wait matches opaque platform await (context, not a library guarantee)

- Claim: On 2026-09-28 the example on emulator-5554 already had `files/laya_flutter/laya-multilingual.onnx` at 1290466290 bytes and still showed Opening… for several minutes before Snake; the Dart isolate stack was empty while that wait continued, consistent with awaiting a platform call. This is observational context for which phase dominates, not a contractual guarantee of wall-clock duration.
- Evidence: Prompt-stated observation for this research stream; library path when cache is complete is `ensureLocal` then `createSession` as cited above.
- Source: Research prompt observation (2026-09-28); `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart:36-47`.

### Closed product assumptions that constrain the meter

- Claim: GOAL forbids a Snake step timer; shared decisions also forbid inventing a fake load percentage that advances on a timer. Weights arrive by one-time Hugging Face download; later runs use the local copy. Public `LayaFlutter.open` and `LoadedRuntime.predict` signatures stay closed unless a real fraction is impossible without a new optional callback — in which case that callback is an option to list, not to adopt in this research.
- Evidence: GOAL closed assumptions and SC-003/SC-004; research prompt shared decisions.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md:28-44`; research prompt for `0007-model-load-progress`.

### Prior solution does not answer load progress

- Claim: The macOS ONNX session sandbox solution covers how to prove session load on macOS (`integration_test`, sandbox entitlements). It does not describe download or session-load progress fractions.
- Evidence: Solution guidance is limited to harness and entitlements for session-open proof.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:21-40`.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Indeterminate meter during `open` (no numeric fraction) | Example home shows label `Loading the model` plus a Flutter progress control with no `value` (or equivalent indeterminate chrome) for the whole `await LayaFlutter.open(...)`. | Example-only UI; no library API change; no fake percentage. | Chosen: matches the finding that neither download nor `createSession` exposes a fraction for the dominant complete-cache wait; stays inside closed public signatures; complies with the no-fake-timer rule. |
| Instrument `_downloadHfFile` for bytes / Content-Length | Replace `pipe` with a listen that accumulates `contentLength`-based fraction and surfaces it somehow to the example. | Library change; only active when Hugging Face (or a partial) download runs; host `File.copy` still needs its own instrumentation; zero updates during complete-cache `createSession`. | Rejected for the observed minutes-long Opening… on a complete 1290466290-byte cache: that path never enters `_downloadHfFile`. Viable only as a first-run download improvement, not as the meter for session load. |
| Discrete real phases (ensureLocal done / createSession started / open done) without inventing intra-phase % | Split or wrap open so the example can show phase labels or step markers tied to real await boundaries. Continuous bar fill during `createSession` still cannot be true. | Needs either example-local wrapping that duplicates open stages, or an optional library progress callback (signature change). Arbitrary phase weights would look like a percentage without measuring wall time. | Rejected as the primary meter: phases are real but still do not yield a continuous fraction during the long native load; adopting a public callback is out of scope unless required for a true fraction, which ORT cannot supply. |
| Optional `onProgress` (or similar) on `LayaFlutter.open` | New optional callback reporting download bytes and/or phase events so the example can drive a determinate bar without forking open. | Public signature change; still cannot report a true fraction inside `createSession` without ORT support. | Listed because a determinate download bar needs a library seam; not chosen: does not create a real session-load fraction, and public `open` stays closed when an indeterminate meter works without it. |

## Constraints discovered

- Public `LayaFlutter.open` / `LoadedRuntime.predict` signatures remain closed unless a real fraction is impossible without an optional callback; an indeterminate meter does not require that callback.
- Label text for this slice is fixed to exactly `Loading the model`; the meter lives on the example home during open (shared decisions).
- Fake percentage advancing on a timer is forbidden (shared decisions; GOAL’s no Snake step timer reinforces not inventing progress with a ticker).
- Complete local ONNX at 1290466290 bytes skips download; session creation remains a single opaque platform Future.
- `flutter_onnxruntime` 1.8.5 and upstream ORT do not expose session-load progress; ORT issue #17796 remains an open feature request.
- Widget-tree redesign and Opening… test-lock wording belong to another stream; this research only answers progress-source and meter-drive options.
- Do not claim VM `flutter test` as session-load proof (prior solution: macOS session proof needs `integration_test`).

## Unresolved

- [UNRESOLVED: Exact wall-clock split on emulator-5554 between `ensureLocal`, companion checks, tokenizer/config read, and `createSession` was not re-measured in this research run; only the prompt observation and code path order are cited.]
- [UNRESOLVED: Whether Hugging Face responses for these artifacts always include a reliable `Content-Length` for a byte-fraction download meter was not verified against a live download in this run.]
- [UNRESOLVED: Whether Android `HttpClient` / method-channel scheduling would allow UI frames during an instrumented download while `createSession` still freezes Dart progress updates was not profiled.]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` — consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` — consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart` — consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/checkpoint_store.dart` — consulted 2026-09-28
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart` — consulted 2026-09-28
- `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/lib/src/onnxruntime.dart` — consulted 2026-09-28
- `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/lib/src/flutter_onnxruntime_method_channel.dart` — consulted 2026-09-28
- `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/lib/src/ort_session.dart` — consulted 2026-09-28
- `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/android/src/main/kotlin/com/masicai/flutteronnxruntime/FlutterOnnxruntimePlugin.kt` — consulted 2026-09-28
- `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/doc/api_usage.md` — consulted 2026-09-28
- https://github.com/microsoft/onnxruntime/issues/17796 — consulted 2026-09-28
- https://github.com/microsoft/onnxruntime/blob/main/csharp/src/Microsoft.ML.OnnxRuntime/SessionOptions.shared.cs — consulted 2026-09-28
- Research prompt observation (emulator-5554 complete cache Opening… wait, 2026-09-28) — cited as context only
