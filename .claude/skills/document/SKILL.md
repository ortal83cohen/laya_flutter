---
name: document
description: Runs the document phase - updates product knowledge, adds ADRs, refreshes verification dates, updates the wiki index, prunes redundancy, and runs the wiki linter.
when_to_use: Use after verification passes to bring the wiki into agreement with the code. Also use when the user asks to update the docs or record a decision. Invoked automatically by the feature pipeline.
argument-hint: "[work-item-id]"
arguments: [item]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent
---

# Document phase

Work item: `$item`

Documentation lands in the same commit as the code. A follow-up commit is documentation debt, and documentation debt compounds silently — nobody notices the wiki drifting until an agent acts on a stale fact.

## Delegate

Spawn one `doc-keeper`. Pass it the work item folder and the diff that passed verification.

## What it must not write

The most counter-intuitive rule in this project, and the one most likely to be violated: do not add a prose overview of the repository. No directory layouts, no dependency lists, no architecture narratives, no restatements of an API the source already declares.

Repository overview files measurably reduce an agent's task success and raise its cost by more than a fifth. The agent reads the summary, then reads the source anyway, and the summary is stale sooner than either. Procedural knowledge that triggers when it is relevant — a skill, a path-scoped rule — is where documentation actually pays.

If the paragraph describes what the code already says, it should not exist.

## What it must write

Facts an agent cannot derive faster by reading the code, running it, or reading `git log`: domain rules and why they exist, external contracts, constraints invisible in the source, and deliberate omissions with their reasons.

An ADR for each decision that was genuinely a choice between viable options — including its `## Confirmation` section naming how compliance is verified and how a violation would be detected. An ADR without an enforcement mechanism decays into a suggestion within a quarter.

An index line in `wiki/INDEX.md` for every new document, saying when to read it. That one sentence is what an agent uses to decide whether to open the file; it matters more than the document's own introduction.

## Verification dates

`last_verified` moves only on documents whose content was actually re-read and confirmed. Refreshing the date on an unchecked document is worse than leaving it stale: it converts a known unknown into a false assurance, and the next agent has no way to tell.

## Compound

Apply the test in `wiki/conventions/goal-loop.md`. Write `wiki/solutions/` only when the lesson is non-obvious, durable, and material. All three must hold. Otherwise set `compound: skipped` in `STATE.yaml` and name the condition that failed. When they hold, copy `wiki/templates/solution.md`, keep one track, add the index line, and set `compound: written` to that path. One learning per work item. Update an existing solution when it is the same problem.

## Prune

Documentation grows by default and shrinks only deliberately. Each run of this phase removes at least one paragraph that is now redundant, superseded, or derivable from the code. If there is genuinely nothing to remove, say so explicitly rather than skipping the step quietly.

## Gate

`python3 tools/lint_wiki.py` exits clean. Every wiki document is reachable from `wiki/INDEX.md` in one hop. The checklist in `wiki/conventions/definition-of-done.md` is fully ticked. `STATE.yaml` records `compound: written` with a path, or `compound: skipped` with the condition that failed.

Set `STATE.yaml` phase to `done` and update the `updated` date.
