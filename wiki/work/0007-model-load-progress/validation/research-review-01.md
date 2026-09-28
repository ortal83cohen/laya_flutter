# Research review — round 01

- Work item: 0007-model-load-progress
- Reviewed artifact: `wiki/work/0007-model-load-progress/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-28

## Verdict

**FAIL**

An emulator wall-clock observation is stated as fact without `[UNVERIFIED]`, and the cited GOAL no-timer wording does not support rejecting a fake load-percentage timer.

## Verification performed

Opened and read the reviewed artifact, both cited streams, and every durable path those streams and the merge name for the claims under review:

- `wiki/work/0007-model-load-progress/00-research.md`
- `wiki/work/0007-model-load-progress/research/opening-chrome.md`
- `wiki/work/0007-model-load-progress/research/load-progress.md`
- `example/lib/main.dart` (lines 16–18, 59–82, 88–174)
- `example/test/widget_test.dart` (lines 7–86)
- `wiki/work/0005-autostart-snake/02-criteria.md` (lines 10–35)
- `lib/src/library.dart` (lines 25–58, 68–186)
- `lib/src/checkpoint_store.dart` (lines 31–32, 64–90)
- `wiki/product/GOAL.md` (lines 28–44)
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` (lines 21–40)
- `wiki/product/classic-snake-example.md` (lines 31–35; cited by opening-chrome stream)
- `wiki/work/0007-model-load-progress/STATE.yaml`
- `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/lib/src/onnxruntime.dart` (lines 23–30)
- `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/lib/src/flutter_onnxruntime_method_channel.dart` (lines 24–41)
- `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/lib/src/ort_session.dart` (lines 91–114)
- `/Users/ortalcohen/.pub-cache/hosted/pub.dev/flutter_onnxruntime-1.8.5/android/src/main/kotlin/com/masicai/flutteronnxruntime/FlutterOnnxruntimePlugin.kt` (lines 212–323)
- https://github.com/microsoft/onnxruntime/issues/17796 (open feature request; maintainer reply 2023-10-05; no shipped load-progress API)

Repository checks (validator re-ran; did not rely on the author’s search claim):

```text
pattern: ProgressIndicator|LinearProgressIndicator|CircularProgressIndicator
path: example/
result: No matches found

pattern: progress|onProgress|contentLength
path: lib/
result: No matches found

pubspec.lock flutter_onnxruntime version: 1.8.5
```

Confirmed `wiki/work/0007-model-load-progress/validation/` had no prior `research-review-*.md` (round 01).

## Per-criterion results

N/A — research review.

## Findings

### F-001 — Emulator minutes-long wait stated without `[UNVERIFIED]`

- Severity: BLOCKER
- Location: `wiki/work/0007-model-load-progress/00-research.md:37-41`
- Criterion affected: none
- Observation: The finding asserts that on 2026-09-28 the example on emulator-5554 already had the ONNX file at the expected length and still showed Opening… for several minutes before Snake. The Source is the load-progress stream, which itself attributes that wall-clock observation to the research prompt and does not re-measure it. No repository file or other durable source confirms the device, duration, or isolate-stack detail. The claim is not marked `[UNVERIFIED]`, even though the Unresolved list only covers the finer wall-clock split.
- Why it matters: The Answer uses “the long wait” on a complete cache as part of the rationale for an indeterminate meter. A planner may treat an unverified host observation as established fact.

### F-002 — GOAL no-timer wording does not support rejecting a fake load-percentage timer

- Severity: BLOCKER
- Location: `wiki/work/0007-model-load-progress/00-research.md:57`
- Criterion affected: none
- Observation: The options table rejects “Fake percentage on a timer” with “Shared decision and the goal's no-timer assumption.” `wiki/product/GOAL.md` line 32 and SC-003 forbid a Snake step timer that advances play without a model result. They do not forbid inventing a load-progress percentage on the home screen. `STATE.yaml` has an empty `decisions` list, so the “shared decision” is not a durable cited source either. Constraint line 64 states the meter must not invent a timer percentage without a supporting source that actually says that.
- Why it matters: A plan that freezes “no fake load percentage” as GOAL-derived product law would misread SC-003, or would inherit an uncited prompt decision as if it were verified wiki authority.

### F-003 — Discrete phase markers omitted from merged options

- Severity: NIT
- Location: `wiki/work/0007-model-load-progress/00-research.md:49-57`
- Criterion affected: none
- Observation: The load-progress stream compared discrete real phases (ensureLocal done / createSession started / open done) as a meter-drive option without inventing intra-phase percentages. The merged Options table drops that row. The research question focuses on numeric fractions, so the omission does not overturn the indeterminate choice.
- Why it matters: A planner who reads only the merge may not see a viable non-fraction alternative that a cited stream already weighed.

### F-004 — GOAL and sandbox listed under Sources without a Findings citation

- Severity: NIT
- Location: `wiki/work/0007-model-load-progress/00-research.md:78-79`
- Criterion affected: none
- Observation: `wiki/product/GOAL.md` and `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` appear under Sources. No Findings subsection in the merge cites them directly; related constraints (“no step timer”, “VM widget tests are not session-load proof”) are stated without those paths. The streams do cite them.
- Why it matters: Inflates merge provenance without attaching a checkable claim in the artifact under review.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| F-001 | research |
| F-002 | research |
| F-003 | research |
| F-004 | research |
