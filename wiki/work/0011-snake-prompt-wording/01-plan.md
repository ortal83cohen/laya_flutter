# Plan: Improve the Snake prompt so the model prefers a safe turn toward food

## Goal

On every living Snake step, the model receives turn instructions that name hunger and forbid
choosing a turn into a wall, and an English state string that still names heading, head, food, and
neighbour kinds and also states Manhattan distance to food and which relative side or sides the food
lies on, while option keys, choice id, and the closed short verdict sentences stay unchanged.

## Approach

Change only the example Snake controller's English builders that feed predict. The turn-question
builder adopts the exact three-sentence instructions from the product contract. The state-string
builder keeps today's heading name, head cell, food cell or none, and left, right, and ahead
neighbour kinds, and when food exists appends the integer Manhattan distance and the Food is
relative-side phrase defined in the contract. When food is absent, Distance and Food is are omitted.
A small helper may derive the relative side phrase from head, food, and heading; it must not invent
a path planner or multi-step plan.

Leave the option-verdict helper's sentence literals and ranking logic alone. Criteria keys stay
left, right, straight in that order. Choice id stays turn. Nothing after predict replaces a wall or
body choice. Do not touch the library tokenizer or open path. Do not move the centered opening
snake, add a timer, change restart-after-death, or change the eighty-by-eighty board.

Update the controller tests that lock state substrings, exact option strings, and banned planner or
shield wording so they assert the new instructions and state facts and still lock the closed verdict
set. Update the classic Snake example product note so the prompt contract records this wording
decision.

## Why this approach

Research disagreed on whether this slice may change only the state string or also the instructions.
The orchestrator closed that disagreement: change both instructions and state, keep the short option
verdicts, and add Manhattan distance plus relative food side to the state. Instruction-only was
rejected because it leaves unused facts the controller already computes. State-only was rejected
because it never says the snake is hungry or that a wall turn is a failure. Putting hunger or
avoid-walls onto option lines was rejected so the locked Best, Slower, Worse, Blocked, Same, and
Open sentences stay. A post-predict shield, absolute or opaque keys, a timer, board-size change,
moving the opening cell, and any confidence or survival acceptance check were rejected as reopening
closed controls or unresolved effects. See wiki/work/0011-snake-prompt-wording/00-research.md and
STATE.yaml decisions. The macOS ONNX sandbox solution does not answer this slice.

## Product contract

Units realise R-001 through R-006 in wiki/work/0011-snake-prompt-wording/04-product-contract.md.
This plan adds no behaviour that contract does not state. Exact English sentences live only in that
contract; implementers match them without inventing wording.

## Units

### U1. Hunger and wall-failure turn instructions

Done when: the turn-question builder returns choice id turn with instructions exactly equal to the
three sentences in R-001, criteria keys left, right, and straight in that order, and each criteria
value still one of the closed short verdict sentences in R-004 with no hunger or plan wording on
those lines.

Files it may touch: example Snake controller (turn-question builder and related instruction literal
only as needed for this unit).

| Scenario               | Category   | Input                                                          | Action                  | Expected outcome                                                                                      | Covers               |
|------------------------|------------|----------------------------------------------------------------|-------------------------|-------------------------------------------------------------------------------------------------------|----------------------|
| Exact instructions     | happy path | Living controller with food                                    | Build the turn question | Instructions equal the three R-001 sentences; id is turn; keys are left, right, straight              | R-001, R-004, AE-001 |
| Option lines unchanged | happy path | Head on top row heading east with food due south; left is wall | Build the turn question | left is Blocked. Wall.; right is Best. Closer to the food.; straight is Worse. Farther from the food. | R-004, AE-002        |
| No hunger on options   | edge       | Any living board                                               | Build the turn question | Joined option descriptions do not contain hungry, planner, shield, override, filter, or plan multi    | R-004                |

### U2. State string with distance and relative food side

