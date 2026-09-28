---
name: quick-change
description: The small-change route - one file, no interface, dependency or data-model impact. Produces a one-page record and runs the checks, skipping the plan and the separate validator.
when_to_use: Use for a typo, a copy change, a single-file bug fix, a version bump, or a formatting change - where the change touches one file and adds no dependency, interface change, data-model change, or security or privacy surface. Anything else uses the feature pipeline.
argument-hint: "[what to change]"
arguments: [request]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Quick change

Request: `$request`

This route exists because ceremony that does not scale down gets bypassed for everything, including
the changes that needed it. It is deliberately cheap, and deliberately narrow.

## Qualify it first

All five must hold:

1. One file changed.
2. No new dependency.
3. No change to a public interface, an exported symbol, a route, or a schema.
4. No change to a data model, a migration, or stored data.
5. No security, privacy, authentication, authorisation or payment surface touched.

If any is false, or you are unsure, stop and use `/feature`. Choosing this route for something that
does not qualify is the most expensive mistake available here, because nothing downstream will catch
it.

A request to finish the product, or to keep going until `wiki/product/GOAL.md` passes, is the `goal`
skill, even when the next edit looks small. A change that meets all five qualifiers stays on this
route even when a goal file exists.

Watch for the change that looks like one file and is not: a constant that another module reads, a
default that changes behaviour elsewhere, a version bump that moves a transitive dependency. If you
find one of these mid-change, abandon this route and open a full work item.

## Do it

Make the change. Add or adjust a test that fails without it — a change with no failing-first test is
indistinguishable from no change.

Run the project's full check suite. Paste the output.

## Record it

Create `wiki/work/NNNN-slug/RECORD.md` — a single file, no phase artifacts. Include: what changed
and why, the file touched, the five qualifying conditions with a one-line confirmation each, the
test that covers it, and the pasted check output.

Copy `wiki/templates/STATE.yaml`, set `route: quick`, `phase: done`.

If the change made a decision worth recording, add an ADR. A quick change can still foreclose an
option.

## Gate

Full check suite green with pasted output, the record exists, and `python3 tools/lint_wiki.py` exits
clean.

## Report

Three lines: what changed, the test that proves it, and the check result.
