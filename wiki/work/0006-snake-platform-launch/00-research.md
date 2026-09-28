# Research: Show the Snake example on Android and iOS

## Question

How can the existing example show the Snake screen on Android and on iOS, with a screenshot as proof, without packing weights into the pub package and without reopening the ONNX runtime choice?

## Answer

The Snake screen appears only after `LayaFlutter.open` returns. On Android and iOS that call is blocked today by two separate facts: the example still points `open` at the Mac host cache (`$HOME/.cache/laya_flutter`), which is not the app sandbox, and the example’s `hf_tokenizers` override throws on every `Tokenizer` call so `open` never returns a `LoadedRuntime`. `flutter_onnxruntime` 1.8.5 documents CPU inference on both platforms once the example’s iOS deployment target is at least 16.0. Proof of SC-005 is a screenshot of the Snake AppBar and board on the connected Android emulator and on a booted iOS simulator, not a log line. Windows and Linux cannot be visually launched on this Darwin host; that is an SC-006 limit, not an SC-005 blocker.

## Findings

### Host cache is complete; the example still opens that Mac path

- Claim: `$HOME/.cache/laya_flutter` on this machine holds the four filenames `CheckpointStore` requires. The cache-root `laya-multilingual.onnx` is a symlink to `onnx/multilingual/laya-multilingual.onnx`, and that target is 1290466290 bytes. Production `main` constructs `ExampleApp(autostart: true)`. After mount, `_openSnake` calls `LayaFlutter.open(resolveHostCache())` at `example/lib/main.dart:100`. `resolveHostCache` uses `LAYA_CACHE_DIR` or `$HOME/.cache/laya_flutter` (`example/lib/main.dart:22-31`). There is no Play Snake button in the home build method (`example/lib/main.dart:126-156`).
- Evidence: Host listing in the device-cache stream; `example/lib/main.dart:16`, `example/lib/main.dart:22-31`, `example/lib/main.dart:91-100`, `example/lib/main.dart:126-156`; `lib/src/checkpoint_store.dart:31-52`.
- Source: `wiki/work/0006-snake-platform-launch/research/device-cache.md`; `example/lib/main.dart`; `lib/src/checkpoint_store.dart`.

### Android and iOS cannot read the Mac host cache as that path

- Claim: Android app-specific storage and the iOS app container are private. `resolveHostCache()` is a host helper. `_findHostOnnxCopy` only looks at `$HOME/.cache/laya_flutter` inside the process that downloads; it does not copy a Mac cache into a device sandbox.
- Evidence: Android app-specific storage docs; Flutter persistence cookbook; `lib/src/library.dart:115-131`.
- Source: `research/device-cache.md`; `https://developer.android.com/training/data-storage/app-specific` (2026-09-27); `lib/src/library.dart`.
- Note: [UNVERIFIED: the exact `Platform.environment['HOME']` value inside the Flutter Android emulator and iOS Simulator processes.]

### Library open already accepts any cache directory and can download once

- Claim: `LayaFlutter.open(Directory cache)` downloads missing artifacts into that directory and skips download when the copy is complete. Weights must not be committed or packed in the pub package.
- Evidence: `lib/src/library.dart:19-58`; `wiki/product/GOAL.md:25,30,44`.
- Source: `lib/src/library.dart`; `wiki/product/GOAL.md`.

### Published hf_tokenizers cannot build for Android or iOS; the example stub throws

- Claim: `hf_tokenizers` 1.2.2 publishes no Android or iOS prebuilts and its build hook throws on those OS targets. The example overrides it with `third_party/hf_tokenizers` so the app can launch, and that stand-in throws `UnsupportedError` from every `Tokenizer` factory. `LayaFlutter.open` creates the ONNX session and then calls `Tokenizer.fromFile`, so open fails before `SnakeScreen` is pushed.
- Evidence: `example/pubspec.yaml:20-25`; `example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:1-34`; `lib/src/library.dart:45-58`; published hook at `~/.pub-cache/hosted/pub.dev/hf_tokenizers-1.2.2/hook/build.dart`.
- Source: `research/mobile-session.md`; those repository paths; `https://pub.dev/packages/hf_tokenizers` (1.2.2, 2026-09-27).

