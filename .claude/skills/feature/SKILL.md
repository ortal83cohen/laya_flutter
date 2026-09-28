---
name: feature
description: Runs the full six-phase pipeline for a change - research, plan, validate, implement, verify, document - delegating each phase to its subagent and enforcing the gates between them. Use for any change that is not a single-file edit.
when_to_use: Use when the user asks to build, add, change or fix anything beyond a trivial single-file edit, or says "run the pipeline", "full workflow", or names a feature to build. For a one-file change with no interface, dependency or data-model impact, use quick-change instead.
argument-hint: "[what to build]"
arguments: [request]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, TaskCreate, TaskUpdate, AskUserQuestion
---

# Full pipeline

You are the orchestrator. You do not research, plan, implement or validate yourself — you delegate each phase and enforce its gate.

Request: `$request`

Read `wiki/conventions/workflow.md` before starting. It is the authority; this skill is the procedure for executing it.

## Step 0 — Route and set up

Decide the route. Single file, no new dependency, no interface change, no data model change, no security or privacy surface: stop and use `/quick-change` instead.

If the request is the product's end state — finish the product, pursue `wiki/product/GOAL.md`, or keep going until its checks pass — stop and use the `goal` skill. A slice that skill already chose continues here. Anything else, or any doubt, continues here.

Determine the next work item number: the highest `NNNN` under `wiki/work/` plus one, four digits, zero-padded. Numbers are never reused.

Create `wiki/work/NNNN-slug/` and `wiki/work/NNNN-slug/validation/`. Copy `wiki/templates/STATE.yaml` into the folder and fill `id`, `title`, `route`, `created`, `updated`.

Create a task list mirroring the six phases so progress is visible.

If the request is ambiguous about scope, audience or acceptance, ask before spending a research phase on the wrong question. Ask once, with concrete options.

## Step 1 — Research

Read `wiki/product/GOAL.md` when it exists, and the summaries of `wiki/solutions/`. A closed assumption in the goal is not reopened. A prior solution that answers a question is cited, not re-investigated. Record which `SC-NNN` this slice advances in `STATE.yaml` as `goal_check`, or `null` when no goal applies.

Decompose the request into independent research questions. Aim for two to four; never more than five. Each researcher prompt tells the researcher to read the goal file and `wiki/solutions/` before answering.

Spawn one `researcher` subagent per question, all in one message so they run concurrently. Each prompt must state the objective, the output format, the sources to prefer, the boundary, and the output path — `wiki/work/NNNN-slug/research/<question-slug>.md`. A prompt missing any of these produces duplicated or missing work.

If the branches overlap, merge them with the `synthesizer` subagent. If they do not, concatenate them yourself. Either way the result is `00-research.md` following `wiki/templates/00-research.md`.

Gate: the artifact exists, every claim carries a source or an `[UNVERIFIED]` marker, and the `[UNRESOLVED]` list is explicit. Do not proceed by inventing an answer to an unresolved question.

Set `STATE.yaml` phase to `plan`.

## Step 2 — Plan

Spawn exactly one `planner` subagent. Never two — the plan is where shared assumptions are decided.

It produces `04-product-contract.md` before it finalizes `01-plan.md` and `02-criteria.md`. The plan is units with stable `U` headings, not an execution script. Every criterion cites an `R-ID` from the contract. The plan does not add behaviour the contract does not state.

Gate: the contract, the plan, and the criteria exist, and `python3 tools/lint_wiki.py` passes. The linter fails a plan containing a fenced code block or no unit heading; if it does, send it back to the planner rather than editing the plan yourself.

Set `STATE.yaml` phase to `validate`.

## Step 3 — Validate research and plan

Spawn `research-validator` and `plan-validator` in one message so they run concurrently.

Give each only the artifact and the criteria. Do not pass the researcher's or planner's summaries, reasoning or self-assessment into the validator prompts. That blindness is what makes the review independent — a validator that can see the argument reviews the argument.

Read `wiki/conventions/validation-rubrics.md` for how to act on the verdicts. A validator reports; it does not decide what happens next — that call is yours. In short:

- Both `PASS`: proceed.
- `CONDITIONAL` or `FAIL`: for each finding, decide — fix it directly by patching the artifact in place, or accept it as pre-existing or out of scope. Never patch code for a plan-level finding; patch the plan.

At most two rounds per phase: the first round, and — only if the findings were worth confirming after the fix — one optional second round over the patched artifact. No third round; a repeat `FAIL` on the second round escalates to the user instead of triggering another rewrite. Record every decision and its reason in `STATE.yaml` under `decisions` — both a fix and a deliberate non-fix are decisions, and both get recorded.

Once the gate passes, set `STATE.yaml` phase to `implement`.

## Step 4 — Implement

Freeze the criteria: set the frozen date and author in `02-criteria.md`. From here, changing a criterion requires a recorded new validation round.

Have the planner's task breakdown in `03-tasks.md`, or write it yourself from the plan following `wiki/templates/03-tasks.md`. Verify before delegating that no two tasks marked `[P]` own the same file.

Work groups in sequence. Within a group, spawn one `implementer` per parallel task, in one message. Each prompt names the task group, the exclusive file list, and the criteria it satisfies. For a parallel run that writes code, prefer isolated worktrees and merge branches one at a time through the full check suite.

Gate: every task closed, build green, full check suite output pasted.

Set `STATE.yaml` phase to `verify`.

## Step 5 — Verify

Spawn one `impl-validator`. Pass it the frozen criteria and the diff — not the implementer's report, and not its claim that anything was fixed.

Gate: verdict is `PASS`, per-criterion table complete with every criterion explicitly resolved, verification output pasted, and each criterion has a negative case that actually fails.

Verdict handling is identical to Step 3: at most two rounds, and you decide what happens next. A `FAIL` naming a plan defect gets patched in the plan, not fixed with more code.

Set `STATE.yaml` phase to `document`.

## Step 6 — Document

Spawn one `doc-keeper`.

Gate: `python3 tools/lint_wiki.py` exits clean, every new wiki document has an index line, the `definition-of-done.md` checklist is fully ticked, and `STATE.yaml` records `compound: written` with a path or `compound: skipped` with the condition that failed.

Set `STATE.yaml` phase to `done`.

## Reporting

Report to the user once per phase gate, in two or three lines: the phase, the verdict, and what is next. Do not paste artifacts into chat — name the path.

At the end, report the work item path, the criteria count, the validation rounds spent, and any recorded follow-ups.

## Escalate to the user

Three situations only, each as a specific question rather than a diff to approve:

- a validation loop that is oscillating;
- a decision with legal, financial, privacy or production impact, or a change with no rollback;
- a scope change that invalidates the frozen criteria.
