# Product contract: Use a four-direction Snake checkpoint in the example

## Advances

SC-003. The requested absolute-direction contract supersedes its prior relative-turn wording.

## Actors

| ID | Actor | What they are trying to do |
|---|---|---|
| A-001 | Example runner | Start the real Snake example with a prepared local Snake checkpoint |
| A-002 | Model | Choose one of four absolute directions from a compatible state and question |
| A-003 | Evaluator | Compare model play against teacher decisions on independent games |

## Requirements

| ID | Requirement |
|---|---|
| R-001 | Each living Snake step shall ask the model for exactly one of up, down, left, or right and apply that direction without substitution. |
| R-002 | The model shall receive the published checkpoint's question wording and state facts needed to interpret its four options. |
| R-003 | A runner with a prepared local checkpoint shall be able to select it for the example; missing or incompatible artifacts shall produce an explicit error instead of silently loading a different checkpoint. |
| R-004 | Every finished model attempt shall record the input, chosen direction, candidate outcome, progress, and failure or collision classification. |
| R-005 | A repeatable evaluation shall measure teacher agreement, food reached, collisions, loops and score over games disjoint by seed, without presenting fixture or publisher metrics as a local tuned-model run. |

## Flows

| ID | Flow | Covers |
|---|---|---|
| F-001 | Configure local checkpoint, open it, send an encoded board, apply returned absolute direction, then record the result. | R-001, R-002, R-003, R-004 |
| F-002 | Run separate seeded games with the public teacher and a configured checkpoint, then report per-game and aggregate metrics. | R-005 |

## Acceptance examples

| ID | Example | Covers |
|---|---|---|
| AE-001 | Head faces right; model returns up; head advances one row north and heading becomes up. | R-001 |
| AE-002 | Head faces right; model returns left into its neck; the model choice is logged and the run ends. | R-001, R-004 |
| AE-003 | No configured local Snake checkpoint exists; the example reports setup is required and does not open the base checkpoint. | R-003 |
| AE-004 | A held-out seeded game yields teacher agreement, food count, collision, loop flag and score, all associated with that game's seed. | R-005 |

## Boundaries

- No tuned weights are downloaded or committed by this work item.
- No training or claimed improvement is performed by this work item.
- No safety mask, fallback or replacement of a valid model direction is introduced.

## Assumptions

- The chosen public checkpoint is `OwaisAli10/laya-snake` at the pinned revision in research.
- The existing general typed-decision library remains available for non-Snake callers.

## Resolve before planning

None.
