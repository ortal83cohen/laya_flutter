# Research review — round 01

- Work item: 0008-snake-choice-log
- Reviewed artifact: `wiki/work/0008-snake-choice-log/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-28

## Verdict

**FAIL**

One cited source range does not support a product-boundary claim that the plan will inherit (library
open and predict stay closed).

## Verification performed

Opened and read every path listed under Sources, plus the two stream files named in Findings:

- `wiki/work/0008-snake-choice-log/00-research.md`
- `wiki/work/0008-snake-choice-log/research/step-record.md`
- `wiki/work/0008-snake-choice-log/research/test-capture.md`
- `wiki/product/GOAL.md` (lines 28–47)
- `wiki/product/classic-snake-example.md` (full)
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` (lines 1–40)
- `wiki/work/0007-restart-on-death/STATE.yaml`
- `example/lib/snake_controller.dart` (lines 42–114, 143–198, 278–288)
- `example/lib/snake_screen.dart` (lines 32–73)
- `example/test/snake_controller_test.dart` (lines 85–120, 302–366, 479–489)
- `lib/src/answers.dart` (lines 55–112, 242–258)

Repository search for developer-log / print APIs (validator re-ran; did not rely on the author’s
search claim):

```text
pattern: debugPrint|dart:developer|\bprint\(|Logger|package:logging|package:logger
glob: *.dart
result: No matches found
```

Confirmed `wiki/work/0008-snake-choice-log/validation/` had no prior `research-review-*.md` (round
01).

## Per-criterion results

N/A — research review.

## Findings

### F-001 — “Library open and predict stay closed” is not supported by the cited ranges

- Severity: BLOCKER
- Location: `wiki/work/0008-snake-choice-log/00-research.md:45-47`
- Criterion affected: none
- Observation: The claim states that library open and predict stay closed. The Source cites
  `wiki/product/GOAL.md` lines 28–32 and 43, `wiki/product/classic-snake-example.md` lines 15–35,
  and `wiki/work/0007-restart-on-death/STATE.yaml`. Those GOAL lines cover weights, quality bar,
  classic Snake rules, licence, platforms, and SC-003; they do not freeze the library open/predict
  API. Classic-snake lines 15–35 cover relative keys, prompt contract, no shield, no timer, and the
  test ban on calling `LayaFlutter.open` / creating an ONNX session. The API-freeze sentence (“The
  library open and predict API from 0002 stays closed for this slice.”) is at
  `wiki/product/classic-snake-example.md:39`, outside the cited range. `0007` STATE.yaml does not
  address the library API.
- Why it matters: A plan built on this research may treat an uncited line as established product
  law, or may treat the weaker “tests must not open a session” wording as if it closed the library
  API surface.

### F-002 — Evidence misstates work item 0007’s phase

- Severity: IMPORTANT
- Location: `wiki/work/0008-snake-choice-log/00-research.md:46`
- Criterion affected: none
- Observation: Evidence says “0007 state still in research.” Opening
  `wiki/work/0007-restart-on-death/STATE.yaml` shows `phase: validate`, not research. The companion
  claim that 0007 is a separate restart slice is supported by that file’s title.
- Why it matters: A false phase claim can distort sequencing and scope coordination with 0007 even
  though the out-of-scope conclusion is otherwise sound.

### F-003 — Return-value observation seam not compared

- Severity: IMPORTANT
- Location: `wiki/work/0008-snake-choice-log/00-research.md:49-58`
- Criterion affected: none
- Observation: Options compare board inference, `debugPrint`/`print` capture, an injected in-memory
  callback, console print via screen callback, and silence on failure. They do not consider having
  `step` return a record (or optional result) that tests and the screen could observe without a new
  constructor callback. Stream `test-capture.md` likewise omits that seam.
- Why it matters: The chosen inject-callback design is presented as the compared winner while
  another viable example-side observation path was never weighed.

### F-004 — Probability key labels lean on the stream, not the cited controller/answers ranges

- Severity: NIT
- Location: `wiki/work/0008-snake-choice-log/00-research.md:21-23`
- Criterion affected: none
- Observation: The claim that a choice answer carries probabilities for `left`, `right`, and
  `straight` cites `snake_controller.dart` 179–198 and `answers.dart` 55–66 and 93–112. Those ranges
  establish that `probabilities` and `confidence` exist and that `step` reads `choice`; they do not
  name the three keys. The three keys are established elsewhere (`buildTurnQuestion` criteria,
  answer shaping, and the test double). The stream file named on the same finding does carry that
  support.
- Why it matters: Primary line citations are incomplete; a reader who skips the stream may think
  `answers.dart` alone guarantees those keys.

### F-005 — Sandbox solution listed as a source but unused in Findings

- Severity: NIT
- Location: `wiki/work/0008-snake-choice-log/00-research.md:86`
- Criterion affected: none
- Observation: `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` appears under Sources. No
  Findings subsection in the merge artifact cites it. The session-proof constraint is carried by
  classic-snake product text instead.
- Why it matters: Inflates provenance without attaching a claim a reviewer can check against that
  file.

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
