# Acceptance criteria: Use a four-direction Snake checkpoint in the example

## Frozen

- Frozen at: 2026-09-28
- Frozen by: main-agent

## Criteria

| ID     | Traces       | Criterion                                                                                                                                                            | How it is checked                        | Negative case                                      |
|--------|--------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------|----------------------------------------------------|
| AC-001 | R-001        | When the model returns up, down, left or right, the example shall apply that absolute direction without substitution.                                                | Controller movement and collision tests  | A reverse move is silently ignored or replaced     |
| AC-002 | R-002        | Every prediction shall receive the public checkpoint's four option keys, descriptions and state fields.                                                              | Exact prompt and encoder fixture tests   | Relative turn key or missing room/tail field       |
| AC-003 | R-003        | A configured local ONNX bundle shall be selected without downloading the default base graph.                                                                         | Opening-path tests                       | Missing bundle silently opens base                 |
| AC-004 | R-004        | Each finished step shall report raw direction, attempted cell, progress and accepted/collision/invalid/failure classification.                                       | Record tests                             | Dangerous choice is changed or omitted from log    |
| AC-005 | R-005        | The evaluator shall report teacher agreement, food reach, collisions, loops and score for disjoint seeded games or clearly state that model results are unavailable. | Harness fixture and missing-model checks | Decision-only rows are reported as full games      |
| AC-006 | R-001, R-003 | The example shall retain one awaited prediction per step and shall present a setup error when the local Snake bundle is absent.                                      | Widget and source checks                 | Timer moves the board or base is opened implicitly |

## Non-functional criteria

| ID     | Traces       | Criterion                                                                                    | How it is checked  | Negative case                      |
|--------|--------------|----------------------------------------------------------------------------------------------|--------------------|------------------------------------|
| AC-007 | R-003, R-005 | The repository shall not contain public checkpoint weights or generated ONNX model binaries. | Git file inventory | A weight or ONNX binary is tracked |

## Explicitly not required

- Actual tuned-model inference without the user's authorization to obtain weights.
- Shipping a new inference engine or modifying the general typed decision types.

## Verdict log

| Round | Date | Verdict | Report |
|-------|------|---------|--------|
