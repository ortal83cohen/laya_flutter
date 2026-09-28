# Product contract: Goal loop above the feature pipeline

## Advances

none

## Actors

| ID    | Actor         | What they are trying to do                                                                       |
|-------|---------------|--------------------------------------------------------------------------------------------------|
| A-001 | The user      | State what finished looks like, then leave planning, implementation, and validation to the agent |
| A-002 | A later agent | Read the end state, prior lessons, and the slice record without asking the user to restate them  |

## Requirements

| ID    | Requirement                                                                                                                                                                                |
|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | When a user states a product end state, an agent shall find a written procedure that selects one slice and runs the six-phase pipeline until the success checks pass or a human gate fires |
| R-002 | When the goal file is missing or still a draft, an agent shall ask the user and shall not invent the end state                                                                             |
| R-003 | When a full-route plan is written, it shall be a set of stable units with test scenarios, and each acceptance criterion shall cite a requirement                                           |
| R-004 | When research or planning starts, the agent shall read the goal file, when it exists, and prior solution summaries                                                                         |
| R-005 | When verification has passed, a solution file shall be written only when the lesson is non-obvious, durable, and material                                                                  |
| R-006 | When a change meets the five quick-route qualifiers, it shall stay on that route; when the request is the whole end state, it shall not be one feature work item                           |
| R-007 | When the wiki linter runs, a plan with no unit heading shall fail, and criteria that cite no requirement shall fail when a product contract is present                                     |

## Flows

| ID    | Flow                                                                                                                                                                                 | Covers              |
|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| F-001 | The user states an end state, or points at an existing goal file. The agent interviews only if the file cannot yet fail a check, then picks one slice and runs the feature pipeline. | R-001, R-002, R-006 |
| F-002 | The plan phase writes a product contract, then units, then criteria that cite requirements. Research and planning read the goal and prior solutions first.                           | R-003, R-004        |
| F-003 | After verification, the document phase applies the three-part compound test and records whether a solution was written.                                                              | R-005               |
| F-004 | The linter rejects a step-only plan and an untraced criterion.                                                                                                                       | R-007               |

## Acceptance examples

| ID     | Example                                                                                                                                              | Covers |
|--------|------------------------------------------------------------------------------------------------------------------------------------------------------|--------|
| AE-001 | An agent opening the wiki index can reach the goal-loop convention in one hop, and that convention names the slice, the pipeline, and the stop rules | R-001  |
| AE-002 | The goal skill and the convention both forbid drafting the end state from the README                                                                 | R-002  |
| AE-003 | The plan template has a unit heading and test scenarios. The criteria template has a traces column. The plan template has no Steps heading           | R-003  |
| AE-004 | The researcher and planner instructions name `wiki/product/GOAL.md` and `wiki/solutions/`                                                            | R-004  |
| AE-005 | The document skill says to skip a solution unless all three conditions hold                                                                          | R-005  |
| AE-006 | The build skill sends an end-state request to the goal skill, and a five-qualifier change to quick-change                                            | R-006  |
| AE-007 | `python3 tools/lint_wiki.py --self-test` prints that a step-only plan is rejected and that criteria without an R-ID are rejected                     | R-007  |

## Boundaries

This slice does not write `wiki/product/GOAL.md`. The user has not stated the product end state.

This slice does not open a pull request, commit, or replace blind validation.

This slice does not import an external skill catalog.

## Assumptions

The six-phase pipeline remains the way a single change is built. The goal loop calls it.

No product goal file exists yet, so this work item's `goal_check` is null.

## Resolve before planning
