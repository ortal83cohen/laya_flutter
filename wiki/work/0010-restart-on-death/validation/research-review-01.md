# Research review — round 01

- Work item: 0010-restart-on-death
- Reviewed artifact: `wiki/work/0010-restart-on-death/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-28

## Verdict

**FAIL**

The death-field, constructor-default, constraint, and controller-test claims that were checked against their cited sources hold, but the artifact asserts Unresolved is empty while still leaving the no-session screen-wiring proof form open, and one constraints bullet cites a source that does not support the restart-button half of the claim.

## Verification performed

Opened and line-checked every path named under Findings, Constraints discovered, and Sources in `00-research.md`, plus the three stream files named in Provenance. Confirmed controller death path, screen loop/title, constructor defaults, GOAL/classic-snake/0003/0005 citations, test ranges, and the sole `wiki/solutions/` file.

```text
$ rg -i 'restart|reset' --glob '*.dart' example || true
(no matches)

$ sed -n '18p' wiki/work/0005-autostart-snake/04-product-contract.md
| R-001 | When the example process starts with production entry settings, the home shall begin opening the runtime without showing a play button, show the existing opening label while that open is in progress, and after a successful open present the Classic Snake screen. |

$ sed -n '66p' wiki/work/0010-restart-on-death/00-research.md
- Proof is a controller test that injects predict and does not open a session. A production-screen pump is not required. The screen's use of the new-run action and the continued loop still need a check that does not open a session.

$ sed -n '73p' wiki/work/0010-restart-on-death/00-research.md
- No play or restart button (`wiki/work/0005-autostart-snake/04-product-contract.md` line 18).

$ sed -n '78,80p' wiki/work/0010-restart-on-death/00-research.md
## Unresolved

None. The gaps named in the stream files are closed by the parent decisions above.

$ ls wiki/solutions/
2026-09-27-macos-onnx-session-sandbox.md

$ sed -n '21p' wiki/work/0010-restart-on-death/STATE.yaml
goal_check: null
```

Line-range spot checks (manual read, not pasted in full): `example/lib/snake_controller.dart` 56–80, 104–140, 179–218; `example/lib/snake_screen.dart` 15–39, 43–48, 58–73, 91–93; `example/test/snake_controller_test.dart` 150–208, 396–471; `example/test/widget_test.dart` 7–86; `example/test/snake_screen_test.dart` 13–42; `wiki/product/GOAL.md` 32, 43; `wiki/product/classic-snake-example.md` 21–31; `wiki/work/0003-classic-snake/04-product-contract.md` 23–24, 57; `wiki/work/0005-autostart-snake/04-product-contract.md` 18, 41–43; `wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` 8–32.

## Per-criterion results

Not applicable — research review, not an implementation review.

## Findings

### F-001 — Screen wiring check left open while Unresolved says none

- Severity: BLOCKER
- Location: `wiki/work/0010-restart-on-death/00-research.md:66`
- Criterion affected: none
- Observation: Parent decisions require a check that the screen uses the new-run action and continues the loop, without opening a session, after rejecting a production `SnakeScreen` pump. The Unresolved section at `wiki/work/0010-restart-on-death/00-research.md:80` states `None`. Stream `research/tests.md:96` had asked whether widget-level proof is required or controller-only is sufficient; that form question is not answered and not listed as unresolved.
- Why it matters: A plan built on this research must invent how to prove screen wiring without a session, or silently drop that required check.

### F-002 — “Restart button” attributed to a play-button-only requirement

- Severity: BLOCKER
- Location: `wiki/work/0010-restart-on-death/00-research.md:73`
- Criterion affected: none
- Observation: The constraints bullet claims “No play or restart button” and cites `wiki/work/0005-autostart-snake/04-product-contract.md` line 18. That line requires production start without a play button; it does not mention a restart control after death.
- Why it matters: The plan would inherit a written ban on a restart button as if frozen by 0005 R-001, when that cited line does not say so.

### F-003 — Truncated claim about calling open from a VM-pumped tree

- Severity: NIT
- Location: `wiki/work/0010-restart-on-death/00-research.md:39`
- Criterion affected: none
- Observation: The sentence ends at “would.” without stating the consequence. The cited sandbox solution and classic-snake open constraints support the intended MissingPluginException / session-open point, but the claim as written is incomplete.
- Why it matters: Style and clarity only; the surrounding finding still points at the right sources.

### F-004 — STATE.yaml cited for SC scope but omitted from Sources

- Severity: NIT
- Location: `wiki/work/0010-restart-on-death/00-research.md:76`
- Criterion affected: none
- Observation: The constraints bullet cites `wiki/work/0010-restart-on-death/STATE.yaml` for not advancing SC-001 through SC-007. That file’s `goal_check: null` at line 21 supports “no goal check claimed”; the Sources list at lines 89–99 does not include STATE.yaml.
- Why it matters: Provenance hygiene; does not change the usable meaning of `goal_check: null` for this slice.

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
| F-004 | research |
