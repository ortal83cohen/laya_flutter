# Research: Device cache for multilingual ONNX on Android and iOS

## Question

How can the existing example app load the already-downloaded multilingual Laya ONNX checkpoint on
Android and on iOS without committing weights and without packing them inside the pub package?

## Answer

The example must stop treating the developer Mac path `$HOME/.cache/laya_flutter` as the cache on
mobile. On Android and iOS the four required artifacts must sit in an app-writable directory that
`LayaFlutter.open` already understands: either filled by the library’s first-run Hugging Face
download, or populated from the host cache by a developer-side copy into that same sandbox. Packing
the ONNX or companions into the pub package or Flutter assets is rejected by the product goal and by
the graph contract.

## Findings

### Host cache already holds a complete flat layout for CheckpointStore

- Claim: On this machine, `$HOME/.cache/laya_flutter` contains the four filenames
  `CheckpointStore.requiredArtifactNames` expects at the cache root: `laya-multilingual.onnx` (
  symlink to the nested file, length 1_290_466_290), `tokenizer.json` (34_363_188 bytes),
  `tokenizer_config.json` (502 bytes), and `rl_agent_config.json` (472 bytes). The real ONNX bytes
  live at `onnx/multilingual/laya-multilingual.onnx`.
- Evidence: Read-only listing and size check of `/Users/ortalcohen/.cache/laya_flutter` on
  2026-09-27; required names at `lib/src/checkpoint_store.dart:46-52`; expected ONNX size at
  `lib/src/checkpoint_store.dart:31-32`.
- Source: Host filesystem listing (this research run);
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/checkpoint_store.dart:31-52`.

### Example open path hard-codes the host cache resolver

- Claim: Play Snake calls `LayaFlutter.open(resolveHostCache())`. `resolveHostCache` returns
  `LAYA_CACHE_DIR` when set, otherwise `$HOME/.cache/laya_flutter`, and throws if both are unset.
- Evidence: `example/lib/main.dart:19-32` and `example/lib/main.dart:74`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart:19-32,74`.

### Library API is already cache-directory agnostic and can download

- Claim: `LayaFlutter.open(Directory cache)` ensures a complete local copy under the caller-chosen
  directory, then opens the ONNX and companions from that same directory. Incomplete caches invoke
  `downloadMultilingualCheckpoint`, which fetches ONNX from `mariojcr/laya-onnx` and companions from
  `convaiinnovations/laya-multilingual`, and may copy an ONNX from `$HOME/.cache/laya_flutter/...`
  only when that host path exists and is complete.
- Evidence: `lib/src/library.dart:19-58`, `lib/src/library.dart:62-131`; completeness rules at
  `lib/src/checkpoint_store.dart:60-90`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart:19-131`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/checkpoint_store.dart:60-90`.

### Product goal forbids packaging weights and prefers one-time download then local reuse

- Claim: Checkpoint weights must not be committed and must not be packed inside the pub package.
  Closed assumption: weights arrive by a one-time Hugging Face download; later runs use the local
  copy (SC-004).
- Evidence: `wiki/product/GOAL.md:23-30,44`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md:23-30,44`.

### Example and package do not declare ONNX or companion assets

- Claim: Neither the library nor the example `pubspec.yaml` declares Flutter `assets` for checkpoint
  files. `onnx_graph.dart` states no ONNX graph binary is committed; callers obtain the file via
  download into a local cache.
- Evidence: `example/pubspec.yaml:27-28` (`uses-material-design` only); `pubspec.yaml` has no
  `flutter: assets`; `lib/src/onnx_graph.dart:17-18`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/pubspec.yaml:27-28`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/pubspec.yaml`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/onnx_graph.dart:17-18`.

### Android and iOS apps cannot read the developer Mac host cache as a shared path

- Claim: Android app-specific storage is private to the app; other locations (including a developer
  workstation’s `$HOME/.cache`) are not readable as that Mac path from inside the device process.
  iOS apps are likewise sandboxed to their container. Therefore `resolveHostCache()` as written is a
  host/desktop helper, not a mobile delivery path.
- Evidence: Android app-specific internal storage documentation; Flutter persistence cookbook
  directs mobile file storage through `path_provider` (documents / support directories), not host
  home paths. macOS-only host-cache sandbox exception is already recorded and is not reopened here.
- Source: `https://developer.android.com/training/data-storage/app-specific` (consulted 2026-09-27);
  `https://docs.flutter.dev/cookbook/persistence/reading-writing-files` (consulted 2026-09-27);
  `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:17-32`;
  `wiki/product/offline-multilingual-onnx.md:19-21`.
