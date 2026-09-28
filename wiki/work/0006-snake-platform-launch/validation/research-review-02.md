# Research review — round 02

- Work item: 0006-snake-platform-launch
- Reviewed artifact: `wiki/work/0006-snake-platform-launch/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-27

## Verdict

**PASS**

Round-01 blockers on the example entry path are closed in the merged artifact; re-checked sources support the remaining factual claims, and unresolved items stay explicit.

## Verification performed

Host cache layout and ONNX size (follow symlink):

```text
$ ls -la "$HOME/.cache/laya_flutter"
... laya-multilingual.onnx -> .../onnx/multilingual/laya-multilingual.onnx
... tokenizer.json (34363188), tokenizer_config.json (502), rl_agent_config.json (472)

$ python3 -c "import os; p=os.path.expanduser('~/.cache/laya_flutter/laya-multilingual.onnx'); print(os.path.getsize(p), os.path.islink(p))"
1290466290 True
```

Example entry path (current tree, re-read):

```text
example/lib/main.dart:16 — runApp(const ExampleApp(autostart: true));
example/lib/main.dart:22-32 — resolveHostCache()
example/lib/main.dart:100 — LayaFlutter.open(resolveHostCache());
example/lib/main.dart:126-156 — home build: AppBar Laya, Opening/error text; no Play Snake control
```

`flutter devices` / simulators (2026-09-27 re-check):

```text
Found 3 connected devices:
  sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 16 (API 36) (emulator)
  macOS (desktop)             • macos         • darwin-arm64  • ...
  Chrome (web)                • chrome        • web-javascript • ...

$ xcrun simctl list devices available | rg "iPhone 17 Pro"
    iPhone 17 Pro (27C93D77-4D20-4F1E-BF66-92C77FF9FE05) (Shutdown)
```

Published floors and example pins:

```text
hf_tokenizers-1.2.2/hook/build.dart:143 — throws when os == OS.android || os == OS.iOS
flutter_onnxruntime-1.8.5 README — CPU Inference ✅ Android / ✅ iOS; iOS minimum 16; proguard keep documented
flutter_onnxruntime-1.8.5/ios/flutter_onnxruntime.podspec:23 — s.platform = :ios, '16.0'
flutter_onnxruntime-1.8.5/android/build.gradle:65 — minSdk = 21
example/ios/.../project.pbxproj — IPHONEOS_DEPLOYMENT_TARGET = 15.0 (lines 363, 491, 543)
example/android/app/build.gradle.kts — minSdk = flutter.minSdkVersion; release has signing only (no minify)
example/android/app/proguard-rules.pro — missing
```

Library / Snake observables:

```text
lib/src/library.dart:19-58 — open(Directory) ensureLocal then session then Tokenizer.fromFile
lib/src/library.dart:115-131 — _findHostOnnxCopy only under $HOME/.cache/laya_flutter
lib/src/checkpoint_store.dart:31-52 — expectedOnnxBytes 1290466290; four required names
example/lib/snake_screen.dart:32-35,89-153 — 12×12 board; AppBar Snake / Snake — ended
example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:9-28 — UnsupportedError on factories and encode/tokenToId
```

Tokenizer package score (pub.dev API 2026-09-27): `dart_sentencepiece_tokenizer` 1.4.1 tags include `platform:android` and `platform:ios`. Host probe `/tmp/dspt_probe` still matches sample encodes (including empty `addSpecialTokens: true` → `[2, 1]`).

External docs: `https://pub.dev/packages/flutter_onnxruntime` (1.8.5), `https://pub.dev/packages/hf_tokenizers` (1.2.2), `https://developer.android.com/training/data-storage/app-specific`.

Stream cross-check: merge options now include rejected `flutter_embedder`; entry-path claims in `00-research.md` match `example/lib/main.dart`. Underlying streams `device-cache.md`, `mobile-session.md`, and `visual-proof.md` still contain stale Play Snake / `:74` citations, but the merged artifact under review no longer repeats them.

## Per-criterion results

Research review — not an implementation review. Acceptance criteria in `02-criteria.md` are not scored here.

| Criterion | Result | Evidence (file:line) | Negative case exercised |
|---|---|---|---|
| — | n/a | — | — |

## Findings

### F-001 — Cited research streams still assert a Play Snake open path

- Severity: NIT
- Location: `wiki/work/0006-snake-platform-launch/research/device-cache.md:21`
- Criterion affected: none
- Observation: The merged `00-research.md` correctly describes autostart and `main.dart:100`. The streams it lists as sources still claim Play Snake / `example/lib/main.dart:74` (`device-cache.md:21-23`, `mobile-session.md:40-41,64`, `visual-proof.md:38-41`). Those stream sentences remain false against the current tree.
- Why it matters: Completeness only for readers who open the streams; the merged research used for planning no longer carries the false entry path.

## Recurrence check

- Previous round: `wiki/work/0006-snake-platform-launch/validation/research-review-01.md`
- Recurring findings: none — round-01 F-001/F-002/F-003 (Play Snake, idle-home button, stale `:74`) do not recur in `00-research.md`; round-01 F-004 (`flutter_embedder` omission) is addressed at `00-research.md:81`
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| F-001 | research |
