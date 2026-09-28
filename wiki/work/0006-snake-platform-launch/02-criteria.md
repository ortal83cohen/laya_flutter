# Acceptance criteria: Show the Snake example on Android and iOS

## Frozen

- Frozen at: 2026-09-27
- Frozen by: orchestrator, at the start of implementation

## Criteria

| ID | Traces | Criterion | How it is checked | Negative case |
|---|---|---|---|---|
| AC-001 | R-001, R-008 | When the example has completed a successful open on Android emulator-5554 against an app-writable cache that holds a complete checkpoint, a screenshot of the visible route shall show AppBar title Snake or Snake — ended and the twelve-by-twelve board. | Launch on emulator-5554, reach Snake after open, capture a screenshot, and inspect the image for that AppBar title and the board. | The capture shows only the idle Laya home, shows neither AppBar title form, omits the board, or SC-005 is claimed from a log line alone. |
| AC-002 | R-002, R-008 | When the example has completed a successful open on a booted iOS simulator against an app-writable cache that holds a complete checkpoint, a screenshot of the visible route shall show AppBar title Snake or Snake — ended and the twelve-by-twelve board. | Boot an iOS simulator, launch, reach Snake after open, capture a screenshot, and inspect the image for that AppBar title and the board. | The capture shows only the idle Laya home, shows neither AppBar title form, omits the board, or SC-005 is claimed from a log line alone. |
| AC-003 | R-003 | When the example starts open on Android or iOS, the Directory passed to open shall be under app-writable storage for that process. | Inspect the example open path used on mobile and confirm the cache argument is an app-writable directory, not solely the Mac host cache helper. | Mobile open still points only at the Mac host cache path that the sandbox cannot read. |
| AC-004 | R-004 | When the app-writable cache directory lacks the required checkpoint artifacts and a network is available, open shall still be able to download those artifacts into that directory. | Call open against an empty app-writable directory with network available and observe artifacts appearing there, or review that the existing download path remains wired to that Directory. | First-run download is removed or cannot target the app-writable directory the example passes to open. |
| AC-005 | R-005 | When the example tokenizer override loads tokenizer.json, encode with addSpecialTokens false shall return token ids, and tokenToId for bos, eos, mask, and pad shall return integer ids, and neither call shall throw UnsupportedError. | Construct the override Tokenizer with a real tokenizer.json, encode a known string, and resolve those four special-token ids. | Encode or tokenToId throws UnsupportedError, or a factory still fails before those calls. |
| AC-006 | R-006 | When each frozen fixture state string is encoded on the host with addSpecialTokens false, once by the library tokenizer and once by the pure-Dart loader the example override uses, in a check that is not compiled under the example dependency override, the token id sequences shall be equal for every string. | Run that package-level check over the full frozen fixture state-string set and compare id lists pairwise. | Any fixture state string yields unequal id sequences, the check uses addSpecialTokens true, the check covers only a sample subset, or the check runs inside the example package where the override hides the library tokenizer. |
| AC-007 | R-007 | When the example iOS project is inspected, its iOS deployment target shall be at least 16.0 in every place the example pins that floor. | Read the example iOS project deployment target settings (and Podfile platform floor if present). | Any remaining example pin below 16.0, including a leftover 15.0 floor. |
| AC-008 | R-009 | When this slice’s packaging is inspected, checkpoint weight files shall not be present as committed pub-package contents or declared distributed example assets. | Review the package and example asset declarations and the git tree for checkpoint binaries added for distribution. | ONNX or other checkpoint weight files are committed into the package or listed as packaged assets for ship. |

## Non-functional criteria

| ID | Traces | Criterion | How it is checked | Negative case |
|---|---|---|---|---|
| AC-009 | R-008 | When a reviewer accepts SC-005 for this slice, the accepted evidence shall include the Android and iOS Snake screenshots described in AC-001 and AC-002 and shall not treat VM flutter test output as that proof. | Confirm the work item evidence set contains both screenshots and that verification notes do not substitute a VM test pass for them. | SC-005 is marked met with only VM tests, only logs, or only idle-home captures. |
| AC-010 | R-004 | When a developer seeds the app-writable cache from the host cache for a visual run, the ONNX file in that directory shall be a regular file of 1290466290 bytes, and the three companion files shall sit beside it. | After the seed, inspect the destination ONNX: it is not a symlink, and its length is 1290466290. | The destination ONNX is a symlink, has a different length, or a companion file is missing. |

## Explicitly not required

- Visual launch or proof on Windows, Linux, macOS, or web (SC-006).
- Changes to public library open or predict signatures.
- Changes to Classic Snake rules, relative turns, await-gated stepping, or the no-timer rule.
- Replacing the library hf_tokenizers pin.
- Android ProGuard keep rules while release minify stays off.
- Physical iOS device proof beyond a booted simulator.
- Re-deciding the macOS sandbox entitlements or integration_test harness from wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md.
- Packing checkpoint weights into the pub package.

## Verdict log

| Round | Date | Verdict | Report |
|---|---|---|---|
