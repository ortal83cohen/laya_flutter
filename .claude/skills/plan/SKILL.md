---
name: plan
description: Runs the plan phase for a work item - delegates to the planner subagent to produce a prose-only implementation plan and frozen acceptance criteria, then enforces the lint gate.
when_to_use: Use to write or rewrite the plan for an existing work item whose research is complete. Invoked automatically by the feature pipeline, and after a validation FAIL routed to the plan phase.
argument-hint: "[work-item-id]"
arguments: [item]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Plan phase

Work item: `$item`

Read its `STATE.yaml` and `00-research.md`. If research has `[UNRESOLVED]` items that block a decision, stop and return to the research phase — planning around a gap by inventing an answer is how a defect reaches implementation.

## Delegate

Spawn exactly one `planner` subagent. Never two. The plan is where every shared assumption is decided, and two planners decide them differently.

The planner writes `04-product-contract.md` before it finalizes the plan. Requirements stay observable. The plan's units cite them. The plan does not add behaviour the contract does not state.

If this is a first-time plan, that's the whole brief. If you're returning here after a validation round found issues, pass the validation report's findings alongside the research and have the planner patch the existing plan in place — not rewrite it from scratch. A full rewrite only happens if the user explicitly asks for one.

## Gate

`04-product-contract.md`, `01-plan.md`, and `02-criteria.md` exist, and `python3 tools/lint_wiki.py` passes. The plan contains at least one `### U<number>.` heading. Every criterion cites an `R-ID`.

The linter fails a plan containing a fenced code block, a snippet or pseudo-code. If it does, send the plan back to the planner. Do not strip the code block yourself — its presence means the planner was writing an implementation, and the surrounding prose is probably relying on it.

Check before proceeding that the criteria are checkable. A criterion containing "correctly", "properly" or "as expected" checks nothing, and one with no negative case is not established by its test. Either is a reason to send the criteria back.

Check that the plan states the shared design decisions — naming, data shapes, error handling, configuration. Each one left implicit costs a validation round once implementation fans out.

Check that no unit is an execution script. A unit states what is true when it is done, which files it may touch, and test scenarios with an input, an action, and an expected outcome. A unit that prescribes code goes back to the planner.

Set `STATE.yaml` phase to `validate`, round to 0, verdict to null.
