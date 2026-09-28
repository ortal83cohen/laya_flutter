---
name: research
description: Runs the research phase for a work item - decomposes a question into parallel research streams, delegates to researcher subagents, and merges their findings into 00-research.md.
when_to_use: Use to start or redo the research phase of an existing work item, or when the user asks to investigate a question before any planning. Invoked automatically by the feature pipeline.
argument-hint: "[work-item-id or question]"
arguments: [target]
allowed-tools: Read, Write, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Research phase

Target: `$target`

If `$target` names an existing work item, read its `STATE.yaml` first. If it is a bare question,
this is a standalone investigation: create the work item folder as described in
`wiki/conventions/workflow.md` before proceeding.

## Decompose

Split the question into two to four independent research questions. Never more than five. Two
questions that must be answered in a fixed order are one question — do not fan them out.

Decide up front which sources are authoritative for this topic and state them in every delegation
prompt. Leaving that to each branch produces branches that trust different things and disagree for
no real reason.

Every prompt also tells the researcher to read `wiki/product/GOAL.md` when it exists, and the
summaries of `wiki/solutions/`, before answering. A closed assumption in the goal is not reopened. A
prior solution that answers the question is cited, not re-investigated.

## Delegate

Spawn one `researcher` subagent per question, all in a single message so they run concurrently.

Each prompt states five things, and a prompt missing any of them will produce duplicated or missing
work:

1. the single question, as an outcome;
2. the output format — `wiki/templates/00-research.md`, and a fifteen-line summary back;
3. which tools and sources to prefer and which to distrust;
4. what is explicitly not this branch's job;
5. the output path it owns: `wiki/work/NNNN-slug/research/<question-slug>.md`. No two branches share
   a path.

## Merge

If the branches overlap, delegate the merge to the `synthesizer` subagent. If they do not overlap,
assemble `00-research.md` yourself.

Preserve every `[UNVERIFIED]` and `[UNRESOLVED]` marker. A marker that disappears in the merge has
been laundered into an assertion.

Where two branches contradict each other, write both positions with their sources and mark the
disagreement. Do not resolve it by picking the more confident wording.

## Gate

The phase is done when `00-research.md` exists, every factual claim carries a source or an
`[UNVERIFIED]` marker, at least two options were compared wherever the question admitted more than
one answer, and the `[UNRESOLVED]` list is explicit.

An explicit unresolved list is a successful outcome. Proceeding by inventing an answer to an
unresolved question is not.

Set `STATE.yaml` phase to `plan`. Report the answer in three sentences and name the artifact path —
do not paste the artifact into chat.
