# Plan: Goal loop above the feature pipeline

## Goal

A user can state what must be true when the project is finished, and a later agent can plan, implement, and validate one slice at a time until those checks pass or a human gate fires. The six-phase pipeline, the blind review, and the quick route stay in place.

## Approach

The authority is a convention the index already knows how to route. The executable procedure is a skill whose name matches its directory. Agents that research, plan, implement, or document are told to read the goal and prior solutions, to write a product contract before the plan, and to treat the plan as units.

The linter grows two checks that match that shape: a full-route plan needs a unit heading, and criteria need a requirement id when a product contract is present. A self-test holds the negative fixtures in memory so the repository never contains a deliberately bad plan.

An architecture decision records why the pipeline was kept. The product goal file itself is not created here.

## Why this approach

Replacing the pipeline would drop frozen criteria and blind validation, which `wiki/conventions/validation-rubrics.md` already treats as the review. Putting the procedure only in a skill would hide it from a session that does not load `.claude/skills/`, which `.claude/rules/agent-config.md` forbids for anything the workflow needs. The research artifact compares those options.

## Product contract

Behaviour is defined in `04-product-contract.md`. The units below realise R-001 through R-007. This plan adds no user-visible behaviour that file does not state.

## Units

### U1. Publish the goal loop

Done when: `wiki/conventions/goal-loop.md` states the interview, the single slice, the call into the six-phase pipeline, the stop rules, and the three-part compound test, and `wiki/INDEX.md` links it.

Files it may touch: `wiki/conventions/goal-loop.md`, `wiki/INDEX.md`, `wiki/conventions/workflow.md`, `AGENTS.md`.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Index hop | happy path | The wiki index | Follow the goal-loop link | The convention is reached in one hop and names slice, pipeline, and stop | R-001, AE-001 |
| Missing authority | error | A procedure that exists only as a skill | Look for an index link and an AGENTS.md pointer | Both are absent, so the slice is incomplete | R-001 |

### U2. Give later slices a contract, units, and a lesson template

Done when: templates exist for the goal, the product contract, a solution, plan units, and criteria that cite a requirement. Naming and the definition of done mention the new ids and the compound record.

Files it may touch: `wiki/templates/GOAL.md`, `wiki/templates/04-product-contract.md`, `wiki/templates/solution.md`, `wiki/templates/01-plan.md`, `wiki/templates/02-criteria.md`, `wiki/templates/03-tasks.md`, `wiki/templates/STATE.yaml`, `wiki/conventions/naming.md`, `wiki/conventions/definition-of-done.md`, `wiki/conventions/validation-rubrics.md`.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Unit plan | happy path | The plan template | Read the units section | A heading of the form U1 is present, with a scenario table | R-003, AE-003 |
| Step script | error | A plan whose only structure is a Steps heading | Compare with the template | The template has no Steps heading, so that shape is no longer the contract | R-003 |

### U3. Point the skills and agents at the loop

Done when: the goal skill executes the convention, the feature skill refuses a whole-product request, research and planning read the goal and solutions, the document phase applies the compound test, and the build skill routes an end state to the goal skill.

Files it may touch: `.claude/skills/goal/SKILL.md`, `.claude/skills/feature/SKILL.md`, `.claude/skills/plan/SKILL.md`, `.claude/skills/research/SKILL.md`, `.claude/skills/document/SKILL.md`, `.claude/skills/implement/SKILL.md`, `.claude/skills/build/SKILL.md`, `.claude/skills/quick-change/SKILL.md`, `.claude/skills/bootstrap-product/SKILL.md`, `.claude/agents/researcher.md`, `.claude/agents/planner.md`, `.claude/agents/doc-keeper.md`, `.claude/agents/plan-validator.md`, `.claude/agents/implementer.md`, `.claude/rules/wiki-artifacts.md`, `.cursor/rules/wiki-artifacts.mdc`.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| End state | happy path | A request to finish the product | Read the build skill and the feature skill | Build sends it to the goal skill, and feature does not keep it as one work item | R-006, AE-006 |
| Missing goal | edge | No goal file | Read the goal skill and the convention | Both say to ask and forbid inventing the end state from the README | R-002, AE-002 |
| Grounding | happy path | A research or plan phase | Read the researcher and planner instructions | Both name the goal file and the solutions directory | R-004, AE-004 |
| Compound bar | error | A lesson the final document already states | Read the document skill | It says to skip unless all three conditions hold | R-005, AE-005 |

### U4. Make the linter enforce the new plan shape

Done when: a plan without a unit heading fails, criteria without a requirement id fail when a contract exists, and a self-test prints both rejections without writing a bad file into the wiki.

Files it may touch: `tools/lint_wiki.py`, `wiki/adr/0001-goal-loop-above-the-feature-pipeline.md`.

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| Self-test | happy path | The linter's in-memory fixtures | Run the self-test | A step-only plan is rejected and an untraced criterion is rejected | R-007, AE-007 |
| Inverted check | error | A build of the predicates that accepts a step-only plan | Run the self-test | The command exits non-zero | R-007 |

## Interfaces and shared decisions

The goal file path is `wiki/product/GOAL.md`. Solution files live in `wiki/solutions/` and use the solution template. The product contract filename is `04-product-contract.md`. Unit headings match `### U` plus a number and a period. Requirement ids match `R-` plus three digits. Success check ids match `SC-` plus three digits.

`STATE.yaml` gains `goal_check`, `compound`, and `compound_reason`. `compound` is `skipped` or `written`. A skip names the failed condition in `compound_reason`.

The convention wins when a skill disagrees with it. The goal skill says so.

Quick-route qualification is unchanged. Bootstrap uses the next unused work item number, because `0001` is this work item.

## Risks

| Risk | Likelihood | Impact | Mitigation | Trigger that means it happened |
|---|---|---|---|---|
| The goal skill and the convention drift | Medium | An agent follows the skill and violates the authority | The skill's first instruction is to read the convention and to prefer it | A rule appears in the skill and the opposite rule appears in the convention |
| Agents invent a product goal to have something to implement | Medium | The library grows toward an end state the user never stated | The convention and the skill forbid drafting the goal from the README, and this slice does not create the file | A `wiki/product/GOAL.md` appears without an interview record |
| The linter rejects an older plan shape that a future quick note might copy | Low | A work item cannot close | Only files named `01-plan.md` inside a work item are checked, and the template shows the new shape | Lint fails a plan that has a unit heading |

## Rollback

Revert the convention, the skill, the agent instructions, the templates, the linter checks, and this work item in one change. No product code depends on them. An existing goal file, if one has been written by then, stays, because deleting a wiki artifact is not how this repository retires a document.

## Out of scope

The product end state itself. A pull request. Replacing blind validation. Importing an external skill catalog. Choosing a model per phase.

## Verification approach

Run `python3 tools/lint_wiki.py` and `python3 tools/lint_wiki.py --self-test` and paste both outputs. Then read the files named in the acceptance criteria and confirm each negative case is the shape those files reject.
