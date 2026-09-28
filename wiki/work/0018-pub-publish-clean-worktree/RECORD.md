# Keep the pub.dev publish checkout clean

The publish workflow now restores the six checked-in Linux and Windows example registrant files
immediately before `pub publish --dry-run`, then checks that those files have no remaining Git
diff. This addresses the warning shown in the failed GitHub Actions run. The workflow narrows the
restore to those six generated files.

## File

`.github/workflows/publish.yml`

## Qualifying conditions

1. One product file changed: `.github/workflows/publish.yml`.
2. No new dependency.
3. No public interface, exported symbol, route, or schema change.
4. No data model, migration, or stored data change.
5. No security, privacy, authentication, authorisation, or payment surface changed.

## Test

The workflow's `Restore generated example registrants` step restores only the six paths listed in
the failed publish log and runs `git diff --exit-code` on the same paths. The check prevents the
dry run from proceeding if any remain modified. The local checkout initially had no changes in
those six files. A local simulated edit was restored from `HEAD`; the repository's Git metadata is
read-only in this environment, so the workflow's `git restore` command could not be exercised
locally.

## Checks

`python3 tools/lint_wiki.py` and `git diff --check` passed. Workflow shell syntax check passed.

`bash tools/check.sh` stopped during Stage 2 before format, analysis, tests, or build because the
Flutter SDK could not write its engine stamp in the protected SDK cache:

```
Preflight: flutter and dart found
lint_wiki: clean (0 warning(s)).
Stage 1 passed: wiki lint
/Users/ortalcohen/flutter/bin/internal/update_engine_version.sh: line 64: /Users/ortalcohen/flutter/bin/cache/engine.stamp: Operation not permitted
Stage 2 failed: dependencies
```

The hosted publish workflow has not been rerun, so successful publication remains unverified.
