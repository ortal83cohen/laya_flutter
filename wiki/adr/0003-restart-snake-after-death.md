---
id: adr-0003-restart-snake-after-death
title: "ADR 0003: Restart the example Snake run after death in the same step loop"
status: active
owner: unassigned
last_verified: 2026-09-28
applies_to: ["example/lib/snake_screen.dart", "example/lib/snake_controller.dart", "example/test/**"]
summary: After a wall or body collision the example replaces the ended run and keeps stepping, with no button and no timer.
---

# ADR 0003: Restart the example Snake run after death in the same step loop

- Status: accepted
- Date: 2026-09-28
- Deciders: work item 0010-restart-on-death, accepted by the user when documentation was closed

## Context and problem statement

When the example snake hits a wall or its own body, should the screen stay on the ended board, wait
for a control, or start a new run, and if it starts a new run, how is that run built without a step
timer?

## Decision drivers

- The user asked for a new game when the snake dies.
- A wall or body still ends the current run; the snake must not pass through either.
- The Snake screen must not use a timer, a delayed future, or a ticker.
- Production launch has no play button, and this slice adds no restart button.
- Predict failure is not death.
- VM tests must not open an ONNX session.

## Considered options

### Replace the ended controller and continue the same await-gated loop

Collision still sets the current run ended and leaves the head off the wall and off the body. The
screen then constructs a new controller the way it constructs the first one, and the loop that was
already running keeps awaiting steps.

### Hold the ended board for a paced interval, then reset

Show the death, wait, then start again.

### Stay ended until the user presses a control

Leave the title Snake — ended until a play or restart control.

### Clear fields on the same controller instance

Keep one controller and write the start snake, heading, and food back onto it.

## Decision outcome

Chosen option: replace the ended controller and continue the same await-gated loop.

A paced hold needs a timer, delayed future, or ticker, which the example forbids. A button conflicts
with automatic restart. Clearing fields on the same instance can miss a field the previous run
changed; construction is the place that already sets the full start state. Collision stays a
separate step so a further step on the ended controller still does not move cells.

## Consequences

- Positive: death does not leave the example on Snake — ended, and the no-timer and no-button rules
  stay intact.
- Negative: the ended title is not a resting screen. A restart that is folded into the collision
  step would make the existing "further step while ended" tests lie.

## Confirmation

From `example/`, `flutter test test/snake_controller_test.dart test/snake_screen_test.dart` must
pass, including the tests named `wall ends the game; further step does not move cells`,
`wall then new-run restores defaults; later step moves`,
`after wall death screen new-runs and continues steps without open`,
`predict failure does not start a new run`, and
`AC-007: Snake screen sources have no Timer, Future.delayed, or Ticker`.

A violation is a wall death whose resting title is Snake — ended, a new run that starts when predict
fails, a Timer or Future.delayed or Ticker on the Snake screen, or a collision step that places the
head on the wall.

## Pros and cons of the options

### Replace and continue

Pros: matches automatic restart, reuses the constructor, keeps one loop. Cons: death is not a screen
the user stays on.

### Paced hold

Pros: the death is visible for a beat. Cons: forbidden by the no-timer rule.

### Wait for a control

Pros: the ended board is obvious. Cons: needs a button this example does not have.

### In-place clear

Pros: no new controller instance. Cons: easy to leave heading, food, or ended stale.

## More information

- `wiki/work/0010-restart-on-death/00-research.md`
- `wiki/work/0010-restart-on-death/01-plan.md`
- `wiki/product/classic-snake-example.md`
