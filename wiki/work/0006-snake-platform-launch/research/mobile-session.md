# Research: Android and iOS constraints for ONNX session and Snake

## Question

What Android and iOS constraints in this repo and in flutter_onnxruntime / hf_tokenizers would stop
the example from creating an ONNX session and showing Snake?

## Answer

The example cannot complete `LayaFlutter.open` on Android or iOS with a working HuggingFace
tokenizer today: the published `hf_tokenizers` build hook refuses those OS targets, and the
example’s path override only stubs the API so the app can launch while every `Tokenizer` call
throws. Separately, the example’s iOS deployment target is 15.0 while `flutter_onnxruntime` 1.8.5
requires iOS 16, which can block linking the ONNX plugin before any session is created.
`flutter_onnxruntime` itself documents CPU inference on Android and iOS once those packaging floors
are met; VM `flutter test` still cannot prove a native session (see the macOS sandbox solution).

## Findings

### GOAL requires Snake on Android and iOS; runtime choice is closed

- Claim: Product success check SC-005 requires the Snake example to build and launch on Android and
  iOS with the Snake screen appearing. Android and iOS are required platforms. Which inference
  runtime to use is a closed product assumption (ONNX via `flutter_onnxruntime`); this research does
  not reopen that choice.
- Evidence: Users and platforms at `wiki/product/GOAL.md:17-19`; closed “one runtime” assumption at
  `wiki/product/GOAL.md:34`; SC-005 at `wiki/product/GOAL.md:45`; ADR chooses ONNX Runtime via
  `flutter_onnxruntime` at `wiki/adr/0002-onnx-runtime-for-laya-inference.md:44-46`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/adr/0002-onnx-runtime-for-laya-inference.md`

### Package depends on flutter_onnxruntime and published hf_tokenizers

- Claim: The library package pins `flutter_onnxruntime: ^1.8.5` and `hf_tokenizers: ^1.2.2`. The
  example depends on the library via path and does not declare those plugins itself.
- Evidence: Root dependencies at `pubspec.yaml:11-15`; example depends on `laya_flutter` path at
  `example/pubspec.yaml:10-13`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/pubspec.yaml`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/pubspec.yaml`

### Published hf_tokenizers refuses Android and iOS at build time

- Claim: `hf_tokenizers` 1.2.2 declares only linux, macos, and windows platforms. Its README marks
  Android and iOS as “not supported yet” and states that adding the package to a mobile Flutter
  target fails at build time because no cross-compiled prebuilts are published. The build hook
  throws when `os == OS.android || os == OS.iOS`.
- Evidence: `platforms:` block at published `pubspec.yaml:25-28`; platforms table and mobile
  paragraphs in README (pub.dev / package README around the Android/iOS row); throw at
  `hook/build.dart:143-149` in the cached 1.2.2 package.
- Source: `https://pub.dev/packages/hf_tokenizers` (version 1.2.2, consulted 2026-09-27);
  `/Users/ortalcohen/.pub-cache/hosted/pub.dev/hf_tokenizers-1.2.2/pubspec.yaml`;
  `/Users/ortalcohen/.pub-cache/hosted/pub.dev/hf_tokenizers-1.2.2/hook/build.dart`;
  `/Users/ortalcohen/.pub-cache/hosted/pub.dev/hf_tokenizers-1.2.2/README.md`

### Example path override avoids the hook so the app can launch, but open cannot tokenize

- Claim: `example/pubspec.yaml` documents that the published hook throws on Android and iOS (no
  prebuilt binary) and overrides `hf_tokenizers` to `third_party/hf_tokenizers` so the example can
  launch. The stand-in has no native hook; every `Tokenizer` factory and encode path throws
  `UnsupportedError` stating there is no mobile binary and that `LayaFlutter.open` cannot tokenize
  on the device yet.
- Evidence: Comment and `dependency_overrides` at `example/pubspec.yaml:20-25`; stand-in description
  and throws at `example/third_party/hf_tokenizers/pubspec.yaml:1-5` and
  `example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:1-34`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/pubspec.yaml`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/third_party/hf_tokenizers/`

### LayaFlutter.open creates the ONNX session before the tokenizer; Snake needs a finished open

- Claim: `LayaFlutter.open` ensures local artifacts, then calls `OnnxRuntime().createSession` on the
  ONNX path, then builds `HfTextEncoder.fromFile` (which calls `Tokenizer.fromFile`). With the
  example stub, session creation can reach the native plugin, but open still fails on the tokenizer
  step and never returns a `LoadedRuntime`. The example only navigates to `SnakeScreen` after a
  successful `LayaFlutter.open`.
