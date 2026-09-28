# Research: Product constraints on restart after Snake death

## Question

Which written product constraints limit an automatic restart of the example Snake game after the snake dies, and which restart shapes stay inside those constraints?

## Answer

Written constraints require that wall or body collision ends the current run (not a pass-through), that steps stay await-gated with no Timer, Future.delayed, or Ticker on the Snake screen, that predict failure is not death and must not invent a turn, that production launch has no play button, and that the library open and predict API stay closed. Inside those bounds, an immediate board reset that starts a new await-gated run without a delay or user control fits; a visible pause that schedules a timer or delayed future for pacing violates the no-timer rule; staying on the ended screen until a user action conflicts with the no-play-button launch rule and the user ask for automatic restart after death.

## Findings

### GOAL ends the current run on wall or body; no step timer; wall is impassable

- Claim: Closed assumptions fix classic Snake: a wall or the snake’s own body ends the game, food spawns on a random empty cell, the model chooses a relative left/right/straight turn, and there is no step timer. SC-003’s negative case includes a timer that moves the snake without a model result, and the snake must not pass through a wall. A restart after death is therefore a new run after that end, not continued live stepping through a wall or body cell.
- Evidence: Closed Snake assumptions; SC-003 check and negative case.
- Source: `wiki/product/GOAL.md:32`; `wiki/product/GOAL.md:43`.

### 0003 freezes ended-on-collision and a hard ban on timer constructs on the Snake screen

- Claim: The frozen 0003 product contract requires that when the head’s next cell is a wall or body, the game ends and the snake does not continue stepping (R-006 / F-003). It also requires that the Snake screen contain no Timer, no Future.delayed, and no Ticker, including for decorative drawing; redraw is state after the awaited step (R-005). Frozen AC-005 and AC-006 encode the same rules. Slice boundaries reject a step timer, a one-shot delay after predict for pacing, and a decorative animation ticker. Those freezes still bind any restart that lives on the Snake screen.
- Evidence: R-005, R-006, F-003, AE-006; Boundaries paragraph on timers; AC-005 and AC-006.
- Source: `wiki/work/0003-classic-snake/04-product-contract.md:23-24`; `wiki/work/0003-classic-snake/04-product-contract.md:33`; `wiki/work/0003-classic-snake/04-product-contract.md:45`; `wiki/work/0003-classic-snake/04-product-contract.md:57`; `wiki/work/0003-classic-snake/02-criteria.md:16-17`.

### classic-snake-example.md forbids pacing delays and treats predict failure as stop, not death

- Claim: SC-003’s timer negative case forbids not only a step clock but also a decorative Ticker and a one-shot delay after predict used for pacing. When predict fails or returns a missing or non-relative choice, the step must not invent a turn and must not advance; the screen stops further steps when a finished step neither ends the game nor changes snake cells. Death for restart purposes is therefore only the existing ended condition (wall or body), not predict failure.
- Evidence: Step gating and predict failure section.
- Source: `wiki/product/classic-snake-example.md:21-25`.

### 0005 removed the play button and kept Snake rules and the no-timer rule closed

- Claim: Work item 0005’s frozen contract starts production Snake without a play button, keeps library open and predict closed, and explicitly does not change Classic Snake rules, relative turns, await-gated stepping, or the ban on a step timer, ticker, or delayed future for pacing. Acceptance criteria list a play button or other manual start control on the production path as explicitly not required. Adding a play or restart button as the death gate is therefore out of scope relative to that freeze and to the shared decision that a play button is out of scope for restart-on-death.
- Evidence: R-001; Boundaries; Explicitly not required; round-0 decision keeping Snake rules and no-timer closed; production note in classic-snake-example.md.
- Source: `wiki/work/0005-autostart-snake/04-product-contract.md:18`; `wiki/work/0005-autostart-snake/04-product-contract.md:41-43`; `wiki/work/0005-autostart-snake/02-criteria.md:26-30`; `wiki/work/0005-autostart-snake/STATE.yaml:17-21`; `wiki/product/classic-snake-example.md:31`.

### Library open/predict stay closed; session reopen is a different concern

- Claim: 0003 and 0005 leave `LayaFlutter.open` and `LoadedRuntime.predict` closed. Host proof that a real ONNX session loads remains outside VM widget tests and belongs on the macOS integration path in the sandbox solution. A board-level restart that reuses an already-loaded runtime does not reopen that proof surface; a restart that called open again from a tree a VM widget test pumps would re-enter the MissingPluginException / sandbox constraints documented there.
- Evidence: 0003 Boundaries and Assumptions; 0005 Boundaries; sandbox guidance; classic-snake-example.md test and open constraints.
- Source: `wiki/work/0003-classic-snake/04-product-contract.md:51`; `wiki/work/0003-classic-snake/04-product-contract.md:71`; `wiki/work/0005-autostart-snake/04-product-contract.md:41`; `wiki/work/0005-autostart-snake/04-product-contract.md:48`; `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-30`; `wiki/product/classic-snake-example.md:27-31`.

### This slice does not advance goal success checks

- Claim: Shared decisions for this work item keep GOAL closed assumptions closed and state that this slice does not advance SC-001 through SC-007; goal_check stays null. Restart behaviour must still respect those closed assumptions and the frozen example contracts, but it is not a vehicle to reopen or claim SC-003 progress.
- Evidence: GOAL closed assumptions; work item goal_check field (null).
- Source: `wiki/product/GOAL.md:28-35`; `wiki/work/0010-restart-on-death/STATE.yaml:29`.

