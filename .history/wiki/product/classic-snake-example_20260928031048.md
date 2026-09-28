---
id: classic-snake-example
title: Classic Snake example constraints
status: active
owner: unassigned
last_verified: 2026-09-28
applies_to: ["example/lib/**", "example/test/**"]
summary: Product constraints for the classic Snake example that a skim of the controller and screen will not explain.
---

# Classic Snake example constraints

Facts that stay true after the 0003-classic-snake slice and that an agent will miss if it only skims
the example sources.

## Why relative turn keys

The goal fixes a relative action space: left turn, right turn, or straight ahead relative to the
current heading. Community Laya Snake demos often use absolute `UP`/`DOWN`/`LEFT`/`RIGHT` keys,
sometimes with planner text and a post-model safety shield. Those patterns are deliberate rejections
here: absolute keys reopen the relative-turn rule, and a shield that overrides the model’s choice
violates the example’s job of showing offline predict. Opaque `A`/`B`/`C` keys and planner-enriched
option text stay unused for this example; they were left open in research and were not claimed as
losers of a bake-off. Boolean-word keys stay rejected because upstream documents them as unsafe for
choice questions.

The short English state string and the choice id `turn` are the slice’s fixed prompt contract.
Changing them for “better play” without a new product decision reopens SC-003’s prompt surface.
Survival length is not a success check; correct classic mechanics and a model-chosen relative turn
each step are.

## Step gating and predict failure

SC-003’s negative case is a timer that moves the snake without a model result. That forbids not only
a step clock but also a decorative `Ticker` and a one-shot delay after predict used for pacing: any
of those makes “absence of a periodic ticker” ambiguous in review. Redraw is state after the awaited
step.

When predict fails or returns a missing or non-relative choice, the step must not invent a turn and
must not advance. This slice adds no user-visible predict-failure UI. The screen therefore stops
further steps when a finished step neither ends the game nor changes snake cells; spinning on an
unchanged board would look like progress while inventing none.

## Board size

The example screen constructs its controller at width 40 and height 40. Classic-rules tests may pass
a smaller board. Playable cells stay column and row in `[0, size)`, and a next cell outside that
range is still a wall.

## Test and open constraints

Classic-rules and await-gate logic tests inject a predict double and must not call
`LayaFlutter.open` or otherwise create an ONNX session. Host session proof stays on the macOS
integration path documented in the sandbox solution; Snake logic proofs are not session proofs.

The running example starts Snake with no play button, because production entry turns autostart on.
The tree a VM widget test pumps uses the default (autostart off) and must not open a session on
mount, including a follow-up frame. Scheduling open from that pumped tree still breaks VM tests (
MissingPluginException / the sandbox solution).

## Deliberate omissions

Android and iOS device launches (SC-005) and extra-platform builds (SC-006) remain later. The
example is one app, not a reusable game engine. The library open and predict API from 0002 stays
closed for this slice.
