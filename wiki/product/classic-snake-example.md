---
id: classic-snake-example
title: Classic Snake example constraints
status: active
owner: unassigned
last_verified: 2026-09-28
applies_to: ["example/lib/**", "example/test/**"]
summary: Absolute-direction Snake example constraints, explicit local checkpoint selection, and automatic restart after death.
---

# Classic Snake example constraints

Constraints an agent will miss by skimming the example sources.

## Absolute checkpoint contract

Work item 0016 supersedes the earlier relative-turn contract. Each step sends the public Snake checkpoint's `move` choice question with exactly four keys: `up`, `down`, `left`, `right`; their descriptions are `move up`, `move down`, `move left`, `move right`. The state string starts with heading, length, and food displacement, then describes each absolute candidate as wall, body, or free/food with reachable-room and tail-reachability facts. This matches the published encoder's prompt surface, with the local controller's literal-move collision rule described below. The running example needs a prepared local ONNX bundle selected with `LAYA_SNAKE_CHECKPOINT_DIR`; it never silently substitutes the base checkpoint. See `example/README.md` for setup and the unverified export boundary.

## Model-owned choice and diagnostics

The model remains the only source of direction. The controller applies a returned absolute key literally, including a reverse move into the neck; that is a body collision, not an ignored move. There is no post-model safety shield or fallback. Recent keys, objective and Manhattan progress are logged as diagnostics, not added to the published state string.

The console record is diagnostic only. It includes the full prompt and state,
the objective to reach food while avoiding walls and body, Manhattan-distance
progress before/after/delta, the returned key, attempted cell, validation result,
and any wall/body/invalid/failure reason. A repeated-turn flag reports three
identical keys or a four-key alternating pattern; it never chooses a direction.

## Step gating and predict failure

SC-003’s negative case is a timer that moves the snake without a model result. That forbids not only a step clock but also a decorative `Ticker` and a one-shot delay after predict used for pacing: any of those makes “absence of a periodic ticker” ambiguous in review. Redraw is state after the awaited step.

When predict fails or returns a missing or non-absolute choice, the step must not invent a direction and must not advance. There is no user-visible predict-failure UI. The screen therefore stops further steps when a finished step neither ends the game nor changes snake cells; spinning on an unchanged board would look like progress while inventing none. That stop is not a death, and it must not start a new run. A valid wall/body choice is still applied and ends the current run under classic rules; the record reports the collision but does not prevent it.

## Restart after death

A wall or the snake's own body still ends the current run. The head does not enter the wall or a body cell, and a further step on that ended controller does not move cells. The screen then replaces the controller with a newly constructed one and continues the same await-gated loop. The resting title is Snake. There is no restart button and no paced delay. A VM test of this path injects predict and must not open a session.

## Board size

The example screen constructs its controller at width 40 and height 40. Classic-rules tests may pass a smaller board. Playable cells stay column and row in `[0, size)`, and a next cell outside that range is still a wall. The public model card's game result was on a 15-by-15 board, so it does not establish behavior on this example board.

## Test and open constraints

Classic-rules and await-gate logic tests inject a predict double and must not call `LayaFlutter.open` or otherwise create an ONNX session. Host session proof stays on the macOS integration path documented in the sandbox solution; Snake logic proofs are not session proofs.

The running example starts the local-bundle open path with no play button, because production entry turns autostart on. Without a configured bundle, the home reports a setup error. The tree a VM widget test pumps uses the default (autostart off) and must not open a session on mount, including a follow-up frame. Scheduling open from that pumped tree still breaks VM tests (MissingPluginException / the sandbox solution).

## Deliberate omissions

Android and iOS device launches (SC-005) and extra-platform builds (SC-006) remain later. The example is one app, not a reusable game engine. The general typed-decision API remains available; the additive local-bundle opener does not make the library Snake-specific.
