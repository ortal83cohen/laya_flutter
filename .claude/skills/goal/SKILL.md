---
name: goal
description: Pursues the product's written end state until its success checks pass. Use when the user defines the final goal of the project, asks to build until that goal is met, or wants planning, implementation, and validation without naming one feature.
when_to_use: Use when the user states what finished looks like, says to keep going until the product goal passes, or asks the agent to plan, implement, and validate the project as a whole. For one named change use feature. For a one-file qualifying edit use quick-change.
argument-hint: "[the end state, or empty to continue the goal on disk]"
arguments: [request]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Product goal

You carry a written end state through the existing pipeline. You do not invent a second pipeline,
and you do not implement a slice yourself. Read `wiki/conventions/goal-loop.md` before starting. It
is the authority; this skill is the procedure.

Request: `$request`

## Step 0 — The goal file

Read `wiki/product/GOAL.md` when it exists.

If it is missing, its status is `draft`, or its success checks are empty, interview before any
slice. One round, the questions in `goal-loop.md`. Do not invent an answer. Do not draft the goal
from the README. A slogan gets two rounds of pushback; if it stays vague, write the user's words,
leave status `draft`, and stop.

When the answers are specific enough that every check can fail, copy `wiki/templates/GOAL.md` to
`wiki/product/GOAL.md`, set status `active`, set `last_verified` to today, and add an index line.
Then continue.

## Step 1 — What is still open

Read the success checks. Run any check that is a command and paste the output. For a check that is
an observation, name the file or behaviour that satisfies it, or say it is still open.

If every check passes, stop. Report that the goal is met and name the goal file. Do not open a
slice.

## Step 2 — One slice

Read the summaries of `wiki/solutions/` and the code the open check names.

Pick the smallest slice after which one open check passes or becomes checkable. Record its `SC-NNN`.

If that slice has more than one plausible product reading, ask one question and stop. The next slice
stays an offer.

If it has one reading, record the assumption and continue.

A closed assumption in the goal is not reopened. A solution that already answers the question is
cited, not re-investigated.

## Step 3 — Run the slice

Follow `.claude/skills/feature/SKILL.md` for this slice. Pass it the slice, the `SC-NNN`, and the
assumption. Do not reimplement the six phases here.

The slice is done when that skill reports the work item `done`, including `compound: written` or
`compound: skipped`.

## Step 4 — Continue or stop

Re-run Step 1.

- Every check passes: stop.
- This slice closed a check, or made one newly checkable, and the next slice has a single product
  reading: go back to Step 2.
- The next slice needs a product decision: stop and ask that one question.
- This slice finished and the same checks are still open in the same way: stop and escalate as an
  oscillating loop. Do not open another slice.

Human gates are only the three in `wiki/conventions/workflow.md`. Do not pause for plan approval or
diff approval.

Do not commit, push, or open a pull request unless the user asked for that in `$request`.

## Reporting

After each slice, two or three lines: the work item path, which check moved, and whether another
slice is starting or why the loop stopped.