- Note: [UNVERIFIED: the exact value of
  `Platform.environment['HOME']` inside a Flutter Android emulator process and an iOS Simulator process on this host.]
  Even if `HOME` is set, it does not grant read access to the Mac developer cache directory from a
  physical device.

### Option A — First-run download into app-writable storage (product-aligned)

- Claim: Point `LayaFlutter.open` at an app-writable directory (Flutter documents or
  application-support path via `path_provider`). On an empty directory the existing downloader
  writes the four artifacts; a later open with a complete directory skips download (SC-004 shape).
- Evidence: Download + skip behaviour at `lib/src/library.dart:19-36` and
  `lib/src/checkpoint_store.dart:64-76`; Flutter recommends `path_provider` for mobile disk
  persistence; `getApplicationSupportDirectory` maps to Android files dir / iOS application support.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart:19-36`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/checkpoint_store.dart:64-76`;
  `https://docs.flutter.dev/cookbook/persistence/reading-writing-files` (consulted 2026-09-27);
  `https://pub.dev/documentation/path_provider/latest/path_provider/getApplicationSupportDirectory.html` (
  consulted 2026-09-27).

### Option B — Developer copy of host cache into the app sandbox (offline / avoid re-download)

- Claim: The already-downloaded host files can be pushed into the installed example’s private
  storage without putting them in the pub package. Android: `adb push` to a world-readable staging
  path such as `/data/local/tmp` or shared storage, then `adb shell run-as <applicationId> cp …`
  into the app’s files directory (debuggable builds). iOS Simulator: resolve the data container with
  `xcrun simctl get_app_container <device> <bundleId> data` (or `documents`) and `cp` the four flat
  filenames into that container from the Mac. Example ids: Android
  `com.example.laya_flutter_example`, iOS `com.example.layaFlutterExample`.
- Evidence: Official `adb push` / `adb pull` copy commands; Android simpleperf docs describe
  `adb push` to `/data/local/tmp` then `run-as` copy for debuggable apps; simctl `get_app_container`
  documented for app/data containers; applicationId and bundle id in the example project.
- Source: `https://developer.android.com/tools/adb#copyfiles` (consulted 2026-09-27);
  `https://android.googlesource.com/platform/prebuilts/simpleperf/+/master/doc/README.md` (run-as +
  `/data/local/tmp` pattern; consulted via Android source documentation 2026-09-27);
  `https://www.iosdev.recipes/simctl/` (`get_app_container`, consulted 2026-09-27);
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/android/app/build.gradle.kts:19`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/ios/Runner.xcodeproj/project.pbxproj:387`.
- Note: When copying from this host, follow the ONNX symlink (copy
  `onnx/multilingual/laya-multilingual.onnx` or use a tool that dereferences links) so the
  destination is a real 1_290_466_290-byte file, not a broken link. Companions must land beside it
  under the same directory passed to `LayaFlutter.open`.

### Rejected — Pack binaries into the package or Flutter assets

- Claim: Shipping the ONNX or companions as package assets or committed binaries violates the
  product boundary and the graph documentation.
- Evidence: `wiki/product/GOAL.md:25`; `lib/src/onnx_graph.dart:17-18`; example has no asset
  entries (`example/pubspec.yaml:27-28`).
- Source: paths above.

### macOS host-cache sandbox is already solved; do not reuse as the mobile plan

- Claim: Prior solution covers macOS integration_test reading `$HOME/.cache/laya_flutter` with a
  DebugProfile entitlement exception. Product knowledge already states that callers who keep weights
  only inside app-writable cache avoid that exception. That guidance is cited, not re-investigated.
- Evidence: `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:17-32`;
  `wiki/product/offline-multilingual-onnx.md:19-21`.
- Source: those files.

### Artifact placement alone does not make example `open` succeed on mobile today

- Claim: The example overrides `hf_tokenizers` with a stub that throws on `Tokenizer.fromFile`, so
  even a complete on-device cache does not let `LayaFlutter.open` finish tokenization on Android/iOS
  in the current example wiring. That is outside the cache-delivery question but bounds what “load”
  can mean for a full open.
- Evidence: `example/pubspec.yaml:20-25`;
  `example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:9-34`; encoder load after session at
  `lib/src/library.dart:49`.
- Source: those paths.

## Options considered

