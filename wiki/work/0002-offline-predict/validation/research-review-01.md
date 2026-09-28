# Research review — round 01

- Work item: 0002-offline-predict
- Reviewed artifact: `wiki/work/0002-offline-predict/00-research.md`
- Reviewer: research-validator
- Date: 2026-09-27

## Verdict

**FAIL**

A cited source (the NandhaKishorM/laya `main` recursive git tree) contradicts the artifact’s claim that official Laya ships no in-tree ONNX exporter, so a constraint planners will treat as fact is unsupported.

## Verification performed

Checked the research question against `00-research.md`, then opened cited Hub APIs, ORT/pub.dev pages, GOAL, and the upstream git tree the artifact names as evidence for the exporter claim.

```text
$ curl -sL "https://api.github.com/repos/NandhaKishorM/laya/git/trees/main?recursive=1" \
  | python3 -c "
import sys,json
paths=[x['path'] for x in json.load(sys.stdin).get('tree',[])]
hits=[p for p in paths if 'export_onnx' in p]
print('export_onnx paths:')
for p in hits: print(' ', p)
print('count', len(hits))
assert 'scripts/export_onnx.py' in paths
print('ASSERT_OK: scripts/export_onnx.py present')
"
export_onnx paths:
  laya-ts/scripts/export_onnx.py
  scripts/export_onnx.py
  tests/test_export_onnx_safety.py
count 3
ASSERT_OK: scripts/export_onnx.py present

$ curl -sL "https://raw.githubusercontent.com/NandhaKishorM/laya/main/scripts/export_onnx.py" \
  | rg -n "input_names|output_names|torch.onnx.export|dynamo"
43:    input_names = [
51:    output_names = ["logits", "act_logits"]
63:    torch.onnx.export(
70:        input_names=input_names
71:        output_names=output_names
```

Official `scripts/export_onnx.py` exports the same five inputs and `logits` / `act_logits` outputs that `ONNXAgent._infer` consumes (verified against `https://raw.githubusercontent.com/NandhaKishorM/laya/main/laya/onnx_agent.py`).

Spot-checks that did support the artifact (not findings):

```text
HF API safetensors.total: laya=421293830, laya-multilingual=321908998, laya-typed-decisions=421293830
HF tree sizes: model.safetensors=842609210; multilingual/=643835514 + tokenizer.json=34363188;
  typed-decisions/model.safetensors=842609220
mariojcr ONNX: english/laya.onnx=1688711336; multilingual/laya-multilingual.onnx=1290466290
pyproject.toml: onnx = ["onnx", "onnxruntime"] present
cardData.license apache-2.0 on all three Hub model ids
flutter_onnxruntime pub.dev: ORT 1.23.0; CPU Inference ✅ on Android/iOS/Linux/macOS/Windows/Web
rl_agent_config max_len: english 512, multilingual 1024, typed-decisions 1024
typed-decisions README benchmark: 0.766 vs 0.362 / 0.342
```

## Per-criterion results

Research review — acceptance-criteria table not applicable.

| Criterion | Result | Evidence (file:line) | Negative case exercised |
|---|---|---|---|
| n/a | n/a | research artifact review, not impl | n/a |

## Findings

### F-001 — Official tree does ship `export_onnx.py`; cited tree evidence is wrong

- Severity: BLOCKER
- Location: `wiki/work/0002-offline-predict/00-research.md:61`
- Criterion affected: none
- Observation: The finding claims the NandhaKishorM/laya `main` tree includes `laya/onnx_agent.py` and “no `export_onnx.py` among listed paths,” and that “the runnable export that matches `ONNXAgent`’s I/O lives in community `mariojcr/laya-onnx`.” The same recursive tree URL the streams cite lists `scripts/export_onnx.py`, `laya-ts/scripts/export_onnx.py`, and `tests/test_export_onnx_safety.py`. The official `scripts/export_onnx.py` calls `torch.onnx.export` on `agent.model` with input names `input_ids`, `attention_mask`, `marker_pos`, `marker_mask`, `qtype` and outputs `logits`, `act_logits` — the `ONNXAgent` contract. The repeated constraint at `00-research.md:143` (“Official Laya does not currently ship `export_onnx.py` in-tree”) restates the same unsupported claim. Community dynamo exports remain real; they are not the only matching exporter.
- Why it matters: A plan built on this research will treat first-party export as absent and force a community-only or reinvented export path, which is a false delivery constraint on the chosen ONNX runtime path.

## Recurrence check

- Previous round: none — first round
- Recurring findings: none
- Oscillating: no

## Routing

| Finding | Belongs to phase |
|---|---|
| F-001 | research |
