# Acceptance criteria: Show model-load progress on the example home

## Frozen

- Frozen at: not yet
- Frozen by: not yet

## Criteria

| ID     | Traces | Criterion                                                                                                                                                         | How it is checked                                                                                                                                          | Negative case                                                                                         |
|--------|--------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| AC-001 | R-001  | When the example home is waiting on open, the system shall show both Opening… and the exact text Loading the model.                                               | Widget or source test of the example home while the opening path is active asserts both strings are present.                                               | Only one of the two strings is present, or Loading the model replaces Opening….                       |
| AC-002 | R-002  | When the example home is waiting on open, the system shall show a progress meter with no numeric fraction and with no wall-clock timer that invents a percentage. | Widget or source inspection confirms a progress control in the opening branch and confirms it is not given a fraction value or a percentage-driving timer. | A percent value is shown, a valued progress fraction is bound, or a timer advances a fake percentage. |
| AC-003 | R-003  | When the default example app is mounted idle with autostart off, the system shall show neither Opening…, nor Loading the model, nor the progress meter.           | Pump the default example app, pump a second frame, and assert all three indicators are absent.                                                             | Any of Opening…, Loading the model, or the progress meter appears on the idle tree.                   |
| AC-004 | R-004  | When open fails on the example home, the system shall show failure text that still begins with Could not open runtime: and shall not navigate to Snake.           | Source or behaviour test asserts the failure prefix remains and Snake navigation is not on the failure path.                                               | The failure prefix changes, or Snake is reached after a failed open.                                  |
| AC-005 | R-005  | When this slice is complete, the public open and predict call shapes of the library shall be unchanged.                                                           | Review the library public open and predict entry points for this slice; assert no progress parameter or callback was added.                                | open or predict gains a progress argument, callback, or other signature change for this work.         |

## Non-functional criteria

| ID | Traces | Criterion | How it is checked | Negative case |
|----|--------|-----------|-------------------|---------------|

(none for this slice)

## Explicitly not required

- A numeric download or session-create fraction
- Download-byte instrumentation or a library progress callback
- Renaming or removing Opening…
- A timer that fakes percentage progress
- Accessibility naming for the meter beyond the visible English label Loading the model
- Wall-clock measurement of cache checks versus session create
- Proof that Hugging Face responses always supply content length
- VM or integration proof that native ONNX session create finished
- Advancement of any goal success check

## Verdict log

| Round | Date | Verdict | Report |
|-------|------|---------|--------|