| Option                                                                                                                               | How it works                                                                                       | Cost                                                                                                                                          | Why rejected / chosen                                                                                                                                             |
|--------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| A. First-run HF download into app-writable dir (`path_provider` + `LayaFlutter.open`)                                                | Empty app cache triggers existing `downloadMultilingualCheckpoint`; complete cache reloads offline | ~1.29 GB ONNX + ~34 MB tokenizer over network once; needs free device storage; needs network on first success                                 | **Chosen** for the product path: matches GOAL closed assumption and SC-004; works on physical devices and simulators without host push; no weights in the package |
| B. Copy host `$HOME/.cache/laya_flutter` four artifacts into the same app-writable dir (`adb`/`run-as` or Simulator `simctl` + `cp`) | Developer stages flat files into the directory the example will pass to `open`                     | Host already has the bytes (~1.29 GB transfer to device); debug/simulator tooling required; physical iOS device copy is harder than Simulator | Viable for offline demos and avoiding a second Hub download; secondary to A for the stated product flow                                                           |
| C. Pack ONNX/companions as Flutter assets or commit them in the pub package                                                          | Ship binaries inside the example or library                                                        | Violates GOAL and graph contract; inflates package; still needs asset-to-file extraction for ORT file paths                                   | **Rejected** by product boundary and research boundary                                                                                                            |

## Constraints discovered

- Four flat filenames are required at the cache root, with ONNX exact size 1_290_466_290 (
  `lib/src/checkpoint_store.dart:31-52,78-89`). Nested `onnx/multilingual/` alone is not enough for
  `CheckpointStore.isComplete` unless a root-level file of the right size exists.
- Weights must not be committed or packed in the pub package (`wiki/product/GOAL.md:25`).
- Example today opens only via `resolveHostCache()` (`example/lib/main.dart:22-74`), which targets
  the developer host cache layout, not mobile app storage.
- `_findHostOnnxCopy` only consults `$HOME/.cache/laya_flutter/...` on the process that runs the
  download (`lib/src/library.dart:115-131`); it does not bridge a Mac host cache into an Android/iOS
  app sandbox.
- ONNX payload is about 1.29 GB; Android docs warn internal storage can be tight and recommend
  checking free space before large writes (
  `https://developer.android.com/training/data-storage/app-specific`).
- Android private-dir injection via `run-as` requires a debuggable app (Android simpleperf /
  `run-as` documentation).
- Example applicationId `com.example.laya_flutter_example`; iOS bundle id
  `com.example.layaFlutterExample`.
- Example `hf_tokenizers` override throws on mobile `fromFile`, so full `LayaFlutter.open` remains
  blocked after artifacts land (`example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:16-18`).
- macOS sandbox exception for host cache is closed knowledge (
  `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`); mobile should use app-writable storage
  instead (`wiki/product/offline-multilingual-onnx.md:19-21`).

## Unresolved

- [UNRESOLVED: Exact `Platform.environment['HOME']` /
  `LAYA_CACHE_DIR` values inside Flutter Android emulator and iOS Simulator processes for this example on this host.]
- [UNRESOLVED: Whether a physical iOS device can receive the ~1.29 GB host-cache copy through a supported developer workflow without a first-run Hub download (Simulator
  `simctl` path is clear; device-side injection is not verified here).]
- [UNRESOLVED: Whether typical Android emulator / phone free space on this project’s devices is enough for the full ONNX plus tokenizer before first download or push.]
- [UNRESOLVED: Whether SC-005 for this slice requires a successful
  `LayaFlutter.open` with the checkpoint, or only the Snake UI appearing (STATE.yaml says library open stays closed; this research only answers artifact placement).]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md` — consulted 2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` —
consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/offline-multilingual-onnx.md` —
  consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart` — consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/checkpoint_store.dart` — consulted
  2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart` — consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/onnx_graph.dart` — consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/pubspec.yaml` — consulted 2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/example/third_party/hf_tokenizers/lib/hf_tokenizers.dart` —
consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/android/app/build.gradle.kts` — consulted
  2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/ios/Runner.xcodeproj/project.pbxproj` —
  consulted 2026-09-27
- Host directory `$HOME/.cache/laya_flutter` — listed read-only 2026-09-27
- `https://developer.android.com/training/data-storage/app-specific` — consulted 2026-09-27
- `https://developer.android.com/tools/adb#copyfiles` — consulted 2026-09-27
- `https://docs.flutter.dev/cookbook/persistence/reading-writing-files` — consulted 2026-09-27
-
`https://pub.dev/documentation/path_provider/latest/path_provider/getApplicationSupportDirectory.html` —
consulted 2026-09-27
- `https://www.iosdev.recipes/simctl/` — consulted 2026-09-27
