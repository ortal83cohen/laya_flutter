# Research: Run the public Snake checkpoint in the example

## Question

Which published Snake checkpoint and input contract can the runnable example use, and what prevents
a model run today?

## Answer

`OwaisAli10/laya-snake` is the best documented candidate for this experiment. Its game, encoder,
teacher and evaluation code are public, and its exact four-direction question is published. The
checkpoint is safetensors rather than ONNX and is not cached locally, so the example can be wired
and tested without claiming a tuned-model run.

## Findings

### Public checkpoint and provenance

- Claim: The pinned Hub revision `21057b19696fb3e27c4f4c644e6cb872ed866486` contains
  `model.safetensors`, encoder config, tokenizer, and `rl_agent_config.json`; it lists no ONNX
  graph. Its config says `jhu-clsp/mmBERT-base`, four absolute move keys, and a fitted choice
  temperature. The model card reports Apache-2.0, 114,476 train and 5,524 validation states, and a
  ten-game 15-by-15 result. Its metadata names `convaiinnovations/laya` while the config and card
  say multilingual; preserve this provenance discrepancy rather than assuming it is resolved.
- Evidence: The read-only Hub revision API returned SHA `21057b19696fb3e27c4f4c644e6cb872ed866486`
  and the seven sibling filenames listed above. The pinned `rl_agent_config.json` returned
  `encoder: jhu-clsp/mmBERT-base`, `snake.base: multilingual`,
  `snake.question.move.criteria: up/down/left/right`, and
  `temperature_by_options.choice:3-5: 0.540590375538304` on 2026-09-28. No weight file was fetched.
- Source: `https://huggingface.co/api/models/OwaisAli10/laya-snake`;
  `https://huggingface.co/OwaisAli10/laya-snake/resolve/21057b19696fb3e27c4f4c644e6cb872ed866486/rl_agent_config.json`;
  `https://huggingface.co/OwaisAli10/laya-snake`.

### Exact input and game contract

- Claim: The source revision `a2971e0cc5838cf4ff211d1fdf968db06b064434` asks one `move` choice with
  `up`, `down`, `left`, `right` and descriptions `move up`, `move down`, `move left`, `move right`.
  The state encoder emits heading, length, food displacement, and four candidate descriptions
  including wall/body or reachable room and tail reachability. Its teacher uses food BFS with a
  tail-reachability check and survival fallbacks. The public game ignores a reverse move; the local
  example will instead treat the model's absolute choice literally and record a collision when
  appropriate, consistent with the user's model-ownership direction.
- Evidence: GitHub API reported the source commit SHA and returned `snake/encode.py`,
  `snake/game.py`, `snake/teacher.py`, and `eval/eval_headless.py` on 2026-09-28. An explicit
  `contents/snake/encode.py?ref=a2971e0cc5838cf4ff211d1fdf968db06b064434` read returned blob SHA
  `117d0a7715da75ac1af03eaf600174c29fe2a1f2`. No source tree was cloned.
- Source: `https://github.com/Okbatti/SnakeGame_Laya/tree/a2971e0cc5838cf4ff211d1fdf968db06b064434`.

### Current local runtime

- Claim: `LayaFlutter.open` downloads a fixed base ONNX graph and companion files.
  `example/lib/snake_controller.dart` currently asks relative keys and uses a different state. The
  host has a cached base ONNX graph but neither public Snake checkpoint in the checked Hugging Face
  cache or repository. Thus no tuned-model result has been observed locally.
- Evidence: `lib/src/library.dart`, `lib/src/checkpoint_store.dart`,
  `example/lib/snake_controller.dart`, and local cache inventory on 2026-09-28.
- Source: repository paths named above.

### Export path

- Claim: Upstream `scripts/export_onnx.py` accepts `--model` and `--output`, loads an `Agent` on
  CPU, and exports the five-input, two-output graph expected by this library. Whether the pinned
  Snake checkpoint actually exports and matches Python on this host is [UNVERIFIED].
- Evidence: Upstream exporter source read on 2026-09-28.
- Source: `https://github.com/NandhaKishorM/laya/blob/main/scripts/export_onnx.py`;
  `lib/src/onnx_graph.dart`.

## Options considered

| Option                      | How it works                                                         | Cost                                                          | Why rejected / chosen                                                                |
|-----------------------------|----------------------------------------------------------------------|---------------------------------------------------------------|--------------------------------------------------------------------------------------|
| OwaisAli10/laya-snake       | Exact public encoder and question; export pinned safetensors to ONNX | Weight download and export remain                             | Chosen for reproducibility and full-game evidence                                    |
| madhavbiplov/laya-snake-mlx | MLX checkpoint with 600 held-out decisions                           | Input state generator and Flutter ONNX export need validation | Rejected as the first integration candidate; 600 decisions do not establish gameplay |
| Existing base ONNX          | Already cached and loads in Flutter                                  | Not Snake tuned and wrong prompt behavior                     | Useful as a separate baseline only                                                   |

## Constraints discovered

- The user has not authorized downloading the tuned weights. No weight or export can be treated as
  tested.
- The example's four absolute keys replace its current relative-key contract. The general library's
  typed decision API remains general.
- A matching exported graph, tokenizer, and calibration config must travel together; a build success
  alone does not prove model behavior.
- Published 15-by-15 game scores cannot be applied to the example's 40-by-40 board.

## Unresolved

- [UNRESOLVED: Does the pinned safetensors checkpoint export to ONNX and match the pinned Python checkpoint on frozen states?]
- [UNRESOLVED: Does the tuned model reach food and avoid collisions in the actual Flutter example on a supported device?]
- [UNRESOLVED: Are the published training games disjoint from every seed in a new independent evaluation?]

## Sources

- Public Hub model card, metadata and pinned config, consulted 2026-09-28.
- Public Snake source revision `a2971e0cc5838cf4ff211d1fdf968db06b064434`, consulted 2026-09-28.
- Upstream Laya ONNX exporter and current repository sources, consulted 2026-09-28.
