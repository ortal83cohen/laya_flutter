# Tasks: Use a four-direction Snake checkpoint in the example

| # | Task                                                                                  | Satisfies                          | Files owned                                                                                                                                            | Done when                                                             |
|---|---------------------------------------------------------------------------------------|------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------|
| 1 | Change actual Snake state, question, movement and diagnostics to absolute directions. | AC-001, AC-002, AC-004, AC-006; U1 | `example/lib/snake_controller.dart`, `example/lib/snake_screen.dart`, `example/test/snake_controller_test.dart`, `example/test/snake_screen_test.dart` | Focused tests pass and no relative choice remains                     |
| 2 | Add explicit local ONNX bundle opening and use it from the example.                   | AC-003, AC-006, AC-007; U2         | `lib/src/library.dart`, `example/lib/main.dart`, related tests                                                                                         | Missing bundle does not fall back to base                             |
| 3 | Add and verify the full-game evaluator and setup documentation.                       | AC-005, AC-007; U3                 | `tool/**`, `wiki/product/**`, `wiki/INDEX.md`                                                                                                          | Seeds and metrics are explicit; unrun model is not reported as tested |

## Test tasks

| #  | Covers         | Positive case                             | Negative case                                                    |
|----|----------------|-------------------------------------------|------------------------------------------------------------------|
| T1 | AC-001, AC-002 | Absolute move and exact prompt            | Reverse/relative key does not masquerade as valid move           |
| T2 | AC-003, AC-006 | Local bundle selected                     | Missing bundle fails without base download                       |
| T3 | AC-004         | Raw choice logged                         | Collision cannot be silently substituted                         |
| T4 | AC-005, AC-007 | Held-out game record contains all metrics | Missing weights or decision-only rows cannot produce game claims |
