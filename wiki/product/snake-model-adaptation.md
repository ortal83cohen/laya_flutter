---
id: snake-model-adaptation
title: Snake model adaptation and evaluation
status: active
owner: unassigned
last_verified: 2026-09-28
applies_to: ["tool/snake_eval.py", "tool/snake_absolute_eval.py", "tool/snake_eval_fixture.jsonl", "example/**"]
summary: Separate the older relative-turn pilot from the absolute-direction public checkpoint experiment and its missing model-run evidence.
---

# Snake model adaptation and evaluation

The example now requires a local ONNX bundle exported from the chosen public
`OwaisAli10/laya-snake` checkpoint at Hub revision
`21057b19696fb3e27c4f4c644e6cb872ed866486`. It does not use the base
`convaiinnovations/laya-multilingual` companion checkpoint or download weights
on startup. The published Snake checkpoint is safetensors, not ONNX. Its tuned
weights were not available locally during work item 0016, so export, loaded
inference, and actual example gameplay remain [UNVERIFIED]. Its card's 15-by-15
results do not establish gameplay quality on the example's 40-by-40 board.

`tool/snake_eval.py` and `tool/snake_eval_fixture.jsonl` remain an older
relative-turn pilot. Its fixture has 8 train and 4 validation rows with geometric
teacher labels. It is not a tuned-checkpoint evaluation and must not be quoted
as one. The absolute-direction evaluator in `tool/snake_absolute_eval.py` is a
separate seeded-game harness: it reports teacher agreement, food reached,
collisions, loops, and score per game and in aggregate when the pinned model and
source are available. It reports an unavailable result without inventing metrics
when they are absent. Its local game applies reverse choices literally, matching
the example rather than upstream's reverse-move substitution.

The checked-in baseline is a deterministic straight-ahead policy, not a
measurement of the Laya checkpoint. On the 4-row validation pilot it reaches
0.75 choice agreement, 0.00 collision rate, 0.00 food-reached rate and 0.50
mean progress delta; loop rate is not measurable from one-step rows. These
numbers are local fixture evidence only.

The prior proposed +0.10 pilot gate was for the relative-turn experiment; it is
not a result or acceptance threshold for the new public checkpoint. A real
absolute-direction comparison must record source and model revisions, independent
game seeds, board size, export provenance, question contract, and per-game
outcomes. No gate authorizes a runtime shield or fallback: the example applies
the model's returned absolute key.

The [checkpoint card](https://huggingface.co/OwaisAli10/laya-snake),
[pinned game source](https://github.com/Okbatti/SnakeGame_Laya/tree/a2971e0cc5838cf4ff211d1fdf968db06b064434),
and [Laya exporter](https://github.com/NandhaKishorM/laya/blob/main/scripts/export_onnx.py)
are external inputs. An ONNX export and same-checkpoint Python/Flutter comparison
have not been run for this work item.