Done when: the state-string builder emits the exact templates in R-002 when food exists and R-003
when food is absent, including Distance and Food is with the allowed side phrases when food exists
and distance is greater than zero, Distance 0 without Food is when distance is zero, and neighbour
kinds still only wall, body, food, or empty.

Files it may touch: example Snake controller (state-string builder and any small helper that derives
the relative food-side phrase from head, food, and heading).

| Scenario                  | Category   | Input                                                      | Action                 | Expected outcome                                                  | Covers        |
|---------------------------|------------|------------------------------------------------------------|------------------------|-------------------------------------------------------------------|---------------|
| Food ahead distance one   | happy path | Head (2,1) east, food (3,1), neighbours empty, empty, food | Build the state string | Exact AE-001 state string                                         | R-002, AE-001 |
| Food right with wall left | happy path | Head (4,0) east, food (4,45)                               | Build the state string | Exact AE-002 state string including Distance 45 and Food is right | R-002, AE-002 |
| Diagonal two sides        | happy path | Head (2,1) east, food (5,3)                                | Build the state string | Contains Distance 5 and Food is ahead and right                   | R-002, AE-003 |
| Food absent               | edge       | Head (2,1) east, food none, three empty neighbours         | Build the state string | Exact AE-004 state string; no Distance; no Food is                | R-003, AE-004 |
| No Toward food phrase     | edge       | Any living board with food                                 | Build the state string | String does not contain Toward food                               | R-002         |

### U3. Apply model choice without post-predict rewrite

Done when: a living step still applies the accepted relative key under today's movement and
collision rules, and nothing after predict substitutes another key when the chosen turn faces a wall
or body.

Files it may touch: example Snake controller only if a regression guard is needed; prefer proving
today's apply path unchanged via tests without altering apply logic.

| Scenario                   | Category   | Input                                        | Action   | Expected outcome                                                             | Covers        |
|----------------------------|------------|----------------------------------------------|----------|------------------------------------------------------------------------------|---------------|
| Wall choice ends run       | happy path | Predict returns left when left is wall       | One step | Run ends under today's wall rule; key is not replaced with right or straight | R-005, AE-005 |
| Valid relative still moves | happy path | Predict returns a non-colliding relative key | One step | Cells advance under today's rules                                            | R-005         |

### U4. Lock tests and product-note prompt contract

Done when: example controller tests assert the new instructions, the new state facts and exact
example strings, and the still-closed option verdict literals and keys; the classic Snake example
product note records that this wording decision changes instructions and state as in the contract
and keeps the closed option set and no-shield rule.

Files it may touch: example Snake controller tests; classic Snake example product note under
wiki/product.

| Scenario                                        | Category    | Input                                         | Action                       | Expected outcome                                                                                               | Covers                              |
|-------------------------------------------------|-------------|-----------------------------------------------|------------------------------|----------------------------------------------------------------------------------------------------------------|-------------------------------------|
| Tests lock new state and instructions           | happy path  | Fixtures matching AE-001 and AE-002           | Run controller prompt tests  | Assertions pass on exact strings; old instruction-only or state-only locks are updated                         | R-001, R-002, R-004, AE-001, AE-002 |
| Step still sends String state and turn question | integration | Injected predict capturing arguments          | One step                     | Captured state is the enriched String; questions map has only turn with relative keys                          | R-001, R-002, R-004                 |
| Product note records decision                   | happy path  | Classic Snake example product note after edit | Read prompt-contract section | Note names hunger-and-wall instructions, Distance and Food is facts, closed verdicts, relative keys, no shield | R-006, AE-006                       |
| Session-free proof                              | edge        | Controller prompt and apply tests             | Run VM tests                 | Injected predict only; no ONNX session open                                                                    | Boundaries                          |

## Interfaces and shared decisions

- Exact English: the product contract is the sole source of the instruction sentences and the state
  templates. Do not paraphrase in code comments as a second contract.
