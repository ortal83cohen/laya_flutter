#!/usr/bin/env python3
"""Evaluate a local Laya Snake checkpoint in complete, seeded source games.

Example (no network access or checkpoint download):
    python3 tool/snake_absolute_eval.py \
        --source-dir /path/to/SnakeGame_Laya \
        --model-dir /path/to/laya-snake --games 10

The source directory must be a clean checkout of Okbatti/SnakeGame_Laya at
a2971e0cc5838cf4ff211d1fdf968db06b064434. The model directory must be a
local copy of OwaisAli10/laya-snake at Hugging Face revision
21057b19696fb3e27c4f4c644e6cb872ed866486, including model.safetensors.
The evaluator verifies the source Git identity and the checkpoint file digests
published for that exact Hub revision. Hashing the weights can take a moment.

Default seeds 2_000_000_000.. are distinct from each other and far above the
pinned source's default training seeds (seed=0, then one seed per game) and its
published headless evaluation seeds (10_000..). Custom/unpublished training
seeds cannot be ruled out. Agreement is measured on decisions made during each
model-controlled game, not on independent held-out fixture rows.
The source game rules are used with evaluator-only adjustments: reverse moves
are applied literally, matching the example's collision semantics. The default
board is 40x40 like the example; use --size 15 for a board-size comparison with
published results. Source food placement uses Python's seeded RNG and selection
from free cells, while the example uses Dart RNG and rejection sampling.
Starvation is disabled here to match the example. The run still uses the source
game and is not a Flutter gameplay measurement.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import os
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any


SOURCE_COMMIT = "a2971e0cc5838cf4ff211d1fdf968db06b064434"
MODEL_REVISION = "21057b19696fb3e27c4f4c644e6cb872ed866486"
MODEL_ID = "OwaisAli10/laya-snake"
DEFAULT_SEED_START = 2_000_000_000
MIN_SEED_START = 1_000_000_000
SOURCE_FILES = ("snake/game.py", "snake/encode.py", "snake/teacher.py")
# Hub tree API at the pinned revision: Git blob OIDs for small files and LFS
# SHA-256 OIDs for large files. The files needed by laya.load are all pinned.
MODEL_FILES = {
    "model.safetensors": (643835514, "sha256", "4be8725b696f9fc1a8cf182e1e443e91b1b0675d0d7b7614fd5f4511b7f57e21"),
    "encoder/config.json": (1938, "git-blob-sha1", "0de0e2d30638873790cf962def52e2acf4db3eef"),
    "rl_agent_config.json": (1179, "git-blob-sha1", "2697b2e17d869e025e1f4700c2160743bb993e21"),
    "tokenizer/tokenizer.json": (34363188, "sha256", "609d8f4c067cd3950f88594c5a802616cea245823836ef5848ee4fc40aab5b6f"),
    "tokenizer/tokenizer_config.json": (524, "git-blob-sha1", "c255ac0c8cb34a37d066cd0dafe313fd769d27ae"),
}


def checked_source(source_dir: Path) -> None:
    if not source_dir.is_dir():
        raise ValueError(f"source directory does not exist: {source_dir}")
    missing = [name for name in SOURCE_FILES if not (source_dir / name).is_file()]
    if missing:
        raise ValueError(f"source directory lacks {', '.join(missing)}: {source_dir}")
    try:
        root = subprocess.run(
            ["git", "-C", str(source_dir), "rev-parse", "--show-toplevel"],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        commit = subprocess.run(
            ["git", "-C", str(source_dir), "rev-parse", "HEAD"],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        changes = subprocess.run(
            ["git", "-C", str(source_dir), "status", "--porcelain", "--", "snake"],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError) as error:
        raise ValueError("source directory must be a Git checkout of the pinned source") from error
    if Path(root).resolve() != source_dir.resolve():
        raise ValueError("source directory must be the Git checkout root")
    if commit != SOURCE_COMMIT:
        raise ValueError(f"source commit {commit} differs from required {SOURCE_COMMIT}")
    if changes:
        raise ValueError(f"pinned Snake source package has local changes: {changes}")


def checked_model(model_dir: Path) -> None:
    if not model_dir.is_dir():
        raise ValueError(f"model directory does not exist: {model_dir}")
    weights = model_dir / "model.safetensors"
    if not weights.is_file() or weights.stat().st_size == 0:
        raise ValueError(f"local checkpoint requires nonempty model.safetensors: {weights}")
    for name, (expected_size, digest_type, expected_digest) in MODEL_FILES.items():
        path = model_dir / name
        if not path.is_file():
            raise ValueError(f"pinned checkpoint file is missing: {path}")
        actual_size = path.stat().st_size
        if actual_size != expected_size:
            raise ValueError(f"pinned checkpoint file has wrong size: {path} ({actual_size} != {expected_size})")
        digest = hashlib.sha256() if digest_type == "sha256" else hashlib.sha1()
        if digest_type == "git-blob-sha1":
            digest.update(f"blob {actual_size}\0".encode("ascii"))
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        if digest.hexdigest() != expected_digest:
            raise ValueError(f"pinned checkpoint file digest differs: {path}")


def source_api(source_dir: Path) -> tuple[Any, Any, Any, Any, Any]:
    # The source checkout is deliberately explicit, verified and imported only
    # after preflight. Keep its engine, encoder, question and teacher together.
    sys.path.insert(0, str(source_dir))
    game_module = importlib.import_module("snake.game")
    encoder_module = importlib.import_module("snake.encode")
    teacher_module = importlib.import_module("snake.teacher")

    class LiteralMoveGame(game_module.Game):
        def resolve(self, move: str) -> str:
            # The example applies an absolute reverse into the neck literally.
            # Game.step and Game.collision both call resolve via next_cell.
            return move

    return (
        LiteralMoveGame,
        game_module.MOVES,
        encoder_module.encode_state,
        encoder_module.QUESTION,
        teacher_module.teacher_move,
    )


def fingerprint(game: Any) -> tuple[Any, ...]:
    return tuple(game.snake), game.heading, game.food


def play_game(
    *, seed: int, size: int, max_steps: int, agent: Any, game_class: Any,
    moves: Any, encode_state: Any, question: Any, teacher_move: Any,
) -> dict[str, Any]:
    game = game_class(size, size, seed=seed)
    game.starve_limit = max_steps + 1
    visited = {fingerprint(game)}
    agreement = food_reached = collisions = reverse_choices = 0
    loop_detected = False
    reverse = {"up": "down", "down": "up", "left": "right", "right": "left"}
    while not game.done and game.steps < max_steps:
        state = encode_state(game)
        teacher = teacher_move(game)
        answer = agent.predict(state, question)["answers"]["move"]
        raw_move = answer["choice"]
        if raw_move not in moves:
            raise ValueError(f"seed {seed}, step {game.steps}: invalid model move {raw_move!r}")
        agreement += raw_move == teacher
        reverse_choices += raw_move == reverse[game.heading]
        before_score = game.score
        game.step(raw_move)
        food_reached += game.score - before_score
        collisions += game.death_cause in ("wall", "self")
        if not game.done:
            key = fingerprint(game)
            loop_detected |= key in visited
            visited.add(key)
    return {
        "seed": seed,
        "steps": game.steps,
        "teacher_agreements": agreement,
        "teacher_agreement_rate": agreement / game.steps if game.steps else None,
        "food_reached": food_reached,
        "reached_any_food": food_reached > 0,
        "collisions": collisions,
        "loop_detected": loop_detected,
        "loop_rate": float(loop_detected),
        "score": game.score,
        "reverse_choices": reverse_choices,
        "termination": game.death_cause if game.done else "max_steps",
    }


def report(games: list[dict[str, Any]], *, size: int, max_steps: int,
           seed_start: int, source_dir: Path, model_dir: Path) -> dict[str, Any]:
    steps = sum(game["steps"] for game in games)
    agreements = sum(game["teacher_agreements"] for game in games)
    food = sum(game["food_reached"] for game in games)
    return {
        "kind": "full_model_controlled_games",
        "model_id": MODEL_ID,
        "expected_model_revision": MODEL_REVISION,
        "local_model_dir": str(model_dir.resolve()),
        "checkpoint_file_digests_verified": True,
        "source_commit_verified": SOURCE_COMMIT,
        "source_dir": str(source_dir.resolve()),
        "hf_hub_offline": os.environ["HF_HUB_OFFLINE"],
        "seed_start": seed_start,
        "seed_note": "Outside pinned source default training and published eval seeds; unpublished custom seeds unverified",
        "board_size": size,
        "board_note": "Default 40x40 matches example dimensions; --size 15 matches the published board dimensions only",
        "max_steps_per_game": max_steps,
        "game_note": "Uses pinned Python source Game and its seeded free-cell food RNG; example uses Dart controller and rejection-sampled food. Reverse moves are literal and starvation is disabled here to match example. Source-game results are not Flutter gameplay results.",
        "action_note": "Raw choice passed to source Game.step with no safety mask; evaluator applies reverse moves literally, so reversing into the neck collides",
        "agreement_note": "Raw choices versus source teacher on model-visited game states; not held-out row accuracy",
        "loop_definition": "Exact snake, heading and food state repeated within a game",
        "games": games,
        "aggregate": {
            "game_count": len(games),
            "steps": steps,
            "teacher_agreements": agreements,
            "teacher_agreement_rate": agreements / steps if steps else None,
            "food_reached": food,
            "games_reaching_food": sum(game["reached_any_food"] for game in games),
            "food_reach_game_rate": sum(game["reached_any_food"] for game in games) / len(games),
            "collisions": sum(game["collisions"] for game in games),
            "collision_game_rate": sum(game["collisions"] > 0 for game in games) / len(games),
            "loop_games": sum(game["loop_detected"] for game in games),
            "loop_rate": sum(game["loop_detected"] for game in games) / len(games),
            "total_score": sum(game["score"] for game in games),
            "mean_score": sum(game["score"] for game in games) / len(games),
            "reverse_choices": sum(game["reverse_choices"] for game in games),
            "terminations": dict(Counter(game["termination"] for game in games)),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--model-dir", type=Path, required=True)
    parser.add_argument("--games", type=int, default=10)
    parser.add_argument("--size", type=int, default=40, help="board width and height (default: 40; use 15 for published board dimensions)")
    parser.add_argument("--max-steps", type=int, default=4000)
    parser.add_argument("--seed-start", type=int, default=DEFAULT_SEED_START)
    args = parser.parse_args()

    # Set before importing Laya or any Hugging Face dependency. No network or
    # implicit cache fallback is allowed by this evaluation command.
    os.environ["HF_HUB_OFFLINE"] = "1"
    os.environ["TRANSFORMERS_OFFLINE"] = "1"
    os.environ["HF_DATASETS_OFFLINE"] = "1"
    try:
        if args.games < 1 or args.size < 4 or args.max_steps < 1:
            raise ValueError("games must be positive, size at least 4, and max-steps positive")
        if args.seed_start < MIN_SEED_START:
            raise ValueError(f"seed-start must be at least {MIN_SEED_START} to avoid published source seeds")
        checked_model(args.model_dir)
        checked_source(args.source_dir)
        game_class, moves, encode_state, question, teacher_move = source_api(args.source_dir)
        import laya  # type: ignore[import-not-found]  # optional local checkpoint dependency
        agent = laya.load(str(args.model_dir.resolve()), device="cpu")
        games = [
            play_game(
                seed=args.seed_start + index, size=args.size, max_steps=args.max_steps,
                agent=agent, game_class=game_class, moves=moves,
                encode_state=encode_state, question=question, teacher_move=teacher_move,
            )
            for index in range(args.games)
        ]
        print(json.dumps(report(games, size=args.size, max_steps=args.max_steps,
                                seed_start=args.seed_start, source_dir=args.source_dir,
                                model_dir=args.model_dir), indent=2, sort_keys=True))
        return 0
    except (OSError, ValueError, KeyError, IndexError, AttributeError,
            ImportError, TypeError, RuntimeError) as error:
        print(f"EVALUATION_UNAVAILABLE: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
