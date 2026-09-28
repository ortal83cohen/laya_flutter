# Plan: Show the Snake example on Android and iOS

## Goal

After this change, a person can launch the example on Android emulator-5554 and on a booted iOS
simulator, reach the Classic Snake screen after a successful open against an app-writable cache, and
prove SC-005 with screenshots of the Snake AppBar and board. The example tokenizer override no
longer blocks open on mobile, a host check shows its token ids match the library tokenizer on the
frozen fixture state strings, and checkpoint weights stay outside the pub package.

## Approach

Keep the public library open and predict surfaces unchanged. On Android and iOS the example declares
path_provider as its own dependency and resolves the application support directory, then a child
directory named laya_flutter, and passes that directory into the existing open call. Leave first-run
download available when that directory is incomplete. On this Darwin host, a developer may seed that
directory from the existing complete host cache so the visual run need not re-download the large
graph. The cache-root ONNX name is a symlink; the seeded file must be a regular file of 1290466290
bytes, not a symlink to the Mac path.

Replace the example’s throwing hf_tokenizers path override with an override that loads the same
tokenizer.json through dart_sentencepiece_tokenizer and returns encode and tokenToId results that
open can consume. Do not change the library’s hf_tokenizers dependency pin. Add a host check that is
not compiled under the example dependency override: it lives in the package test tree, encodes every
frozen fixture state string with addSpecialTokens false using both hf_tokenizers and
dart_sentencepiece_tokenizer, and requires equal token id sequences. The example override must call
that same pure-Dart loader. dart_sentencepiece_tokenizer is a dev dependency of the library package
for that check, not a replacement of the library’s runtime hf_tokenizers pin.

Raise the example iOS deployment target to at least 16.0 so flutter_onnxruntime’s documented iOS
floor is met. Leave Android release minify and ProGuard keep rules untouched. Do not pack weights as
assets. Do not treat VM flutter test as native session proof; cite
wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md for why host session proof on macOS used
integration_test and a sandbox exception, and do not reuse that path as Android or iOS Snake proof.
Capture screenshots of the Snake AppBar title Snake or Snake — ended and the board on emulator-5554
and on a booted iOS simulator. Windows, Linux, macOS, and web launches stay out of this slice.

## Why this approach

Research rejected packing weights into the package because GOAL forbids it. Relying on
resolveHostCache alone was rejected because Android and iOS cannot read the Mac host cache path.
Keeping the throwing example tokenizer stub was rejected because open never returns a loaded
runtime. Using published hf_tokenizers without an override was rejected because its build hook fails
on Android and iOS. Cross-compiled mobile prebuilts for hf_tokenizers are not in the published 1.2.2
package. dart_sentencepiece_tokenizer behind the example Tokenizer surface was chosen so mobile open
can encode without changing public library signatures or the library pin. A host cache copy is
secondary to first-run download: useful on this machine so the visual run can reuse existing bytes,
not a substitute for the product download path. Log lines and the idle Laya home were rejected as
SC-005 proof; flutter screenshot of the Snake route is the chosen proof, with platform-native
capture as fallback. See wiki/work/0006-snake-platform-launch/00-research.md and the closed
decisions in STATE.yaml. The macOS ONNX sandbox solution explains host session harness limits and is
cited only; it is not re-decided here.

## Product contract

Units realise R-001 through R-009 in wiki/work/0006-snake-platform-launch/04-product-contract.md.
This plan adds no behaviour that contract does not state.

## Units

### U1. App-writable cache directory for open

Done when: on Android and iOS the example passes an app-writable directory into the existing open
entry; an incomplete directory can still be filled by the existing first-run download; a developer
may seed that directory from a complete host cache for a visual run; weights are not added to the
pub package.

Files it may touch: example application Dart sources that resolve the cache path and call open;
example documentation comments only if needed to describe the host-copy option; no package library
public API files.

| Scenario                           | Category   | Input                                                                                                                                                                  | Action                         | Expected outcome                                                                              | Covers               |
|------------------------------------|------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------|-----------------------------------------------------------------------------------------------|----------------------|
| Mobile open uses app-writable path | happy path | Example on Android or iOS                                                                                                                                              | Start open                     | Cache argument is under app-writable storage, not solely the Mac host cache helper path       | R-003, AE-003        |
| First-run download still available | happy path | Empty app-writable cache and network available                                                                                                                         | Call open                      | Missing artifacts are downloaded into that directory; open can succeed without package assets | R-004, R-009, AE-003 |
| Host copy seeds visual run         | edge       | Complete host cache, with the ONNX symlink dereferenced into a regular file of 1290466290 bytes, copied with the three companion files into the app-writable directory | Call open with network blocked | Open loads the local copy and does not require a new download                                 | R-004                |
| Weights stay unpackaged            | negative   | Inspect pub package and example asset lists                                                                                                                            | Review packaging               | No checkpoint weight binaries are committed or declared as distributed package assets         | R-009                |

