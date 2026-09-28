# Acceptance criteria: Goal loop above the feature pipeline

## Frozen

- Frozen at: 2026-09-27
- Frozen by: implementing agent

## Criteria

| ID     | Traces | Criterion                                                                                                                                                                                           | How it is checked                                                                                                   | Negative case                                                       |
|--------|--------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------|
| AC-001 | R-001  | When an agent opens the wiki index, the goal-loop convention shall be one hop away and shall name the slice, the six-phase pipeline, and the stop rules                                             | Read `wiki/INDEX.md` and `wiki/conventions/goal-loop.md`                                                            | A goal procedure that is absent from the index and from `AGENTS.md` |
| AC-002 | R-002  | When the goal file is missing, the goal skill and the convention shall tell the agent to ask and shall forbid inventing the end state from the README                                               | Read `.claude/skills/goal/SKILL.md` and `wiki/conventions/goal-loop.md`                                             | A sentence that tells the agent to draft the goal from the README   |
| AC-003 | R-003  | When a full-route plan is templated, the template shall contain a stable unit heading and test scenarios, and the criteria template shall cite a requirement                                        | Read `wiki/templates/01-plan.md` and `wiki/templates/02-criteria.md`                                                | A Steps heading that is the execution contract of the plan template |
| AC-004 | R-004  | When research or planning starts, the researcher and planner instructions shall name the goal file and the solutions directory                                                                      | Read `.claude/agents/researcher.md` and `.claude/agents/planner.md`                                                 | An instruction that says to ignore the goal                         |
| AC-005 | R-005  | When verification has passed, the document skill and the doc-keeper shall write a solution only when all three compound conditions hold                                                             | Read `.claude/skills/document/SKILL.md` and `.claude/agents/doc-keeper.md`                                          | An instruction to write a solution for every work item              |
| AC-006 | R-006  | When the user states an end state, the build skill shall send it to the goal skill, and the feature skill shall not keep it as one work item; a five-qualifier change shall stay on the quick route | Read `.claude/skills/build/SKILL.md`, `.claude/skills/feature/SKILL.md`, and `.claude/skills/quick-change/SKILL.md` | A build skill whose only full route is the feature skill            |
| AC-007 | R-007  | When the wiki linter self-test runs, a plan with no unit heading shall be rejected and criteria with no requirement id shall be rejected                                                            | Run `python3 tools/lint_wiki.py --self-test` and paste the output                                                   | A self-test that exits zero while accepting a step-only plan        |

## Non-functional criteria

| ID     | Traces | Criterion                                                       | How it is checked                                     | Negative case                                                          |
|--------|--------|-----------------------------------------------------------------|-------------------------------------------------------|------------------------------------------------------------------------|
| AC-008 | R-001  | When the wiki linter runs on the repository, it shall exit zero | Run `python3 tools/lint_wiki.py` and paste the output | A new wiki document with no index line, which the linter already fails |

## Explicitly not required

A filled `wiki/product/GOAL.md`. The user has not stated the product end state.

A solution file for this work item. The lesson is the convention itself, so the compound test fails
the non-obvious condition.

A commit or a pull request.

## Verdict log

| Round | Date       | Verdict | Report                       |
|-------|------------|---------|------------------------------|
| 1     | 2026-09-27 | PASS    | validation/impl-review-01.md |
