# Research review — round 01

- Work item: 0006-snake-platform-launch
- Reviewed artifact: `wiki/work/0006-snake-platform-launch/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-27

## Verdict

**FAIL**

The merged research’s approach is mostly sourced, but it asserts a false example entry path (Play
Snake / wrong open line) that the cited `example/lib/main.dart` lines do not support, so the
research quality gate is unmet.

## Verification performed

Host cache layout and ONNX size (follow symlink):

```text
$ ls -la "$HOME/.cache/laya_flutter"
... laya-multilingual.onnx -> .../onnx/multilingual/laya-multilingual.onnx
... tokenizer.json (34363188), tokenizer_config.json (502), rl_agent_config.json (472)

$ python3 -c "import os; p=os.path.expanduser('~/.cache/laya_flutter/laya-multilingual.onnx'); print(os.path.getsize(p))"
1290466290
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

Published floors (cached packages + pub.dev fetch 2026-09-27):

```text
hf_tokenizers-1.2.2/hook/build.dart:143 — throws when os == OS.android || os == OS.iOS
flutter_onnxruntime-1.8.5/ios/flutter_onnxruntime.podspec:23 — s.platform = :ios, '16.0'
flutter_onnxruntime-1.8.5/android/build.gradle:65 — minSdk = 21
example/ios/.../project.pbxproj — IPHONEOS_DEPLOYMENT_TARGET = 15.0 (lines 363, 491, 543)
example/android/app/proguard-rules.pro — missing
```

Tokenizer sample probe re-run:

```text
$ cd /tmp/dspt_probe && dart run bin/parity2.dart
true len=12 text=choice question: ...
true len=8 text= left: turn left ...
true len=3 text= <mask> turn right
empty true hf=[2, 1] sp=[2, 1]
```

Example entry path (current tree):

```text
example/lib/main.dart:16 — runApp(const ExampleApp(autostart: true));
example/lib/main.dart:100 — LayaFlutter.open(resolveHostCache());
# no "Play Snake" control in example/lib/main.dart build method (lines 126–156)
```

External docs consulted: `https://pub.dev/packages/flutter_onnxruntime` (1.8.5),
`https://pub.dev/packages/hf_tokenizers` (1.2.2),
`https://pub.dev/packages/dart_sentencepiece_tokenizer` (1.4.1 + score Android/iOS),
`https://developer.android.com/training/data-storage/app-specific` (updated 2026-09-16).

Stream merge check: read `research/device-cache.md`, `mobile-session.md`, `visual-proof.md`,
`mobile-tokenizer.md` for dropped or contradicted sourced claims. Streams share the same stale Play
Snake / `:74` open-line citations; the merge did not correct them against the current example.
Chosen options (app-writable download, host copy secondary, `dart_sentencepiece_tokenizer` example
override, screenshot proof) match the streams’ choices; `flutter_embedder` rejection remains only in
`mobile-tokenizer.md` (not required in the merge table once rejected).

## Per-criterion results

Research review — not an implementation review. Acceptance criteria in `02-criteria.md` are not
scored here.

| Criterion | Result | Evidence (file:line) | Negative case exercised |
|-----------|--------|----------------------|-------------------------|
| —         | n/a    | —                    | —                       |

## Findings

### F-001 — Example open path claimed as Play Snake; tree uses autostart

- Severity: BLOCKER
- Location: `wiki/work/0006-snake-platform-launch/00-research.md:15`
- Criterion affected: AC-001, AC-002, AC-003 (entry path to open / Snake)
- Observation: The claim states that Play Snake calls `LayaFlutter.open(resolveHostCache())` and
  cites `example/lib/main.dart:19-32,74`. In the current tree, `main()` launches
  `ExampleApp(autostart: true)` (`example/lib/main.dart:16`), open runs from `_openSnake` after
  autostart (`example/lib/main.dart:100`), and line 74 is `String? _error;`, not an open call. There
  is no Play Snake control in the home `build` method (`example/lib/main.dart:126-156`). The cited
  source does not say what the claim says.
- Why it matters: A plan that treats a button press as the mobile open trigger will mis-describe the
  example that AC-001/AC-002 must launch and screenshot.

### F-002 — Idle-home negative proof invents a Play Snake button

- Severity: BLOCKER
- Location: `wiki/work/0006-snake-platform-launch/00-research.md:46`
- Criterion affected: AC-001, AC-002, AC-009
- Observation: The claim says the idle home title `Laya` and the Play Snake button are not SC-005
  proof, citing `example/lib/main.dart:52-117`. Those lines define autostart wiring and
  `_openSnake`; the visible idle chrome is title `Laya` plus Opening/error text, with no Play Snake
  button (`example/lib/main.dart:126-156`). The idle-home negative case is still valid without
  inventing a button, but the button claim is unsupported by the cited file.
- Why it matters: Screenshot rejection criteria that name UI that does not exist confuse
  verification of AC-001/AC-002/AC-009.

### F-003 — Merged evidence line for open is stale relative to current main.dart

- Severity: IMPORTANT
- Location: `wiki/work/0006-snake-platform-launch/00-research.md:16`
- Criterion affected: AC-003
- Observation: Evidence points at `example/lib/main.dart:19-32,74` for `resolveHostCache` and the
  open call. `resolveHostCache` at 19–32 is correct; the open call is at line 100. The same stale
  `:74` citation appears in the device-cache and mobile-session streams that the merge lists as
  sources.
- Why it matters: Reviewers following the cited lines will not find the mobile-relevant
  `open(resolveHostCache())` call, weakening trust in AC-003 evidence paths.

### F-004 — flutter_embedder alternative omitted from merge options table

- Severity: NIT
- Location: `wiki/work/0006-snake-platform-launch/00-research.md:68`
- Criterion affected: none
- Observation: `research/mobile-tokenizer.md` sourced and rejected `flutter_embedder` as a second
  ORT stack. The merge options table lists pure-Dart and cross-compiled `hf_tokenizers` paths but
  does not record that rejected alternative.
- Why it matters: Completeness only; the chosen mobile tokenizer path is still present and sourced.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| F-001   | research         |
| F-002   | research         |
| F-003   | research         |
| F-004   | research         |