### Prior solutions do not prescribe restart shape

- Claim: The only file under `wiki/solutions/` addresses macOS ONNX session-load harness constraints. It does not define death, restart, or post-ended UI. It is cited only when a restart design would touch session open.
- Evidence: Solution summary and when-to-apply.
- Source: `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-40`.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Immediate reset of the board and continued await-gated steps with no delay | On wall/body ended, clear or replace the run state (new snake, food, heading, ended cleared) and continue the existing await-gated predict→turn→advance loop without Timer, Future.delayed, or Ticker | No death “beat”; ended UI may flash for only one rebuild; must still distinguish predict-failure stop from death restart | **Favoured for constraint fit** — meets automatic restart after death, keeps no-timer / no-play-button / library-closed rules, and treats restart as a new run after the current run ends |
| Visible pause then reset | After ended, hold the ended board for a paced interval, then reset and resume steps | Familiar arcade cadence; clearer death moment | **Violates the no-timer rule** if the pause is implemented with Timer, Future.delayed, or Ticker (forbidden by 0003 R-005/AC-005 and classic-snake-example.md pacing ban). A pause that is only “wait for the next awaited predict on an ended board” is not a visible death pause and conflicts with “no further stepping as a live run” unless ended is cleared first without a delay |
| Stay on the ended screen until a user action | After death, freeze the ended board until the user presses play/restart (or leaves and re-enters) | Clear ended state; no pacing timer required | **Rejected for this ask** — conflicts with automatic restart after death and with 0005’s removal of a production play button; reintroducing a manual start control is out of scope |

## Constraints discovered

- Wall or own body ends the current run; the snake must not pass through a wall (`wiki/product/GOAL.md:32`; `wiki/product/GOAL.md:43`; `wiki/work/0003-classic-snake/04-product-contract.md:24`).
- Restart after death is a new run after that end, not continued live stepping past collision (shared decision; GOAL closed assumption; 0003 R-006 / AC-006).
- Predict failure is not death: no invented turn, no advance, stop further steps (`wiki/product/classic-snake-example.md:21-25`).
- No step timer; Snake screen must not construct Timer, Future.delayed, or Ticker, including for decorative drawing or post-predict pacing (`wiki/product/GOAL.md:32`; `wiki/product/GOAL.md:43`; `wiki/work/0003-classic-snake/04-product-contract.md:23`; `wiki/work/0003-classic-snake/04-product-contract.md:57`; `wiki/work/0003-classic-snake/02-criteria.md:16`; `wiki/product/classic-snake-example.md:21-23`; `wiki/work/0005-autostart-snake/04-product-contract.md:42`).
- Production example starts Snake with no play button; adding a play/restart button as the death gate is out of scope (`wiki/product/classic-snake-example.md:31`; `wiki/work/0005-autostart-snake/04-product-contract.md:18`; `wiki/work/0005-autostart-snake/02-criteria.md:26-27`).
- Library `LayaFlutter.open` and predict API stay closed (`wiki/work/0003-classic-snake/04-product-contract.md:51`; `wiki/work/0005-autostart-snake/04-product-contract.md:41`).
- Relative turn keys, English state prompt surface, and “example is one app not a game engine” stay closed (`wiki/product/classic-snake-example.md:15-19`; `wiki/product/classic-snake-example.md:35`; `wiki/work/0003-classic-snake/04-product-contract.md:55-59`).
- VM-pumped example tree must not open an ONNX session; host session proof stays on macOS integration_test (`wiki/product/classic-snake-example.md:27-31`; `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md:8-30`).
- This slice does not advance SC-001–SC-007; goal_check stays null (`wiki/work/0010-restart-on-death/STATE.yaml:29`).

## Unresolved

- [UNRESOLVED: Must a new run allocate a fresh controller instance, or may the same controller clear ended and re-seed board fields in place, as long as live stepping does not continue through the collision cell?]
- [UNRESOLVED: Is any non-timer “visible pause” (for example holding ended for one Flutter frame via setState only) allowed, or must reset happen in the same completion path that sets ended?]
- [UNRESOLVED: If death UI text exists today, must it remain visible across the reset boundary, or may it disappear as soon as the new run starts?]
- [UNRESOLVED: Should an automatic restart ever call LayaFlutter.open again, or is reuse of the already-loaded LoadedRuntime mandatory for this slice?]

## Sources

- `wiki/product/GOAL.md`, consulted 2026-09-28
- `wiki/product/classic-snake-example.md`, consulted 2026-09-28
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-28
- `wiki/work/0003-classic-snake/04-product-contract.md`, consulted 2026-09-28
- `wiki/work/0003-classic-snake/02-criteria.md`, consulted 2026-09-28
- `wiki/work/0005-autostart-snake/04-product-contract.md`, consulted 2026-09-28
- `wiki/work/0005-autostart-snake/02-criteria.md`, consulted 2026-09-28
- `wiki/work/0005-autostart-snake/STATE.yaml`, consulted 2026-09-28
- `wiki/work/0010-restart-on-death/STATE.yaml`, consulted 2026-09-28
- `wiki/work/0003-classic-snake/research/step-loop.md`, consulted 2026-09-28 (prior research; timer options already closed by 0003 freeze)
