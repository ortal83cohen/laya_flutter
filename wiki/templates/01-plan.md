<!-- Copy to wiki/work/NNNN-slug/01-plan.md.

     PROSE ONLY. This file must contain zero fenced code blocks, zero snippets and zero
     pseudo-code. tools/lint_wiki.py fails the build if it finds any. Name the file, the
     function and the change in words; do not write the change out.

     Delete the guidance comments as you fill each section. -->

# Plan: <work item title>

## Goal

<!-- One paragraph. What will be true after this change that is not true now. Stated as an
     outcome a user or another system can observe, not as an activity. -->

## Approach

<!-- Two to four paragraphs describing the approach in words. Name the components, the files
     and the interfaces involved. Explain the shape of the solution, not its syntax. -->

## Why this approach

<!-- Name the alternatives considered and say why each was rejected. Reference the research
     artifact. A plan with no rejected alternatives has not chosen anything. -->

## Product contract

<!-- Behaviour is defined in 04-product-contract.md. This plan does not add behaviour that
     file does not state. Name the requirements the units realise. -->

## Units

<!-- Each unit is a heading of the form "### U1. Name", "### U2. Name", and so on.
     Existing numbers are never renumbered. A deleted unit leaves a gap. A split keeps the
     original number on the original concept and takes the next unused number for the new one.

     A unit states what is true when it is done and which files it may touch. It does not
     prescribe code or a keystroke sequence. Under each unit, list the test scenarios that
     apply. Each scenario names an input, an action, and an expected outcome. Use only the
     categories that apply: happy path, edge, error, integration. -->

### U1. <name>

Done when:

Files it may touch:

| Scenario | Category | Input | Action | Expected outcome | Covers |
|---|---|---|---|---|---|
| | happy path | | | | R-001, AE-001 |

## Interfaces and shared decisions

<!-- The decisions every unit must build against: naming, data shapes, error handling,
     configuration. Decide them here. Once implementation fans out, these cannot be
     renegotiated without a new validation round. -->

## Risks

<!-- One row per risk. A risk with no mitigation and no trigger is a wish. -->

| Risk | Likelihood | Impact | Mitigation | Trigger that means it happened |
|---|---|---|---|---|

## Rollback

<!-- How this change is undone if it turns out to be wrong. A plan with no rollback is a
     one-way door and must be escalated before implementation. -->

## Out of scope

<!-- What this work item deliberately does not do. Every item here is a defence against
     scope creep during implementation. -->

## Verification approach

<!-- In words: how the acceptance criteria in 02-criteria.md will be checked. Which commands,
     which fixtures, which negative cases. -->
