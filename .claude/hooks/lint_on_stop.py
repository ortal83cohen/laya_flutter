#!/usr/bin/env python3
"""Stop hook: refuse to end a turn that leaves the wiki linter failing.

A phase reported complete with a failing check is the most expensive lie in this
pipeline, because every later phase builds on it. This hook makes "done" mean the
checks pass rather than that the agent believes they would.

Blocks at most once per session. A second failure is escalated to the human
instead of looped on, which is the same rule the validation phases follow.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def project_dir() -> Path:
    env = os.environ.get("CLAUDE_PROJECT_DIR")
    if env:
        return Path(env)
    return Path(__file__).resolve().parent.parent.parent


def stamp_for(session_id: str) -> Path:
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_")[:64] or "unknown"
    return Path(tempfile.gettempdir()) / f"lint_on_stop.{safe}"


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        payload = {}

    if payload.get("stop_hook_active"):
        return 0  # already inside a blocked stop; do not nest

    root = project_dir()
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

    stamp = stamp_for(str(payload.get("session_id", "")))
    if stamp.exists():
        print(
            "lint_wiki is still failing and this session has already been sent back "
            "once. Do not attempt a third pass: report the remaining findings to the "
            "user as a specific question and stop.\n" + result.stderr.strip()[:2000],
            file=sys.stderr,
        )
        return 0

    stamp.touch()
    print(
        "lint_wiki is failing, so this turn is not done. Fix these findings, then "
        "finish:\n" + result.stderr.strip()[:2000],
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception:  # noqa: BLE001 - a broken hook must never wedge the session
        raise SystemExit(0)
