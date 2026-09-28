---
name: bootstrap-product
description: Turns a product idea into the project's first working skeleton - picks the stack, sets up the toolchain and the check suite, wires the linter into CI, and records the founding decisions as ADRs.
when_to_use: Use once, on an empty repository, when the user describes a product idea and there is no source code or toolchain yet. Not for adding a feature to an existing codebase - use feature for that.
argument-hint: "[product idea]"
arguments: [idea]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Bootstrap a product

Idea: `$idea`

This repository ships an agent workflow and no product. This skill runs once, to give the workflow
something to work on. After it completes, every change goes through `/feature` or `/quick-change`.

## Step 1 — Settle the shape

Ask the user, in one round, using concrete options rather than open questions:

- what the product must do for its first user, stated as one observable outcome;
- who runs it and where — a person's browser, a phone, a server, a command line;
- the hard constraints: language or platform already decided, systems it must talk to, data it must
  not touch.

Do not ask about architecture. That is the research phase's job.

## Step 2 — Research the stack as a work item

Do not choose the stack from habit. Open the next unused work item number and run `/research` on the
question of which stack fits the answers from step 1, with one research stream per candidate.
Compare at least two viable candidates on: fit for the target platform, maturity of its test
tooling, how cheaply an agent can run a full check suite in it, and licence terms.

The cost of the check suite matters more than it looks. Every phase of this pipeline runs it, so a
stack whose full suite takes ten minutes taxes every future change.

## Step 3 — Plan and validate

Run `/plan` and `/validate` on that work item as normal. The criteria for this work item are about
the skeleton, not the product: a check suite that runs, a build that produces something runnable, a
linter wired in, and the wiki linter passing in CI.

Do not skip validation because this is setup. The stack decision is the single hardest choice in the
repository to reverse.

## Step 4 — Implement the skeleton

Create only what a first feature needs:

- the toolchain and its lockfile;
- one runnable entry point that does the simplest real thing;
- the test framework, with one passing test and one deliberately failing test you then fix, to prove
  the suite actually reports failure;
- a formatter and a linter, configured, with the configuration committed;
- a single documented command that runs the full check suite. Name it in `AGENTS.md` under a
  `## Checks` heading so every later phase knows what to run;
- a CI workflow running that command plus `python3 tools/lint_wiki.py`.

The deliberately failing test is not ceremony. A suite that has never reported a failure has not
been shown to be capable of reporting one.

## Step 5 — Record the decisions

Run `/document`. Add an ADR for the stack choice and for any other decision that foreclosed a viable
option, each with a real `## Confirmation` section.

Add a `## Checks` section to `AGENTS.md` naming the exact commands: full suite, single test, format,
lint. This is the highest-value line in the whole file — every subsequent phase depends on it.

Run the `goal` skill's interview so `wiki/product/GOAL.md` records the observable outcome, the
boundaries, and the success checks from step 1. Do not write a product overview. Domain constraints
belong in the goal's boundaries, not in a directory layout or a dependency list.

## Gate

The check suite runs and passes from a clean checkout. CI is green. `python3 tools/lint_wiki.py`
exits clean. `AGENTS.md` names the check commands. The bootstrap work item is `done`.
`wiki/product/GOAL.md` is `active`, or the interview stopped at `draft` because the user has not yet
named checks that can fail.

After this, use `/feature`.
