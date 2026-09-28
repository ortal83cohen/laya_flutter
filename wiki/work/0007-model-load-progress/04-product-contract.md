# Product contract: Show model-load progress on the example home

## Advances

none

## Actors

| ID    | Actor               | What they are trying to do                                                                                   |
|-------|---------------------|--------------------------------------------------------------------------------------------------------------|
| A-001 | Example app user    | See that the model is still loading while open runs, then reach Snake when open succeeds                     |
| A-002 | Example test runner | Confirm idle chrome stays off and opening chrome keeps the locked Opening… text plus the new label and meter |

## Requirements

| ID    | Requirement                                                                                                                                                              |
|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | When the example home is waiting on open, it shall show the existing Opening… text and also the exact English label Loading the model.                                   |
| R-002 | When the example home is waiting on open, it shall show a progress meter that does not display a numeric fraction and does not advance by a wall-clock percentage timer. |
| R-003 | When the example app is mounted idle with autostart off, it shall show neither Opening…, nor Loading the model, nor the progress meter.                                  |
| R-004 | When open fails, the example home shall keep the existing failure prefix text and shall not navigate to Snake.                                                           |
| R-005 | This slice shall not change the public open or predict call shapes of the library.                                                                                       |

## Flows

| ID    | Flow                                                                                                                                                                                                                                              | Covers       |
|-------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| F-001 | Production entry starts open. While open is in progress the home shows Opening…, Loading the model, and an indeterminate progress meter. On success the app navigates to Snake and those opening indicators are no longer the active home chrome. | R-001, R-002 |
| F-002 | Default idle mount with autostart off never enters the opening branch, so none of the opening indicators appear.                                                                                                                                  | R-003        |
| F-003 | Open fails. The home shows the existing failure text with its locked prefix and does not push Snake.                                                                                                                                              | R-004        |

## Acceptance examples

| ID     | Example                                                                                                                                                | Covers       |
|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| AE-001 | Open is in progress on the example home. The tree contains Opening… and Loading the model, and a progress control is present with no percentage value. | R-001, R-002 |
| AE-002 | The default example app is pumped idle for a second frame. Opening…, Loading the model, and the progress meter are all absent.                         | R-003        |
| AE-003 | Open fails. The failure text still begins with Could not open runtime: and Snake is not reached.                                                       | R-004        |
| AE-004 | A review of the public library surface shows open and predict signatures unchanged by this slice.                                                      | R-005        |

## Boundaries

- No download-byte instrumentation and no progress callback on the library open path.
- No rename or removal of Opening….
- No fake percentage driven by a timer.
- No change to Snake rules, step timing, or navigation success path beyond leaving opening chrome
  when open finishes.
- No claim that VM widget tests prove native session load; that remains a host integration concern
  per the macOS session-sandbox solution.
- Wall-clock split between cache checks and session create is not a product requirement.
- Reliable Hugging Face content-length behaviour is out of scope for this indeterminate meter.
- Accessibility naming for the meter beyond the fixed English label Loading the model is not
  specified in this slice.

## Assumptions

- Opening chrome remains gated by the existing private opening flag on the example home.
- On a complete local cache the long wait is an opaque session create with no fraction to report, so
  an indeterminate meter is the honest UI.
- The autostart slice locks Opening…, the failure prefix, and success-only navigation; this slice
  adds chrome beside that lock and does not reopen those rules.
- goal_check stays null; this slice does not advance a goal success check.
- Snake remains classic with no step timer; that closed goal assumption is untouched.

## Resolve before planning

(none — unresolved research items do not change these requirements)