- Evidence: Session then encoder at `lib/src/library.dart:45-58`; `HfTextEncoder.fromFile` at
  `lib/src/tokenize.dart:44-45`; `_openSnake` awaits open then pushes `SnakeScreen` at
  `example/lib/main.dart:65-83`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`

### flutter_onnxruntime supports Android and iOS CPU inference with packaging floors

- Claim: `flutter_onnxruntime` 1.8.5 wraps ONNX Runtime 1.23.0 and marks CPU inference complete for
  Android and iOS. The Android Gradle module sets `minSdk = 21`. Android docs require a
  `proguard-rules.pro` keep rule for `ai.onnxruntime.**`. iOS requires minimum version 16.0 and
  static linkage (`use_frameworks! :linkage => :static` for CocoaPods); SPM requires the app’s
  Minimum Deployments to be at least 16.0.
- Evidence: Implementation-status table and Android/iOS sections on pub.dev README; `minSdk = 21` at
  plugin `android/build.gradle:65`; `s.platform = :ios, '16.0'` at
  `ios/flutter_onnxruntime.podspec:23`; Package.swift `.iOS("16.0")` in the same package tree.
- Source: `https://pub.dev/packages/flutter_onnxruntime` (version 1.8.5, consulted 2026-09-27);
  `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/`

### Example Android config uses Flutter defaults; no proguard keep file is present

- Claim: The example Android app sets `minSdk = flutter.minSdkVersion` (not an explicit override).
  The main manifest has no unusual permission or activity constraints beyond the standard Flutter
  template. There is no `android/app/proguard-rules.pro` in the example tree. Release minify/shrink
  is not enabled in `app/build.gradle.kts`, so the missing keep file is a documented plugin
  requirement that does not yet appear wired into this example’s release config.
- Evidence: `minSdk` at `example/android/app/build.gradle.kts:22`; main manifest at
  `example/android/app/src/main/AndroidManifest.xml:1-45`; no proguard matches under
  `example/android/`; release block has only debug signing at
  `example/android/app/build.gradle.kts:32-38`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/android/`

### Example iOS deployment target is 15.0; Info.plist has no ATS or custom ORT keys

- Claim: The Xcode project sets `IPHONEOS_DEPLOYMENT_TARGET = 15.0` in multiple configurations. That
  is below `flutter_onnxruntime`’s iOS 16.0 floor. `Info.plist` is a standard Flutter template (
  orientations, scene manifest, launch storyboard) with no App Transport Security exception or other
  ONNX-specific keys. No `Podfile` is checked in under `example/ios/`, so CocoaPods `platform` /
  `use_frameworks! :linkage => :static` lines from the plugin README are not present in-repo yet;
  SPM would still require Minimum Deployments ≥ 16.0.
- Evidence: Deployment target at `example/ios/Runner.xcodeproj/project.pbxproj:363` (and sibling
  configs at lines 491 and 543 per search); Info.plist at `example/ios/Runner/Info.plist:1-70`; glob
  found no `example/ios/Podfile*`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/ios/`

### Example cache resolution is host-shaped (`HOME` / `LAYA_CACHE_DIR`)

- Claim: The example opens the runtime against `resolveHostCache()`, which uses `LAYA_CACHE_DIR` or
  `$HOME/.cache/laya_flutter`. If `HOME` is unset and `LAYA_CACHE_DIR` is unset, open throws before
  session creation. How to place the checkpoint on a device is out of scope for this stream; the
  host-shaped path itself is still a constraint on the current open call used to reach Snake.
- Evidence: `resolveHostCache` at `example/lib/main.dart:19-32`; open call at
  `example/lib/main.dart:74`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`
- Note: [UNVERIFIED: exact `HOME` / writable-path behavior of
  `Platform.environment` on stock Android and iOS Flutter runners for this example.]

### VM flutter test cannot register the ONNX plugin (cite prior solution)

- Claim: Host session-open proof belongs on a device/integration harness. VM `flutter test` does not
  register `flutter_onnxruntime` and surfaces `MissingPluginException`. That fact was established
  for macOS and applies to any VM-only session proof; it is not re-investigated here.
- Evidence: Summary and guidance at `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-30`.
- Source:
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`

## Options considered

