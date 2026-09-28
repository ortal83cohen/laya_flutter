# Product contract: Improve the Snake prompt so the model prefers a safe turn toward food

## Advances

SC-003

## Actors

| ID    | Actor                                    | What they are trying to do                                                                                                 |
|-------|------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| A-001 | Person running the Classic Snake example | See the model choose a relative turn from English that names hunger, wall failure, and the board facts needed to seek food |
| A-002 | VM logic-test runner                     | Prove the exact English state, instructions, and option verdicts without opening an ONNX session                           |

## Requirements

| ID    | Requirement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|-------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| R-001 | When a living controller builds the turn question, the choice instructions shall be exactly: The snake is hungry. Choose one relative turn toward the food. A turn into a wall is a failure; do not choose it.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| R-002 | When a living controller builds the English state string and food is present, that string shall be exactly, with the live values filled in: Heading followed by the cardinal heading name and a period; Head followed by the head cell in parentheses and a period; Food followed by the food cell in parentheses and a period; Distance followed by the integer Manhattan distance from head to food and a period; Food is followed by the relative food-side phrase defined under Assumptions and a period; Left followed by the left neighbour kind and a period; Right followed by the right neighbour kind and a period; Ahead followed by the ahead neighbour kind and a period. Neighbour kinds remain only wall, body, food, or empty. Spaces and punctuation match the acceptance examples. |
| R-003 | When a living controller builds the English state string and food is absent, that string shall be exactly, with the live values filled in: Heading followed by the cardinal heading name and a period; Head followed by the head cell in parentheses and a period; Food none followed by a period; Left followed by the left neighbour kind and a period; Right followed by the right neighbour kind and a period; Ahead followed by the ahead neighbour kind and a period. That string shall omit Distance and Food is.                                                                                                                                                                                                                                                                             |
| R-004 | When a living controller builds the turn question, the choice id shall be turn, the criteria keys in order shall be left, then right, then straight, and each criteria value shall be exactly one of these short verdict sentences and no other wording: Blocked. Wall. ; Blocked. Body. ; Best. Eat the food now. ; Open. Empty cell. ; Best. Closer to the food. ; Slower. Also closer to the food. ; Best. Least far from the food. ; Worse. Farther from the food. ; Best. Same distance to the food. ; Same. Not closer to the food. Those option lines shall not mention hunger, a multi-step plan, a planner, a shield, an override, or a filter.                                                                                                                                             |
| R-005 | When a living step finishes after predict returns an accepted relative key, the controller shall apply that key under today's movement and collision rules and shall not replace a wall-bound or body-bound choice with another key after predict.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| R-006 | When the classic Snake example product note describes the prompt contract, it shall record that this wording decision changes both the turn instructions and the state string as in R-001 through R-003, keeps the closed option verdict set and relative keys in R-004, and does not add a post-predict shield.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |

## Flows

| ID    | Flow                                                                                                                                                                                                         | Covers                     |
|-------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------|
| F-001 | Living step builds the enriched English state, builds the turn question with the hunger-and-wall instructions and the closed short verdicts, then calls predict with id turn and keys left, right, straight. | R-001, R-002, R-003, R-004 |
| F-002 | Living step accepts the returned relative key and advances or ends under today's rules with no post-predict rewrite.                                                                                         | R-005                      |
| F-003 | Product note for the classic Snake example states the new prompt-contract wording decision.                                                                                                                  | R-006                      |

## Acceptance examples

| ID     | Example                                                                                                                                                                                                                                                                                                                                           | Covers              |
|--------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| AE-001 | Head at (2,1), heading east, food at (3,1), left empty, right empty, ahead food. State string is exactly: Heading east. Head (2,1). Food (3,1). Distance 1. Food is ahead. Left empty. Right empty. Ahead food. Instructions are exactly the three sentences in R-001. Criteria straight is Best. Eat the food now.                               | R-001, R-002, R-004 |
| AE-002 | Head at (4,0), heading east, food at (4,45), left wall, right empty, ahead empty. State string is exactly: Heading east. Head (4,0). Food (4,45). Distance 45. Food is right. Left wall. Right empty. Ahead empty. Criteria left is Blocked. Wall. Criteria right is Best. Closer to the food. Criteria straight is Worse. Farther from the food. | R-002, R-004        |
| AE-003 | Head at (2,1), heading east, food at (5,3). State string contains exactly Distance 5 and Food is ahead and right among the facts required by R-002.                                                                                                                                                                                               | R-002               |
| AE-004 | Head at (2,1), heading east, food absent, left empty, right empty, ahead empty. State string is exactly: Heading east. Head (2,1). Food none. Left empty. Right empty. Ahead empty.                                                                                                                                                               | R-003               |
| AE-005 | Predict returns left when left is a wall; the step ends the run under today's wall rule and does not substitute right or straight after predict.                                                                                                                                                                                                  | R-005               |
| AE-006 | The classic Snake example product note names the hunger-and-wall instructions, the Distance and Food is state facts, and the closed short verdict set with relative keys left, right, straight and id turn.                                                                                                                                       | R-006               |

## Boundaries

- This slice does not change the library tokenizer, open, or predict.
- This slice does not change option criteria keys, choice id, or the closed short verdict sentence
  set listed in R-004.
- This slice does not add hunger or a multi-step plan onto option lines, and does not use
  planner-enriched option text.
- This slice does not add a post-predict safety shield, absolute keys, opaque A/B/C keys, or
  boolean-word keys.
- This slice does not add a step timer, change restart-after-death, or change the eighty-by-eighty
  board construction.
- This slice does not move the omitted-initial-snake opening away from the board center.
- This slice does not require higher model confidence or longer survival as a success check.
- Tokenizer token counts, on-disk rl_agent_config head_max_len overrides, and why a device log
  showed head (2,0) stay out of scope.
- Host session-load proof remains outside VM flutter test (macOS integration path from the sandbox
  solution).

## Assumptions

- Orchestrator decisions close the research disagreement: both instructions and state string change;
  option verdicts stay the existing short set; no confidence or survival criterion; opening cell
  stays the board center.
- Relative food-side phrase: compare food to head in the current heading's frame. Ahead means food
  lies strictly forward; behind means strictly backward; left means strictly to the heading's left;
  right means strictly to the heading's right. When food lies on a diagonal, the phrase is the
  forward-or-back word, then the word and, then the left-or-right word, with exactly those two sides
  and no third word. Allowed phrases are only: ahead; behind; left; right; ahead and left; ahead and
  right; behind and left; behind and right. When Manhattan distance is zero, the state includes
  Distance 0 and omits the Food is clause.
- Neighbour kinds and the mapping from relative turn to next cell stay today's classification: wall,
  body, food, or empty for left, right, and ahead.
- Which short verdict sentence attaches to each relative key stays today's ranking inside the option
  verdict helper; this slice does not rewrite that ranking, only forbids changing the sentence
  literals and forbids adding hunger or plan text to them.
- The short English state remains a single String sent as the predict state; the turn question
  remains the only question on a living step.
- SC-003 still means classic mechanics plus a model-chosen relative turn each step; survival length
  is not a success check.

## Resolve before planning

(none — orchestrator decisions closed the research disagreements that would have blocked drafting
exact English)
