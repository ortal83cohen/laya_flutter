---
id: adr-0001-goal-loop-above-the-feature-pipeline
title: "ADR 0001: Pursue a product goal as slices through the existing pipeline"
status: active
owner: unassigned
last_verified: 2026-09-27
applies_to: ["**"]
summary: A written end state is pursued one slice at a time through the six-phase pipeline, not by replacing that pipeline.
---

# ADR 0001: Pursue a product goal as slices through the existing pipeline

- Status: accepted
- Date: 2026-09-27
- Deciders: the workflow change recorded in work item 0001-goal-loop

## Context and problem statement

How should an agent carry a product from a stated end state through planning, implementation, and validation, without dropping the checks the repository already requires?

## Decision drivers

- The user must be able to state an end state once and have later sessions read it.
- Blind validation, frozen criteria, and the three human gates already catch defects a single-pass builder misses.
- A procedure that exists only as a skill is invisible to a session that does not load `.claude/skills/`.
- Ceremony has to stay cheap for a one-file change.

## Considered options

### Keep the six-phase pipeline and add an outer loop

The end state lives in `wiki/product/GOAL.md`. Each slice is a normal full-route work item. The loop stops when the checks pass or a human gate fires.

### Replace the pipeline with a single plan-then-build pass

One skill would plan and implement without a frozen contract, a blind validator, or a per-slice record.

### Store the procedure only in a skill

Faster to write. Sessions that do not load skills would not see it.

## Decision

Chosen option: keep the six-phase pipeline and add an outer loop, with the authority in `wiki/conventions/goal-loop.md` and the execution in the `goal` skill.

Plans become units with stable identifiers. Product behaviour for a slice lives in `04-product-contract.md`, and each acceptance criterion cites a requirement from that contract. Learnings are written to `wiki/solutions/` only when the compound test passes.

The quick route is unchanged.

## Consequences

Each full-route slice gains a product contract and unit headings. The linter rejects a plan that has no unit heading, and rejects criteria that do not cite a requirement when a contract is present. Agents read the goal and prior solutions before research and planning.

A session can no longer treat "build the product" as one feature work item.

## Confirmation

Compliance is verified by `python3 tools/lint_wiki.py`, which fails a full-route plan that lacks a `### U<number>.` heading, and fails `02-criteria.md` that cites no `R-NNN` when `04-product-contract.md` is present. `python3 tools/lint_wiki.py --self-test` must reject a step-only plan and an untraced criterion.

A violation is a goal procedure that is not linked from `wiki/INDEX.md`, a feature skill that accepts the whole end state as one work item, or a solution file written when the compound test failed. The first is a lint error. The second is visible in `.claude/skills/feature/SKILL.md`, which sends that request to the goal skill. The third is visible in `STATE.yaml` as `compound: written` without the three conditions, which the document phase is required to record.