| Option                                                       | How it works                                                                                                                                                                                       | Cost                                                                                                                                  | Why rejected / chosen                                                                                                                                                                                                    |
|--------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Existing path override (`example/third_party/hf_tokenizers`) | Example `dependency_overrides` replace the published package with a Dart-only stand-in that has no build hook, so Android/iOS builds are not killed by the hook; `Tokenizer` APIs throw at runtime | App can launch; `LayaFlutter.open` still fails after (or without) a usable tokenize step, so SnakeScreen is not reached via real open | **Chosen for launch packaging** — matches the comment already in `example/pubspec.yaml`; only option that lets the example compile without the published mobile hook. Does **not** satisfy tokenization for a real open. |
| Published `hf_tokenizers` ^1.2.2 (no override)               | Library dependency as-is; hook downloads desktop prebuilts or builds host cargo; Android/iOS throw in the hook                                                                                     | Build fails on Android/iOS before the skeleton/Snake UI can launch                                                                    | **Rejected for mobile launch** — documented by package README, hook throw, and example pubspec comment. Cannot show Snake because the app does not start.                                                                |

Neither option provides a working mobile HuggingFace tokenizer for `HfTextEncoder`. Shipping real
mobile prebuilts (or another tokenizer package) is outside the two options this stream was asked to
compare.

## Constraints discovered

- Published `hf_tokenizers` 1.2.2: no Android/iOS platforms, no mobile prebuilts, build hook throws
  on those OS targets (`https://pub.dev/packages/hf_tokenizers`; `hook/build.dart:143-149`).
- Example override removes the hook failure but replaces tokenization with intentional
  `UnsupportedError` (`example/pubspec.yaml:20-25`;
  `example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:9-34`).
- `LayaFlutter.open` requires both a successful `OnnxRuntime().createSession` and a successful
  `Tokenizer.fromFile` before Snake can be shown (`lib/src/library.dart:45-58`;
  `example/lib/main.dart:74-82`).
- `flutter_onnxruntime` 1.8.5: Android `minSdk` 21; iOS ≥ 16.0; Android proguard keep for
  `ai.onnxruntime.**`; CocoaPods static linkage guidance (
  `https://pub.dev/packages/flutter_onnxruntime`).
- Example iOS `IPHONEOS_DEPLOYMENT_TARGET` is 15.0 (
  `example/ios/Runner.xcodeproj/project.pbxproj:363`), below the plugin’s iOS 16 floor.
- Example Android uses Flutter’s default `minSdk` and has no `proguard-rules.pro` (
  `example/android/app/build.gradle.kts:22`; missing keep file under `example/android/`).
- Example open path is `$HOME/.cache/laya_flutter` or `LAYA_CACHE_DIR` (
  `example/lib/main.dart:19-32`); device cache placement is out of scope here.
- VM `flutter test` cannot prove native ONNX session load (
  `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-30`).
- Inference runtime remains ONNX / `flutter_onnxruntime` (closed; not reopened).

## Unresolved

- [UNRESOLVED: After raising the example iOS deployment target to 16.0 (and applying CocoaPods static linkage or SPM), does
  `flutter_onnxruntime` 1.8.5 create a session on a real Android/iOS device for the multilingual Laya graph, including RAM/time limits for the ~1.3–1.7 GB F32 graph?]
- [UNRESOLVED: What concrete `HOME` /
  `LAYA_CACHE_DIR` values does the example see on Android and iOS runners, and does
  `ensureLocal` succeed there without a host-style cache path?]
- [UNRESOLVED: When will
  `hf_tokenizers` publish Android/iOS prebuilts (or an official mobile hook path), and until then is a different tokenizer acceptable for SC-005 without changing the closed library API?]
- [UNRESOLVED: Does a debug Android/iOS build of this example currently fail, succeed, or only fail at open — no device build was run in this research stream.]
- [UNRESOLVED: Is the missing
  `proguard-rules.pro` a release-only risk for this example, or does any default Flutter minify path already apply?]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`,
consulted 2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/adr/0002-onnx-runtime-for-laya-inference.md`,
consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/pubspec.yaml`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/pubspec.yaml`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/third_party/hf_tokenizers/`, consulted
  2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/android/`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/ios/`, consulted 2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`,
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart`,
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/lib/main.dart`, consulted 2026-09-27
- `https://pub.dev/packages/flutter_onnxruntime` (1.8.5) and cached package under
  `~/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/`, consulted 2026-09-27
- `https://pub.dev/packages/hf_tokenizers` (1.2.2) and cached package under
  `~/.pub-cache/hosted/pub.dev/hf_tokenizers-1.2.2/`, consulted 2026-09-27
