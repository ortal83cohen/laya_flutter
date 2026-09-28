# Research review — round 02

- Work item: 0002-offline-predict
- Reviewed artifact: `wiki/work/0002-offline-predict/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-27

## Verdict

**PASS**

The round-01 exporter falsity is gone: cited upstream sources confirm `scripts/export_onnx.py` and the ONNXAgent I/O contract, and the remaining high-stakes Hub / ORT / checkpoint / API claims that were reopened check out. One leftover options-table phrasing is a NIT only.

## Verification performed

Re-opened the artifact and the sources it cites. Did not treat round 01 or author notes as proof of a fix.

```text
$ curl -sL "https://api.github.com/repos/NandhaKishorM/laya/git/trees/main?recursive=1" \
  | python3 -c "
import sys,json
paths=[x['path'] for x in json.load(sys.stdin).get('tree',[])]
hits=[p for p in paths if 'export_onnx' in p or 'onnx_agent' in p]
print('onnx-related paths:')
for p in hits: print(' ', p)
print('has scripts/export_onnx.py', 'scripts/export_onnx.py' in paths)
print('has laya/onnx_agent.py', 'laya/onnx_agent.py' in paths)
"
onnx-related paths:
  laya-ts/scripts/export_onnx.py
  laya/onnx_agent.py
  scripts/export_onnx.py
  tests/test_export_onnx_safety.py
has scripts/export_onnx.py True
has laya/onnx_agent.py True

$ curl -sL "https://raw.githubusercontent.com/NandhaKishorM/laya/main/scripts/export_onnx.py" \
  | rg -n "input_names|output_names|torch.onnx.export|dynamo"
43:    input_names = [
51:    output_names = ["logits", "act_logits"]
63:    torch.onnx.export(
70:        input_names=input_names,
71:        output_names=output_names,

$ curl -sL "https://huggingface.co/mariojcr/laya-onnx/raw/main/export_onnx.py" \
  | rg -n "dynamo|torch.onnx.export" | head -5
172:    # dynamo exporter: ...
179:    prog = torch.onnx.export(..., dynamo=True, ...)

HF API safetensors.total / license:
  laya=421293830 apache-2.0
  laya-multilingual=321908998 apache-2.0
  laya-typed-decisions=421293830 apache-2.0

HF tree sizes (official):
  laya model.safetensors=842609210; tokenizer/tokenizer.json=3583228; max_len=512
  laya-multilingual model.safetensors=643835514; tokenizer/tokenizer.json=34363188; max_len=1024
  laya-typed-decisions model.safetensors=842609220; tokenizer/tokenizer.json=3583228; max_len=1024
  encoder max_position_embeddings=8192 on all three
  no .onnx in official Hub trees for the three model ids

mariojcr ONNX: english/laya.onnx=1688711336; multilingual/laya-multilingual.onnx=1290466290
mariojcr README: max |Δ logits| = 1.8e-6; torch.onnx.export(dynamo=True)
receptron README: five inputs; max logit difference ≈ 1e-5; outputs include act_probs (artifact claims inputs only)
yehor README: type_ids / lengths / n_opts; int8 argmax 100% vs its fp32

pyproject.toml: onnx = ["onnx", "onnxruntime"] present
ONNXAgent._infer: choice=argmax, score=expected level, noul=p[1]; session.run(["logits","act_logits"], ...)
typed-decisions card: 0.766 vs 0.362 / 0.342; Router auto-select only with auto_task_detection=True
multilingual card: 100+ languages; weaker English; score position bias; default Router keeps english+multilingual
flutter_onnxruntime: wraps ORT 1.23.0; CPU Inference ✅ on Android/iOS/Linux/macOS/Windows/Web
local stub: empty LayaFlutter facade; pubspec has no license field ([UNVERIFIED] marker retained honestly)
```

Spot-checks that support the patched artifact (not findings): runtime/checkpoint/API conclusions answer the research question; options tables retain alternatives; unresolved list covers the open questions raised in the body (mobile RAM/latency, web practicality, quant parity, fixture language, Router lifecycle subset, hooks shape, shortlist embedder, system_one alias, presets packaging).

## Per-criterion results

Research review — acceptance-criteria table not applicable.

| Criterion | Result | Evidence (file:line) | Negative case exercised |
|---|---|---|---|
| n/a | n/a | research artifact review, not impl | n/a |

## Findings

### F-001 — Options row still labels the chosen export path as dynamo-only

- Severity: NIT
- Location: `wiki/work/0002-offline-predict/00-research.md:115`
- Criterion affected: none
- Observation: The chosen ONNX Runtime option’s “How it works” cell says export uses a “`torch.onnx` dynamo path.” The official in-tree exporter cited elsewhere in the same artifact (`scripts/export_onnx.py`) calls `torch.onnx.export` without `dynamo=True`. The community `mariojcr/laya-onnx` script is the one that sets `dynamo=True`. The finding at line 61 and the constraint at line 143 already separate those two exporters correctly; only this options-table cell conflates them.
- Why it matters: Style/precision only. It does not restore the round-01 false constraint that official export is absent, and it does not change the runtime, first-checkpoint, or API conclusions.

## Recurrence check

- Previous round: `wiki/work/0002-offline-predict/validation/research-review-01.md`
- Recurring findings: none — round-01 F-001 (official tree ships no `export_onnx.py` / community-only matching exporter) is not restated; the patched artifact at lines 61 and 143 claims the opposite, and reopened sources confirm that claim
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| F-001 | research (optional polish; does not block proceed) |
