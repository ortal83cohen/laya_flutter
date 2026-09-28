# Research: Restart the example Snake game when the snake dies

## Question

When the example Snake game ends because the head's next cell is a wall or the snake's own body,
what must a new run restore, which written constraints limit that restart, and what can a test
observe without opening an ONNX session?

## Answer

Death writes only `ended` and leaves the last living snake, heading, and food in place; the screen
step loop then exits and the title can stay `Snake — ended`. A new run must restore
constructor-equivalent play (`ended` false, the default three-cell snake, heading east, food on an
empty cell) and start await-gated steps again, without a timer, without a play button, and without
calling open again. Collision itself must still refuse to place a live head on the wall or through
the body. Logic tests that inject a predict double are the proof surface; pumping production
`SnakeScreen` would need a real session.

## Findings

### Death flips only `ended`; the loop does not resume

- Claim: `step` returns immediately when `ended` is already true. Predict failure or a missing or
  non-relative choice returns without setting `ended` and without advancing. Only a valid relative
  choice reaches the collision check. A wall or body cell sets `ended` and returns without changing
  the snake, heading, or food. The screen loops while the game is not ended, starts that loop once,
  and shows `Snake — ended` when `ended` is true. After the loop returns, `_loopStarted` stays true,
  so matching constructor fields does not by itself resume play.
- Evidence: Collision branch and early returns in the controller; one-shot loop and title in the
  screen.
- Source: `example/lib/snake_controller.dart` lines 179–218; `example/lib/snake_screen.dart` lines
  43–48, 58–73, and 91–93. Same facts in `research/end-state.md`.

### A new game must match the screen's constructor defaults, not only clear `ended`

- Claim: The screen builds one controller with width 80, height 80, a new random source, and the
  loaded runtime's predict, and does not pass an initial snake, heading, or food. Defaults are
  heading east, cells `(2,0)`, `(1,0)`, `(0,0)` head-first, food from a successful empty-cell
  placement, and `ended` false. Living steps change heading and cells before death, so the ended
  controller still holds that previous run. The product note on board size says the same 80 by 80
  screen construction, and classic-rules tests may use a smaller board.
- Evidence: Screen construction and constructor defaults.
- Source: `example/lib/snake_screen.dart` lines 32–39; `example/lib/snake_controller.dart` lines
  56–80 and 104–140; `wiki/product/classic-snake-example.md` lines 27–29.

### Immediate reset is the only shape inside the written constraints

- Claim: A wall or body ends the current run and the snake must not pass through a wall. The Snake
  screen must not use a timer, a delayed future, or a ticker, including for pacing. Predict failure
  stops further steps and is not death. Production launch has no play button. Open and predict stay
  closed. This slice does not advance SC-001 through SC-007.
- Evidence: Goal closed assumptions and SC-003; frozen 0003 timer and collision rules;
  classic-snake-example step gating; 0005 no-play-button freeze.
- Source: `wiki/product/GOAL.md` lines 32 and 43; `wiki/product/classic-snake-example.md` lines
  21–31; `wiki/work/0003-classic-snake/04-product-contract.md` lines 23–24 and 57;
  `wiki/work/0005-autostart-snake/04-product-contract.md` lines 18 and 41–43. Same facts in
  `research/constraints.md`.

### Existing death proof is controller-only and must keep failing a live head on the wall

- Claim: Wall and body tests inject a predict double, assert `ended`, assert the head stays on the
  pre-collision cell, and assert a further step leaves cells unchanged. Predict failure leaves
  `ended` false. Widget tests cover autostart and timer absence, not death. `SnakeScreen` requires a
  loaded runtime and has no predict-injection parameter. No restart or reset surface exists in the
  example today.
- Evidence: Collision tests, predict-failure test, widget and screen source tests, screen
  constructor.
- Source: `example/test/snake_controller_test.dart` lines 150–208 and 396–471;
  `example/test/widget_test.dart` lines 7–86; `example/test/snake_screen_test.dart` lines 13–42;
  `example/lib/snake_screen.dart` lines 15–39. Same facts in `research/tests.md`.

### Prior solution does not define restart

- Claim: The only solution file covers macOS ONNX session load and sandbox cache. A restart that
  reuses an already-loaded runtime does not reopen that surface. A restart that called open from a
  tree a VM widget test pumps would hit the MissingPluginException and sandbox constraints that
  solution documents.
- Evidence: Solution summary.
- Source: `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` lines 8–32.

## Options considered

