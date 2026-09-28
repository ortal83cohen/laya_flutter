#!/bin/sh
set -eu

# Helper script to bump patch version in pubspec.yaml and update CHANGELOG.md
# Usage: ./bump_patch_version.sh [repository_root]
# Environment:
#   RELEASE_DATE (optional) - date to use for changelog entry
#   OCCUPIED_VERSIONS (optional) - whitespace-separated three-component versions to skip

# Determine repository root
if [ $# -gt 0 ]; then
    REPO_ROOT="$1"
else
    SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
    REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
fi

# Validate repository root exists
if [ ! -d "$REPO_ROOT" ]; then
    echo "Error: Repository root directory does not exist: $REPO_ROOT" >&2
    exit 1
fi

PUBSPEC_PATH="$REPO_ROOT/pubspec.yaml"
CHANGELOG_PATH="$REPO_ROOT/CHANGELOG.md"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC_PATH" ]; then
    echo "Error: pubspec.yaml not found at: $PUBSPEC_PATH" >&2
    exit 1
fi

# Check if CHANGELOG.md exists
if [ ! -f "$CHANGELOG_PATH" ]; then
    echo "Error: CHANGELOG.md not found at: $CHANGELOG_PATH" >&2
    exit 1
fi

# Read current version from pubspec.yaml
VERSION_LINE=$(grep "^version:" "$PUBSPEC_PATH" || true)
if [ -z "$VERSION_LINE" ]; then
    echo "Error: No top-level version key found in pubspec.yaml" >&2
    exit 1
fi

CURRENT_VERSION=$(echo "$VERSION_LINE" | sed 's/^version: *//;s/ *$//')

# Validate version format (exactly three dot-separated numeric components)
if ! echo "$CURRENT_VERSION" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' >/dev/null; then
    echo "Error: Version must be exactly three dot-separated numeric components, got: $CURRENT_VERSION" >&2
    exit 1
fi

# Extract version components
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

# Compute new version (increment patch), then skip occupied hosted versions.
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
OCCUPIED_SKIP_CAP=50
OCCUPIED_INCREMENTS=0

for OCCUPIED_TOKEN in ${OCCUPIED_VERSIONS-}; do
    if ! echo "$OCCUPIED_TOKEN" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' >/dev/null; then
        echo "Error: Malformed occupied version: $OCCUPIED_TOKEN" >&2
        exit 1
    fi
done

while true; do
    OCCUPIED_MATCH=0
    for OCCUPIED_TOKEN in ${OCCUPIED_VERSIONS-}; do
        if [ "$OCCUPIED_TOKEN" = "$NEW_VERSION" ]; then
            OCCUPIED_MATCH=1
            break
        fi
    done
    if [ "$OCCUPIED_MATCH" -eq 0 ]; then
        break
    fi
    if [ "$OCCUPIED_INCREMENTS" -ge "$OCCUPIED_SKIP_CAP" ]; then
        echo "Error: Occupied-version skip cap of 50 exceeded." >&2
        exit 1
    fi
    OCCUPIED_INCREMENTS=$((OCCUPIED_INCREMENTS + 1))
    NEW_PATCH=$((NEW_PATCH + 1))
    NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
done

# Validate CHANGELOG.md format. The title may be preceded by blank lines, so its line
# number is resolved here and reused when the file is rebuilt below.
TITLE_LINE_NUMBER=$(grep -n -v '^[[:space:]]*$' "$CHANGELOG_PATH" | head -n1 | cut -d: -f1)
if [ -z "$TITLE_LINE_NUMBER" ]; then
    echo "Error: CHANGELOG.md is empty: $CHANGELOG_PATH" >&2
    exit 1
fi

FIRST_NON_BLANK=$(sed -n "${TITLE_LINE_NUMBER}p" "$CHANGELOG_PATH" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
if [ "$FIRST_NON_BLANK" != "# Changelog" ]; then
    echo "Error: First non-blank line in CHANGELOG.md must be '# Changelog', got: $FIRST_NON_BLANK" >&2
    exit 1
fi

# Check if new version already exists in changelog. A heading is either the version alone
# or the version followed by the dated remainder.
if grep -Eq "^## $NEW_VERSION([[:space:]]|$)" "$CHANGELOG_PATH"; then
    echo "Error: Version $NEW_VERSION already exists in CHANGELOG.md" >&2
    exit 1
fi

# An Unreleased heading is exactly two hashes, one space, and Unreleased.
UNRELEASED_COUNT=$(grep -c '^## Unreleased$' "$CHANGELOG_PATH" || true)
if [ "${UNRELEASED_COUNT:-0}" -gt 1 ]; then
    echo "Error: More than one Unreleased heading was found." >&2
    exit 1
fi

# Determine release date
if [ -n "${RELEASE_DATE:-}" ]; then
    DATE="$RELEASE_DATE"
else
    DATE=$(date -u +%Y-%m-%d)
fi

# Prepare new files content in memory
TEMP_PUBSPEC=$(mktemp)
TEMP_CHANGELOG=$(mktemp)

# Clean up temp files on exit
trap 'rm -f "$TEMP_PUBSPEC" "$TEMP_CHANGELOG"' EXIT

# Create new pubspec.yaml content
sed "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_PATH" > "$TEMP_PUBSPEC"

# Create new CHANGELOG.md content: everything up to and including the title line, the new
# section, then the remainder. The new body is promoted Unreleased start and wrap lines
# when that span is populated; otherwise it is the automated sentence. Copied Unreleased
# lines are omitted from the remainder so the exact heading stays without those items.
awk -v title_line="$TITLE_LINE_NUMBER" \
    -v new_version="$NEW_VERSION" \
    -v date="$DATE" \
    '
    { lines[NR] = $0 }
    END {
        n = NR
        heading_nr = 0
        for (i = 1; i <= n; i++) {
            if (lines[i] == "## Unreleased") {
                heading_nr = i
                break
            }
        }
        span_end = 0
        if (heading_nr > 0) {
            span_end = n
            for (i = heading_nr + 1; i <= n; i++) {
                if (lines[i] ~ /^## /) {
                    span_end = i - 1
                    break
                }
            }
            attach = 0
            for (i = heading_nr + 1; i <= span_end; i++) {
                line = lines[i]
                if (substr(line, 1, 2) == "- ") {
                    is_copy[i] = 1
                    attach = 1
                } else if (attach && line !~ /^[[:space:]]*$/ && line ~ /^[[:space:]]/) {
                    is_copy[i] = 1
                } else {
                    attach = 0
                }
            }
        }

        for (i = 1; i <= title_line; i++) {
            print lines[i]
        }
        print ""
        print "## " new_version " - " date
        print ""

        copied = 0
        if (heading_nr > 0) {
            for (i = heading_nr + 1; i <= span_end; i++) {
                if (is_copy[i]) {
                    print lines[i]
                    copied = 1
                }
            }
        }
        if (!copied) {
            print "- Automated patch release from main."
        }
        print ""

        started = 0
        for (i = title_line + 1; i <= n; i++) {
            if (is_copy[i]) {
                continue
            }
            if (!started && lines[i] ~ /^[[:space:]]*$/) {
                continue
            }
            started = 1
            print lines[i]
        }
    }
    ' "$CHANGELOG_PATH" > "$TEMP_CHANGELOG"

# Validate that we successfully created new content
if ! grep -q "^version: $NEW_VERSION$" "$TEMP_PUBSPEC"; then
    echo "Error: Failed to create updated pubspec.yaml content" >&2
    exit 1
fi

if ! grep -q "^## $NEW_VERSION - $DATE$" "$TEMP_CHANGELOG"; then
    echo "Error: Failed to create updated CHANGELOG.md content" >&2
    exit 1
fi

# Move temp files into place (atomic operation)
mv "$TEMP_PUBSPEC" "$PUBSPEC_PATH"
mv "$TEMP_CHANGELOG" "$CHANGELOG_PATH"

# Output new version
echo "$NEW_VERSION"