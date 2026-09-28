#!/usr/bin/env python3
"""PostToolUse hook: lint the wiki and agent config right after a relevant write.

Instruction compliance decays over a long session. A rule that is checked by a
process holds; a rule that is only written down drifts. This hook is the process.

Reads the hook payload on stdin. Exits 2 with the findings on stderr when a write
inside the enforced paths leaves the linter failing, which surfaces the findings
to the agent so it fixes them in the same turn.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ENFORCED_PREFIXES = ("wiki/", ".claude/", ".cursor/", "AGENTS.md", "CLAUDE.md")


def project_dir() -> Path:
    env = os.environ.get("CLAUDE_PROJECT_DIR")
    if env:
        return Path(env)
    return Path(__file__).resolve().parent.parent.parent


def written_path(payload: dict) -> str | None:
    tool_input = payload.get("tool_input") or {}
    for key in ("file_path", "path", "notebook_path"):
        value = tool_input.get(key)
        if isinstance(value, str) and value:
            return value
    return None


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0  # not a payload we understand; never block on that

    root = project_dir()
    target = written_path(payload)
    if not target:
        return 0

    try:
        rel = str(Path(target).resolve().relative_to(root.resolve()))
    except (ValueError, OSError):
        return 0  # outside the project

    if not rel.startswith(ENFORCED_PREFIXES):
        return 0

    linter = root / "tools" / "lint_wiki.py"
    if not linter.is_file():
        return 0

    result = subprocess.run(
        [sys.executable, str(linter), "--quiet"],
        cwd=str(root),
        capture_output=True,
        text=True,
        timeout=25,
    )
    if result.returncode == 0:
        return 0

    lines = [ln for ln in result.stderr.splitlines() if ln.startswith("error:")]
    about_this_file = [ln for ln in lines if rel in ln]
    shown = about_this_file or lines

    print(
        f"lint_wiki failed after writing {rel}. Fix these before continuing:\n"
        + "\n".join(shown[:20]),
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:  # noqa: BLE001 - a broken hook must never block the session
        raise SystemExit(0)
