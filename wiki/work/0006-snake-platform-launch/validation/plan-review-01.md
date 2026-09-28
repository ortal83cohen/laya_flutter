# Plan review — round 01

- Work item: 0006-snake-platform-launch
- Reviewed artifact: wiki/work/0006-snake-platform-launch/01-plan.md (with 02-criteria.md,
  04-product-contract.md)
- Reviewer: plan-validator
- Date: 2026-09-27

## Verdict

**FAIL**

Three blockers make the plan unsafe to implement as written: a false claim that path_provider is
already available to the example, an undecided (and under the example override currently impossible)
way to run the dual-tokenizer host parity check, and an unmentioned host-cache ONNX symlink risk on
the host-copy path the plan relies on for visual runs.

## Verification performed

Commands run by this reviewer (read-only), with output:

```text
=== path_provider in example/pubspec.yaml ===
(no matches)
=== path_provider lock entry ===
249:  path_provider:
250-    dependency: transitive
=== example deps show override ===
- laya_flutter 0.1.6 [flutter flutter_onnxruntime hf_tokenizers]
- hf_tokenizers 0.0.0
=== iOS deployment targets ===
363:				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
491:				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
543:				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
=== host cache onnx entry ===
lrwxr-xr-x@ 1 ortalcohen  staff  78 …/laya-multilingual.onnx -> …/onnx/multilingual/laya-multilingual.onnx
=== open call site ===
22:Directory resolveHostCache() {
100:      final LoadedRuntime runtime = await LayaFlutter.open(resolveHostCache());
=== Tokenizer surface used by library ===
45:    return HfTextEncoder(Tokenizer.fromFile(path));
53:    return HfTextEncoder(Tokenizer.fromBytes(data));
74:    final int? id = tok.tokenToId(token);
87:    final List<int> ids = _tokenizer.encode(
=== fenced blocks in plan ===
(none)
```

Also confirmed: `03-tasks.md` is absent (parallelism file ownership not reviewable this round);
`01-plan.md` contains no fenced code blocks; each AC cites at least one `R-ID`; U1–U5 each include
scenarios with input, action, and expected outcome.

## Per-criterion results

Plan-phase coverage map (not an implementation verdict):

| Criterion | Plan coverage                                     | Unit |
|-----------|---------------------------------------------------|------|
| AC-001    | Covered                                           | U5   |
| AC-002    | Covered                                           | U5   |
| AC-003    | Covered                                           | U1   |
| AC-004    | Covered (download half of R-004)                  | U1   |
| AC-005    | Covered                                           | U2   |
| AC-006    | Named in U3, but U3 wiring is blocked (see F-002) | U3   |
| AC-007    | Covered                                           | U4   |
| AC-008    | Covered                                           | U1   |
| AC-009    | Covered                                           | U5   |

## Findings

### F-001 — Plan claims path_provider is already available to the example

- Severity: BLOCKER
- Location: `wiki/work/0006-snake-platform-launch/01-plan.md:9`
- Criterion affected: AC-003, AC-004
- Observation: The approach states the example will resolve an app-writable directory “via the usual
  Flutter path provider pattern already available to the example.” `example/pubspec.yaml` does not
  declare `path_provider`. In `example/pubspec.lock` it is only `dependency: transitive` (via
  `flutter_onnxruntime`). The example currently opens with `resolveHostCache()` only (
  `example/lib/main.dart:22`, `example/lib/main.dart:100`).
- Why it matters: An implementer following the plan will treat a direct import as already legal. A
  transitive-only package is not a declared example dependency; the assumption as written is false.

### F-002 — Host parity check cannot compare override vs library under the example override as planned

- Severity: BLOCKER
- Location: `wiki/work/0006-snake-platform-launch/01-plan.md:52`
- Criterion affected: AC-006
- Observation: U3 requires encoding each frozen fixture state string “with the example override and
  with the library hf_tokenizers Tokenizer.” Shared decisions leave the check under “the example or
  tools area” (`01-plan.md:54`, `01-plan.md:89`) without choosing how both implementations coexist.
  Today `example/pubspec.yaml:23-25` uses `dependency_overrides` so the whole example resolution,
  including path-dep `laya_flutter`, gets `hf_tokenizers 0.0.0` from `third_party` (`dart pub deps`
  shows a single override package). Under that graph there is not a second, published
  `hf_tokenizers` Tokenizer to compare against.
