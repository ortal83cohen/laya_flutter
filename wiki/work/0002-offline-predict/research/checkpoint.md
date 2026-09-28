# Research: First offline Laya checkpoint for Flutter

## Question

Which Laya checkpoint, or which set, should the first offline Flutter library download and run so a caller can get choice, score, and noul answers on a phone?

## Answer

Download and run `convaiinnovations/laya-multilingual` first. One checkpoint is enough for offline `choice`, `score`, and `noul` on a phone: it is the smallest published weight file of the three, keeps the longer default context and 100+ language coverage that the English root does not, and still answers short English states such as Snake. Do not make all three checkpoints the first-slice download. A later Router-style path that optionally adds English (and only then typed-decisions) is recommended, not required for the first download.

## Findings

### Goal and closed assumptions fix the job, not the Hub id

- Claim: The product needs a one-time Hugging Face download, then offline typed decisions that return choice, score, and noul with argmax parity to Python on a frozen fixture set. Android and iOS are required. Checkpoint choice is left to research, with a preference for the full offline feature set when that set fits on device. Snake is a short English `choice` example and must not by itself define the library's checkpoint set.
- Evidence: Outcome, boundaries, closed assumptions, and SC-001 / SC-002 / SC-004 / SC-005 in the product goal.
- Source: `wiki/product/GOAL.md` lines 13–35 and 39–45.

### Upstream ships three checkpoints with the same decision primitives

- Claim: Laya publishes three checkpoints. Upstream documents every one as a non-autoregressive decision model that answers typed `choice`, `score`, and `noul` questions in a single forward pass. The Python `Router` picks among them per request; typed-decisions is not an automatic default unless `auto_task_detection=True`.
- Evidence: Checkpoint table and quickstart in the GitHub README; Hub family card; typed-decisions card stating Router will not select it automatically without `auto_task_detection=True`.
- Source: `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md` (checkpoint table near "Three checkpoints, and a `Router`"); `https://huggingface.co/convaiinnovations/laya` (family table and Route Mode quickstart); `https://huggingface.co/convaiinnovations/laya-typed-decisions/raw/main/README.md` (Quickstart / Router note). Consulted 2026-09-27.

### Published sizes, params, and context differ by checkpoint

- Claim: Exact Hub file sizes and parameter totals for the three checkpoints, as returned by the Hugging Face tree and model APIs on 2026-09-27, are:

| Checkpoint | Hub id / path | Params (HF `safetensors.total`) | `model.safetensors` bytes | Tokenizer `tokenizer.json` bytes | Default `max_len` in `rl_agent_config.json` | Upstream context summary |
|---|---|---|---|---|---|---|
| English | `convaiinnovations/laya` (repo root) | 421,293,830 | 842,609,210 (~803.6 MiB) | 3,583,228 (~3.4 MiB) | 512 | ModernBERT-large, context 512 |
| Multilingual | `convaiinnovations/laya-multilingual` (also `laya` subfolder `multilingual/`) | 321,908,998 | 643,835,514 (~614.0 MiB) | 34,363,188 (~32.8 MiB) | 1024 | mmBERT-base, 1024 (up to 8,192) |
| Typed-decisions | `convaiinnovations/laya-typed-decisions` (also `laya` subfolder `typed-decisions/`) | 421,293,830 | 842,609,220 (~803.6 MiB) | 3,583,228 (~3.4 MiB) | 1024 | ModernBERT-large, context 1024 |

  Hub card prose rounds English load to "~808 MB" and multilingual to "~647 MB". Encoder configs for all three list `max_position_embeddings`: 8192; default request budgets come from each `rl_agent_config.json` `max_len` / `head_max_len`. Multilingual's card and README say pass `max_len=8192` for long documents.
- Evidence: Hugging Face recursive tree `size` / LFS size fields; model API `safetensors.total`; raw `rl_agent_config.json` and `encoder/config.json` for each path; Hub single-model mode prose.
- Source: `https://huggingface.co/api/models/convaiinnovations/laya/tree/main?recursive=true`; `https://huggingface.co/api/models/convaiinnovations/laya-multilingual/tree/main?recursive=true`; `https://huggingface.co/api/models/convaiinnovations/laya-typed-decisions/tree/main?recursive=true`; `https://huggingface.co/api/models/convaiinnovations/laya`; `https://huggingface.co/api/models/convaiinnovations/laya-multilingual`; `https://huggingface.co/api/models/convaiinnovations/laya-typed-decisions`; `https://huggingface.co/convaiinnovations/laya/raw/main/rl_agent_config.json`; `https://huggingface.co/convaiinnovations/laya/raw/main/multilingual/rl_agent_config.json`; `https://huggingface.co/convaiinnovations/laya/raw/main/typed-decisions/rl_agent_config.json`; `https://huggingface.co/convaiinnovations/laya/raw/main/encoder/config.json`; `https://huggingface.co/convaiinnovations/laya/raw/main/multilingual/encoder/config.json`; `https://huggingface.co/convaiinnovations/laya/raw/main/typed-decisions/encoder/config.json`; `https://huggingface.co/convaiinnovations/laya` (Single-Model Mode). Consulted 2026-09-27.

