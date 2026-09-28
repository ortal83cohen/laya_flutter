# Tasks: Goal loop above the feature pipeline

## Legend

- `[P]` — may run in a parallel subagent. Only mark a task `[P]` if no other `[P]` task in the same group touches any of the same files.
- Every task cites the criteria it satisfies and the unit it completes. A task satisfying no criterion does not belong here.
- Owned files are exclusive. Two tasks never list the same file.

## Groups

### Group 1 — Authority and templates

| # | Task | Satisfies | Files owned | Parallel | Done when |
|---|---|---|---|---|---|
| 1.1 | U1. Write the goal-loop convention, point the workflow and AGENTS.md at it, and index it | AC-001 | `wiki/conventions/goal-loop.md`, `wiki/conventions/workflow.md`, `wiki/INDEX.md`, `AGENTS.md` | | The index links the convention |
| 1.2 | U2. Add the goal, contract, solution, unit, and criteria templates, and the naming and done rules | AC-003 | `wiki/templates/GOAL.md`, `wiki/templates/04-product-contract.md`, `wiki/templates/solution.md`, `wiki/templates/01-plan.md`, `wiki/templates/02-criteria.md`, `wiki/templates/03-tasks.md`, `wiki/templates/STATE.yaml`, `wiki/conventions/naming.md`, `wiki/conventions/definition-of-done.md`, `wiki/conventions/validation-rubrics.md` | | The plan template has a unit heading and no Steps heading |

### Group 2 — Procedure and enforcement

| # | Task | Satisfies | Files owned | Parallel | Done when |
|---|---|---|---|---|---|
| 2.1 | U3. Add the goal skill and point feature, plan, research, document, implement, build, quick-change, bootstrap, and the agents at the loop | AC-002, AC-004, AC-005, AC-006 | `.claude/skills/goal/SKILL.md`, `.claude/skills/feature/SKILL.md`, `.claude/skills/plan/SKILL.md`, `.claude/skills/research/SKILL.md`, `.claude/skills/document/SKILL.md`, `.claude/skills/implement/SKILL.md`, `.claude/skills/build/SKILL.md`, `.claude/skills/quick-change/SKILL.md`, `.claude/skills/bootstrap-product/SKILL.md`, `.claude/agents/researcher.md`, `.claude/agents/planner.md`, `.claude/agents/doc-keeper.md`, `.claude/agents/plan-validator.md`, `.claude/agents/implementer.md`, `.claude/rules/wiki-artifacts.md`, `.cursor/rules/wiki-artifacts.mdc` | | The build skill routes an end state to the goal skill |
| 2.2 | U4. Enforce unit headings and requirement traces in the linter, and record the decision | AC-007, AC-008 | `tools/lint_wiki.py`, `wiki/adr/0001-goal-loop-above-the-feature-pipeline.md` | | The self-test rejects a step-only plan |

## Serialised files

| File | Owning task |
|---|---|
| `wiki/INDEX.md` | 1.1 |
| `AGENTS.md` | 1.1 |

## Test tasks

| # | Covers | Positive case | Negative case |
|---|---|---|---|
| 2.2 | AC-007 | Self-test accepts a unit heading and an R-001 citation | Self-test rejects a step-only plan and an untraced criterion |
| 2.2 | AC-008 | `python3 tools/lint_wiki.py` exits zero | A wiki document missing from the index fails that command |