### U2. Example tokenizer override encodes without throwing

Done when: the example’s hf_tokenizers path override no longer throws UnsupportedError from
Tokenizer factories or encode; it loads tokenizer.json with dart_sentencepiece_tokenizer; the
library package still depends on hf_tokenizers at its existing pin; open can proceed past tokenize
on Android and iOS once a session and tokenizer file are available.

Files it may touch: example third_party hf_tokenizers override sources; example pubspec dependency
declarations for the override and dart_sentencepiece_tokenizer; not the library pubspec tokenizer
pin.

| Scenario                 | Category   | Input                                                | Action                                                                      | Expected outcome                                                                                                  | Covers        |
|--------------------------|------------|------------------------------------------------------|-----------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|---------------|
| Override encode succeeds | happy path | tokenizer.json path and a sample state string        | Construct Tokenizer via the override and encode with addSpecialTokens false | Encode returns token ids; UnsupportedError is not thrown                                                          | R-005, AE-004 |
| Special token ids        | happy path | The same tokenizer.json                              | Call tokenToId for bos, eos, mask, and pad                                  | Each call returns an integer id and does not throw                                                                | R-005         |
| Library pin unchanged    | edge       | Library package dependencies                         | Inspect library pubspec                                                     | hf_tokenizers remains the library runtime pin; dart_sentencepiece_tokenizer is not the library runtime dependency | R-005         |
| Throw stub removed       | negative   | Prior override behaviour that threw on every factory | Call the same factories after the change                                    | Those calls no longer fail solely because the platform is Android or iOS                                          | R-005         |

### U3. Host fixture token-id parity check

Done when: a host-runnable check in the package test tree, outside the example dependency override,
encodes every frozen fixture state string with addSpecialTokens false using hf_tokenizers and using
dart_sentencepiece_tokenizer, and asserts equal token id sequences for each string. The example
override calls that same pure-Dart loader.

Files it may touch: a package test and a dev dependency declaration for
dart_sentencepiece_tokenizer; not an example test that would see only the override.

| Scenario                  | Category   | Input                                                        | Action                                                                         | Expected outcome                                      | Covers        |
|---------------------------|------------|--------------------------------------------------------------|--------------------------------------------------------------------------------|-------------------------------------------------------|---------------|
| All fixture strings match | happy path | Frozen fixture state strings and a complete tokenizer.json   | Encode both tokenizers with addSpecialTokens false, from the package test tree | Id sequences equal for every string                   | R-006, AE-004 |
| Mismatch fails the check  | negative   | Deliberately altered encode result or a string that diverges | Run the same check                                                             | The check fails when any string’s id sequences differ | R-006         |

### U4. Example iOS deployment target at least 16

Done when: the example iOS project sets IPHONEOS_DEPLOYMENT_TARGET to at least 16.0 everywhere the
example currently pins a lower floor.

Files it may touch: example iOS Xcode project settings and related Podfile platform floor if the
example pins one.

| Scenario                 | Category   | Input                                                         | Action                             | Expected outcome                                              | Covers |
|--------------------------|------------|---------------------------------------------------------------|------------------------------------|---------------------------------------------------------------|--------|
| Floor is at least 16     | happy path | Example iOS project after the change                          | Inspect deployment target settings | Every relevant pin is at least 16.0                           | R-007  |
| Prior 15.0 floor is gone | negative   | Search for a 15.0 example iOS deployment target left in place | Inspect project settings           | A remaining 15.0 floor for the example Runner fails this unit | R-007  |

### U5. Snake screenshots on Android and iOS

Done when: the example has been launched on emulator-5554 and on a booted iOS simulator, open has
succeeded against the app-writable cache path, and a screenshot of each shows the Snake AppBar title
Snake or Snake — ended and the twelve-by-twelve board. Idle Laya home screenshots and log lines
alone are not accepted.

Files it may touch: none required for product behaviour; evidence artifacts under the work item
folder for the two screenshots if the team stores them there; launch and capture are verification
actions.

| Scenario            | Category    | Input                                                 | Action                                | Expected outcome                                              | Covers               |
|---------------------|-------------|-------------------------------------------------------|---------------------------------------|---------------------------------------------------------------|----------------------|
| Android Snake proof | integration | emulator-5554 with successful open                    | Capture screenshot of the Snake route | Image shows AppBar title Snake or Snake — ended and the board | R-001, R-008, AE-001 |
| iOS Snake proof     | integration | Booted iOS simulator with successful open             | Capture screenshot of the Snake route | Image shows the same AppBar title forms and the board         | R-002, R-008, AE-002 |
| Idle home rejected  | negative    | Screenshot of only the Laya home or a flutter run log | Offer as SC-005 proof                 | Reviewer rejects; SC-005 remains unmet                        | R-008                |

## Interfaces and shared decisions

