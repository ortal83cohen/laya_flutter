# Research review — round 01

- Work item: 0003-classic-snake
- Reviewed artifact: `wiki/work/0003-classic-snake/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-27

## Verdict

**PASS**

Cited primary sources support the relative-turn prompt answer and the await-gated step-loop answer;
options are compared; unresolved items match the open questions the body raises; nothing found that
would invalidate a plan built on this research.

## Verification performed

Opened `00-research.md`, then opened the child streams and every primary source they name. Confirmed
local line content with a small Python spot-check; fetched remote URLs consulted in the artifact.

```text
$ python3 - <<'PY'
# spot-check cited local lines contain the claimed substrings
OK: wiki/product/GOAL.md:15 contains 'next step waits for the model'
OK: wiki/product/GOAL.md:32 contains 'left turn, a right turn, or straight'
OK: wiki/product/GOAL.md:32 contains 'no step timer'
OK: wiki/product/GOAL.md:43 contains 'absence of a periodic ticker'
OK: lib/src/loaded_runtime.dart:58 contains 'String] or a [Map]'
OK: lib/src/loaded_runtime.dart:60 contains 'Future<Map<String, LayaAnswer>> predict'
OK: lib/src/answers.dart:47 contains 'Choice: label → description'
OK: lib/src/answers.dart:254 contains 'choice: keys[best]'
OK: lib/src/tokenize.dart:130 contains "e.value == null || e.value == ''"
OK: example/lib/main.dart:22 contains 'SkeletonHomePage'
OK: wiki/work/0003-classic-snake/STATE.yaml:21 contains 'not redesigned'
PY
```

Remote fetches (2026-09-27):

- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md` lines 970–973: Honest
  limits — avoid boolean-word choice labels; semantic or opaque labels; validate on checkpoint.
- `https://raw.githubusercontent.com/F0Rextasy/omp-laya-judge/main/demo/snake.py`: `DIRS` keys `UP`/
  `DOWN`/`LEFT`/`RIGHT`; choice criteria over those keys; planner descriptions and safety shield.
- `https://raw.githubusercontent.com/mizorewww/laya-mlx/main/docs/SNAKE_DEMO.md` section "What the
  AI does": distribution over UP, DOWN, LEFT, RIGHT; feature-assisted planner; safety shield.
- Flutter `Timer.periodic`, `Ticker`, `Future` (incl. `doWhile`), `WidgetTester.pump`, and pub.dev
  `FakeAsync` docs: match the step-loop claims about periodic clocks, await gating, and fake-time
  negative tests.

Spot-checks that supported the artifact (not findings): SC-003 and closed Snake rules at GOAL
15–16 / 32 / 43; predict Future and state shape; choice key at temperature-softmax argmax;
`renderOptions` key/description rendering; example still a skeleton; macOS ONNX solution does not
prescribe Snake control.

## Per-criterion results

Research review — acceptance-criteria table not applicable.

| Criterion | Result | Evidence (file:line)               | Negative case exercised |
|-----------|--------|------------------------------------|-------------------------|
| n/a       | n/a    | research artifact review, not impl | n/a                     |

## Findings

### F-001 — Source line misattributes GOAL 15–16 to `research/prompt.md`

- Severity: NIT
- Location: `wiki/work/0003-classic-snake/00-research.md:21`
- Criterion affected: none
- Observation: The finding states that both `research/prompt.md` and `research/step-loop.md` cite
  `wiki/product/GOAL.md` lines 15–16, 32, and 43. `research/step-loop.md` does cite those lines.
  `research/prompt.md` cites GOAL lines 26–27, 32, and 43, not 15–16. The product claim itself (
  relative turns, classic death/food rules, no step timer, SC-003) is still supported by GOAL at
  lines 15–16, 32, and 43 when checked directly.
- Why it matters: Bibliographic only; does not change the closed assumptions a plan would take from
  GOAL.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding       | Belongs to phase |
|---------------|------------------|
| (no blockers) | —                |
