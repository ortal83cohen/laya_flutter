---
id: snake-model-adaptation
title: Snake model adaptation and evaluation
status: active
owner: unassigned
last_verified: 2026-09-28
applies_to: ["tool/snake_eval.py", "tool/snake_eval_fixture.jsonl", "example/**"]
summary: The example currently uses the multilingual base checkpoint; this document defines reproducible Snake evaluation and a future fine-tuning gate without adding a runtime shield.
---

# Snake model adaptation and evaluation

The example currently uses the `convaiinnovations/laya-multilingual` companion
checkpoint. The accepted runtime graph is the separate
`mariojcr/laya-onnx/multilingual/laya-multilingual.onnx` artifact. The repository
contains no Snake-specific fine-tuned checkpoint and no training script. This is
an evidence boundary, not a claim that the upstream base model can make optimal
Snake decisions.

`tool/snake_eval.py` and `tool/snake_eval_fixture.jsonl` provide a small pilot
evaluation. The fixture has 8 train and 4 validation rows with geometric teacher
labels. The evaluator measures teacher agreement, food reached, collisions,
mean Manhattan-distance progress and loop rate when trajectory rows provide a
loop flag. It also enforces a disjoint split and malformed-fixture checks.

The checked-in baseline is a deterministic straight-ahead policy, not a
measurement of the Laya checkpoint. On the 4-row validation pilot it reaches
0.75 choice agreement, 0.00 collision rate, 0.00 food-reached rate and 0.50
mean progress delta; loop rate is not measurable from one-step rows. These
numbers are local fixture evidence only.

The future experiment must export the current base model and a separately
fine-tuned Snake checkpoint on the same validation trajectories. It must record
the base revision, fixture hash, seed, question contract, calibration split and
checkpoint id. The proposed pilot gate is at least +0.10 absolute validation
agreement over base, no collision-rate increase, matching or improved food
reach, and a lower trajectory loop rate. No gate authorizes a runtime shield or
fallback: the game continues to execute the model's returned relative key.

Upstream's official [fine-tuning workflow](https://github.com/NandhaKishorM/laya)
is external infrastructure; it has not been run for this project. Until a real
run produces prediction exports, base-model and fine-tuned-model metrics remain
unmeasured.
