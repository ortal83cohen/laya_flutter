#!/bin/sh
set -eu

# Test script for tools/bump_patch_version.sh
# Runs against fixture directories under tools/fixtures/bump-patch-version/

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
HELPER_SCRIPT="$SCRIPT_DIR/bump_patch_version.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures/bump-patch-version"

# Fixed release date for consistent test assertions
export RELEASE_DATE="2026-01-02"

test_case() {
    unset OCCUPIED_VERSIONS || true
    local case_name="$1"
    local fixture_dir="$FIXTURES_DIR/$case_name"
    
    if [ ! -d "$fixture_dir" ]; then
        echo "FAIL: $case_name - fixture directory not found"
        return 1
    fi
    
    # Create temp directory and copy fixture
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT
    
    cp -r "$fixture_dir"/* "$temp_dir/" 2>/dev/null || true
    
    case "$case_name" in
        "valid-patch")
            # Test: pubspec 0.1.1 → stdout exactly 0.1.2, exit 0
            local output
            if output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) && [ $? -eq 0 ]; then
                if [ "$output" = "0.1.2" ]; then
                    # Assert written pubspec has version: 0.1.2
                    if grep -q "^version: 0.1.2$" "$temp_dir/pubspec.yaml"; then
                        # Assert changelog line 3 equals expected format
                        local line3
                        line3=$(sed -n '3p' "$temp_dir/CHANGELOG.md")
                        if [ "$line3" = "## 0.1.2 - 2026-01-02" ]; then
                            # Check no square brackets
                            if ! echo "$line3" | grep -q '\[' && ! echo "$line3" | grep -q '\]'; then
                                # Assert line 5 equals expected bullet
                                local line5
                                line5=$(sed -n '5p' "$temp_dir/CHANGELOG.md")
                                if [ "$line5" = "- Automated patch release from main." ]; then
                                    # Check previous heading still appears
                                    if grep -q "## 0.1.1 - 2026-08-01" "$temp_dir/CHANGELOG.md"; then
                                        echo "PASS: $case_name"
                                        return 0
                                    else
                                        echo "FAIL: $case_name - previous heading missing"
                                    fi
                                else
                                    echo "FAIL: $case_name - wrong bullet line: '$line5'"
                                fi
                            else
                                echo "FAIL: $case_name - heading contains brackets"
                            fi
                        else
                            echo "FAIL: $case_name - wrong heading line 3: '$line3'"
                        fi
                    else
                        echo "FAIL: $case_name - pubspec version not updated correctly"
                    fi
                else
                    echo "FAIL: $case_name - wrong output: '$output'"
                fi
            else
                echo "FAIL: $case_name - helper failed or wrong exit code"
            fi
            ;;
            
        "valid-minor-untouched")
            # Test: pubspec 1.2.3 → written pubspec has version: 1.2.4
            if sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                if grep -q "^version: 1.2.4$" "$temp_dir/pubspec.yaml"; then
                    # Assert no line equals version: 1.3.0 or version: 2.0.0
                    if ! grep -q "^version: 1.3.0$" "$temp_dir/pubspec.yaml" && \
                       ! grep -q "^version: 2.0.0$" "$temp_dir/pubspec.yaml"; then
                        echo "PASS: $case_name"
                        return 0
                    else
                        echo "FAIL: $case_name - wrong version component changed"
                    fi
                else
                    echo "FAIL: $case_name - version not updated to 1.2.4"
                fi
            else
                echo "FAIL: $case_name - helper failed"
            fi
            ;;
            
        "valid-leading-blank")
            # Test: a changelog whose title is preceded by a blank line keeps exactly one
            # title line and one blank separator before the previously top-most section.
            local output
            if output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) && [ "$output" = "2.4.10" ]; then
                # The fixture's leading blank line is preserved, so the title sits on line 2
                # and the new section starts on line 4.
                local title_count separator
                title_count=$(grep -c '^# Changelog$' "$temp_dir/CHANGELOG.md")
                separator=$(sed -n '7p' "$temp_dir/CHANGELOG.md")
                if [ "$title_count" = "1" ]; then
                    if [ "$(sed -n '4p' "$temp_dir/CHANGELOG.md")" = "## 2.4.10 - 2026-01-02" ] \
                       && [ "$(sed -n '6p' "$temp_dir/CHANGELOG.md")" = "- Automated patch release from main." ] \
                       && [ -z "$separator" ] \
                       && [ "$(sed -n '8p' "$temp_dir/CHANGELOG.md")" = "## 2.4.9 - 2026-08-01" ]; then
                        echo "PASS: $case_name"
                        return 0
                    else
                        echo "FAIL: $case_name - new section not laid out as expected"
                    fi
                else
                    echo "FAIL: $case_name - title line count was $title_count"
                fi
            else
                echo "FAIL: $case_name - helper failed or wrong output: '${output:-}'"
            fi
            ;;

        "reject-prerelease")
            # Test: version 0.1.1-dev.1 → non-zero, both files byte-identical
            local before_pubspec before_changelog
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            before_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
            
            if ! sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                local after_pubspec after_changelog
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                after_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ "$before_changelog" = "$after_changelog" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - files were modified"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-two-components")
            # Test: version 0.1 → non-zero, both files byte-identical
            local before_pubspec before_changelog
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            before_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
            
            if ! sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                local after_pubspec after_changelog
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                after_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ "$before_changelog" = "$after_changelog" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - files were modified"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-no-changelog-title")
            # Test: CHANGELOG.md without # Changelog title → non-zero, files byte-identical
            local before_pubspec before_changelog
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            before_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
            
            if ! sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                local after_pubspec after_changelog
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                after_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ "$before_changelog" = "$after_changelog" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - files were modified"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-missing-changelog")
            # Test: valid pubspec, no CHANGELOG.md → non-zero, stdout empty, pubspec byte-identical
            local before_pubspec
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            
            local output exit_code
            set +e
            output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null)
            exit_code=$?
            set -e
            
            if [ $exit_code -ne 0 ]; then
                local after_pubspec
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ -z "$output" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - pubspec modified or stdout not empty"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-missing-pubspec")
            # Test: empty directory → non-zero, non-empty stderr, stdout empty, directory still empty
            local output stderr_output exit_code
            set +e
            stderr_output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>&1 >/dev/null)
            output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null)
            exit_code=$?
            set -e
            
            if [ $exit_code -ne 0 ]; then
                if [ -n "$stderr_output" ] && [ -z "$output" ]; then
                    # Check directory is still empty
                    if [ -z "$(ls -A "$temp_dir" 2>/dev/null)" ]; then
                        echo "PASS: $case_name"
                        return 0
                    else
                        echo "FAIL: $case_name - directory not empty"
                    fi
                else
                    echo "FAIL: $case_name - wrong output behavior"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        "reject-changelog-ahead")
            # Test: pubspec 0.1.1 and CHANGELOG.md with ## 0.1.2 → non-zero, files byte-identical
            local before_pubspec before_changelog
            before_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
            before_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
            
            if ! sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1; then
                local after_pubspec after_changelog
                after_pubspec=$(cat "$temp_dir/pubspec.yaml" 2>/dev/null || echo "")
                after_changelog=$(cat "$temp_dir/CHANGELOG.md" 2>/dev/null || echo "")
                
                if [ "$before_pubspec" = "$after_pubspec" ] && [ "$before_changelog" = "$after_changelog" ]; then
                    echo "PASS: $case_name"
                    return 0
                else
                    echo "FAIL: $case_name - files were modified"
                fi
            else
                echo "FAIL: $case_name - helper should have failed"
            fi
            ;;
            
        *)
            echo "FAIL: $case_name - unknown test case"
            return 1
            ;;
    esac
    
    return 1
}

copy_fixture() {
    local fixture_name="$1"
    local dest="$2"
    cp -r "$FIXTURES_DIR/$fixture_name"/. "$dest/"
}

files_unchanged() {
    local dir="$1"
    local before_pubspec="$2"
    local before_changelog="$3"
    [ "$(cat "$dir/pubspec.yaml" 2>/dev/null || echo "")" = "$before_pubspec" ] &&
        [ "$(cat "$dir/CHANGELOG.md" 2>/dev/null || echo "")" = "$before_changelog" ]
}

assert_chosen_version() {
    local dir="$1"
    local expected="$2"
    grep -q "^version: $expected$" "$dir/pubspec.yaml" &&
        grep -Eq "^## $expected - 2026-01-02$" "$dir/CHANGELOG.md"
}

run_occupied_success() {
    local name="$1"
    local fixture_name="$2"
    local occupied="$3"
    local expected="$4"
    local temp_dir output
    temp_dir=$(mktemp -d)
    copy_fixture "$fixture_name" "$temp_dir"
    if output=$(OCCUPIED_VERSIONS="$occupied" sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) &&
        [ "$output" = "$expected" ] &&
        assert_chosen_version "$temp_dir" "$expected"; then
        echo "PASS: $name"
        rm -rf "$temp_dir"
        return 0
    fi
    echo "FAIL: $name - expected '$expected', output was '$output'"
    rm -rf "$temp_dir"
    return 1
}

run_occupied_reject() {
    local name="$1"
    local fixture_name="$2"
    local occupied="$3"
    local temp_dir before_pubspec before_changelog status
    temp_dir=$(mktemp -d)
    copy_fixture "$fixture_name" "$temp_dir"
    before_pubspec=$(cat "$temp_dir/pubspec.yaml")
    before_changelog=$(cat "$temp_dir/CHANGELOG.md")
    status=0
    OCCUPIED_VERSIONS="$occupied" sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1 || status=$?
    if [ "$status" -ne 0 ] && files_unchanged "$temp_dir" "$before_pubspec" "$before_changelog"; then
        echo "PASS: $name"
        rm -rf "$temp_dir"
        return 0
    fi
    echo "FAIL: $name - expected reject with untouched files, status=$status"
    rm -rf "$temp_dir"
    return 1
}

test_occupied_cases() {
    local failures=0
    local temp_dir output
    local occupied_fifty occupied_fifty_one i
    local stderr_file status before_pubspec before_changelog

    if ! run_occupied_success "occupied-empty-plus-one" "valid-patch" "" "0.1.2"; then
        failures=$((failures + 1))
    fi

    temp_dir=$(mktemp -d)
    copy_fixture "valid-patch" "$temp_dir"
    if output=$(OCCUPIED_VERSIONS="0.1.2" sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) &&
        [ "$output" = "0.1.3" ] &&
        assert_chosen_version "$temp_dir" "0.1.3" &&
        ! grep -Eq "^## 0.1.2 " "$temp_dir/CHANGELOG.md"; then
        echo "PASS: occupied-skip-next"
    else
        echo "FAIL: occupied-skip-next - expected 0.1.3 without a 0.1.2 heading"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    temp_dir=$(mktemp -d)
    copy_fixture "valid-patch" "$temp_dir"
    unset OCCUPIED_VERSIONS || true
    if output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) && [ "$output" = "0.1.2" ]; then
        echo "PASS: occupied-skip-next-negative-unset"
    else
        echo "FAIL: occupied-skip-next-negative-unset - expected 0.1.2"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    temp_dir=$(mktemp -d)
    copy_fixture "valid-patch" "$temp_dir"
    if output=$(OCCUPIED_VERSIONS="0.1.2 0.1.3" sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) &&
        [ "$output" = "0.1.4" ] &&
        assert_chosen_version "$temp_dir" "0.1.4" &&
        ! grep -Eq "^## 0.1.2 " "$temp_dir/CHANGELOG.md" &&
        ! grep -Eq "^## 0.1.3 " "$temp_dir/CHANGELOG.md"; then
        echo "PASS: occupied-consecutive"
    else
        echo "FAIL: occupied-consecutive - expected only 0.1.4"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    if ! run_occupied_success "occupied-consecutive-negative-only-next" "valid-patch" "0.1.2" "0.1.3"; then
        failures=$((failures + 1))
    fi

    if ! run_occupied_success "occupied-later-not-next" "valid-patch" "0.1.3" "0.1.2"; then
        failures=$((failures + 1))
    fi

    if ! run_occupied_success "occupied-later-and-next" "valid-patch" "0.1.2 0.1.3" "0.1.4"; then
        failures=$((failures + 1))
    fi

    occupied_fifty_one=""
    i=2
    while [ "$i" -le 52 ]; do
        occupied_fifty_one="$occupied_fifty_one 0.1.$i"
        i=$((i + 1))
    done
    temp_dir=$(mktemp -d)
    copy_fixture "valid-patch" "$temp_dir"
    before_pubspec=$(cat "$temp_dir/pubspec.yaml")
    before_changelog=$(cat "$temp_dir/CHANGELOG.md")
    stderr_file=$(mktemp)
    status=0
    OCCUPIED_VERSIONS="$occupied_fifty_one" sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>"$stderr_file" || status=$?
    if [ "$status" -ne 0 ] &&
        files_unchanged "$temp_dir" "$before_pubspec" "$before_changelog" &&
        grep -q "50" "$stderr_file"; then
        echo "PASS: occupied-cap-exceeded"
    else
        echo "FAIL: occupied-cap-exceeded - status=$status stderr=$(cat "$stderr_file")"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir" "$stderr_file"

    occupied_fifty=""
    i=2
    while [ "$i" -le 51 ]; do
        occupied_fifty="$occupied_fifty 0.1.$i"
        i=$((i + 1))
    done
    if ! run_occupied_success "occupied-cap-boundary" "valid-patch" "$occupied_fifty" "0.1.52"; then
        failures=$((failures + 1))
    fi

    if ! run_occupied_reject "occupied-malformed-two-component" "valid-patch" "0.1"; then
        failures=$((failures + 1))
    fi
    if ! run_occupied_reject "occupied-malformed-prerelease" "valid-patch" "0.1.2-beta"; then
        failures=$((failures + 1))
    fi
    if ! run_occupied_reject "occupied-malformed-non-numeric" "valid-patch" "abc"; then
        failures=$((failures + 1))
    fi
    if ! run_occupied_success "occupied-malformed-negative-well-formed" "valid-patch" "0.1.9" "0.1.2"; then
        failures=$((failures + 1))
    fi

    if ! run_occupied_reject "occupied-chosen-heading" "occupied-chosen-heading" "0.1.2"; then
        failures=$((failures + 1))
    fi
    if ! run_occupied_success "occupied-chosen-heading-negative" "valid-patch" "0.1.2" "0.1.3"; then
        failures=$((failures + 1))
    fi

    temp_dir=$(mktemp -d)
    copy_fixture "occupied-intermediate-heading" "$temp_dir"
    if output=$(OCCUPIED_VERSIONS="0.1.2" sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) &&
        [ "$output" = "0.1.3" ] &&
        assert_chosen_version "$temp_dir" "0.1.3" &&
        grep -Eq "^## 0.1.2 " "$temp_dir/CHANGELOG.md"; then
        echo "PASS: occupied-intermediate-heading"
    else
        echo "FAIL: occupied-intermediate-heading - expected 0.1.3 while keeping 0.1.2 heading"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    if ! run_occupied_reject "occupied-intermediate-heading-negative" "occupied-intermediate-heading" ""; then
        failures=$((failures + 1))
    fi

    OCCUPIED_VERSIONS="0.1.2"
    export OCCUPIED_VERSIONS
    temp_dir=$(mktemp -d)
    copy_fixture "valid-patch" "$temp_dir"
    unset OCCUPIED_VERSIONS || true
    if output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) && [ "$output" = "0.1.2" ]; then
        echo "PASS: occupied-parent-env-unset"
    else
        echo "FAIL: occupied-parent-env-unset - expected plus-one after unset"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    if grep -E 'https?://|[[:space:]]git[[:space:]]|^git[[:space:]]' "$HELPER_SCRIPT" >/dev/null; then
        echo "FAIL: bump helper references a host, URL, or git command"
        failures=$((failures + 1))
    else
        echo "PASS: occupied-no-network-no-git"
    fi

    return "$failures"
}

count_exact_unreleased() {
    grep -c '^## Unreleased$' "$1" || true
}

section_body() {
    local file="$1"
    local version="$2"
    awk -v ver="$version" '
        $0 == "## " ver " - 2026-01-02" { in_sec = 1; next }
        in_sec && /^## / { exit }
        in_sec && $0 !~ /^[[:space:]]*$/ { print }
    ' "$file"
}

numbered_section() {
    local file="$1"
    local heading="$2"
    awk -v h="$heading" '
        $0 == h { p = 1 }
        p && $0 != h && /^## / { exit }
        p { print }
    ' "$file"
}

unreleased_span_lines() {
    awk '
        $0 == "## Unreleased" { p = 1; next }
        p && /^## / { exit }
        p { print }
    ' "$1"
}

lookalike_present() {
    local file="$1"
    local heading="$2"
    local note="$3"
    grep -Fxq -- "$heading" "$file" && grep -Fxq -- "$note" "$file"
}

test_unreleased_cases() {
    local failures=0
    local temp_dir output status stderr_file before_pubspec before_changelog
    local after_pubspec after_changelog body span
    local before_sec after_sec scratch_sec
    local before_sum after_sum scratch_sum
    local line5 expected_body

    unset OCCUPIED_VERSIONS || true

    # AC-001: no exact Unreleased heading keeps the automated sentence and invents none.
    temp_dir=$(mktemp -d)
    copy_fixture "valid-patch" "$temp_dir"
    output=""
    status=0
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || status=$?
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    if [ "$status" -eq 0 ] && [ "$output" = "0.1.2" ] &&
        [ "$body" = "- Automated patch release from main." ] &&
        [ "$(count_exact_unreleased "$temp_dir/CHANGELOG.md")" = "0" ]; then
        echo "PASS: unreleased-missing"
    else
        echo "FAIL: unreleased-missing - status=$status output='$output' body='$body'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-001 negative: adding an exact heading and a hyphen-space bullet promotes that bullet.
    temp_dir=$(mktemp -d)
    copy_fixture "valid-patch" "$temp_dir"
    awk '
        { print }
        $0 == "# Changelog" {
            print ""
            print "## Unreleased"
            print ""
            print "- Unique promoted bullet."
        }
    ' "$temp_dir/CHANGELOG.md" > "$temp_dir/CHANGELOG.md.next"
    mv "$temp_dir/CHANGELOG.md.next" "$temp_dir/CHANGELOG.md"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    if [ "$output" = "0.1.2" ] &&
        [ "$body" = "- Unique promoted bullet." ] &&
        [ "$body" != "- Automated patch release from main." ]; then
        echo "PASS: unreleased-missing-negative"
    else
        echo "FAIL: unreleased-missing-negative - output='$output' body='$body'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-002: heading-only span stays empty and keeps the heading.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-heading-only" "$temp_dir"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    if [ "$output" = "0.1.2" ] &&
        [ "$body" = "- Automated patch release from main." ] &&
        [ "$(count_exact_unreleased "$temp_dir/CHANGELOG.md")" = "1" ]; then
        echo "PASS: unreleased-heading-only"
    else
        echo "FAIL: unreleased-heading-only - output='$output' body='$body'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-002 negative: a hyphen-space line in that span is promoted.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-heading-only" "$temp_dir"
    awk '
        { print }
        $0 == "## Unreleased" { print "- Inserted heading-only bullet." }
    ' "$temp_dir/CHANGELOG.md" > "$temp_dir/CHANGELOG.md.next"
    mv "$temp_dir/CHANGELOG.md.next" "$temp_dir/CHANGELOG.md"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    if [ "$body" = "- Inserted heading-only bullet." ] &&
        [ "$body" != "- Automated patch release from main." ]; then
        echo "PASS: unreleased-heading-only-negative"
    else
        echo "FAIL: unreleased-heading-only-negative - body='$body'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-003: subsection-only span is empty; heading and ### stay.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-subsection-only" "$temp_dir"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    span=$(unreleased_span_lines "$temp_dir/CHANGELOG.md")
    if [ "$output" = "0.1.2" ] &&
        [ "$body" = "- Automated patch release from main." ] &&
        [ "$(count_exact_unreleased "$temp_dir/CHANGELOG.md")" = "1" ] &&
        printf '%s\n' "$span" | grep -Fxq "### Added"; then
        echo "PASS: unreleased-subsection-only"
    else
        echo "FAIL: unreleased-subsection-only - output='$output' body='$body' span='$span'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-003 negative: a hyphen-space line under ### is promoted; automated is absent.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-subsection-only" "$temp_dir"
    awk '
        { print }
        $0 == "### Added" { print "- Subsection bullet." }
    ' "$temp_dir/CHANGELOG.md" > "$temp_dir/CHANGELOG.md.next"
    mv "$temp_dir/CHANGELOG.md.next" "$temp_dir/CHANGELOG.md"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    if [ "$body" = "- Subsection bullet." ] &&
        ! printf '%s\n' "$body" | grep -Fxq -- "- Automated patch release from main."; then
        echo "PASS: unreleased-subsection-only-negative"
    else
        echo "FAIL: unreleased-subsection-only-negative - body='$body'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-004, AC-005, AC-007, AC-008, AC-013: mid-file wrapped promotion.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-mid-file-wrapped" "$temp_dir"
    expected_body=$(printf '%s\n' \
        "- First promoted note that wraps" \
        "  onto a continuation line." \
        "- Second promoted note that also wraps" \
        "  onto another continuation line.")
    before_sec=$(numbered_section "$temp_dir/CHANGELOG.md" "## 0.1.1 - 2026-08-01")
    before_older=$(numbered_section "$temp_dir/CHANGELOG.md" "## 0.1.0 - 2026-07-01")
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    after_sec=$(numbered_section "$temp_dir/CHANGELOG.md" "## 0.1.1 - 2026-08-01")
    after_older=$(numbered_section "$temp_dir/CHANGELOG.md" "## 0.1.0 - 2026-07-01")
    span=$(unreleased_span_lines "$temp_dir/CHANGELOG.md")
    first_two_hash=$(awk '/^## / { print; exit }' "$temp_dir/CHANGELOG.md")
    if [ "$output" = "0.1.2" ] &&
        [ "$body" = "$expected_body" ] &&
        ! printf '%s\n' "$body" | grep -Fxq -- "- Automated patch release from main." &&
        [ "$(count_exact_unreleased "$temp_dir/CHANGELOG.md")" = "1" ] &&
        ! printf '%s\n' "$span" | grep -e '^- ' >/dev/null &&
        ! printf '%s\n' "$span" | grep -Fxq -- "  onto a continuation line." &&
        ! printf '%s\n' "$span" | grep -Fxq -- "  onto another continuation line." &&
        [ "$after_sec" = "$before_sec" ] &&
        [ "$after_older" = "$before_older" ] &&
        [ "$first_two_hash" = "## 0.1.2 - 2026-01-02" ]; then
        echo "PASS: unreleased-mid-file-wrapped"
    else
        echo "FAIL: unreleased-mid-file-wrapped - output='$output' body='$body'"
        failures=$((failures + 1))
    fi

    # AC-005 negative: a second run on the emptied tree writes the automated sentence.
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.3")
    if [ "$output" = "0.1.3" ] &&
        [ "$body" = "- Automated patch release from main." ]; then
        echo "PASS: unreleased-second-run-empty"
    else
        echo "FAIL: unreleased-second-run-empty - output='$output' body='$body'"
        failures=$((failures + 1))
    fi

    # AC-007 negative: changing one numbered bullet after the run reports a difference.
    scratch_sec=$(printf '%s\n' "$after_sec" | sed 's/Previous release notes./Changed release notes./')
    if [ "$after_sec" = "$before_sec" ] && [ "$scratch_sec" != "$before_sec" ]; then
        echo "PASS: unreleased-numbered-scratch-diff"
    else
        echo "FAIL: unreleased-numbered-scratch-diff - comparison did not detect a change"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-004 negative: single-line items copy start lines only; no wrap is invented.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-mid-file-wrapped" "$temp_dir"
    awk '
        $0 == "  onto a continuation line." { next }
        $0 == "  onto another continuation line." { next }
        { print }
    ' "$temp_dir/CHANGELOG.md" > "$temp_dir/CHANGELOG.md.next"
    mv "$temp_dir/CHANGELOG.md.next" "$temp_dir/CHANGELOG.md"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    expected_body=$(printf '%s\n' \
        "- First promoted note that wraps" \
        "- Second promoted note that also wraps")
    if [ "$body" = "$expected_body" ] &&
        ! printf '%s\n' "$body" | grep -q '^[[:space:]]'; then
        echo "PASS: unreleased-wrapped-no-invented-wrap"
    else
        echo "FAIL: unreleased-wrapped-no-invented-wrap - body='$body'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-006 / AC-008 / AC-009: two exact headings fail closed.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-duplicate-heading" "$temp_dir"
    before_pubspec=$(cat "$temp_dir/pubspec.yaml")
    before_changelog=$(cat "$temp_dir/CHANGELOG.md")
    before_sum=$(cksum "$temp_dir/pubspec.yaml" "$temp_dir/CHANGELOG.md")
    stderr_file=$(mktemp)
    output=""
    status=0
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>"$stderr_file") || status=$?
    after_sum=$(cksum "$temp_dir/pubspec.yaml" "$temp_dir/CHANGELOG.md")
    if [ "$status" -ne 0 ] && [ -z "$output" ] &&
        grep -q "Unreleased" "$stderr_file" &&
        files_unchanged "$temp_dir" "$before_pubspec" "$before_changelog" &&
        [ "$before_sum" = "$after_sum" ]; then
        echo "PASS: unreleased-duplicate-heading"
    else
        echo "FAIL: unreleased-duplicate-heading - status=$status output='$output' stderr=$(cat "$stderr_file")"
        failures=$((failures + 1))
    fi

    # AC-009 negative: a one-byte edit after checksumming reports a difference.
    printf 'x' >> "$temp_dir/CHANGELOG.md"
    scratch_sum=$(cksum "$temp_dir/pubspec.yaml" "$temp_dir/CHANGELOG.md")
    if [ "$scratch_sum" != "$before_sum" ]; then
        echo "PASS: unreleased-checksum-scratch"
    else
        echo "FAIL: unreleased-checksum-scratch - checksums still matched"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir" "$stderr_file"

    # AC-006 negative: one exact heading and one hyphen-space bullet writes both files.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-heading-only" "$temp_dir"
    awk '
        { print }
        $0 == "## Unreleased" { print "- Single heading bullet." }
    ' "$temp_dir/CHANGELOG.md" > "$temp_dir/CHANGELOG.md.next"
    mv "$temp_dir/CHANGELOG.md.next" "$temp_dir/CHANGELOG.md"
    before_pubspec=$(cat "$temp_dir/pubspec.yaml")
    before_changelog=$(cat "$temp_dir/CHANGELOG.md")
    status=0
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || status=$?
    after_pubspec=$(cat "$temp_dir/pubspec.yaml")
    after_changelog=$(cat "$temp_dir/CHANGELOG.md")
    if [ "$status" -eq 0 ] &&
        [ "$after_pubspec" != "$before_pubspec" ] &&
        [ "$after_changelog" != "$before_changelog" ]; then
        echo "PASS: unreleased-duplicate-negative-single"
    else
        echo "FAIL: unreleased-duplicate-negative-single - status=$status"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-009: existing heading-disagreement reject leaves both files untouched.
    temp_dir=$(mktemp -d)
    copy_fixture "reject-changelog-ahead" "$temp_dir"
    before_pubspec=$(cat "$temp_dir/pubspec.yaml")
    before_changelog=$(cat "$temp_dir/CHANGELOG.md")
    before_sum=$(cksum "$temp_dir/pubspec.yaml" "$temp_dir/CHANGELOG.md")
    status=0
    sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1 || status=$?
    after_sum=$(cksum "$temp_dir/pubspec.yaml" "$temp_dir/CHANGELOG.md")
    if [ "$status" -ne 0 ] &&
        files_unchanged "$temp_dir" "$before_pubspec" "$before_changelog" &&
        [ "$before_sum" = "$after_sum" ]; then
        echo "PASS: unreleased-heading-disagreement-untouched"
    else
        echo "FAIL: unreleased-heading-disagreement-untouched - status=$status"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-010 negative: wrapped result fails the valid-patch line-5 automated-sentence check.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-mid-file-wrapped" "$temp_dir"
    sh "$HELPER_SCRIPT" "$temp_dir" >/dev/null 2>&1 || true
    line5=$(sed -n '5p' "$temp_dir/CHANGELOG.md")
    if [ "$line5" != "- Automated patch release from main." ]; then
        echo "PASS: unreleased-line-number-fail-on-wrapped"
    else
        echo "FAIL: unreleased-line-number-fail-on-wrapped - line 5 was the automated sentence"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-012: each lookalike keeps the automated sentence and its own lines.
    for lookalike_case in \
        "unreleased-lookalike-dated|## Unreleased - 2026-01-02|- Lookalike dated note." \
        "unreleased-lookalike-bracketed|## [Unreleased]|- Lookalike bracketed note." \
        "unreleased-lookalike-lowercase|## unreleased|- Lookalike lowercase note."
    do
        local fixture_name lookalike_heading lookalike_note
        fixture_name=$(printf '%s\n' "$lookalike_case" | cut -d'|' -f1)
        lookalike_heading=$(printf '%s\n' "$lookalike_case" | cut -d'|' -f2)
        lookalike_note=$(printf '%s\n' "$lookalike_case" | cut -d'|' -f3)
        temp_dir=$(mktemp -d)
        copy_fixture "$fixture_name" "$temp_dir"
        output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
        body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
        if [ "$output" = "0.1.2" ] &&
            [ "$body" = "- Automated patch release from main." ] &&
            lookalike_present "$temp_dir/CHANGELOG.md" "$lookalike_heading" "$lookalike_note"; then
            echo "PASS: $fixture_name"
        else
            echo "FAIL: $fixture_name - output='$output' body='$body'"
            failures=$((failures + 1))
        fi
        rm -rf "$temp_dir"
    done

    # AC-012 negative: replacing a lookalike with the exact heading promotes those notes.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-lookalike-dated" "$temp_dir"
    sed 's/^## Unreleased - 2026-01-02$/## Unreleased/' \
        "$temp_dir/CHANGELOG.md" > "$temp_dir/CHANGELOG.md.next"
    mv "$temp_dir/CHANGELOG.md.next" "$temp_dir/CHANGELOG.md"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    span=$(unreleased_span_lines "$temp_dir/CHANGELOG.md")
    if [ "$body" = "- Lookalike dated note." ] &&
        ! printf '%s\n' "$span" | grep -Fxq -- "- Lookalike dated note."; then
        echo "PASS: unreleased-lookalike-negative-exact"
    else
        echo "FAIL: unreleased-lookalike-negative-exact - body='$body' span='$span'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-013 negative: bullets left under a numbered section stay there.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-mid-file-wrapped" "$temp_dir"
    awk '
        $0 == "## Unreleased" { skip_blank = 1; next }
        skip_blank && $0 ~ /^[[:space:]]*$/ { skip_blank = 0; next }
        { skip_blank = 0; print }
    ' "$temp_dir/CHANGELOG.md" > "$temp_dir/CHANGELOG.md.next"
    mv "$temp_dir/CHANGELOG.md.next" "$temp_dir/CHANGELOG.md"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    after_sec=$(numbered_section "$temp_dir/CHANGELOG.md" "## 0.1.1 - 2026-08-01")
    if [ "$body" = "- Automated patch release from main." ] &&
        printf '%s\n' "$after_sec" | grep -Fxq -- "- First promoted note that wraps" &&
        printf '%s\n' "$after_sec" | grep -Fxq -- "  onto a continuation line."; then
        echo "PASS: unreleased-mid-file-negative-under-numbered"
    else
        echo "FAIL: unreleased-mid-file-negative-under-numbered - body='$body'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-014: occupied plus-one with populated Unreleased writes the free version.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-occupied-populated" "$temp_dir"
    expected_body=$(printf '%s\n' \
        "- Occupied promotion note" \
        "  that continues here.")
    output=$(OCCUPIED_VERSIONS="0.1.2" sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.3")
    span=$(unreleased_span_lines "$temp_dir/CHANGELOG.md")
    if [ "$output" = "0.1.3" ] &&
        [ "$body" = "$expected_body" ] &&
        ! grep -Eq "^## 0.1.2 " "$temp_dir/CHANGELOG.md" &&
        [ "$(count_exact_unreleased "$temp_dir/CHANGELOG.md")" = "1" ] &&
        ! printf '%s\n' "$span" | grep -e '^- ' >/dev/null; then
        echo "PASS: unreleased-occupied-populated"
    else
        echo "FAIL: unreleased-occupied-populated - output='$output' body='$body'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-014 negative: unset occupied list places the body under plus-one.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-occupied-populated" "$temp_dir"
    unset OCCUPIED_VERSIONS || true
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    if [ "$output" = "0.1.2" ] &&
        [ "$body" = "$expected_body" ] &&
        ! grep -Eq "^## 0.1.3 " "$temp_dir/CHANGELOG.md"; then
        echo "PASS: unreleased-occupied-populated-negative-unset"
    else
        echo "FAIL: unreleased-occupied-populated-negative-unset - output='$output' body='$body'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-019: orphan-only span keeps the automated sentence and the orphan.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-orphan-only" "$temp_dir"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    span=$(unreleased_span_lines "$temp_dir/CHANGELOG.md")
    if [ "$output" = "0.1.2" ] &&
        [ "$body" = "- Automated patch release from main." ] &&
        printf '%s\n' "$span" | grep -Fxq -- "  orphan continuation without a start item"; then
        echo "PASS: unreleased-orphan-only"
    else
        echo "FAIL: unreleased-orphan-only - output='$output' body='$body' span='$span'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    # AC-019 negative: the same whitespace line after a start line is a wrap and is removed.
    temp_dir=$(mktemp -d)
    copy_fixture "unreleased-orphan-only" "$temp_dir"
    awk '
        $0 == "  orphan continuation without a start item" {
            print "- Start item."
            print
            next
        }
        { print }
    ' "$temp_dir/CHANGELOG.md" > "$temp_dir/CHANGELOG.md.next"
    mv "$temp_dir/CHANGELOG.md.next" "$temp_dir/CHANGELOG.md"
    output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) || true
    body=$(section_body "$temp_dir/CHANGELOG.md" "0.1.2")
    span=$(unreleased_span_lines "$temp_dir/CHANGELOG.md")
    expected_body=$(printf '%s\n' \
        "- Start item." \
        "  orphan continuation without a start item")
    if [ "$body" = "$expected_body" ] &&
        ! printf '%s\n' "$span" | grep -Fxq -- "  orphan continuation without a start item"; then
        echo "PASS: unreleased-orphan-negative-as-wrap"
    else
        echo "FAIL: unreleased-orphan-negative-as-wrap - body='$body' span='$span'"
        failures=$((failures + 1))
    fi
    rm -rf "$temp_dir"

    return "$failures"
}

# Test real repository root
test_real_repo() {
    unset OCCUPIED_VERSIONS || true
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf '$temp_dir'" EXIT
    
    # Copy real pubspec.yaml and CHANGELOG.md
    cp "$REPOSITORY_ROOT/pubspec.yaml" "$temp_dir/"
    cp "$REPOSITORY_ROOT/CHANGELOG.md" "$temp_dir/"
    
    local current_version expected_version output
    current_version=$(sed -n 's/^version:[[:space:]]*//p' "$REPOSITORY_ROOT/pubspec.yaml" | head -n 1)
    expected_version=$(printf '%s\n' "$current_version" | awk -F. \
        'NF == 3 { printf "%s.%s.%d\n", $1, $2, $3 + 1 }')

    if output=$(sh "$HELPER_SCRIPT" "$temp_dir" 2>/dev/null) && [ "$output" = "$expected_version" ]; then
        echo "PASS: real-repo-test"
        return 0
    else
        echo "FAIL: real-repo-test - expected '$expected_version', output was '$output'"
        return 1
    fi
}

# Run all test cases
echo "Running bump_patch_version.sh tests..."

failures=0

for case_name in valid-patch valid-minor-untouched valid-leading-blank \
                 reject-prerelease reject-two-components \
                 reject-no-changelog-title reject-missing-changelog reject-missing-pubspec \
                 reject-changelog-ahead; do
    if ! test_case "$case_name"; then
        failures=$((failures + 1))
    fi
done

# Test against real repository
if ! test_real_repo; then
    failures=$((failures + 1))
fi

occupied_failures=0
test_occupied_cases || occupied_failures=$?
failures=$((failures + occupied_failures))

unreleased_failures=0
test_unreleased_cases || unreleased_failures=$?
failures=$((failures + unreleased_failures))

if [ $failures -eq 0 ]; then
    echo "All tests passed"
    exit 0
else
    echo "$failures test(s) failed"
    exit 1
fi
