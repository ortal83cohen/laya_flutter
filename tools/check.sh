#!/bin/sh
set -eu

REPOSITORY_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPOSITORY_ROOT"

for binary in flutter dart; do
  if ! command -v "$binary" >/dev/null 2>&1; then
    echo "Preflight failed: missing required binary: $binary" >&2
    exit 1
  fi
done
echo "Preflight: flutter and dart found"

stage_failed() {
  echo "Stage $1 failed: $2" >&2
  exit 1
}

python3 tools/lint_wiki.py || stage_failed 1 "wiki lint"
echo "Stage 1 passed: wiki lint"

flutter pub get || stage_failed 2 "dependencies"
(cd example && flutter pub get) || stage_failed 2 "dependencies"
echo "Stage 2 passed: dependencies"

dart format --output=none --set-exit-if-changed \
  lib test integration_test example/lib example/test ||
  stage_failed 3 "format"
echo "Stage 3 passed: format"

dart analyze --fatal-infos --fatal-warnings || stage_failed 4 "analysis"
(cd example && dart analyze --fatal-infos --fatal-warnings) ||
  stage_failed 4 "example analysis"
echo "Stage 4 passed: analysis"

flutter test || stage_failed 5 "tests"
(cd example && flutter test) || stage_failed 5 "example tests"
echo "Stage 5 passed: tests"

(cd example && flutter build web) || stage_failed 6 "build"
test -f example/build/web/index.html || stage_failed 6 "build"
echo "Stage 6 passed: build"

sh tools/test_bump_patch_version.sh || stage_failed 7 "version bump test"
echo "Stage 7 passed: version bump test"

sh tools/test_occupied_pubdev_versions.sh || stage_failed 8 "occupied pub.dev versions test"
echo "Stage 8 passed: occupied pub.dev versions test"