- Cache: the example passes a Directory into the existing LayaFlutter.open. On Android and iOS that
  Directory is the application support directory from a direct path_provider dependency, plus a
  child directory named laya_flutter. It is not resolveHostCache alone. Desktop host helpers may
  remain for non-mobile launches but are not the mobile path.
- Population: incomplete cache still uses the library’s existing download-into-cache behaviour. A
  host copy into that directory is allowed for visual runs on this machine. The copied ONNX must be
  a regular file of 1290466290 bytes. Copying the cache-root symlink as a symlink is not a valid
  seed.
- Tokenizer: library runtime pin stays hf_tokenizers. Example path dependency override implements
  Tokenizer.fromFile, tokenToId, and encode using dart_sentencepiece_tokenizer over the cache’s
  tokenizer.json. Public open and predict signatures stay unchanged.
- Parity: the host check runs in the package test tree so it is not subject to the example
  dependency override. Both sides encode with addSpecialTokens false, matching library sequence
  building. Coverage is every frozen fixture state string. Equality is on token id sequences. The
  example override must use the same pure-Dart loader that the check compares to hf_tokenizers.
- iOS: example deployment target minimum 16.0. Android minSdk stays at Flutter defaults sufficient
  for flutter_onnxruntime unless a build forces a change; ProGuard keep is out of scope while
  release minify is off.
- Proof: SC-005 evidence is screenshots of Snake chrome on emulator-5554 and a booted iOS simulator.
  Prefer flutter screenshot; platform-native capture is an allowed fallback. Do not cite
  wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md as Android or iOS proof; that solution
  remains the macOS session harness note only.

## Risks

| Risk                                                                                      | Likelihood | Impact                                               | Mitigation                                                                                                              | Trigger that means it happened                                                         |
|-------------------------------------------------------------------------------------------|------------|------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| Emulator or simulator lacks free space for the 1.29 GB graph                              | Medium     | Open fails before Snake appears                      | Prefer host-cache copy into the app-writable directory; confirm free space before download                              | Open fails with disk or download errors despite a correct path                         |
| dart_sentencepiece_tokenizer diverges on a fixture string                                 | Medium     | Host parity check fails; override cannot be accepted | Run U3 before visual claims; fix override or reject the package for this slice                                          | Any fixture string’s id sequences differ                                               |
| tokenizer.json load exhausts mobile process memory                                        | Medium     | Open fails after session create                      | Measure on device during implement; if load fails, stop and escalate rather than packing a smaller unofficial tokenizer | Process is killed or encode throws out-of-memory while loading tokenizer.json          |
| flutter_onnxruntime session fails on the multilingual graph after the iOS floor is raised | Medium     | Snake never reached despite tokenizer fix            | Confirm session create on emulator and simulator; record the failure as a blocker if it is not a config mistake         | SESSION_CREATION_FAILED or equivalent after deployment target and cache path are fixed |
| Booted simulator does not appear in flutter devices                                       | Low        | iOS proof blocked                                    | Boot the researched simulator UDID, re-list devices, then launch                                                        | flutter devices still lists no iOS target after boot                                   |
| flutter screenshot yields an unreadable frame                                             | Low        | Proof delayed                                        | Fall back to adb exec-out screencap or simctl io screenshot                                                             | Captured PNG does not show AppBar and board                                            |

## Rollback

Revert example Dart cache-path changes, the third_party hf_tokenizers override and related example
pubspec dependency edits, the host parity check addition, and the iOS deployment target bump. No
library public API migration is involved. Cached downloads inside app sandboxes can be deleted by
uninstalling the app or clearing app storage; host cache under the developer home is unchanged.
Screenshot evidence files can be removed from the work item folder. This is not a one-way door.

## Out of scope

- Changes to public LayaFlutter.open or LoadedRuntime.predict signatures.
- Changes to Classic Snake rules, relative turns, await-gated stepping, or the no-timer rule.
- Packing or committing checkpoint weights into the pub package.
- Replacing the library hf_tokenizers pin with dart_sentencepiece_tokenizer.
- Android ProGuard keep rules while release minify stays off.
- Visual launch or SC-006 proof on Windows, Linux, macOS, or web.
- Treating VM flutter test or macOS integration_test as SC-005 Snake proof.
- Physical iOS device proof beyond a booted simulator.
- Reopening the ONNX runtime choice or the macOS sandbox entitlements solution.

## Verification approach

Run the host token-id parity check over every frozen fixture state string and require equal
sequences. Inspect the example for an app-writable cache Directory passed to open on mobile, for
first-run download still reachable, and for absence of packaged weight assets. Confirm the example
iOS deployment target is at least 16.0. Launch the example on emulator-5554 and on a booted iOS
simulator, complete open against the app-writable cache (download or host copy), navigate to Snake,
and store screenshots that show AppBar title Snake or Snake — ended and the board. Reject idle Laya
home images and log-only evidence. Do not claim SC-005 from a green VM widget test alone.
