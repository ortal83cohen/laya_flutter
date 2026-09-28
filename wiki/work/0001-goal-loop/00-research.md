# Research: Goal loop above the feature pipeline

## Question

How can a user state a product end state once, and have an agent plan, implement, and validate until
that end state is true, without discarding the six-phase pipeline?

## Answer

Keep the six-phase pipeline and put a goal loop above it. The end state lives in
`wiki/product/GOAL.md`. Each slice is a normal full-route work item with a product contract and
stable plan units. Learnings land in `wiki/solutions/` only when they would otherwise be
re-investigated. The procedure cannot live only in a skill, because a session that does not load
skills would not see it.

## Findings

### The repository has a per-change pipeline and no product end state

- Claim: A change that is not a single qualifying file goes through research, plan, validate,
  implement, verify, and document.
- Evidence: `wiki/conventions/workflow.md` defines those phases and two routes. `AGENTS.md` points
  every change at that file.
- Source: `wiki/conventions/workflow.md`, `AGENTS.md`.

### Nothing on disk states what finished means

- Claim: There is no product goal, no solutions folder, and no work item to continue.
- Evidence: `wiki/` contains conventions, templates, and an index. `README.md` describes a Flutter
  library and the workflow folders. Searches for `wiki/product` and `wiki/work` returned no files
  before this work item.
- Source: `README.md`, `wiki/INDEX.md`.

### Blind validation is already stronger than a single-pass builder

- Claim: A validator receives the artifact and the criteria, not the author's reasoning, and does
  not apply fixes.
- Evidence: `wiki/conventions/validation-rubrics.md` and `.claude/skills/validate/SKILL.md`.
- Source: those two files.

### A skill-only procedure would be invisible to part of the audience

- Claim: Nothing whose absence would break the workflow may live only under `.claude/`.
- Evidence: `.claude/rules/agent-config.md` states that rule, and `.cursor/rules/agent-config.mdc`
  mirrors it.
- Source: `.claude/rules/agent-config.md`.

### An external loop separates end state, requirements, execution guardrails, and learnings

- Claim: The compound-engineering core loop is ideate or brainstorm, then plan, then work, then
  compound, with an optional hands-off pipeline after the product shape is settled. Strategy is an
  anchor those steps read. Plans record decisions and test scenarios rather than code. Learnings are
  written only when they are non-obvious, durable, and material.
- Evidence: The published guides for the core loop, brainstorm, plan, work, compound, strategy, and
  the hands-off pipeline.
- Source: `https://github.com/EveryInc/compound-engineering-plugin/blob/main/docs/guides/README.md`
  and the linked guides `ce-brainstorm.md`, `ce-plan.md`, `ce-work.md`, `ce-compound.md`,
  `ce-strategy.md`, and `lfg.md`, consulted 2026-09-27.

## Options considered

| Option                                             | How it works                                                        | Cost                                              | Why rejected / chosen                                                     |
|----------------------------------------------------|---------------------------------------------------------------------|---------------------------------------------------|---------------------------------------------------------------------------|
| Outer loop over the existing pipeline              | A goal file, one slice at a time, each slice a full-route work item | One more artifact per slice, the product contract | Chosen. Keeps blind validation, frozen criteria, and the quick route.     |
| Replace the pipeline with one plan-then-build pass | A single skill plans and implements until the user stops it         | Loses the frozen yardstick and the blind review   | Rejected. The repository already treats those as the expensive checks.    |
| Skill only, no wiki authority                      | The procedure sits under `.claude/skills/`                          | Invisible when skills are not loaded              | Rejected. The agent-config rule forbids a workflow that lives only there. |

## Constraints discovered

- Plans stay prose. `tools/lint_wiki.py` already fails a fenced code block in `01-plan.md`.
- `AGENTS.md` must stay under 200 lines. The linter fails above that.
- Skill `name` must match the directory name. Description plus `when_to_use` is truncated at 1536
  characters.
- Path-scoped rules exist twice, under `.claude/rules/` and `.cursor/rules/`, and a name mismatch
  fails the linter.
- Documents under `wiki/` outside `work/` and `templates/` need frontmatter and an index line.
- Commits and pull requests stay with the user unless the request that started the loop asked for
  them. That is a user rule of the session, recorded here as a constraint on the loop, not as a
  repository file.

## Unresolved

- [UNRESOLVED: what a user of this Flutter library will be able to observe when the product is finished.]
  This work item must not invent that answer. The goal file stays unwritten until the user states
  it.

## Sources

- `wiki/conventions/workflow.md`, `wiki/conventions/validation-rubrics.md`, `wiki/INDEX.md`,
  `AGENTS.md`, `README.md`, `.claude/rules/agent-config.md`, `.claude/skills/feature/SKILL.md`,
  `.claude/skills/validate/SKILL.md`, `tools/lint_wiki.py`. Consulted 2026-09-27.
- Compound-engineering guides listed above. Consulted 2026-09-27.
