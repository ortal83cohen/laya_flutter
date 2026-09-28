#!/usr/bin/env bash
# Cursor afterFileEdit hook. Project hooks run from the project root, so the path
# below is relative to the repository, not to .cursor/.
#
# Mirrors .claude/hooks/lint_on_write.py. Cursor reads the hook payload on stdin;
# this wrapper ignores it and lints the whole wiki, which is cheap enough to do
# unconditionally and avoids depending on the payload shape.
set -uo pipefail

if [ ! -f tools/lint_wiki.py ]; then
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  exit 0
fi

output="$(python3 tools/lint_wiki.py --quiet 2>&1)"
status=$?

if [ "$status" -eq 0 ]; then
  exit 0
fi

echo "lint_wiki failed. Fix these before continuing:" >&2
echo "$output" | head -n 20 >&2
exit 2
