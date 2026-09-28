#!/bin/sh
set -eu

# Offline tests for tools/occupied_pubdev_versions.py

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PARSER="$SCRIPT_DIR/occupied_pubdev_versions.py"
FIXTURES_DIR="$SCRIPT_DIR/fixtures/occupied-pubdev-versions"

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1 - $2" >&2
    return 1
}

run_parser_file() {
    python3 "$PARSER" "$1"
}

assert_zero_stdout() {
    local name="$1"
    local file="$2"
    local expected="$3"
    local output status
    output=$(run_parser_file "$file") && status=0 || status=$?
    if [ "$status" -ne 0 ]; then
        fail "$name" "expected exit 0, got $status"
        return 1
    fi
    if [ "$output" != "$expected" ]; then
        fail "$name" "expected '$expected', got '$output'"
        return 1
    fi
    pass "$name"
}

assert_nonzero_empty_stdout() {
    local name="$1"
    local file="$2"
    local output status
    output=$(run_parser_file "$file" 2>/dev/null) && status=0 || status=$?
    if [ "$status" -eq 0 ]; then
        fail "$name" "expected non-zero exit"
        return 1
    fi
    if [ -n "$output" ]; then
        fail "$name" "expected empty stdout, got '$output'"
        return 1
    fi
    pass "$name"
}

failures=0

echo "Running occupied_pubdev_versions.py tests..."

if ! assert_zero_stdout "valid-list" \
    "$FIXTURES_DIR/valid-list.json" \
    "0.1.0 0.1.1 0.1.4 0.1.5 0.1.6"; then
    failures=$((failures + 1))
fi

stdin_output=$(python3 "$PARSER" < "$FIXTURES_DIR/valid-list.json") && stdin_status=0 || stdin_status=$?
if [ "$stdin_status" -eq 0 ] && [ "$stdin_output" = "0.1.0 0.1.1 0.1.4 0.1.5 0.1.6" ]; then
    pass "valid-list-stdin"
else
    echo "FAIL: valid-list-stdin - expected list on stdin" >&2
    failures=$((failures + 1))
fi

if ! assert_zero_stdout "retracted" \
    "$FIXTURES_DIR/retracted.json" \
    "0.1.5 0.1.6"; then
    failures=$((failures + 1))
fi

retracted_removed_dir=$(mktemp -d)
trap 'rm -rf "$retracted_removed_dir"' EXIT
printf '%s\n' '{"name":"webmcp_flutter","latest":{"version":"0.1.6"},"versions":[{"version":"0.1.5"}]}' \
    > "$retracted_removed_dir/removed.json"
if ! assert_zero_stdout "retracted-removed" \
    "$retracted_removed_dir/removed.json" \
    "0.1.5"; then
    failures=$((failures + 1))
fi

if ! assert_zero_stdout "empty-versions" \
    "$FIXTURES_DIR/empty-versions.json" \
    ""; then
    failures=$((failures + 1))
fi

if ! assert_nonzero_empty_stdout "missing-versions" \
    "$FIXTURES_DIR/missing-versions.json"; then
    failures=$((failures + 1))
fi

if ! assert_nonzero_empty_stdout "invalid-json" \
    "$FIXTURES_DIR/invalid.json"; then
    failures=$((failures + 1))
fi

if ! assert_nonzero_empty_stdout "versions-object" \
    "$FIXTURES_DIR/versions-object.json"; then
    failures=$((failures + 1))
fi

if ! assert_zero_stdout "latest-not-complete" \
    "$FIXTURES_DIR/valid-list.json" \
    "0.1.0 0.1.1 0.1.4 0.1.5 0.1.6"; then
    failures=$((failures + 1))
fi

if ! assert_zero_stdout "latest-only" \
    "$FIXTURES_DIR/latest-only.json" \
    "0.1.6"; then
    failures=$((failures + 1))
fi

if ! assert_zero_stdout "mixed-prerelease" \
    "$FIXTURES_DIR/mixed-prerelease.json" \
    "0.1.0 0.1.6"; then
    failures=$((failures + 1))
fi

if grep -E 'https?://|[[:space:]]git[[:space:]]|^git[[:space:]]' "$PARSER" >/dev/null; then
    echo "FAIL: parser references a host, URL, or git command" >&2
    failures=$((failures + 1))
else
    pass "no-network-no-git"
fi

if [ "$failures" -eq 0 ]; then
    echo "All tests passed"
    exit 0
fi
echo "$failures test(s) failed" >&2
exit 1
