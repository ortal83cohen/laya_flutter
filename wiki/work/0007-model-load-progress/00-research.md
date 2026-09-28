# Research: Show model-load progress on the example home

## Question

Where can the example home show the English label "Loading the model" and a progress meter while
open runs, without breaking the locked Opening… chrome, and can that meter be driven by a numeric
fraction from download or from session creation?

## Answer

Opening… is shown on the example home only while the private opening flag is true, which covers the
await of open before navigation to Snake. The safe addition is the exact label "Loading the model"
plus a progress meter as further siblings in that same branch, leaving the Opening… string in place.
Neither the library download nor session creation exposes a numeric progress fraction. On a complete
cache the remaining wait is the opaque session create, so the meter is indeterminate. A fake
percentage on a timer is rejected by the work-item decision in STATE.yaml, not by GOAL's Snake
step-timer rule.

## Findings

### Opening chrome is gated by the opening flag

- Claim: The example home sets an opening flag, awaits open, navigates to Snake on success, and
  shows the text Opening… only while that flag is true. Production entry turns autostart on; the
  default constructors leave autostart off, so an idle mount does not enter that branch.
- Evidence: Open path and conditional text in the example home; production entry and default-off
  constructors.
- Source: `wiki/work/0007-model-load-progress/research/opening-chrome.md` (citing
  `example/lib/main.dart:16-18`, `example/lib/main.dart:89-141`, `example/lib/main.dart:157-160`)

### Tests and the prior slice lock Opening… and the failure prefix

- Claim: The idle widget test pumps the default example app, pumps a second frame, and requires
  Opening… to be absent. A source test requires the example home source to contain Opening…, the
  failure prefix Could not open runtime:, and Snake navigation only after success, and forbids a
  play button and navigation inside the failure path. Frozen criteria from the autostart slice
  require that same opening label while open is in progress.
- Evidence: Example widget tests and the autostart acceptance criteria.
- Source: `wiki/work/0007-model-load-progress/research/opening-chrome.md` (citing
  `example/test/widget_test.dart:7-18`, `example/test/widget_test.dart:40-86`,
  `wiki/work/0005-autostart-snake/02-criteria.md:10-16`)

### No progress meter exists yet; the new label is additive

- Claim: The example tree has no progress indicator today. Replacing Opening… with Loading the model
  would break the source lock. Adding both the new label and a meter inside the same opening branch
  keeps the lock and stays off the idle tree.
- Evidence: Search of the example tree; option comparison in the opening-chrome stream.
- Source: `wiki/work/0007-model-load-progress/research/opening-chrome.md`

### Neither download nor session create reports a fraction

- Claim: Open ensures a local checkpoint, then awaits a single session create, with no progress
  parameter. A complete ONNX of the expected byte length skips download. The download path pipes the
  HTTP body without counting bytes. The installed flutter_onnxruntime 1.8.5 session create is one
  method-channel call with no progress field, and the Android handler returns only after the native
  session exists. Upstream ONNX Runtime has an open request for load progress and no shipped
  fraction API.
- Evidence: Library open and download; plugin Dart and Android session create; ONNX Runtime issue
  17796.
- Source: `wiki/work/0007-model-load-progress/research/load-progress.md` (citing
  `lib/src/library.dart:25-58` and `lib/src/library.dart:149-186`, `lib/src/checkpoint_store.dart`,
  flutter_onnxruntime 1.8.5 sources, https://github.com/microsoft/onnxruntime/issues/17796)

### The observed Android wait is the opaque session create

- Claim: The complete-cache path skips download and then awaits session
  create. [UNVERIFIED: on 2026-09-28 the example on emulator-5554 already had the ONNX file at the expected length and still showed Opening… for several minutes before Snake.]
  That duration is not re-measured in a repository source. The code path itself does not depend on
  the duration.
- Evidence: Complete-cache short-circuit in the library; the duration sentence is marked unverified
  because the load-progress stream attributes it to a prompt observation and no durable log is
  cited.
- Source: `wiki/work/0007-model-load-progress/research/load-progress.md` (citing
  `lib/src/library.dart` and `lib/src/checkpoint_store.dart` for the code path)

### Contradiction resolved: the label is added, not a rename

- Claim: The load-progress stream once described the shared decision as renaming Opening… to Loading
  the model. The opening-chrome stream and the source test require Opening… to remain. The merged
  decision is additive: keep Opening… and also show Loading the model while opening.
- Evidence: Opening-chrome option B rejected; load-progress example-home finding used the word
  rename.
- Source: `wiki/work/0007-model-load-progress/research/opening-chrome.md`;
  `wiki/work/0007-model-load-progress/research/load-progress.md`

## Options considered

| Option                                                                                    | How it works                                                                                                                      | Cost                                                                                           | Why rejected / chosen                                                                                                      |
|-------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| Indeterminate meter plus the new label, inside the existing opening branch, Opening… kept | While open is in progress the home shows Opening…, the exact text Loading the model, and a progress control with no numeric value | Example UI and its test only; no library signature change                                      | Chosen. Matches both streams: chrome lock stays, and no fraction exists for the long session-create wait                   |
| Replace Opening… with Loading the model                                                   | One status string                                                                                                                 | Breaks the source test and the prior slice's opening label                                     | Rejected                                                                                                                   |
| Byte fraction from the download pipe                                                      | Count transferred bytes against content length                                                                                    | Library change; silent on a complete cache, which is the wait that was observed                | Rejected for this slice                                                                                                    |
| Optional progress callback on open                                                        | Library reports phases or download bytes                                                                                          | Public signature change; still no true fraction inside session create                          | Rejected. An indeterminate meter does not need it                                                                          |
| Discrete phase markers without a fake intra-phase percent                                 | Show real await boundaries only                                                                                                   | Still no fraction during session create; easy to look like a percentage if phases are weighted | Rejected as the primary meter. Recorded in the load-progress stream and not chosen                                         |
| Fake percentage on a timer                                                                | Bar advances with wall clock                                                                                                      | Looks like progress the runtime does not report                                                | Rejected by the work-item decision in STATE.yaml. GOAL's no-step-timer rule applies to Snake steps, not to this home meter |

## Constraints discovered

- The literal Opening… must remain in the example home source, and the idle default app must not
  show it.
- The open-failure prefix and the rule that failure does not navigate to Snake stay as they are.
- Public open and predict signatures stay closed.
- The meter must not invent a percentage with a timer. That limit is the work-item decision in
  STATE.yaml, not GOAL's Snake step-timer rule.
- This slice does not advance a goal success check. Snake rules, including no step timer, stay
  closed.
- VM widget tests are not session-load proof.

## Unresolved

- [UNRESOLVED: Exact wall-clock split on emulator-5554 between cache checks and session create was not re-measured in this research run.]
- [UNRESOLVED: Whether Hugging Face responses always include a reliable content length was not verified against a live download; that does not block an indeterminate meter.]
- [UNRESOLVED: Accessibility naming for the meter beyond the fixed English label was not specified.]

## Sources

- `wiki/work/0007-model-load-progress/research/opening-chrome.md`, consulted 2026-09-28
- `wiki/work/0007-model-load-progress/research/load-progress.md`, consulted 2026-09-28
- `wiki/product/GOAL.md`, consulted 2026-09-28
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-28