- Why it matters: AC-006 and R-006 require pairwise equality against the library tokenizer. Without
  a decided harness that can load both surfaces in one run, U3 is not implementable from the plan
  text alone, and parallel implementers would invent incompatible wiring.

### F-003 — Host-copy visual-run path omits the host-cache ONNX symlink risk

- Severity: BLOCKER
- Location: `wiki/work/0006-snake-platform-launch/01-plan.md:35`
- Criterion affected: AC-001, AC-002 (via R-004 host-copy path)
- Observation: U1’s “Host copy seeds visual run” scenario and the population decision (
  `01-plan.md:87`) allow copying the four flat host-cache artifacts into the app-writable directory,
  and the risk table prefers that copy when disk is tight (`01-plan.md:97`). On this host,
  `$HOME/.cache/laya_flutter/laya-multilingual.onnx` is a symlink to
  `onnx/multilingual/laya-multilingual.onnx`, not a flat real file. The plan never states that a
  naive copy of the cache-root name can plant a broken link into the mobile sandbox. Research
  recorded the dereference need; the plan does not.
- Why it matters: A failed or incomplete host copy leaves open unable to load the graph, so
  Android/iOS Snake screenshots never become available even when cache path and tokenizer work are
  otherwise correct.

### F-004 — App-writable directory API left undecided

- Severity: IMPORTANT
- Location: `wiki/work/0006-snake-platform-launch/01-plan.md:86`
- Criterion affected: AC-003
- Observation: Shared decisions require “app-writable storage resolved in the example” but do not
  choose among path_provider surfaces (application support vs documents vs temporary) or a
  subdirectory naming convention. Research preferred application support; the plan does not adopt
  that choice.
- Why it matters: Different choices change where host-copy tooling must place files and what “under
  app-writable storage” means at review time.

### F-005 — U2 scenarios omit tokenToId, which open requires before encode

- Severity: IMPORTANT
- Location: `wiki/work/0006-snake-platform-launch/01-plan.md:45`
- Criterion affected: AC-005, R-005
- Observation: U2 scenarios cover factory construction and `encode`, and the negative case is about
  factories no longer failing on Android/iOS. Library `HfTextEncoder` calls `tokenToId` for special
  tokens during construction (`lib/src/tokenize.dart:74`) before later `encode` use. The current
  stub throws on `tokenToId` as well (
  `example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:21-23`). The plan’s “Tokenizer surface”
  prose (`01-plan.md:88`) does not appear as a scenario with input, action, and expected outcome for
  `tokenToId`.
- Why it matters: An override that only makes `encode` succeed can still leave open unable to return
  a loaded runtime, which is the product intent of R-005.

### F-006 — Parity equality does not fix encode options

- Severity: IMPORTANT
- Location: `wiki/work/0006-snake-platform-launch/01-plan.md:89`
- Criterion affected: AC-006
- Observation: Parity is defined as equal token id sequences for every frozen fixture state string,
  without stating whether both sides call `encode` with `addSpecialTokens: true` or `false`. Library
  sequence building uses `addSpecialTokens: false` in the researched path.
- Why it matters: Two honest implementations can disagree on the check solely because the flag was
  left to the implementer.

### F-007 — Host-copy half of R-004 has no acceptance criterion

- Severity: IMPORTANT
- Location: `wiki/work/0006-snake-platform-launch/02-criteria.md:15`
- Criterion affected: none (gap relative to R-004 / U1)
- Observation: R-004 and U1 include developer host-copy into the app-writable directory (
  `04-product-contract.md:23`, `01-plan.md:35`). AC-004 only checks first-run download when the
  directory is empty and the network is available.
- Why it matters: The visual-run mitigation the plan and risk table rely on is not frozen into a
  checkable criterion, so verify can pass AC-004 while the host-copy path remains unproven.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| F-001   | plan             |
| F-002   | plan             |
| F-003   | plan             |
| F-004   | plan             |
| F-005   | plan             |
| F-006   | plan             |
| F-007   | plan             |

Parallelism: `03-tasks.md` does not exist yet; no file-ownership collision check was possible this
round.
