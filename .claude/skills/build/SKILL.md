---
name: build
description: Single entry point for day-to-day development on this repo - given an end state, a feature request, or a pointer to more information, decides the right route (goal, quick-change, or the full feature pipeline) and drives it end to end, so the user never has to pick a phase or a route skill themselves.
when_to_use: Use as the default for any implementation request phrased as a goal or ask - "add X", "fix Y", "make Z work", "here's a doc, build this" - including when the user only points to a ticket, doc, or prior conversation for context. Do not use when the user explicitly names a specific phase (research/plan/validate/implement/verify/document) or a specific route (quick-change/feature) themselves - honor that explicit choice instead by invoking the named skill directly.
argument-hint: "[goal, feature request, or pointer to more information]"
arguments: [request]
allowed-tools: Read, Grep, Glob, Bash, Agent, Skill, AskUserQuestion
---

# Build - auto-routed entry point

You are a dispatcher, not a pipeline. All the actual work happens inside `/goal`, `/quick-change`, or `/feature`; this skill exists only to remove the step where the user has to choose between them.

Request: `$request`

## Step 1 - Understand the request

If the request points at more information instead of stating it directly - a ticket, a doc, a design, an earlier conversation - read or fetch it before routing. Do not guess scope from a bare pointer.

If the goal is genuinely ambiguous (unclear scope, unclear acceptance, conflicting signals), ask one concrete question before routing. Do not spend a full pipeline run on the wrong question. If the request is merely small, that is not ambiguity - it is a routing signal, handled in Step 2.

## Step 2 - Decide the route

Read `wiki/conventions/workflow.md` if you have not already this session.

If the request is the product's end state — finish the product, pursue `wiki/product/GOAL.md`, keep going until its success checks pass, or define the final goal and carry it through planning, implementation, and validation — invoke the `goal` skill and stop. One named change stays in this step.

Apply the five quick-route qualifiers:

1. One file changed.
2. No new dependency.
3. No change to a public interface, exported symbol, route, or schema.
4. No change to a data model, a migration, or stored data.
5. No security, privacy, authentication, authorisation, or payment surface touched.

All five hold, with no doubt: this is the quick route. Any one false, or any doubt at all: this is the full route. Doubt always resolves to the full route - a wrong choice there is the expensive one.

## Step 3 - Dispatch

Quick route: invoke the `quick-change` skill with the request.

Full route: invoke the `feature` skill with the request.

Do not reimplement either pipeline's steps here, and do not run both. The invoked skill owns everything from here - phase artifacts, gates, validation rounds, the wiki record. Your job ends at the correct handoff.

## Step 4 - Report

Relay whatever the invoked skill reports back to the user. Add one line naming which route was taken and why, since that decision was made on the user's behalf.
