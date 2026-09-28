# Tasks: Evaluate and prepare Snake-specific model adaptation

## Groups

### Group 1 — Provenance and contract

| # | Task | Satisfies | Files owned | Done when |
|---|---|---|---|---|
| 1.1 | Write checkpoint/training provenance and the model-adaptation product note. | AC-001, AC-002, AC-006 | `wiki/work/0015-snake-model-adaptation/00-research.md`, `wiki/product/snake-model-adaptation.md`, `wiki/INDEX.md` | Sources, boundaries and future gates are explicit. |

### Group 2 — Evaluation artifact

| # | Task | Satisfies | Files owned | Done when |
|---|---|---|---|---|
| 2.1 | Add the standard-library evaluator and labelled train/validation fixture. | AC-003, AC-004, AC-005, AC-007 | `tool/snake_eval.py`, `tool/snake_eval_fixture.jsonl` | Valid, invalid and prediction-comparison runs produce the contract output. |
| 2.2 | Record the checked-in straight-policy baseline evidence. | AC-004 | `wiki/work/0015-snake-model-adaptation/evidence/baseline-straight.json` | Evidence matches a fresh evaluator run and is labelled non-model. |

## Test tasks

| # | Covers | Positive case | Negative case |
|---|---|---|---|
| T1 | AC-003, AC-007 | Standard-library validation accepts the fixture | Duplicate or colliding fixture is rejected |
| T2 | AC-004 | Straight baseline metrics match evidence | Output missing loop-rate limitation fails review |
| T3 | AC-005 | Base/fine-tuned prediction files share the schema | Unknown/duplicate/missing ids fail |
