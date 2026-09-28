# Freeze host parity fixtures

Procedure that produced `test/fixtures/parity_fixtures.json` for work item
`0002-offline-predict` unit U6 / AC-004 and AC-006.

## Environment

- Python venv outside the repo: `/tmp/laya_parity_venv`
- Packages: `laya==0.3.20` with `laya[onnx]` and `onnxruntime`
- Multilingual graph already on disk (do not re-download the 1290466290-byte file):
  `$HOME/.cache/laya_flutter/onnx/multilingual/laya-multilingual.onnx`
- Companions from `$HOME/.cache/laya_flutter`
  (`rl_agent_config.json`, `tokenizer.json`, `tokenizer_config.json`) staged as:

  `/tmp/laya_multilingual_checkpoint/rl_agent_config.json`
  `/tmp/laya_multilingual_checkpoint/tokenizer/tokenizer.json`
  `/tmp/laya_multilingual_checkpoint/tokenizer/tokenizer_config.json`

## Python run

Reference outputs come from a live `laya.onnx_agent.ONNXAgent` predict on
`convaiinnovations/laya-multilingual` companions plus the local multilingual
ONNX graph. They are not copied from Dart.

For each fixture state, call `agent.predict(state, questions)` with one choice,
one score, and one noul question (instructions and criteria included).

Committed fields per fixture:

- `choice_label` — Python answer `choice` for the choice question
- `score_level` — Python answer `score` for the score question
- `noul_side` — higher-probability noul slot from Python `noul` (P(true)):
  `true` when `noul > 0.5`, else `false`. Upstream ONNXAgent does not emit a
  `side` key; this follows the product contract for noul side.

## English-only sets

A fixture set with only English states is incomplete for this slice. The VM
test rejects such a set. Regeneration must keep at least one short English
state and one non-English state.

## Host integration test embed

The committed file is `test/fixtures/parity_fixtures.json`. The macOS
integration_test app runs sandboxed and cannot read the package tree, so
`integration_test/host_parity_test.dart` embeds the same JSON in
`kParityFixturesJson`. After regenerating the fixture file, paste the new JSON
into that constant so the host comparison stays in sync.

## Weights

Do not commit ONNX binaries, safetensors, or other checkpoint weights into the
package tree.
