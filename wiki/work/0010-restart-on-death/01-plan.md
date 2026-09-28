# Plan: Restart the example Snake game when the snake dies

## Goal

When the example Snake run ends on a wall or own-body collision, the screen starts a new run without
a user control and without a paced delay: collision still refuses a live head on the wall or through
the body, then a separate new-run action restores constructor-equivalent play and await-gated steps
continue on the already-loaded runtime. Predict failure does not restart. Proof stays on
session-free controller and screen checks that inject predict.

## Approach

Keep collision as today's end of the current run. Do not fold reset into the collision step. After
the screen observes that the run has ended from wall or body, it starts a new run by constructor
replacement: it discards the ended controller and builds a new Snake controller the same way the
screen builds one today for width, height, and predict from the loaded runtime, reusing the random
source already owned for that screen when that reuse is natural. The new controller must show ended
false, the default three-cell snake head-first at (2,0), (1,0), (0,0), heading east, and food on an
empty cell under the existing spawn rules.

Immediately after that replacement, the screen runs await-gated steps again. It does not call open.
It does not use a timer, delayed future, or ticker for death or restart. It does not start a second
concurrent step loop. The resting title after restart is Snake; the ended title is not the resting
state.

Leave library open and predict untouched. Leave relative turn keys and the no-play-button production
path untouched. Do not add a restart button.

Prove the new-run restore and post-restart advance with controller tests that inject a predict
double and never open a session. Prove that the screen invokes the new-run action after death and
continues the loop with a screen-level check that does not open a session. The seam is an optional
predict override on the screen. Production omits the override, and each step calls the loaded
runtime's predict. The check supplies the override together with a session-less runtime, and the
screen uses only the override for steps, so it never calls predict on that runtime and never calls
open.

## Why this approach

Research and the parent decisions chose an immediate new run with no delay. A visible pause was
rejected because a pause needs a timer, delayed future, or ticker, which 0003 and the classic Snake
example forbid. Staying ended until a user action was rejected because it conflicts with automatic
restart and with 0005's removal of a production play button. Constructor replacement was favoured
over in-place clear because the constructor is the only place that sets the full default play state
today; in-place clear remains viable only if every default is matched, and this plan does not use
it. Proof uses a predict-injected controller test; pumping production SnakeScreen with a real
session was rejected for this slice because VM tests must not open a session. See
wiki/work/0010-restart-on-death/00-research.md. The macOS ONNX sandbox solution is not reopened;
restart reuses an already-loaded runtime and does not call open from a pumped tree.

## Product contract

Units realise R-001 through R-006 in wiki/work/0010-restart-on-death/04-product-contract.md. This
plan adds no behaviour that contract does not state.

## Units

### U1. Collision still ends the current run only

Done when: a wall or own-body collision sets the current run ended without placing the head on the
wall or advancing through the body, leaves snake cells, heading, and food unchanged on that step,
and a further step while that run is still ended leaves cells unchanged; that collision step does
not itself perform the new-run restore.

Files it may touch: example Snake controller only if a compile-forced touch is required to keep
collision separate from new-run; prefer leaving collision logic behaviourally unchanged.

| Scenario                                 | Category   | Input                                                      | Action                                  | Expected outcome                                                                            | Covers        |
|------------------------------------------|------------|------------------------------------------------------------|-----------------------------------------|---------------------------------------------------------------------------------------------|---------------|
| Wall ends without occupying wall         | happy path | Living run; predict chooses a relative turn into a wall    | One step                                | ended true; head remains on pre-collision cell; cells, heading, food unchanged on that step | R-001, AE-001 |
| Body ends without advancing through body | happy path | Living run; predict chooses a relative turn into the body  | One step                                | ended true; head remains on pre-collision cell; cells unchanged on that step                | R-001, AE-002 |
| Further step while ended is inert        | edge       | Run already ended by wall or body; new-run not yet invoked | Another step                            | Snake cells unchanged                                                                       | R-001         |
| Collision step is not the new run        | edge       | Just after wall or body end                                | Inspect state before any new-run action | Cells are still the previous living layout, not the default three-cell start                | R-001, R-003  |

### U2. New-run action restores constructor-equivalent play

Done when: a distinct new-run path, realised by constructing a replacement Snake controller the way
the screen constructs one today, yields ended false, cells (2,0), (1,0), (0,0) head-first, heading
east, and food on an empty cell; the existing random source may be reused; a later step on that new
controller can change cells again when predict returns a valid relative turn.

