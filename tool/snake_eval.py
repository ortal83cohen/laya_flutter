#!/usr/bin/env python3
"""Validate and score a small, model-independent Snake decision fixture.

This tool does not train a checkpoint and does not call a model. It validates a
train/validation split, scores supplied prediction JSONL, and can score a simple
straight-ahead baseline. It is intentionally standard-library-only so the
fixture contract can be checked before a GPU environment is available.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any


CHOICES = ("left", "right", "straight")
HEADINGS = ("north", "east", "south", "west")


def turn_heading(heading: str, choice: str) -> str:
    index = HEADINGS.index(heading)
    if choice == "left":
        index = (index - 1) % 4
    elif choice == "right":
        index = (index + 1) % 4
    return HEADINGS[index]


def next_cell(head: list[int], heading: str) -> list[int]:
    col, row = head
    if heading == "north":
        row -= 1
    elif heading == "east":
        col += 1
    elif heading == "south":
        row += 1
    else:
        col -= 1
    return [col, row]


def distance(a: list[int], b: list[int]) -> int:
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


def candidate(row: dict[str, Any], choice: str) -> dict[str, Any]:
    state = row["state"]
    heading = turn_heading(state["heading"], choice)
    cell = next_cell(state["head"], heading)
    inside = 0 <= cell[0] < state["width"] and 0 <= cell[1] < state["height"]
    body = cell in state["snake"]
    kind = "wall" if not inside else "body" if body else "food" if cell == state["food"] else "empty"
    return {
        "heading": heading,
        "cell": cell,
        "kind": kind,
        "collision": kind in ("wall", "body"),
        "food_reached": kind == "food",
        "progress_delta": distance(state["head"], state["food"]) - distance(cell, state["food"]),
    }


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        try:
            value = json.loads(line)
        except json.JSONDecodeError as error:
            raise ValueError(f"{path}:{line_number}: invalid JSON: {error}") from error
        if not isinstance(value, dict):
            raise ValueError(f"{path}:{line_number}: expected a JSON object")
        rows.append(value)
    return rows


def validate_fixture(rows: list[dict[str, Any]]) -> None:
    if not rows:
        raise ValueError("fixture is empty")
    ids: set[str] = set()
    splits: set[str] = set()
    for row in rows:
        row_id = row.get("id")
        if not isinstance(row_id, str) or not row_id:
            raise ValueError("every fixture row needs a non-empty id")
        if row_id in ids:
            raise ValueError(f"duplicate fixture id: {row_id}")
        ids.add(row_id)
        split = row.get("split")
        if split not in ("train", "validation"):
            raise ValueError(f"{row_id}: split must be train or validation")
        splits.add(split)
        state = row.get("state")
        if not isinstance(state, dict):
            raise ValueError(f"{row_id}: state must be an object")
        required = ("width", "height", "heading", "head", "food", "snake")
        missing = [key for key in required if key not in state]
        if missing:
            raise ValueError(f"{row_id}: missing state fields {missing}")
        if state["heading"] not in HEADINGS:
            raise ValueError(f"{row_id}: unknown heading")
        if state["head"] != state["snake"][0]:
            raise ValueError(f"{row_id}: head must equal snake[0]")
        if state["food"] in state["snake"]:
            raise ValueError(f"{row_id}: food must not overlap the snake")
        teacher = row.get("teacher_choice")
        if teacher not in CHOICES:
            raise ValueError(f"{row_id}: teacher_choice must be one of {CHOICES}")
        teacher_candidate = candidate(row, teacher)
        if teacher_candidate["collision"]:
            raise ValueError(f"{row_id}: teacher_choice collides")
    if splits != {"train", "validation"}:
        raise ValueError("fixture must contain both train and validation rows")


def metric_report(rows: list[dict[str, Any]], predictions: list[dict[str, Any]], split: str) -> dict[str, Any]:
    expected = {row["id"]: row for row in rows if row["split"] == split}
    seen: set[str] = set()
    correct = collisions = food_reached = 0
    progress: list[int] = []
    loop_values: list[bool] = []
    for prediction in predictions:
        row_id = prediction.get("id")
        if row_id not in expected:
            raise ValueError(f"prediction id is not in {split}: {row_id}")
        if row_id in seen:
            raise ValueError(f"duplicate prediction id: {row_id}")
        seen.add(row_id)
        row = expected[row_id]
        choice = prediction.get("choice")
        if choice in CHOICES:
            outcome = candidate(row, choice)
            collisions += int(prediction.get("collision", outcome["collision"]))
            food_reached += int(prediction.get("food_reached", outcome["food_reached"]))
            progress.append(int(prediction.get("progress_delta", outcome["progress_delta"])))
            correct += int(choice == row["teacher_choice"])
        else:
            progress.append(0)
        if "loop_detected" in prediction:
            loop_values.append(bool(prediction["loop_detected"]))
    if seen != set(expected):
        missing = sorted(set(expected) - seen)
        raise ValueError(f"predictions missing {split} rows: {missing}")
    total = len(expected)
    return {
        "rows": total,
        "choice_accuracy": correct / total,
        "teacher_agreement": correct / total,
        "collision_rate": collisions / total,
        "food_reached_rate": food_reached / total,
        "mean_progress_delta": sum(progress) / total,
        "loop_rate": (sum(loop_values) / len(loop_values)) if loop_values else None,
        "loop_rate_note": "requires trajectory predictions with loop_detected" if not loop_values else None,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fixture", type=Path, required=True)
    parser.add_argument("--predictions", type=Path)
    parser.add_argument("--baseline-straight", action="store_true")
    parser.add_argument("--split", default="validation", choices=("train", "validation"))
    args = parser.parse_args()

    rows = load_jsonl(args.fixture)
    validate_fixture(rows)
    result: dict[str, Any] = {
        "fixture": str(args.fixture),
        "rows": len(rows),
        "split_counts": dict(Counter(row["split"] for row in rows)),
        "teacher_label_counts": dict(Counter(row["teacher_choice"] for row in rows)),
        "evaluated_split": args.split,
        "evaluations": {},
        "training_status": "not run; this tool only validates fixtures and scores predictions",
    }
    if args.baseline_straight:
        rows_in_split = [row for row in rows if row["split"] == args.split]
        predictions = [{"id": row["id"], "choice": "straight"} for row in rows_in_split]
        result["evaluations"]["baseline_straight"] = metric_report(rows, predictions, args.split)
    if args.predictions:
        predictions = load_jsonl(args.predictions)
        by_model: dict[str, list[dict[str, Any]]] = {}
        for prediction in predictions:
            model = prediction.get("model", "unspecified")
            by_model.setdefault(model, []).append(prediction)
        for model, model_predictions in sorted(by_model.items()):
            result["evaluations"][model] = metric_report(rows, model_predictions, args.split)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
