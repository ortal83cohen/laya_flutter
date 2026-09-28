# Plan review — round 02

- Work item: 0006-snake-platform-launch
- Reviewed artifact: wiki/work/0006-snake-platform-launch/01-plan.md (with 02-criteria.md,
  04-product-contract.md)
- Reviewer: plan-validator
- Date: 2026-09-27

## Verdict

**PASS**

Round-01 blockers and importants are closed in the current plan and criteria text; no new blocker
was found. The plan is safe to implement as written.

## Verification performed

Commands run by this reviewer (read-only), with output:

```text
=== path_provider in example/pubspec.yaml ===
(no matches)
=== path_provider lock entry ===
249:  path_provider:
250-    dependency: transitive
=== example deps override ===
20:# The published hf_tokenizers hook throws on Android and iOS (no prebuilt
23:dependency_overrides:
24:  hf_tokenizers:
25:    path: third_party/hf_tokenizers
=== library pubspec tokenizer ===
15:  hf_tokenizers: ^1.2.2
=== fenced blocks in plan ===
(none)
=== 03-tasks.md ===
ls: wiki/work/0006-snake-platform-launch/03-tasks.md: No such file or directory
=== host cache onnx ===
lrwxr-xr-x@ 1 ortalcohen  staff  78 …/laya-multilingual.onnx -> …/onnx/multilingual/laya-multilingual.onnx
=== ONNX target size ===
1290466290 …/onnx/multilingual/laya-multilingual.onnx
=== iOS deployment ===
363:				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
491:				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
543:				IPHONEOS_DEPLOYMENT_TARGET = 15.0;
=== open call site (current code, pre-implement) ===
22:Directory resolveHostCache() {
100:      final LoadedRuntime runtime = await LayaFlutter.open(resolveHostCache());
=== tokenize encode flag ===
addSpecialTokens: false (sequence-building call sites in lib/src/tokenize.dart)
tokenToId via <bos>, <eos>, <mask>, <pad> at HfTextEncoder construction
=== override stub still throws (pre-implement) ===
fromFile / tokenToId / encode → UnsupportedError
=== fixture state strings ===
parity_fixtures.json: 2 fixtures; each has string field "state"
=== AC vague wording ===
(none of correctly|properly|as expected in 02-criteria.md)
=== CheckpointStore companions ===
requiredArtifactNames: laya-multilingual.onnx, tokenizer.json,
tokenizer_config.json, rl_agent_config.json; expectedOnnxBytes = 1290466290
```

Round-01 defect closure check against current artifacts (re-read, not author claim):

| Round-01 finding                         | Status in current plan/criteria                                                                                                                                 |
|------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| F-001 path_provider “already available”  | Gone — `01-plan.md:9`, `01-plan.md:87` require a direct example `path_provider` dependency (code still transitive-only; plan no longer claims otherwise)        |
| F-002 host parity under example override | Gone — `01-plan.md:11`, `01-plan.md:53-55`, `01-plan.md:90`, AC-006: package test tree, outside example override; both tokenizers with `addSpecialTokens` false |
| F-003 host-copy ONNX symlink             | Gone — `01-plan.md:9`, `01-plan.md:35`, `01-plan.md:88`; AC-010 requires regular file of 1290466290 bytes                                                       |
| F-004 app-writable API undecided         | Gone — application support + child `laya_flutter` (`01-plan.md:9`, `01-plan.md:87`)                                                                             |
| F-005 missing tokenToId scenario         | Gone — U2 scenario `01-plan.md:47`; AC-005                                                                                                                      |
| F-006 addSpecialTokens undecided         | Gone — false in approach, U2, U3, shared decisions, AC-005, AC-006                                                                                              |
| F-007 host-copy without criterion        | Gone — AC-010 traces R-004                                                                                                                                      |

Also confirmed: `01-plan.md` has no fenced code blocks; each AC cites at least one `R-ID` and has a
negative case; U1–U5 each include scenarios with input, action, and expected outcome; plan behaviour
stays inside `04-product-contract.md` R-001–R-009; risks have mitigation and trigger; rollback is
present; `03-tasks.md` is absent so parallelism file-ownership was not reviewable.

## Per-criterion results

Plan-phase coverage map (not an implementation verdict):

| Criterion | Plan coverage | Unit |
|-----------|---------------|------|
| AC-001    | Covered       | U5   |
| AC-002    | Covered       | U5   |
| AC-003    | Covered       | U1   |
| AC-004    | Covered       | U1   |
| AC-005    | Covered       | U2   |
| AC-006    | Covered       | U3   |
| AC-007    | Covered       | U4   |
| AC-008    | Covered       | U1   |
| AC-009    | Covered       | U5   |
| AC-010    | Covered       | U1   |

## Findings

None.

## Recurrence check

- Previous round: wiki/work/0006-snake-platform-launch/validation/plan-review-01.md
- Recurring findings: none — each round-01 defect above is addressed in the current plan or criteria
  text with a different decision or criterion
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---------|------------------|
| (none)  | —                |

Parallelism: `03-tasks.md` does not exist yet; no file-ownership collision check was possible this
round.
