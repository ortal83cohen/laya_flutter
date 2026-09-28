# Research review — round 02

- Work item: 0010-restart-on-death
- Reviewed artifact: `wiki/work/0010-restart-on-death/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-28

## Verdict

**PASS**

The death-field, constructor-default, constraint, proof-surface, and parent-decision claims that
were checked against their cited sources hold; the two round-01 blockers are closed in the patched
artifact and Unresolved being empty is consistent with those decisions.

## Verification performed

Opened and line-checked every path named under Findings, Constraints discovered, Parent decisions,
and Sources in `00-research.md`, plus the three stream files named in Provenance and
`wiki/work/0010-restart-on-death/validation/research-review-01.md` for the recurrence check only.
Confirmed controller death path, screen loop/title, constructor defaults,
GOAL/classic-snake/0003/0005 citations, test ranges, `LoadedRuntime.validationOnly` as a
session-less runtime, and the sole `wiki/solutions/` file.

```text
$ rg -n 'restart|reset' --glob '*.dart' example || true
(no matches)

$ sed -n '18p' wiki/work/0005-autostart-snake/04-product-contract.md
| R-001 | When the example process starts with production entry settings, the home shall begin opening the runtime without showing a play button, show the existing opening label while that open is in progress, and after a successful open present the Classic Snake screen. |

$ sed -n '66p' wiki/work/0010-restart-on-death/00-research.md
- Proof is a controller test that injects predict and does not open a session. A production-screen pump that opens a session is not required. The screen check that new-run runs and the loop continues uses an optional predict override on the screen: production omits it and steps call the loaded runtime's predict; the check supplies the override plus a session-less runtime and must never call that runtime's predict and never call open.

$ sed -n '73p' wiki/work/0010-restart-on-death/00-research.md
- Production launch has no play button (`wiki/work/0005-autostart-snake/04-product-contract.md` line 18). This slice also adds no restart button, because restart is automatic; that restart-button ban is a decision of this work item, not a sentence in the 0005 play-button requirement.

$ sed -n '39p' wiki/work/0010-restart-on-death/00-research.md
- Claim: The only solution file covers macOS ONNX session load and sandbox cache. A restart that reuses an already-loaded runtime does not reopen that surface. A restart that called open from a tree a VM widget test pumps would hit the MissingPluginException and sandbox constraints that solution documents.

$ sed -n '78,80p' wiki/work/0010-restart-on-death/00-research.md
## Unresolved

None. The gaps named in the stream files are closed by the parent decisions above.

$ sed -n '29p' wiki/work/0010-restart-on-death/STATE.yaml
goal_check: null

$ ls wiki/solutions/
2026-09-27-macos-onnx-session-sandbox.md

$ sed -n '30,43p' lib/src/loaded_runtime.dart
  /// Test-only runtime that validates inputs without an ONNX session.
  ///
  /// Used by VM tests that must not call [OnnxRuntime.createSession].
  @visibleForTesting
  LoadedRuntime.validationOnly({
    TextEncoder? encoder,
    List<double> temperature = const <double>[1.0, 1.0, 1.0],
    Map<String, double> temperatureByOptions = const <String, double>{},
    this.maxLen = 512,
    this.headMaxLen = 192,
  }) : _session = null,
       _encoder = encoder ?? _UnusedEncoder(),
       _temperature = temperature,
       _temperatureByOptions = temperatureByOptions;
```

Line-range spot checks (manual read, not pasted in full): `example/lib/snake_controller.dart` 56–80,
104–140, 179–218; `example/lib/snake_screen.dart` 15–39, 43–48, 58–73, 91–93;
`example/test/snake_controller_test.dart` 150–208, 396–471; `example/test/widget_test.dart` 7–86;
`example/test/snake_screen_test.dart` 13–42; `wiki/product/GOAL.md` 32, 43;
`wiki/product/classic-snake-example.md` 21–35; `wiki/work/0003-classic-snake/04-product-contract.md`
23–24, 57; `wiki/work/0005-autostart-snake/04-product-contract.md` 18, 41–43;
`wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md` 8–32; stream Unresolved lists in
`research/end-state.md`, `research/constraints.md`, and `research/tests.md` against Parent decisions
at `00-research.md` 56–66.

## Per-criterion results

Not applicable — research review, not an implementation review.

## Findings

None.

## Recurrence check

- Previous round: `wiki/work/0010-restart-on-death/validation/research-review-01.md`
- Recurring findings: none
- Oscillating: no

Round-01 F-001 (screen wiring form open while Unresolved empty) is closed at `00-research.md:66` by
naming an optional predict override plus a session-less runtime. Round-01 F-002 (restart button
attributed to 0005 R-001) is closed at `00-research.md:73` by separating the play-button citation
from this slice’s restart-button decision. Round-01 F-003 (truncated sentence) and F-004 (STATE.yaml
missing from Sources) are closed at `00-research.md:39` and `00-research.md:100`.

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| (none)  | —                |
