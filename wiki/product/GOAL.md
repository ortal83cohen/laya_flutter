---
id: product-goal
title: Product goal
status: active
owner: unassigned
last_verified: 2026-09-27
applies_to: ["**"]
summary: Offline Flutter access to Laya's typed decisions, matching Python on a frozen fixture set, with a classic Snake example.
---

# Product goal

## Outcome

A Flutter app downloads a Laya checkpoint once from Hugging Face and then, with no network, asks this library for the model's typed decisions. On a frozen fixture set those decisions match a Python Laya run of the same checkpoint, state, and questions. The included example is a classic Snake game whose next step waits for the model.

## Users and where it runs

Flutter developers call the library from their own apps. Android and iOS are required. macOS, Windows, Linux, and web are part of the finished product only when one runtime covers them without a second engine.

## Boundaries

- The library does not fine-tune, train, or generate text.
- The library does not host an HTTP server and does not call a remote inference API after the checkpoint is on disk.
- Checkpoint weights are not committed and are not packed inside the pub package.
- The Snake example is one app. It is not a game engine.

## Closed assumptions

- Weights arrive by a one-time Hugging Face download. Later runs use the local copy.
- Quality bar: the choice label, the score level, and the noul side match Python Laya on a frozen fixture set. The noul side is the slot with the higher probability.
- Snake is classic: a wall or the snake's own body ends the game, food appears on a random empty cell, and the model chooses a left turn, a right turn, or straight ahead relative to the current heading. There is no step timer.
- The package code is Apache-2.0, the same licence as the Laya weights.
- Ship every platform one runtime covers. If one runtime does not cover desktop or web, Android and iOS are still required.
- Which checkpoints to load, and which offline Python features to expose, are chosen by research against what a Flutter caller needs. The stated preference is the full offline feature set when that set is appropriate on device.

## Success checks

| ID | Check | How it is checked | Negative case |
|---|---|---|---|
| SC-001 | With the checkpoint already on disk and the network unavailable, one library call returns a choice answer, a score answer, and a noul answer for a single state. | A test loads a local checkpoint, blocks network use, and asserts all three answer types are present. | The call needs a network request, throws, or omits one of the three types. |
| SC-002 | On a frozen fixture set, the library's choice label, score level, and noul side match a Python Laya run of the same checkpoint, state, and questions. | Compare the library output to the committed Python outputs for every fixture. | Any fixture disagrees. |
| SC-003 | The example Snake game places food on a random empty cell, sends the situation to the model on every step, turns from the model's choice, does not advance on a timer, and ends on a wall or on its own body. | Logic tests for spawn, collision, and the absence of a periodic ticker, plus a run of the example. | A timer moves the snake without a model result, food spawns on the body, or the snake passes through a wall. |
| SC-004 | The first successful run stores the checkpoint from Hugging Face. A later run loads that copy and does not download it again. | Two runs against the same cache directory. The second run has the network disabled. | The second run downloads again, or fails without a network despite a complete local copy. |
| SC-005 | The Snake example runs on Android and on iOS. | Build and launch the example on both. | Either platform fails to build, or the Snake screen does not appear. |
| SC-006 | Every extra platform the chosen runtime covers without a second engine runs the same example. | The runtime research names those platforms. The example is built on each named platform. | A platform that research named as covered fails to build. If research names none, this check passes by recording that fact. |
| SC-007 | A caller can invoke offline every decision feature the API research lists as in scope. | The API research names the features. A test calls each one against a local checkpoint with the network unavailable. | A listed feature has no offline call, or the call needs the network. |
