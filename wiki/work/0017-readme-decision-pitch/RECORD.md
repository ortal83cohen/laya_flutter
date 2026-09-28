# README leads with the offline decision model

The package README opened on the ONNX runtime, tokenizers, and file names. Readers who want a
decision in their app had to infer the product from the engine. The README now leads with the
offline decision loop: a situation, typed questions, and answers an app can act on, then what that
enables and the Snake example.

## File

`README.md`

No behavioral test applies. The change is user-facing prose. The previous README had no assertion to
fail first.

## Qualifying conditions

1. One product file changed: `README.md`.
2. No new dependency.
3. No public interface, exported symbol, route, or schema change.
4. No data model, migration, or stored data change.
5. No security, privacy, authentication, authorisation, or payment surface.

## Proof

Read `README.md`. The opening describes an offline decision model. The question table names choice,
score, and noul in plain language. The Snake section states that each step waits for a direction and
that a clock does not advance the snake.

## Checks

`bash tools/check.sh` (2026-09-28) stopped at stage 3. Wiki lint and dependency resolution passed.
Format failed on `integration_test/host_session_load_test.dart`, a file this change does not touch.
`dart format --output=none --set-exit-if-changed` reports that file as needing a line wrap.
`git diff` for that path is empty, so the unformatted lines are already in the tree.

```
Preflight: flutter and dart found
lint_wiki: clean (0 warning(s)).
Stage 1 passed: wiki lint
Resolving dependencies...
Downloading packages...
  material_color_utilities 0.13.0 (0.13.1 available)
  test_api 0.7.12 (0.7.14 available)
  vector_math 2.4.0 (2.4.3 available)
Got dependencies!
3 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Resolving dependencies in `./example`...
Downloading packages...
Got dependencies in `./example`.
Resolving dependencies...
Downloading packages...
! hf_tokenizers 0.0.0 from path third_party/hf_tokenizers (overridden)
  material_color_utilities 0.13.0 (0.13.1 available)
  test_api 0.7.12 (0.7.14 available)
  vector_math 2.4.0 (2.4.3 available)
Got dependencies!
3 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Stage 2 passed: dependencies
Changed integration_test/host_session_load_test.dart
Formatted 24 files (1 changed) in 0.08 seconds.
Stage 3 failed: format
```

Exit code 1.

A follow-up run applied `dart format` to that host test only, so stage 3 could pass, then restored
the file with `git checkout`. With format temporarily satisfied, stage 4 (analysis) passed and stage
5 failed on an existing assertion, also outside this change:

`test/offline_predict_test.dart` expects `Snake checkpoint is not configured in app_settings.dart.`
The example source says `Snake checkpoint is not configured. Set it in app_settings.dart.`

The quick-change gate is not met. Both failures are already in the tree and are not caused by
`README.md`.
