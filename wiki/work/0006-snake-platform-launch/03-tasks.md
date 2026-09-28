# Tasks: Show the Snake example on Android and iOS

## Legend

- `[P]` — may run in a parallel subagent. Only mark a task `[P]` if no other `[P]` task in the same
  group touches any of the same files.
- Every task cites the criteria it satisfies and the unit (`U1`, `U2`) it completes. A task
  satisfying no criterion does not belong here.
- Owned files are exclusive. Two tasks never list the same file.

## Groups

Groups run in sequence. No task in this work item is parallel. U1 through U4 share example and
package dependency files, so they are one task. U5 starts only after that task is closed.

### Group 1 — Cache path, tokenizer, parity, iOS floor

| #   | Task                                                                                                                                                                                                                                                                                                                                            | Satisfies                                      | Files owned                                                                                                                                                                                                                                           | Parallel | Done when                                                                                                                                                                                                                                                  |
|-----|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1.1 | U1, U2, U3, U4. Example opens an application-support laya_flutter directory on Android and iOS; the example tokenizer override encodes with dart_sentencepiece_tokenizer; a package test compares that loader to hf_tokenizers on every frozen fixture state string with addSpecialTokens false; example iOS deployment target is at least 16.0 | AC-003, AC-004, AC-005, AC-006, AC-007, AC-008 | example/lib/main.dart, example/pubspec.yaml, example/third_party/hf_tokenizers/lib/hf_tokenizers.dart, example/third_party/hf_tokenizers/pubspec.yaml, pubspec.yaml, test/tokenizer_id_parity_test.dart, example/ios/Runner.xcodeproj/project.pbxproj |          | Done 2026-09-27: mobile cache via path_provider application support + laya_flutter; override encodes with dart_sentencepiece_tokenizer; package parity test green; IPHONEOS_DEPLOYMENT_TARGET 16.0; format/analyze/flutter test/example flutter test green |

### Group 2 — Visual proof

| #   | Task                                                                                                                                                                         | Satisfies                      | Files owned                                    | Parallel | Done when                                                                                                                                                                                                                                                                                                                                                                                                                               |
|-----|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|------------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2.1 | U5. Seed a dereferenced checkpoint into the app-writable cache, launch the example on emulator-5554 and on a booted iOS simulator, and store screenshots of the Snake screen | AC-001, AC-002, AC-009, AC-010 | wiki/work/0006-snake-platform-launch/evidence/ |          | Done 2026-09-28: Android cache at files/laya_flutter holds a regular laya-multilingual.onnx of 1290466290 bytes plus the three companions; iOS simulator 27C93D77-4D20-4F1E-BF66-92C77FF9FE05 (iPhone 17 Pro) Library/Application Support/laya_flutter holds the same regular file and companions. Screenshots: evidence/android-emulator-5554.png and evidence/ios-iphone-17-pro.png, each showing AppBar Snake — ended and the board. |

## Serialised files

| File                  | Owning task |
|-----------------------|-------------|
| example/pubspec.yaml  | 1.1         |
| pubspec.yaml          | 1.1         |
| example/lib/main.dart | 1.1         |

## Test tasks

| #   | Covers                         | Positive case                                                                                   | Negative case                                                      |
|-----|--------------------------------|-------------------------------------------------------------------------------------------------|--------------------------------------------------------------------|
| 1.1 | AC-005                         | Override encode and tokenToId succeed                                                           | UnsupportedError from encode or tokenToId                          |
| 1.1 | AC-006                         | Package test, addSpecialTokens false, all fixture state strings match                           | A diverging string, or the test running under the example override |
| 1.1 | AC-007                         | Every example iOS deployment pin is at least 16.0                                               | A remaining 15.0 pin                                               |
| 1.1 | AC-003, AC-004, AC-008         | Mobile open uses application support plus laya_flutter; download path remains; no weight assets | Mobile open uses only the Mac host cache, or weights are packaged  |
| 2.1 | AC-001, AC-002, AC-009, AC-010 | Snake screenshots on Android and iOS; ONNX at the seed is a regular 1290466290-byte file        | Idle home, logs only, or a symlink ONNX                            |