| Option                                                | How it works                                                                                                | Cost                                                        | Why rejected / chosen                                                                                                                                            |
|-------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Immediate new run, no delay                           | After wall or body ends the current run, restore constructor-equivalent play and continue await-gated steps | Ended title is not the resting screen                       | Chosen. Only shape that restarts automatically without a timer or a play button (`research/constraints.md`).                                                     |
| Visible pause then reset                              | Hold the ended board, then reset                                                                            | Familiar death beat                                         | Rejected. A pause uses a timer, delayed future, or ticker, which 0003 and classic-snake-example forbid (`research/constraints.md`).                              |
| Stay ended until a user action                        | Freeze until play or restart is pressed                                                                     | Clear ended moment                                          | Rejected. Conflicts with automatic restart and with 0005's removal of a production play button (`research/constraints.md`).                                      |
| New controller instance                               | Replace the ended controller with one built the way the screen builds it today, then run steps again        | Screen must replace its controller and start the loop again | Favoured mechanism for matching a fresh construction, because the constructor is the only place that sets the full default play state (`research/end-state.md`). |
| In-place clear of the same controller                 | Set the same play fields back to constructor defaults, then run steps again                                 | Must not miss a field the previous run changed              | Viable if every default is matched. Not favoured as the definition of freshly constructed (`research/end-state.md`).                                             |
| Controller logic test with an injected predict double | Drive wall or body death, then the new-run action, and assert cells move again only after that action       | Does not by itself prove the screen calls the action        | Chosen proof. Existing death tests already use this harness (`research/tests.md`).                                                                               |
| Pump production SnakeScreen                           | Assert the ended title then a restarted board                                                               | Requires a real loaded runtime                              | Rejected for this proof. VM tests must not open a session (`research/tests.md`).                                                                                 |

## Parent decisions that close the research gaps

These choices pick among options the three streams already compared. They are not new facts about
the code.

- The collision step still ends the current run: the head does not occupy the wall cell or advance
  through the body, and a further step while that run is still ended does not change cells. The new
  run is a separate action the screen invokes with no user control.
- After that action, play matches the screen's constructor defaults: `ended` false, cells `(2,0)`,
  `(1,0)`, `(0,0)` head-first, heading east, food on an empty cell under the existing spawn rules.
  Food need not be bit-identical to the first game's food.
- The random source already owned by the controller may be reused. A second random source is not
  required.
- The screen must run await-gated steps again after the new run starts. Whether the one-shot loop
  flag is cleared is not a product requirement, as long as two loops do not run together.
- The plan chooses new-controller versus in-place clear. Both are allowed when the observables above
  hold. The constructor path is the favoured mechanism.
- There is no paced pause. The resting screen is the new game, title `Snake`. The ended title is not
  the resting state.
- Restart reuses the already-loaded runtime. It does not call open again.
- Proof is a controller test that injects predict and does not open a session. A production-screen
  pump that opens a session is not required. The screen check that new-run runs and the loop
  continues uses an optional predict override on the screen: production omits it and steps call the
  loaded runtime's predict; the check supplies the override plus a session-less runtime and must
  never call that runtime's predict and never call open.

## Constraints discovered

- Death is wall or own body only. Predict failure is not death and must not restart (
  `wiki/product/classic-snake-example.md` lines 21–25).
- The snake must not pass through a wall (`wiki/product/GOAL.md` line 43).
- No timer, delayed future, or ticker on the Snake screen (
  `wiki/work/0003-classic-snake/04-product-contract.md` line 23).
- Production launch has no play button (`wiki/work/0005-autostart-snake/04-product-contract.md` line
  18). This slice also adds no restart button, because restart is automatic; that restart-button ban
  is a decision of this work item, not a sentence in the 0005 play-button requirement.
- Library open and predict stay closed (`wiki/work/0005-autostart-snake/04-product-contract.md` line
  41).
- VM classic-rules tests inject predict and must not create a session (
  `wiki/product/classic-snake-example.md` lines 33–35).
- This slice does not advance SC-001 through SC-007 (`wiki/work/0010-restart-on-death/STATE.yaml`
  line 29).

## Unresolved

None. The gaps named in the stream files are closed by the parent decisions above.

## Provenance

- `research/end-state.md` — death fields, constructor defaults, loop exit, reconstruct versus
  in-place.
- `research/constraints.md` — timer, button, library, and restart-shape constraints.
- `research/tests.md` — existing death tests and the no-session proof surface.

## Sources

- `wiki/product/GOAL.md`, consulted 2026-09-28.
- `wiki/product/classic-snake-example.md`, consulted 2026-09-28.
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, consulted 2026-09-28.
- `example/lib/snake_controller.dart`, consulted 2026-09-28.
- `example/lib/snake_screen.dart`, consulted 2026-09-28.
- `example/test/snake_controller_test.dart`, consulted 2026-09-28.
- `example/test/widget_test.dart`, consulted 2026-09-28.
- `example/test/snake_screen_test.dart`, consulted 2026-09-28.
- `wiki/work/0003-classic-snake/04-product-contract.md`, consulted 2026-09-28.
- `wiki/work/0005-autostart-snake/04-product-contract.md`, consulted 2026-09-28.
- `wiki/work/0010-restart-on-death/STATE.yaml`, consulted 2026-09-28.
