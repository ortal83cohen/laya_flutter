# Research review — round 01

- Work item: 0016-absolute-snake-checkpoint
- Reviewed artifact: `wiki/work/0016-absolute-snake-checkpoint/00-research.md`
- Reviewer: Codex (independent research validator)
- Date: 2026-09-28

## Verdict

**CONDITIONAL**

The public model card, exporter, and cited local code support the candidate and current-runtime claims, but the immutable checkpoint and Snake source revisions underlying the exact input contract could not be independently inspected in this round.

## Verification performed

- Read only `00-research.md`, frozen `02-criteria.md`, the validation rubric and template, and cited primary sources. Did not inspect the plan, transcript, or author reasoning.
- `rg -n -o '21057b19696fb3e27c4f4c644e6cb872ed866486|a2971e0cc5838cf4ff211d1fdf968db06b064434|\[UNVERIFIED\]|\[UNRESOLVED' wiki/work/0016-absolute-snake-checkpoint/00-research.md`:

  ```text
  15:21057b19696fb3e27c4f4c644e6cb872ed866486
  17:21057b19696fb3e27c4f4c644e6cb872ed866486
  21:a2971e0cc5838cf4ff211d1fdf968db06b064434
  23:a2971e0cc5838cf4ff211d1fdf968db06b064434
  33:[UNVERIFIED]
  54:[UNRESOLVED
  55:[UNRESOLVED
  56:[UNRESOLVED
  61:a2971e0cc5838cf4ff211d1fdf968db06b064434
  ```

- `rg -n -o 'AC-00[1-7]|Actual tuned-model inference' wiki/work/0016-absolute-snake-checkpoint/02-criteria.md`:

  ```text
  12:AC-001
  13:AC-002
  14:AC-003
  15:AC-004
  16:AC-005
  17:AC-006
  23:AC-007
  27:Actual tuned-model inference
  ```

- `rg -n -o 'downloadMultilingualCheckpoint|ensureLocal|mariojcr/laya-onnx|convaiinnovations/laya-multilingual|await predict' lib/src/library.dart lib/src/checkpoint_store.dart example/lib/snake_controller.dart`:

  ```text
  example/lib/snake_controller.dart:408:await predict
  lib/src/checkpoint_store.dart:20:mariojcr/laya-onnx
  lib/src/checkpoint_store.dart:26:convaiinnovations/laya-multilingual
  lib/src/checkpoint_store.dart:64:ensureLocal
  lib/src/library.dart:31:downloadMultilingualCheckpoint
  lib/src/library.dart:36:ensureLocal
  lib/src/library.dart:68:downloadMultilingualCheckpoint
  ```
- Read the public [Snake checkpoint model card](https://huggingface.co/OwaisAli10/laya-snake): it publishes the four-direction `move` question, an example state with room and tail fields, Apache-2.0 metadata, training/validation counts, and author-reported ten-game results. Read the public [Snake repository README](https://github.com/Okbatti/SnakeGame_Laya): it describes the encoder, teacher, gameplay evaluation, and optional safety mask. Read the public [ONNX exporter](https://github.com/NandhaKishorM/laya/blob/main/scripts/export_onnx.py): it accepts `--model` and `--output`, loads `Agent` on CPU, and names five inputs and two outputs.
- Retrieval of the [pinned checkpoint config](https://huggingface.co/OwaisAli10/laya-snake/resolve/21057b19696fb3e27c4f4c644e6cb872ed866486/rl_agent_config.json) and [pinned Snake source tree](https://github.com/Okbatti/SnakeGame_Laya/tree/a2971e0cc5838cf4ff211d1fdf968db06b064434) returned browser-tool access errors. A direct read-only request produced: `curl: (6) Could not resolve host: huggingface.co`. No weights or other files were downloaded.

## Findings

### F-001 — Pinned input contract remains independently unverified

- Severity: BLOCKER
- Location: `wiki/work/0016-absolute-snake-checkpoint/00-research.md:15`
- Criterion affected: AC-002, AC-003
- Observation: The pinned revision's file inventory, config contents, and absence of an ONNX graph are asserted at line 15. The exact encoder and game behavior are attributed to a pinned source revision at line 21. The current model card supports the general prompt and reported results, but neither pinned revision could be retrieved in this round; the unpinned model card and repository README do not establish the exact immutable contents. The asserted config attribution of the four move keys is likewise unconfirmed.
- Why it matters: AC-002 depends on the exact checkpoint input contract, and AC-003 depends on the actual bundle contents. The reported pins are the reproducibility boundary for those claims.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| F-001 | research |
