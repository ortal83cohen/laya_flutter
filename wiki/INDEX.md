---
id: index
title: Wiki index
status: active
owner: unassigned
last_verified: 2026-09-28
applies_to: ["**"]
summary: Router for the whole wiki. One line per document, stating when to read it.
---

# Wiki index

Every document in this wiki is reachable from here in one hop. If you add a document, add its line here in the same commit or the lint fails.

## Conventions — read before writing anything

| Document | Read it when |
|---|---|
| [workflow.md](conventions/workflow.md) | Starting any change. Defines the three routes, the six phases, and the gates between them. |
| [goal-loop.md](conventions/goal-loop.md) | The user has stated what finished looks like, or an agent is about to pick the next slice. |
| [naming.md](conventions/naming.md) | Creating any file or frontmatter block. Defines IDs, slugs, numbering, required fields. |
| [validation-rubrics.md](conventions/validation-rubrics.md) | Acting as a validator, or reading a validation report. Defines verdicts, severities, evidence rules. |
| [model-routing.md](conventions/model-routing.md) | Choosing which model runs a phase or a subagent. |
| [parallelism.md](conventions/parallelism.md) | Deciding whether to fan out to multiple subagents, and how to merge their output. |
| [definition-of-done.md](conventions/definition-of-done.md) | Closing a work item. The checklist that must pass before a phase or item is done. |

## Templates — copy, do not improvise

| Document | Read it when |
|---|---|
| [templates/00-research.md](templates/00-research.md) | Writing the research artifact. |
| [templates/01-plan.md](templates/01-plan.md) | Writing the plan. Prose only, no code blocks. |
| [templates/02-criteria.md](templates/02-criteria.md) | Writing acceptance criteria before implementation. |
| [templates/03-tasks.md](templates/03-tasks.md) | Breaking the plan into ordered tasks. |
| [templates/validation-report.md](templates/validation-report.md) | Producing any validation verdict. |
| [templates/STATE.yaml](templates/STATE.yaml) | Creating a new work item folder. |
| [templates/adr.md](templates/adr.md) | Recording an architecture decision. |
| [templates/GOAL.md](templates/GOAL.md) | Writing `wiki/product/GOAL.md` from the user's end state. |
| [templates/04-product-contract.md](templates/04-product-contract.md) | Writing the requirements for one slice, before the plan is finalized. |
| [templates/solution.md](templates/solution.md) | Writing a learning that passed the compound test. |

## Decisions

| Document | Read it when |
|---|---|
| [adr/0001-goal-loop-above-the-feature-pipeline.md](adr/0001-goal-loop-above-the-feature-pipeline.md) | Deciding whether a product end state replaces the six-phase pipeline or rides above it. |
| [adr/0002-onnx-runtime-for-laya-inference.md](adr/0002-onnx-runtime-for-laya-inference.md) | Choosing or changing the on-device engine for offline Laya inference. |
| [adr/0003-restart-snake-after-death.md](adr/0003-restart-snake-after-death.md) | Changing what the example does after the snake hits a wall or its own body. |

## Product

| Document | Read it when |
|---|---|
| [GOAL.md](product/GOAL.md) | Starting any slice, or checking whether the product is finished. |
| [offline-multilingual-onnx.md](product/offline-multilingual-onnx.md) | Proving host ONNX session load, touching macOS entitlements for the cache, or selecting a multilingual graph source. |
| [classic-snake-example.md](product/classic-snake-example.md) | Changing Snake prompt keys, step gating, predict-failure behaviour, restart after death, the example autostart flag, or example tests that must not open a session. |
| [snake-model-adaptation.md](product/snake-model-adaptation.md) | Evaluating the current Snake checkpoint, preparing a future fine-tune, or changing the Snake train/validation fixture and metrics. |
| [release-pipeline.md](product/release-pipeline.md) | Enabling automated pub.dev releases, configuring `RELEASE_GITHUB_TOKEN`, or understanding what each push to `main` publishes. |

## Project records

Files under `wiki/solutions/` are added here in the same change that creates them. Work items live under `wiki/work/` and are not indexed one by one.

| Document | Read it when |
|---|---|
| [solutions/2026-09-27-macos-onnx-session-sandbox.md](solutions/2026-09-27-macos-onnx-session-sandbox.md) | A macOS host ONNX session test fails with MissingPluginException or sandbox errno 1. |