### flutter_onnxruntime’s iOS floor is 16; the example target is 15.0

- Claim: `flutter_onnxruntime` 1.8.5 marks CPU inference complete for Android (`minSdk` 21) and iOS (minimum 16.0, static linkage guidance). The example iOS project sets `IPHONEOS_DEPLOYMENT_TARGET` to 15.0. The example Android app uses Flutter’s default `minSdk` and has no `proguard-rules.pro`; release minify is not enabled in the app Gradle file.
- Evidence: Plugin podspec and README; `example/ios/Runner.xcodeproj/project.pbxproj` deployment target 15.0; `example/android/app/build.gradle.kts`.
- Source: `research/mobile-session.md`; `https://pub.dev/packages/flutter_onnxruntime` (1.8.5, 2026-09-27).

### Snake screen proof is the AppBar and the 12 by 12 board

- Claim: `SnakeScreen` shows AppBar title `Snake` or `Snake — ended` and a square 12 by 12 board. The home chrome with title `Laya`, the line Classic Snake driven by offline Laya predict, and Opening or error text, without that Snake AppBar, is not that proof. A log line is not that proof. The current home build method has no Play Snake button.
- Evidence: `example/lib/snake_screen.dart:32-35,89-153`; `example/lib/main.dart:16,126-156`; `wiki/product/GOAL.md:45`.
- Source: `research/visual-proof.md`.

### This host can see Android now; iOS simulators exist but are shut down

- Claim: `flutter devices` on 2026-09-27 listed Android `emulator-5554`, macOS, and Chrome. `xcrun simctl list devices available` listed iOS simulators including iPhone 17 Pro (`27C93D77-4D20-4F1E-BF66-92C77FF9FE05`, iOS 26.3), all Shutdown. No iOS device was connected.
- Evidence: Host command output recorded in the visual-proof stream.
- Source: `research/visual-proof.md`.

### Windows and Linux cannot be visually launched on this Mac

- Claim: Runtime research already named macOS, Windows, Linux, and web as the extra platforms one ONNX Runtime covers. This host’s `flutter devices` list includes macOS and Chrome and does not include Windows or Linux. Those two extras are an SC-006 host gap.
- Evidence: `wiki/work/0002-offline-predict/research/runtime.md:9`; host `flutter devices`.
- Source: `research/visual-proof.md`.

### macOS sandbox solution is cited, not reopened

- Claim: Proving an ONNX session on macOS needs `integration_test`, and the app sandbox can block `~/.cache` until a DebugProfile exception allows it. That does not prove the Android or iOS Snake screen.
- Evidence: `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:21-32`.
- Source: that solution file.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| First-run Hugging Face download into an app-writable directory | `LayaFlutter.open` on an empty `path_provider` directory runs the existing downloader | About 1.29 GB plus tokenizer once; needs network and free space | Chosen by the cache stream as the product path: matches the one-time download assumption and works without a host push |
| Copy the host cache into the app sandbox with adb or simctl | Developer copies the four artifacts into the directory the example will pass to `open`. The cache-root ONNX name is a symlink; the copy must be a regular file of 1290466290 bytes, not a link back to the Mac path | Transfer of the existing bytes; debug or simulator tooling | Viable for this host so the visual run does not download again; secondary to the product download path |
| Pack weights as Flutter assets or commit them | Ship binaries inside the package | Violates the product boundary | Rejected |
| Example `hf_tokenizers` path override | Dart stub with no build hook | App can compile; `Tokenizer` throws; Snake is not reached | Chosen only as the packaging workaround that lets the example build. It does not tokenize |
| Published `hf_tokenizers` 1.2.2 with no override | Real desktop tokenizer | Android and iOS builds fail in the hook | Rejected for a mobile launch |
| `flutter screenshot` of the Snake route | One CLI capture on a connected device | Needs the Snake route to be visible | Chosen as the SC-005 proof for both platforms |
| `adb exec-out screencap` or `simctl io screenshot` | Platform-native framebuffer capture | One platform each | Fallbacks if `flutter screenshot` fails |
| Log lines from `flutter run` | Treat process output as success | No pixels | Rejected |
| `dart_sentencepiece_tokenizer` behind the example `Tokenizer` surface | Pure Dart loader of the same `tokenizer.json`; library `open` / `predict` signatures stay | New example dependency; sample host ids matched; full fixture parity not yet run | Chosen for mobile open. Do not replace the library `hf_tokenizers` pin |
| Cross-compiled `hf_tokenizers` mobile prebuilts | Keep the Rust tokenizer | Not in 1.2.2 | Viable later; not available for this slice |
| `flutter_embedder` as the mobile tokenizer | FFI plugin that can load `tokenizer.json` and also bundles an ONNX stack | Second inference engine beside the closed runtime | Rejected |