Files it may touch: example Snake controller (only if a named new-run helper is introduced for
testability), example Snake screen (construction and ownership of the replacement controller).

| Scenario                         | Category   | Input                                                                 | Action                                                       | Expected outcome                                                                       | Covers        |
|----------------------------------|------------|-----------------------------------------------------------------------|--------------------------------------------------------------|----------------------------------------------------------------------------------------|---------------|
| Restore after wall death         | happy path | Controller ended by wall; previous cells not the defaults             | Invoke new-run / replace with freshly constructed controller | ended false; cells (2,0), (1,0), (0,0) head-first; heading east; food on an empty cell | R-003, AE-001 |
| Restore after body death         | happy path | Controller ended by body                                              | Same new-run action                                          | Same constructor-equivalent observables                                                | R-003, AE-002 |
| Steps advance only after new run | happy path | After new-run restore; injected predict returns a valid relative turn | One step                                                     | Snake cells change from the default start layout                                       | R-003, AE-001 |
| Food need not match prior game   | edge       | Previous food cell recorded before death                              | New-run action                                               | Food is on some empty cell; identity with the previous food cell is not required       | R-003         |

### U3. Screen restarts after death without open, timer, or dual loops

Done when: after wall or body death, the Snake screen invokes the new-run action with no user
control; it does not call open; it reuses the loaded runtime's predict; it starts await-gated steps
again; two step loops do not run together; it introduces no timer, delayed future, or ticker for
death or restart; the resting title after restart is Snake; the ended title is not the resting
state; predict failure does not trigger the new-run action.

Files it may touch: example Snake screen; example Snake screen tests or harness seams needed for
session-free proof.

| Scenario                         | Category   | Input                                                                 | Action                                       | Expected outcome                                                          | Covers               |
|----------------------------------|------------|-----------------------------------------------------------------------|----------------------------------------------|---------------------------------------------------------------------------|----------------------|
| Screen new-run after death       | happy path | Screen with loaded runtime already in hand; wall or body ends the run | Observe post-death path                      | New-run action runs; await-gated steps continue; open is not called again | R-002, R-004, AE-003 |
| Resting title is Snake           | happy path | After new-run on the screen                                           | Observe title                                | Title is Snake; ended title is not the resting state                      | R-006, AE-003        |
| No paced death delay             | edge       | Death then restart path                                               | Inspect screen sources and runtime behaviour | No timer, delayed future, or ticker used for death or restart             | R-002                |
| Single loop                      | edge       | Restart after death                                                   | Start steps again                            | Only one await-gated step loop is active                                  | R-004                |
| Predict failure does not restart | error      | Living run; predict fails or choice is missing or not relative        | One step                                     | ended remains false from that stop alone; new-run action does not run     | R-005, AE-004        |

### U4. Session-free proof for controller and screen

Done when: controller tests drive wall and body death, then the new-run action, with an injected
predict double and no session; a screen-level check shows the screen invokes the new-run action and
continues the loop without opening a session; existing collision and predict-failure assertions
remain meaningful.

Files it may touch: example Snake controller tests; example Snake screen tests or related example
tests that must stay session-free.

| Scenario                               | Category    | Input                                                             | Action                             | Expected outcome                                                                          | Covers               |
|----------------------------------------|-------------|-------------------------------------------------------------------|------------------------------------|-------------------------------------------------------------------------------------------|----------------------|
| Controller wall then new run           | happy path  | Injected predict steers into wall, then valid turns after new run | Step to death; new-run; step again | End observables then restore observables; cells can move after restore; no session opened | R-001, R-003, AE-001 |
| Controller body then new run           | happy path  | Injected predict steers into body, then valid turns after new run | Same sequence                      | Same end-then-restore pattern; no session opened                                          | R-001, R-003, AE-002 |
| Screen invokes new run without session | integration | Screen under a harness that supplies predict without open         | Drive or simulate death            | New-run invoked; loop continues; open not called; no ONNX session required                | R-002, R-004, AE-003 |
| Predict failure stays non-restart      | error       | Injected predict fails                                            | One step                           | ended false; new-run not invoked                                                          | R-005, AE-004        |

## Interfaces and shared decisions

- Mechanism: constructor replacement. The screen owns replacing the ended Snake controller with a
  newly constructed one. In-place clear of fields on the same instance is rejected for this slice.
  The controller field is late final today, so replacement cannot assign through that binding; the
  field must become assignable before the new instance is stored.
