#!/usr/bin/env python3
"""Print occupied pub.dev versions from a hosted-repository package-list JSON body."""

from __future__ import annotations

import json
import re
import sys

THREE_COMPONENT = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")


def occupied_versions(payload: object) -> str:
    if not isinstance(payload, dict) or "versions" not in payload:
        raise ValueError("missing versions array")
    versions = payload["versions"]
    if not isinstance(versions, list):
        raise ValueError("versions is not an array")
    tokens: list[str] = []
    for entry in versions:
        if not isinstance(entry, dict):
            continue
        version = entry.get("version")
        if isinstance(version, str) and THREE_COMPONENT.fullmatch(version):
            tokens.append(version)
    return " ".join(tokens)


def main(argv: list[str]) -> int:
    if len(argv) > 2:
        print("Error: expected at most one file path argument.", file=sys.stderr)
        return 1
    try:
        if len(argv) == 2:
            with open(argv[1], encoding="utf-8") as handle:
                raw = handle.read()
        else:
            raw = sys.stdin.read()
        payload = json.loads(raw)
    except OSError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    except json.JSONDecodeError:
        print("Error: invalid JSON", file=sys.stderr)
        return 1
    try:
        line = occupied_versions(payload)
    except ValueError as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1
    print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
