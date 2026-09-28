# Research: Visual proof of Snake on Android and iOS

## Question

What observable proves the example Snake screen appeared on Android and on iOS, which launch targets exist on this developer machine, and which extra platforms already named by runtime research cannot be visually launched here?

## Answer

SC-005 needs a pixel capture of the Snake route (AppBar title `Snake` or `Snake — ended`, plus the square board grid), not a log line. On this Darwin host, `flutter devices` currently lists Android `emulator-5554`, desktop `macos`, and web `chrome`; many iOS simulators exist but are all Shutdown (including iPhone 17 Pro on iOS 26.3), so iOS is not a connected Flutter target until a simulator is booted. Of the SC-006 extras named by runtime research (macOS, Windows, Linux, web), this host cannot visually launch Windows or Linux; macOS and Chrome are present as Flutter devices.

## Findings

### SC-005 requires the Snake screen to appear on Android and iOS

- Claim: Product success check SC-005 is that the Snake example runs on Android and on iOS, checked by building and launching on both. The negative case is a failed build or that the Snake screen does not appear. SC-006 covers every extra platform the chosen runtime covers without a second engine.
- Evidence: SC-005 and SC-006 rows in the success-checks table.
- Source: `wiki/product/GOAL.md:45-46`

### Runtime research already named macOS, Windows, Linux, and web as extras

- Claim: The closed runtime answer for offline predict chooses ONNX Runtime and states that the extra platforms that one runtime covers without a second engine are macOS, Windows, Linux, and web. This research does not re-choose the runtime; those four names are the SC-006 set to compare against host launchability.
- Evidence: Answer paragraph naming those four platforms.
- Source: `wiki/work/0002-offline-predict/research/runtime.md:9`

### macOS session proof is a prior host constraint, not SC-005 visual proof

- Claim: A prior solution records that proving an ONNX session on this macOS host needs `integration_test` (not VM `flutter test`) and may need a DebugProfile sandbox exception for the cache path. That is session-load knowledge for host macOS, not a substitute for SC-005 screenshots on Android and iOS.
- Evidence: Guidance to use macOS `integration_test` and sandbox cache exception.
- Source: `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:21-32`

### Snake screen observable: AppBar title and board grid

- Claim: After the home opens a runtime and navigates, `SnakeScreen` shows an AppBar title of `Snake` while the game is running, or `Snake — ended` when finished. The body is a centered square `AspectRatio` containing a 12×12 `_BoardView` grid: green cells for the snake, red for food, grey for empty, with light grey borders.
- Evidence: AppBar titles and board composition at `example/lib/snake_screen.dart:89-153`; board size set to width/height 12 at `example/lib/snake_screen.dart:32-35`.
- Source: `example/lib/snake_screen.dart:32-35`, `example/lib/snake_screen.dart:89-153`

### Reaching SnakeScreen requires leaving the idle home

- Claim: The example entry is idle `ExampleHomePage` with title `Laya` and a `Play Snake` button. Session open and push of `SnakeScreen` happen only in `_openSnake` after that control. A screenshot of the idle home alone does not prove the Snake screen appeared.
- Evidence: Idle home, button, open-then-push at `example/lib/main.dart:52-117`.
- Source: `example/lib/main.dart:52-117`

### Connected Flutter launch targets on this host (re-checked)

- Claim: `flutter devices` from `/Users/ortalcohen/Documents/GitHub/laya_flutter` on 2026-09-27 reported three connected devices: `sdk gphone64 arm64` as `emulator-5554` (android-arm64, Android 16 API 36 emulator), `macOS` (`macos`, darwin-arm64), and `Chrome` (`chrome`, web-javascript). No iOS simulator appeared in that connected list. `adb devices` listed `emulator-5554` as `device`. Host kernel is Darwin arm64 (`uname`).
- Evidence: Command output of `flutter devices`, `adb devices`, and `uname -s` / `uname -m`, consulted 2026-09-27.
- Source: host commands from `/Users/ortalcohen/Documents/GitHub/laya_flutter` (2026-09-27)

### iOS simulators exist but are all Shutdown

- Claim: `xcrun simctl list devices available` listed many available simulators under iOS 17.2, 18.2, and 26.3, all with state Shutdown. Under iOS 26.3, `iPhone 17 Pro` has UDID `27C93D77-4D20-4F1E-BF66-92C77FF9FE05` and is Shutdown. No Booted simulator was listed. Until a simulator is booted, Flutter cannot treat iOS as a connected launch target for run or screenshot.
- Evidence: `xcrun simctl list devices available` output, consulted 2026-09-27 (re-check matched the known-host fact that iOS sims exist and were shut down, including iPhone 17 Pro on iOS 26.3).
- Source: host command `xcrun simctl list devices available` (2026-09-27)

### Extra platforms this host cannot visually launch: Windows and Linux

- Claim: Of macOS, Windows, Linux, and web, `flutter devices` on this Darwin host listed `macos` and `chrome` but did not list any Windows or Linux desktop device. Visual launch of Windows and Linux Flutter targets is therefore not available on this machine without a different host or remote device. macOS and web remain launchable here as Flutter devices; they are out of the SC-005 slice except for this host inventory.
- Evidence: Connected-device list from `flutter devices` (three devices: Android emulator, macOS, Chrome); host `uname -s` = Darwin.
- Source: host `flutter devices` and `uname` (2026-09-27); extras named at `wiki/work/0002-offline-predict/research/runtime.md:9`