- Construction inputs for the replacement match today's screen construction: width eighty, height
  eighty, predict from the already-loaded runtime when no override is set, no initial snake,
  heading, or food overrides. Do not change the production board size. Work item 0009 set that size
  after the first plan review, which had recorded one hundred twenty; eighty is the screen
  construction as of this plan text. If the screen literals are not eighty by eighty when
  implementation starts, stop and report a plan defect. The random source already owned for that
  screen may be reused; a second random source is not required.
- Screen predict seam: an optional predict override. When it is absent, steps use the loaded
  runtime's predict. When it is present, steps use the override only and do not call the runtime's
  predict and do not call open. The session-free screen check uses that override with a session-less
  runtime.
- New-run is a separate action from the collision step. Collision only ends the current run. The
  screen invokes new-run after observing wall or body end.
- Naming in words: treat the screen's post-death path as the new-run action. If a controller-side
  helper exists only for tests, it must produce the same constructor-equivalent observables; it must
  not redefine collision.
- Error handling: predict failure, missing choice, and non-relative choice do not set ended and do
  not invoke new-run.
- Loop policy: after new-run, await-gated steps run again. Two loops must not run together. How the
  one-shot loop flag is cleared or replaced is an implementation detail.
- Title: resting state after restart shows Snake. The ended title is not the resting state.
- Open: do not call open on restart. Reuse the loaded runtime.
- Library: do not change open or predict under the package library sources.
- Buttons: do not add a play or restart button. Do not restore a production play button.
- Relative turns: do not change relative turn keys or the relative-turn contract.
- Proof: controller tests inject predict and open no session. Screen proof of new-run invocation and
  continued loop also opens no session. Production SnakeScreen pump with a real session is not
  required for this slice.
- Goal: advances none; goal_check stays null.

## Risks

| Risk                                                                                                          | Likelihood | Impact                                                             | Mitigation                                                                                                                      | Trigger that means it happened                                                                                |
|---------------------------------------------------------------------------------------------------------------|------------|--------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| Folding restore into the collision step breaks the wall-must-not-be-occupied rule or makes death unobservable | Medium     | SC-003-style collision guarantees regress                          | Keep collision and new-run as separate actions; keep tests that assert pre-collision head and inert further step before new-run | Wall death leaves head on the wall cell, or cells already show the default start on the collision step itself |
| Starting steps again without clearing the one-shot loop leaves the board idle after death                     | Medium     | Automatic restart fails in the running app                         | Screen must actually run await-gated steps again after replacement; cover with a screen-level session-free check                | After death, new controller exists but no further steps run                                                   |
| Two step loops run after restart                                                                              | Low        | Duplicate steps or races                                           | Ensure only one loop is active when restarting                                                                                  | Two concurrent step loops observed after death                                                                |
| Screen proof accidentally calls open or needs a real session                                                  | Medium     | VM tests hit MissingPluginException or reopen the sandbox solution | Inject predict; never open in the proof path; cite the sandbox solution only as out of scope                                    | Screen test opens a session or fails with MissingPluginException                                              |
| In-place clear sneaks in and misses a field                                                                   | Low        | Partial reset leaves stale heading or food                         | Stick to constructor replacement in review                                                                                      | Diff mutates fields on the ended instance instead of replacing it                                             |

## Rollback

Revert the example Snake screen, any controller helper added only for new-run, and the related
example tests. The previous behaviour returns: death sets ended, the loop exits, and the ended title
can remain. No data migration and no one-way door. Library sources are untouched, so rollback stays
inside the example.

## Out of scope

- Any change under the package library sources, including open and predict.
- A play or restart button.
- Changes to relative turn keys or relative-turn rules.
- A paced pause or death animation that uses a timer, delayed future, or ticker.
- Calling open again after the runtime is loaded.
- Treating predict failure as death or as a restart trigger.
- In-place clear as the chosen new-run mechanism.
- Pumping production SnakeScreen with a real ONNX session as the required proof.
- Advancing SC-001 through SC-007; goal_check remains null.
- Reopening or changing the macOS ONNX session sandbox solution.

## Verification approach

Run the example controller tests that inject a predict double: wall death, body death, inert further
step while ended, new-run restore to constructor defaults, cells advancing only after new-run, and
predict failure neither ending nor restarting. Run the session-free screen-level check that the
screen invokes new-run after death and continues await-gated steps without calling open. Confirm by
review that the Snake screen introduces no timer, delayed future, or ticker for death or restart,
that resting title after restart is Snake, and that library sources are untouched. Do not treat VM
flutter test as session-load proof.
