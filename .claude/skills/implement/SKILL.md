---
name: implement
description: Runs the implement phase - freezes the acceptance criteria, then delegates task groups to implementer subagents with exclusive file ownership.
when_to_use: Use to implement a work item whose plan has passed validation, or to resume an interrupted implementation. Invoked automatically by the feature pipeline.
argument-hint: "[work-item-id]"
arguments: [item]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Implement phase

Work item: `$item`

Read `STATE.yaml`, `04-product-contract.md`, `01-plan.md`, `02-criteria.md` and `03-tasks.md`. Do not start unless the latest plan review is `PASS`, or `CONDITIONAL` with every blocker closed. Do not implement behaviour the product contract does not state.

## Freeze the criteria

Set the frozen date and author in `02-criteria.md`. From this point the criteria are the independent yardstick, and they only function as one because they existed before the code. Changing a criterion now requires a recorded new validation round, never a silent edit.

## Prepare the task breakdown

If `03-tasks.md` does not exist, write it from the plan following `wiki/templates/03-tasks.md`.

Before delegating anything, verify that no two tasks marked `[P]` own the same file. If two do, the marking is wrong, not the plan: unmark one. Parallel writes to a shared file produce merges that compile and disagree at runtime, and the disagreement surfaces far from its cause.

Confirm that the plan's interfaces section actually decided the shared choices — naming, data shapes, error handling, configuration. If one is open, stop and return it as a plan defect. Do not decide it yourself and pass it down; the parallel branches will each decide it differently and no amount of context-sharing afterwards repairs that.

## Delegate

Work groups in sequence. Within a group, spawn one `implementer` per parallel task, all in a single message. Target three concurrent, five at the very most.

Each prompt states the work item, the task group, the unit ids, the exclusive file list, and the criteria those tasks satisfy. The units say what must be true. The implementer decides how.

Before a unit is dispatched, if its scenarios already pass, mark that task closed and do not dispatch it.

For a parallel run that writes code, give each subagent an isolated worktree and merge the branches one at a time, each through the full check suite. Concurrent writers in one working directory are a reliable source of state nobody can explain.

## Watch for

Stop and report a plan defect, rather than working around it, if an implementer reports that a criterion cannot be satisfied without one of these:

- adding a mock to make a failing test pass;
- widening an assertion to accept the current output;
- skipping or marking a test pending.

These are the recorded failure modes of agent implementation, not shortcuts. When a test cannot pass honestly, the plan is wrong.

## Gate

Every task closed. Build green. The project's full check suite run, with its output pasted — "tests pass" without output is not a report.

Set `STATE.yaml` phase to `verify`, round to 0, verdict to null.