- Relative food-side derivation: from head, food, and current heading only. Forward and back are
  mutually exclusive; left and right are mutually exclusive. A diagonal yields exactly two sides
  joined by and, with the forward-or-back word first. Allowed phrases are only those listed in the
  contract assumptions. When distance is zero, emit Distance 0 and omit Food is.
- Manhattan distance: non-negative integer equal to absolute column difference plus absolute row
  difference between head and food; shown only when food exists.
- Option verdicts: do not edit the closed sentence literals; do not add hunger or plan text to them;
  planner-enriched option text stays unused.
- Closed controls: keys left, right, straight; id turn; no post-predict shield; no absolute,
  boolean, or A/B/C keys; no timer; no restart change; no board-size change; omitted initial snake
  stays board center.
- Files in scope: example Snake controller, example Snake controller tests, classic Snake example
  product note. Library tokenizer and other library sources are out of bounds.
- Goal check: SC-003. No acceptance criterion may require higher confidence or longer survival.
- Unresolved and out of scope for success checks: multilingual tokenizer token counts under the
  forty-eight-token option encode cap; on-disk rl_agent_config head_max_len or max_len overrides;
  explanation of a device log that showed head (2,0).

## Risks

| Risk                                                             | Likelihood | Impact                              | Mitigation                                                                          | Trigger that means it happened                                |
|------------------------------------------------------------------|------------|-------------------------------------|-------------------------------------------------------------------------------------|---------------------------------------------------------------|
| Implementer invents different English                            | Medium     | Tests and contract disagree         | Freeze exact sentences in the product contract and assert them in tests             | Diff ships paraphrase that fails substring or equality checks |
| Hunger or plan text leaks into option lines                      | Medium     | Reopens planner-enriched option ban | Keep option-verdict literals unchanged; ban those words in joined option text tests | Option criteria contain hungry, planner, or plan multi        |
| Post-predict rewrite creeps in                                   | Low        | Violates no-shield rule             | Do not add branches after predict that substitute keys; keep R-005 test             | Wall choice is replaced with a safer key                      |
| Scope creep into confidence or survival                          | Medium     | Unresolved effect treated as done   | Explicitly not required in criteria; no AC for confidence or survival length        | A criterion or test requires higher confidence or longer runs |
| Token cap clips longer option text if someone lengthens verdicts | Low        | Silent truncation at encode         | This slice does not lengthen option verdicts; leave tokenizer untouched             | Option sentences grow beyond today's closed set               |

## Rollback

Revert the example Snake controller builders, the related controller test locks, and the classic
Snake example product-note wording paragraph. Previous instructions, state template, and product
note return. No data migration and no one-way door. Library sources stay untouched, so rollback
stays inside the example and the product note.

## Out of scope

- Library tokenizer, open, predict, and any package library source change.
- Changing option criteria keys, choice id, or the closed short verdict sentence set.
- Hunger or multi-step plan wording on option lines; planner-enriched option text.
- Post-predict safety shield; absolute, opaque, or boolean keys.
- Step timer, restart-after-death change, board-size change, moving the opening snake.
- Any acceptance check that requires higher confidence or longer survival.
- Measuring or asserting multilingual tokenizer token counts.
- On-disk rl_agent_config head_max_len or max_len overrides.
- Explaining why a device log showed head (2,0).
- Reopening or changing the macOS ONNX session sandbox solution.

## Verification approach

Run the example Snake controller tests after updating the prompt locks. Confirm exact instruction
equality, exact state strings for the acceptance examples, closed option verdict literals, relative
keys and id turn, and the wall-choice apply path with no post-predict substitution. Confirm those
tests inject predict and open no session. Review the classic Snake example product note for the
recorded wording decision. Do not treat confidence, survival length, or tokenizer counts as pass or
fail for this slice. Format and analyze remain the repository checks on touched Dart under example
when implementation runs.