### No ONNX weight files are published next to the safetensors checkpoints

- Claim: The published siblings for the family root and the two standalone repos list `model.safetensors`, tokenizer files, encoder config, and `rl_agent_config.json`. No `.onnx` file appears in those listings. The Hub card still names an optional Python extra `laya[onnx]`, which is a runtime packaging note, not a published ONNX artifact on the Hub paths inspected here.
- Evidence: Sibling / tree listings for the three model ids; Installation line on the Hub card.
- Source: Hugging Face API responses cited above; `https://huggingface.co/convaiinnovations/laya`. Consulted 2026-09-27.

### Multilingual is the feature-rich general checkpoint that still fits one phone download

- Claim: Relative to English, multilingual is smaller on disk for weights, default-context-longer, faster on upstream T4 batch tables, and covers 100+ languages. Upstream still answers English through it; the multilingual card says it is weaker on English than the English checkpoint and tells callers to route rather than replace for English-optimised work. It documents a measured position bias on ordinal `score` (including English) and advises using the English checkpoint for English `score` questions when quality of that primitive matters.
- Evidence: Multilingual model card architecture, limits, speed table, and "use this checkpoint for anything that is not English"; family routing benchmark table on the Hub card.
- Source: `https://huggingface.co/convaiinnovations/laya-multilingual/raw/main/README.md`; `https://huggingface.co/convaiinnovations/laya`. Consulted 2026-09-27.

### English is the Hub default for English text, not a larger feature set

- Claim: English (`ModernBERT-large`, 421M, default 512 context) is what the Router selects for Latin-script English and is stronger on upstream English suites (for example MASSIVE English intent 0.783 vs 0.657 multilingual; XNLI English 0.860 vs 0.843). It collapses outside English. It does not add decision primitives beyond choice / score / noul. Its weight file is larger than multilingual's.
- Evidence: Family routing evidence table; Honest Limits "English only on root"; architecture section.
- Source: `https://huggingface.co/convaiinnovations/laya`; `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md`. Consulted 2026-09-27.

### Typed-decisions is a specialist fine-tune, not a new primitive set

- Claim: Typed-decisions keeps the same ModernBERT-large class size as English (421M params, ~842.6 MB weights) with default context 1024. It is fine-tuned for four workflows (invoice processing, security incidents, customer service, agent-trace observability) and reaches 0.766 accuracy on that benchmark versus 0.362 / 0.342 for the base English and multilingual checkpoints. Its card warns it may behave like base English or worse outside those workflows, is English-only, and is not the silent Router default.
- Evidence: Typed-decisions README benchmark and Limits sections; family typed-decisions comparison table.
- Source: `https://huggingface.co/convaiinnovations/laya-typed-decisions/raw/main/README.md`; `https://huggingface.co/convaiinnovations/laya`. Consulted 2026-09-27.

### Shipping more than one checkpoint on a phone is storage-realistic; keeping all three hot is not the upstream default

- Claim: Weight-plus-tokenizer totals for one copy of each checkpoint are about 846 MB (English), 678 MB (multilingual), and 846 MB (typed-decisions). All three models and tokenizers sum to about 2.37 GB. The Hub card states the lazy `Router()` keeps two checkpoints resident (`english` and `multilingual`), that a single-language deployment never builds the second, and that `max_loaded=1` reloads on every switch (median reload quoted as 7.4 s CPU / 10.3 s T4). Therefore: one checkpoint on disk and in memory matches the first phone download; two on disk (english + multilingual) matches upstream's automatic pair and is a realistic optional expansion; requiring all three as the first download adds ~846 MB for a specialist that Router does not auto-select, and keeping three hot is an explicit `max_loaded=3` / preload choice, not the default.
- Evidence: Byte sizes from the tree API; Production Preload & Memory section on the Hub card.
- Source: Hugging Face tree APIs above; `https://huggingface.co/convaiinnovations/laya` (Production Preload & Memory). Consulted 2026-09-27.
- Claim: [UNVERIFIED: peak RAM and wall-clock latency for any of these checkpoints under a mobile Flutter runtime on specific Android or iOS devices.] File sizes and server/T4 numbers do not substitute for on-device measurement.

### Apache-2.0 weights match the package licence assumption

- Claim: Hub cards for all three checkpoints declare `license: apache-2.0`. The product goal already closes that the package code is Apache-2.0, the same licence as the Laya weights.
- Evidence: Model card YAML / API `cardData.license`; goal closed assumptions.
- Source: Hugging Face API `cardData` for the three model ids; `wiki/product/GOAL.md` line 33. Consulted 2026-09-27.

