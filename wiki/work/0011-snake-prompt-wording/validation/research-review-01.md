# Research review — round 01

- Work item: 0011-snake-prompt-wording
- Reviewed artifact: `wiki/work/0011-snake-prompt-wording/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-28

## Verdict

**FAIL**

Living scored strings, caps, closed keys, and the stream disagreement are largely supported, but the artifact asserts an eighty-by-eighty production board and head cell `(40, 40)` that the living screen source it relies on does not contain.

## Verification performed

Opened the merged artifact and its three cited research streams, then opened the primary sources those streams name. Confirmed living board construction and product-note board wording with:

```text
$ python3 - <<'PY'
from pathlib import Path
import re
screen = Path('example/lib/snake_screen.dart').read_text()
m = re.search(r'return SnakeController\(\s*width:\s*(\d+),\s*height:\s*(\d+),', screen)
print('snake_screen._createController width/height:', m.groups() if m else 'NOT FOUND')
print('contains width: 80?', 'width: 80' in screen)
print('contains width: 60?', 'width: 60' in screen)
product = Path('wiki/product/classic-snake-example.md').read_text()
print('product note 80 and 80:', 'width 80 and height 80' in product)
print('centered head for 60:', 60//2, 60//2)
print('centered head for 80:', 80//2, 80//2)
PY
```

```text
snake_screen._createController width/height: ('60', '60')
contains width: 80? False
contains width: 60? True
product note 80 and 80: True
centered head for 60: 30 30
centered head for 80: 40 40
```

Also read and spot-checked against living sources:

- `example/lib/snake_controller.dart` (`buildStateString`, `buildTurnQuestion`, `step`, `_optionVerdict`, `_bestFoodTurn`, `_classify`, `_manhattan`, `_centeredOpeningSnake`)
- `example/lib/snake_screen.dart` (`_createController`, `_startNewRun`)
- `lib/src/tokenize.dart` (`renderOptions`, `buildSequence`, option `maxLength: 48`, defaults `maxLen` 512 / `headMaxLen` 192)
- `lib/src/answers.dart` (`_choiceKeys`, choice shaping)
- `lib/src/loaded_runtime.dart` (defaults and config fallbacks)
- `example/test/snake_controller_test.dart` (state / verdict locks)
- `wiki/product/GOAL.md`, `wiki/product/classic-snake-example.md`, `wiki/adr/0003-restart-snake-after-death.md`
- `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`, `wiki/INDEX.md`
- `wiki/work/0003-classic-snake/research/prompt.md` and related 0003 artifacts named by the streams
- `wiki/work/0011-snake-prompt-wording/STATE.yaml`

Character lengths of living rendered options recomputed; longest is 42 characters for `straight: Slower. Also closer to the food.` and `straight: Best. Same distance to the food.`.

## Per-criterion results

N/A — research review; no frozen acceptance criteria apply to this artifact.

## Findings

### F-001 — Production board size and opening head cell are false against living screen source

- Severity: BLOCKER
- Location: `wiki/work/0011-snake-prompt-wording/00-research.md:27`
- Criterion affected: none
- Observation: The artifact claims the example screen constructs the controller at width 80 and height 80, and later that production opens with head `(40, 40)` on that board (`00-research.md:57`, `:117`, `:130`; also Answer `:11`). The supporting stream `research/scored-text.md:75` cites `example/lib/snake_screen.dart` lines 49–70 for that construction. Those lines set `width: 60` and `height: 60`, so the centered opening head is `(30, 30)`, not `(40, 40)`. `wiki/product/classic-snake-example.md:31-33` still says width 80 and height 80, so the product note and living screen disagree; the living-screen cite does not support the 80×80 / `(40, 40)` claim.
- Why it matters: Closed-control inventory and the “do not change the eighty-by-eighty board” rejection treat an incorrect living board size as settled fact, and the opening-cell unresolved item is framed around the wrong production coordinates.

### F-002 — Cited STATE.yaml already closes the stream disagreement the Unresolved list still leaves open

- Severity: IMPORTANT
- Location: `wiki/work/0011-snake-prompt-wording/00-research.md:132`
- Criterion affected: none
- Observation: The artifact retains a DISAGREEMENT and marks unresolved whether this slice may change only the state string or also instructions / option English (`00-research.md:15`, `:91-97`, `:132-134`). It also cites `wiki/work/0011-snake-prompt-wording/STATE.yaml` for the product-decision finding (`00-research.md:81-83`). That STATE file’s `decisions[0].reason` already records that the research disagreement was closed by choosing both turn instructions and state-string facts (hunger / avoid-walls instructions; Manhattan and relative food side in state; existing short option verdicts). The artifact does not surface that cited resolution.
- Why it matters: A plan built only from the Unresolved list would treat surface scope as open after the work-item state file the research cites has already closed it.

### F-003 — “Researcher brief” is not an openable repository source

- Severity: NIT
- Location: `wiki/work/0011-snake-prompt-wording/00-research.md:82`
- Criterion affected: none
- Observation: Shared-design claims are partly sourced to a “researcher brief for `0011-snake-prompt-wording`” via `research/closed-decisions.md:23` and `:95`. No such file appears under the work item. Durable support for keys staying `left` / `right` / `straight` and for a wording product decision exists elsewhere (`classic-snake-example.md`, `STATE.yaml`), so the brief citation is unnecessary rather than inventing those controls.
- Why it matters: A later reader cannot open the named brief to re-check the claim.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| F-001 | research |
| F-002 | research |
| F-003 | research |
