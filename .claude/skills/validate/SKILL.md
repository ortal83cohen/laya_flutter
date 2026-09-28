---
name: validate
description: Runs a validation round - spawns blind adversarial validators against an artifact and its criteria, then the main agent decides what happens next.
when_to_use: Use to validate research, a plan, or an implementation for an existing work item, or when the user asks to review or check a phase before proceeding. Invoked automatically by the feature pipeline.
argument-hint: "[work-item-id] [research|plan|impl]"
arguments: [item, phase]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Validation round

Work item: `$item` — phase: `$phase`

Read `wiki/conventions/validation-rubrics.md`. It is the authority on verdicts, severities and evidence; this skill is the procedure for running a round.

## Before spawning

Read `STATE.yaml`. This phase gets at most two validation rounds: the first round, and — only if the first round's findings were fixed and are worth confirming — one optional second round over the patched artifact. If two rounds have already run for `$phase`, do not spawn a third validator; escalate to the user instead of iterating further.

## Spawn

For `$phase` of `research` or `plan`, spawn `research-validator` and `plan-validator` in a single message so they run concurrently. For `impl`, spawn one `impl-validator`.

Each prompt passes only: the artifact or diff, the acceptance criteria, and the output path for its report.

It must not pass the author's summary, reasoning, transcript, self-assessment, or any claim that a previous finding was fixed. A validator that can see the argument reviews the argument instead of the artifact, and that is precisely the failure this blindness prevents.

## Read the verdict, then decide

A validator reports findings; it does not decide what happens next. That call belongs to the main agent, using the report as evidence, not as a verdict to execute mechanically:

- `PASS` — proceed to the next phase.
- `CONDITIONAL` or `FAIL` — for each finding, decide: fix it directly by patching the artifact in place, or accept it as pre-existing or out of scope. Never close a plan-level finding by changing code — a finding against the plan gets patched in the plan, an implementation finding gets patched in the code.

Do not accept a claim that a finding was fixed without re-running the check that found it. Patch the existing artifact rather than rewriting it from scratch; a rewrite is a decision for the user to make explicitly, not a default response to a `FAIL`. If it's the second round for this phase, do not spawn a third regardless of the verdict — escalate to the user instead.

## Decide and record

For each finding, record the decision in `STATE.yaml` under `decisions`: the verdict, the action taken, and the reason.

Set `verdict`. Move any finding you chose not to fix into `blockers`, with its source report and severity, so it stays visible.

## Report

Two or three lines: the verdict, the finding count, and what you decided to do about them. Name the report path; do not paste it.
