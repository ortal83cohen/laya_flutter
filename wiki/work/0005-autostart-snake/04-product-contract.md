# Product contract: Start the example Snake game without a play button

## Advances

none

## Actors

| ID    | Actor                          | What they are trying to do                                 |
|-------|--------------------------------|------------------------------------------------------------|
| A-001 | Person running the example app | Reach Classic Snake without pressing a play control        |
| A-002 | VM widget test runner          | Pump the example root tree without opening an ONNX session |

## Requirements

| ID    | Requirement                                                                                                                                                                                                                                                           |
|-------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | When the example process starts with production entry settings, the home shall begin opening the runtime without showing a play button, show the existing opening label while that open is in progress, and after a successful open present the Classic Snake screen. |
| R-002 | When the runtime open started from that production path fails, the home shall show the existing open-failure text and shall not present the Classic Snake screen.                                                                                                     |
| R-003 | When a caller builds the example root with the default autostart setting (off), a single pump of that tree shall not open an ONNX session and shall not show the opening label.                                                                                       |
| R-004 | When a caller builds the example root with autostart off, the home shall remain idle for session open until some later explicit start path runs; mounting alone shall not open a session.                                                                             |

## Flows

| ID    | Flow                                                                                                                                                                                     | Covers       |
|-------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| F-001 | Production launch: process entry enables autostart; home starts open; opening label appears; successful open navigates to Snake; runtime closes when leaving Snake as today.             | R-001        |
| F-002 | Production launch with open failure: same start path; open fails; existing failure text appears; Snake is not shown.                                                                     | R-002        |
| F-003 | Default root pump: widget test (or any caller) builds the root with autostart default off; one pump shows the Laya title chrome and neither opens a session nor shows the opening label. | R-003, R-004 |

## Acceptance examples

| ID     | Example                                                                                                                                                                        | Covers       |
|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| AE-001 | A device or host launch of the example with production entry settings shows no play button, shows the opening label while open runs, then shows Snake after a successful open. | R-001        |
| AE-002 | The same production path with a failing open keeps the user on the home and shows the existing open-failure wording; Snake does not appear.                                    | R-002        |
| AE-003 | `flutter test` of the example widget test pumps the default root, finds the Laya title, finds no opening label, and does not require a native ONNX plugin.                     | R-003, R-004 |

## Boundaries

- This slice does not change the library open or predict API.
- This slice does not change Classic Snake rules, relative turns, await-gated stepping, or the ban
  on a step timer, ticker, or delayed future for pacing.
- This slice adds no predict-failure UI.
- This slice does not open a session in the process entry before the widget tree runs.
- This slice does not use a test-harness environment signal to skip open.
- This slice does not add a second application root for tests.
- This slice does not claim SC-003 or SC-005; goal_check stays null.
- Host proof that a real ONNX session loads remains outside VM widget tests (macOS integration path
  from the sandbox solution).

## Assumptions

- The Play Snake label is today’s chrome, not a goal requirement; removing it from the running app
  is allowed.
- Reusing the home’s existing opening label and open-failure text is enough chrome for production
  autostart.
- The lasting product rule for VM safety is “the tree a widget test pumps does not open a session,”
  not “a user must press a button.”
- An explicit autostart flag defaulting to off is the constructor contract that separates production
  from the pumped tree.

## Resolve before planning

(none)