### A log line alone is not the SC-005 observable

- Claim: GOAL SC-005’s negative case is that the Snake screen does not appear. Work-item state for this slice already records that appearance must be confirmed by a screenshot, not only by a log line. Therefore stdout/log success from `flutter run` is insufficient proof by itself.
- Evidence: SC-005 negative case at `wiki/product/GOAL.md:45`; slice reason requiring screenshot confirmation.
- Source: `wiki/product/GOAL.md:45`; `wiki/work/0006-snake-platform-launch/STATE.yaml:21`

### Screenshot capture options (compared, not executed against a running Snake UI)

- Claim: At least three capture paths exist for a later verification step. (1) `flutter screenshot` takes a screenshot from a connected device; default `--type=device` uses the device’s native screenshot of the entire screen; `-o` sets the output path; `-d` selects the device. (2) On Android, `adb exec-out screencap -p` (or `adb shell screencap -p`) writes a PNG of the display; local `screencap -h` documents `-p` as PNG output. (3) On iOS Simulator, `xcrun simctl io booted screenshot <file>` saves a PNG of the booted simulator; `simctl help io` documents that operation and example. This research did not launch an app or capture a Snake frame (boundary: no emulator/build launch).
- Evidence: `flutter screenshot --help` (2026-09-27); Flutter CLI table entry for `screenshot` at `https://docs.flutter.dev/reference/flutter-cli` (consulted 2026-09-27); `adb shell screencap -h` / device help (2026-09-27); `xcrun simctl help io` screenshot operation and example (2026-09-27).
- Source: host CLI help (2026-09-27); `https://docs.flutter.dev/reference/flutter-cli` (2026-09-27)

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| `flutter screenshot -d <id> -o <path>` after SnakeScreen is visible | Flutter CLI asks the connected device for a full-screen capture (default `--type=device`) | Needs a running Flutter session on a connected device; one command shape for Android and (when booted) iOS | **Chosen for SC-005 proof.** Same tool for both required platforms; captures chrome outside Flutter if present; matches the slice’s screenshot requirement without platform-specific scripts |
| `adb exec-out screencap -p > android-snake.png` | Android platform-tools dump the emulator/device framebuffer as PNG | Android-only; requires `adb` and a device in `device` state | **Viable for Android only.** Useful fallback if `flutter screenshot` fails on the emulator; cannot prove iOS |
| `xcrun simctl io booted screenshot ios-snake.png` | Simulator IO saves the booted sim display to a file | iOS Simulator only; requires a Booted simulator (none are Booted on this host today) | **Viable for iOS Simulator only.** Natural fallback when a sim is booted; cannot prove Android |
| Rely on `flutter run` / log lines only | Treat “Launching…” or Dart logs as success | Cheap, but no pixels | **Rejected.** SC-005 negative case is that the Snake screen does not appear; slice state forbids log-only confirmation |

## Constraints discovered

- SC-005 proof must show the Snake route UI (title `Snake` / `Snake — ended` and the board), not the idle `Laya` / `Play Snake` home alone (`example/lib/snake_screen.dart:89-153`; `example/lib/main.dart:101-117`; `wiki/product/GOAL.md:45`).
- Android visual launch is available now via connected `emulator-5554`; iOS visual launch requires booting a Shutdown simulator first (host `flutter devices` and `simctl list`, 2026-09-27).
- This research must not launch emulators or builds; capture commands were verified by help/list only, not by producing Snake PNGs.
- Windows and Linux cannot be visually launched from this Darwin Flutter device list; that is an SC-006 host gap to record, not an SC-005 blocker (`runtime.md:9`; host `flutter devices`).
- Prior macOS ONNX sandbox/`integration_test` guidance applies if a later slice proves session load on macOS; it is not SC-005 Android/iOS screenshot proof (`wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:21-32`).

## Unresolved

- [UNRESOLVED: Will booting an iOS simulator (for example iPhone 17 Pro, UDID 27C93D77-4D20-4F1E-BF66-92C77FF9FE05) make an iOS entry appear in `flutter devices` on this host without further Xcode or Flutter doctor fixes?]
- [UNRESOLVED: After a real `example` launch, does `flutter screenshot` on `emulator-5554` and on a booted iOS simulator produce readable PNG evidence of the Snake AppBar and board, or will a platform-native capture be required?]
- [UNRESOLVED: Does opening Snake on device require a completed local checkpoint under the host cache before `SnakeScreen` can appear, and would a failed open leave only the idle home or error text (blocking the SC-005 observable)?]
- [UNRESOLVED: Are there any physical iOS or Android devices on this machine that were offline during the check and would change the launch-target inventory?]

## Sources

- `wiki/product/GOAL.md`, consulted 2026-09-27
- `wiki/work/0002-offline-predict/research/runtime.md`, consulted 2026-09-27
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-27
- `wiki/work/0006-snake-platform-launch/STATE.yaml`, consulted 2026-09-27
- `example/lib/main.dart`, consulted 2026-09-27
- `example/lib/snake_screen.dart`, consulted 2026-09-27
- Host: `flutter devices`, `adb devices`, `adb shell screencap -h`, `flutter screenshot --help`, `xcrun simctl list devices available`, `xcrun simctl help io`, `uname`, consulted 2026-09-27 from `/Users/ortalcohen/Documents/GitHub/laya_flutter`
- `https://docs.flutter.dev/reference/flutter-cli`, consulted 2026-09-27