### Router across checkpoints is the recommended long-term shape, not the first download

- Claim: Upstream recommends `Router` in production so English and non-English states hit different checkpoints, with typed-decisions only on explicit override (or `auto_task_detection=True`). For this Flutter library's first offline download, that Router behaviour should stay a recommendation: implement one multilingual local load that satisfies SC-001 / SC-002 / SC-004, then optionally download English (and only if needed typed-decisions) without making the three-way set mandatory for a phone to run.
- Evidence: Route Mode section and typed-decisions Router notes; goal preference for full features when appropriate on device.
- Source: `https://huggingface.co/convaiinnovations/laya`; `https://huggingface.co/convaiinnovations/laya-typed-decisions/raw/main/README.md`; `wiki/product/GOAL.md` line 35. Consulted 2026-09-27.

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|---|---|---|---|
| Multilingual only (`convaiinnovations/laya-multilingual`) | One HF download of mmBERT-base Laya; offline `predict` returns choice, score, and noul for any supported language including short English | ~644 MB weights + ~34 MB tokenizer on disk; default 1024 context (8192 opt-in); weaker English / English-score behaviour than the English checkpoint per upstream | **Chosen** for the first phone download. Smallest weights, broadest general features that still fit one device-held checkpoint, and enough for SC-001 primitives. Snake's English `choice` does not require a different first pick. |
| English only (`convaiinnovations/laya`) | One HF download of ModernBERT-large Laya; best upstream English routing target; same three primitives | ~843 MB weights + ~3.4 MB tokenizer; default 512 context; no usable non-English coverage | **Rejected as the first required download.** Strong for English-only apps and for English `score` quality, but it drops the multilingual / long-context features that still fit on a phone, and Snake alone must not force that narrower set. Remains the best optional second download for a Router-like English path. |
| All three (english + multilingual + typed-decisions) | Mirror full Python `Router(preload=True)` surface on device | ~2.37 GB weights+tokenizers; three builds if kept hot; typed-decisions unused unless explicitly selected | **Rejected as the first-slice set.** Storage can hold it on many phones, but typed-decisions adds no new primitives, is a four-workflow specialist, and is not the automatic Router default. Full three-way residency is an optional later expansion, not the first download. |

## Constraints discovered

- Weights stay out of the pub package; the app downloads from Hugging Face once, then runs offline (`wiki/product/GOAL.md`).
- Quality bar is argmax parity with Python on a frozen fixture set for choice label, score level, and noul side (`wiki/product/GOAL.md`). Fixtures must be generated against the same Hub checkpoint the library loads.
- Android and iOS are required; a phone must be able to hold the chosen checkpoint (`wiki/product/GOAL.md` and the research brief).
- All three published checkpoints expose `choice`, `score`, and `noul`; typed-decisions does not add a fourth primitive.
- Multilingual is smaller and broader, but upstream documents weaker English suites and English `score` position bias; English remains the better companion checkpoint if English score quality becomes a product requirement beyond parity fixtures.
- No `.onnx` weight files are published beside these Hub checkpoints (as of 2026-09-27 listings). Runtime packaging that mentions ONNX is out of scope for this question.
- Upstream lazy Router keeps at most two checkpoints hot by default (`english` + `multilingual`).
- Licence of the published weights is Apache-2.0, matching the closed package-licence assumption.

## Unresolved

- [UNRESOLVED: measured peak RAM, load time, and per-step latency for `laya-multilingual` (and optional English) under the yet-to-be-chosen Flutter mobile runtime on representative Android and iOS devices.]
- [UNRESOLVED: whether the first frozen fixture set should include non-English states, which would strengthen multilingual as the parity anchor, or English-only states, which would make an English companion download more urgent for score quality.]
- [UNRESOLVED: whether any caller-facing product requirement will need the four typed-decisions workflows soon enough to justify a third on-device download.]

## Sources

- `wiki/product/GOAL.md`. Consulted 2026-09-27.
- `https://raw.githubusercontent.com/NandhaKishorM/laya/main/README.md`. Consulted 2026-09-27.
- `https://huggingface.co/convaiinnovations/laya` and `https://huggingface.co/api/models/convaiinnovations/laya` plus `.../tree/main?recursive=true` and raw `rl_agent_config.json` / `encoder/config.json` (root, `multilingual/`, `typed-decisions/`). Consulted 2026-09-27.
- `https://huggingface.co/convaiinnovations/laya-multilingual` (card, API, recursive tree, raw README). Consulted 2026-09-27.
- `https://huggingface.co/convaiinnovations/laya-typed-decisions` (card, API, recursive tree, raw README). Consulted 2026-09-27.
- `wiki/solutions/` does not exist; no prior solution cited.
