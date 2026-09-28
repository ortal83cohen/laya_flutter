---
id: goal-loop
title: Product goal loop
status: active
owner: unassigned
last_verified: 2026-09-27
applies_to: ["**"]
summary: How an agent pursues a written product end state, one slice at a time, through the existing six-phase pipeline.
---

# Product goal loop

The six-phase pipeline in `workflow.md` builds one change. This document builds the product. The
user states what must be true when the project is finished. The agent plans, implements, and
validates until those checks pass, or until a human gate fires.

The procedure the agent executes is the `goal` skill. This document is the authority. When they
disagree, this document wins.

## What the user provides

One observable end state. Not a feature list, not an architecture, not a slogan.

The agent writes it to `wiki/product/GOAL.md` by copying `wiki/templates/GOAL.md`. The file carries
the usual frontmatter, and `wiki/INDEX.md` gains a line for it in the same change.

Required contents:

- the outcome a user can observe when the project is finished;
- who uses it and where it runs;
- boundaries: what finished does not include;
- assumptions the user already closed, so later slices do not reopen them;
- success checks, `SC-001` upward, each with a way to check it and a negative case.

A success check that cannot fail is not a check. "Works correctly" is not a check.

## When the goal is missing

If `wiki/product/GOAL.md` is absent, its status is `draft`, or its success checks are empty, the
agent asks before any slice. One round, two to four questions, concrete options where a real choice
exists:

- what a user will be able to observe when the project is finished;
- who uses it and where it runs;
- what the finished product explicitly does not do;
- which command or observable proves each claim.

The agent does not ask about architecture. The agent does not invent an answer, and does not draft
the goal from the README. A slogan gets two rounds of pushback. If it is still vague, the agent
writes the user's words, leaves the status at `draft`, and stops. No slice starts against a draft
goal.

Status becomes `active` only when every success check names an observable and a way to fail it.

## One slice

A slice is the smallest change after which one open success check passes, or becomes checkable for
the first time.

The agent reads, in this order: `wiki/product/GOAL.md`, the summaries of every file in
`wiki/solutions/`, and the code the check names. It picks one slice. It records which `SC-NNN` that
slice advances.

If the next slice has more than one plausible product reading, the agent asks one question and
stops. The next slice is an offer, not a second pipeline started in silence. If there is a single
reading, the agent records the assumption on the work item and continues.

A closed assumption in the goal is not reopened. A solution document that already answers the
question is cited, not re-investigated.

## What a slice runs

Each slice is a full-route work item under `workflow.md`. The goal skill does not grow a private
pipeline.

During the plan phase the work item gains `04-product-contract.md`, copied from
`wiki/templates/04-product-contract.md`, before the plan is finalized. The contract states actors,
requirements (`R-001` upward), flows, and acceptance examples, as behaviour a user can observe. The
plan does not add behaviour the contract does not state.

The plan is a set of units. See `workflow.md` for the unit rules. Each acceptance criterion cites
the `R-ID` it checks.

## After the slice

The document phase applies the compound test below, then the agent re-checks the goal.

- Every success check passes: stop. The goal is met.
- The slice closed a check, or made one newly checkable, and the next slice has a single product
  reading: open the next work item and continue.
- The next slice needs a product decision: stop and offer that decision as one question.
- The slice finished and the same checks are still open in the same way: stop and escalate as an
  oscillating loop. Do not open another slice to make the loop look like progress.

Human gates are the three in `workflow.md`: an oscillating validation loop, a legal, financial,
privacy, or production decision, and a scope change that invalidates frozen criteria. The goal loop
adds no others. It does not pause for plan approval or diff approval.

The loop does not commit, push, or open a pull request unless the user asked for that in the request
that started it.

## Compound test

After verification passes, write one file under `wiki/solutions/` only when all three hold:

1. Non-obvious: the reasoning is not recoverable from the final code, tests, or existing wiki.
2. Durable: it will still matter on a later slice, past this diff.
3. Material: forgetting it would cause the same investigation, or the same defect, again.

The counterfactual: if the solution file disappeared, would a later agent reading the implementation
repeat the investigation? If no, do not write it. Record `compound: skipped` in `STATE.yaml` and
name the condition that failed.

When all three hold, copy `wiki/templates/solution.md`, keep one track (bug or knowledge), add the
index line, and set `compound: written` to that path. One learning per slice. Update an existing
solution when it is the same problem, rather than adding a second file.

## What this loop does not change

Blind validation, frozen criteria, and the quick route stay as `workflow.md` defines them. A change
that meets all five quick-route qualifiers stays on `/quick-change`, even when a goal file exists. A
change that advances a success check and fails any qualifier is a slice, and uses the full route.
