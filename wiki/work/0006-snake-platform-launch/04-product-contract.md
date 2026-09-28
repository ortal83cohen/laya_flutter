# Product contract: Show the Snake example on Android and iOS

## Advances

SC-005

## Actors

| ID    | Actor                                       | What they are trying to do                                                                 |
|-------|---------------------------------------------|--------------------------------------------------------------------------------------------|
| A-001 | Person launching the example on Android     | Reach the Classic Snake screen on the connected emulator after a successful open           |
| A-002 | Person launching the example on iOS         | Reach the Classic Snake screen on a booted simulator after a successful open               |
| A-003 | Reviewer checking SC-005                    | Confirm Snake is visible from screenshots, not from idle home chrome or process logs       |
| A-004 | Host verifier of the example tokenizer path | Confirm example encode ids match the library tokenizer on the frozen fixture state strings |

## Requirements

| ID    | Requirement                                                                                                                                                                                                                                                                                                |
|-------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | When the example runs on the connected Android emulator with a complete local checkpoint available under the directory the example passes to open, and open succeeds, the Classic Snake screen shall appear with AppBar title Snake or Snake — ended and the twelve-by-twelve board.                       |
| R-002 | When the example runs on a booted iOS simulator with a complete local checkpoint available under the directory the example passes to open, and open succeeds, the Classic Snake screen shall appear with AppBar title Snake or Snake — ended and the twelve-by-twelve board.                               |
| R-003 | When the example starts open on Android or iOS, it shall pass an app-writable directory into the existing open entry, not rely on the Mac host cache path as the only cache the mobile process can read.                                                                                                   |
| R-004 | When that app-writable directory lacks the required checkpoint artifacts and a network is available, the existing first-run download path shall remain able to populate that directory; a developer on this host may also place a copy of an existing complete cache into that directory for a visual run. |
| R-005 | When the example’s tokenizer override is used during open on Android or iOS, encode shall complete without the current UnsupportedError throw so open can return a loaded runtime and the Snake screen can be reached.                                                                                     |
| R-006 | When a host check outside the example dependency override encodes each frozen fixture state string with addSpecialTokens false, once with the library tokenizer and once with the pure-Dart loader the example override uses, the token id sequences shall be equal for every such string.                 |
| R-007 | When the example iOS project is built, its iOS deployment target shall be at least 16.0.                                                                                                                                                                                                                   |
| R-008 | When SC-005 is claimed for this slice, proof shall be a screenshot of the Snake AppBar title Snake or Snake — ended and the board on Android emulator-5554 and on a booted iOS simulator; a screenshot or observation of only the idle Laya home, or a log line alone, shall not count as proof.           |
| R-009 | When this slice ships, checkpoint weight files shall remain outside the pub package and shall not be committed as packaged assets for distribution.                                                                                                                                                        |

## Flows

| ID    | Flow                                                                                                                                                                                                                                                   | Covers                                          |
|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------|
| F-001 | Android visual run: example resolves an app-writable cache directory; artifacts arrive by first-run download or by a host copy of a complete cache; open succeeds; Snake screen is shown; a screenshot captures the AppBar and board on emulator-5554. | R-001, R-003, R-004, R-005, R-008, R-009        |
| F-002 | iOS visual run: same cache and open path on a booted simulator after the iOS deployment target is at least 16.0; Snake screen is shown; a screenshot captures the AppBar and board.                                                                    | R-002, R-003, R-004, R-005, R-007, R-008, R-009 |
| F-003 | Host tokenizer parity: on the developer host, outside the example dependency override, encode every frozen fixture state string with addSpecialTokens false using the library tokenizer and the pure-Dart loader; id sequences match.                  | R-006                                           |

## Acceptance examples

| ID     | Example                                                                                                                                                                                                                                                                                           | Covers              |
|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| AE-001 | On emulator-5554, after a successful open against an app-writable cache that holds a complete checkpoint, a screenshot shows AppBar title Snake or Snake — ended and the twelve-by-twelve board.                                                                                                  | R-001, R-008        |
| AE-002 | On a booted iOS simulator, after the same successful open path, a screenshot shows the same AppBar title forms and the board.                                                                                                                                                                     | R-002, R-007, R-008 |
| AE-003 | An empty app-writable cache directory passed to open triggers the existing first-run download when the network is available; a later open against that populated directory does not require packing weights into the pub package.                                                                 | R-003, R-004, R-009 |
| AE-004 | A package-level host test encodes each frozen fixture state string with addSpecialTokens false using the library tokenizer and the pure-Dart loader and finds equal id lists; the example override no longer throws UnsupportedError on encode or on tokenToId for the special tokens open needs. | R-005, R-006        |

## Boundaries

- This slice advances SC-005 only. Extra platforms named by runtime research (macOS, Windows, Linux,
  web) stay under SC-006 and are not launched or proven here.
- Public library open and loaded-runtime predict signatures stay closed.
- Classic Snake rules, relative turns, await-gated stepping, and the ban on a step timer stay
  closed.
- Checkpoint weights stay out of the pub package.
- The library keeps its existing tokenizer package pin; only the example override changes so mobile
  open can tokenize.
- Android release minify ProGuard keep rules are out of scope while release minify stays off.
- Proving a native ONNX session via VM flutter test is not this slice’s proof path. The macOS
  sandbox and integration_test guidance in wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md
  remains for host session proofs and is not reopened or applied as Android or iOS Snake proof.
- A physical iOS device is not required; a booted simulator is sufficient for this slice.

## Assumptions

- The closed slice decisions in STATE.yaml stand: app-writable directory into existing open;
  first-run download remains available; host copy of the existing cache is allowed for the visual
  run; example override encodes with the pure-Dart tokenizer chosen in research; library tokenizer
  pin unchanged; host id check on frozen fixture state strings is required; iOS deployment target at
  least 16; screenshot proof on emulator-5554 and a booted iOS simulator.
- Four flat checkpoint artifacts at the cache root remain the open contract; the ONNX graph size
  recorded in research is unchanged.
- The Snake screen chrome (AppBar title Snake or Snake — ended and the square board) is the only
  visual proof accepted for SC-005 on this slice.
- Free space, on-device tokenizer memory, and which screenshot CLI succeeds are implementation
  risks, not open product choices.

## Resolve before planning

(none — remaining research unresolved items are closed by STATE.yaml decisions or are verification
risks, not requirement forks)