## Constraints discovered

- Four flat filenames must sit at the cache root; the ONNX file must be 1290466290 bytes. Weights stay out of the pub package.
- The example reaches `SnakeScreen` only after `LayaFlutter.open` succeeds.
- The example iOS deployment target 15.0 is below `flutter_onnxruntime` 1.8.5’s iOS 16 floor.
- VM `flutter test` cannot prove a native ONNX session.
- Android visual launch can use `emulator-5554` now. iOS needs a simulator booted first.
- Windows and Linux cannot be visually launched on this machine. They stay on SC-006.
- A fourth stream compared tokenizers. `dart_sentencepiece_tokenizer` 1.4.1 is pure Dart, documents Android and iOS, and loads Hugging Face `tokenizer.json`. A host probe matched `hf_tokenizers` 1.2.2 on sample encodes of the Laya tokenizer, including special ids. Full frozen-fixture parity and on-device RAM are still unverified. Public `open` and `predict` signatures do not need to change. Source: `research/mobile-tokenizer.md`.

## Unresolved

- [UNRESOLVED: Exact `HOME` / `LAYA_CACHE_DIR` inside the Flutter Android emulator and iOS Simulator processes.]
- [UNRESOLVED: Whether a physical iOS device can receive the host-cache copy without a first-run download. Simulator `simctl` is the path this research verified as a documented workflow.]
- [UNRESOLVED: Whether this emulator and a booted simulator have free space for the 1.29 GB graph.]
- [UNRESOLVED: Whether `dart_sentencepiece_tokenizer` 1.4.1 matches `hf_tokenizers` on every frozen fixture string, not only the host samples in `research/mobile-tokenizer.md`. The slice decision is to check those fixture strings on the host before accepting the example override.]
- [UNRESOLVED: Whether Android and iOS can load the ~34 MB `tokenizer.json` in the example process.]
- [UNRESOLVED: After the iOS deployment target is at least 16, does `flutter_onnxruntime` create a session on the multilingual graph on this emulator and on a simulator, including memory limits?]
- [UNRESOLVED: Will booting iPhone 17 Pro (`27C93D77-4D20-4F1E-BF66-92C77FF9FE05`) make an iOS device appear in `flutter devices`?]
- [UNRESOLVED: Whether `flutter screenshot` produces a readable PNG of the Snake AppBar and board, or a native capture is required.]
- [UNRESOLVED: Whether the missing Android `proguard-rules.pro` matters for a debug launch. Release minify is not enabled in the example Gradle file.]

## Sources

- `wiki/work/0006-snake-platform-launch/research/device-cache.md`, `research/mobile-session.md`, `research/visual-proof.md`, `research/mobile-tokenizer.md` — 2026-09-27
- `wiki/product/GOAL.md` — 2026-09-27
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` — 2026-09-27
- `wiki/work/0002-offline-predict/research/runtime.md` — 2026-09-27
- `example/lib/main.dart`, `example/lib/snake_screen.dart`, `lib/src/library.dart`, `lib/src/checkpoint_store.dart` — 2026-09-27
- `https://pub.dev/packages/flutter_onnxruntime` (1.8.5) and `https://pub.dev/packages/hf_tokenizers` (1.2.2) — 2026-09-27
