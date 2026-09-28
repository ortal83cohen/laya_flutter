/// Multilingual Laya ONNX graph contract and download artifact names.
///
/// Preferred producer: upstream `scripts/export_onnx.py` on NandhaKishorM/laya
/// main, which names the five inputs and the two outputs below.
///
/// Accepted runtime graph for this slice: the community file
/// `mariojcr/laya-onnx` → `multilingual/laya-multilingual.onnx`
/// (1_290_466_290 bytes). A host session already opened that file and exposed
/// exactly those input and output names. The community model card reports
/// logit parity with PyTorch (max |Δ logits| = 1.8e-6 under ONNX Runtime 1.29
/// CPU) for that graph class.
///
/// Official Hub `convaiinnovations/laya-multilingual` publishes safetensors,
/// not this ONNX file. Tokenizer and `rl_agent_config` still come from that
/// checkpoint id so decoding matches Python.
///
/// No ONNX graph binary is committed in this package; callers obtain the file
/// via download into a local cache.
library;

/// Hugging Face id for tokenizer and temperature / agent config companions.
const String multilingualCheckpointId = 'convaiinnovations/laya-multilingual';

/// Community Hub repo that publishes a matching multilingual ONNX graph.
const String multilingualOnnxRepoId = 'mariojcr/laya-onnx';

/// Relative path of the runtime graph inside [multilingualOnnxRepoId].
const String multilingualOnnxRelativePath =
    'multilingual/laya-multilingual.onnx';

/// Byte size of the accepted community multilingual ONNX file.
const int multilingualOnnxByteSize = 1290466290;

/// Preferred in-tree exporter path on NandhaKishorM/laya (not shipped here).
const String preferredOnnxExporterPath = 'scripts/export_onnx.py';

/// Upstream ONNX agent input names, in order.
const List<String> onnxAgentInputNames = <String>[
  'input_ids',
  'attention_mask',
  'marker_pos',
  'marker_mask',
  'qtype',
];

/// Upstream ONNX agent output names, in order.
const List<String> onnxAgentOutputNames = <String>['logits', 'act_logits'];

/// Companion files from [multilingualCheckpointId] for decode parity.
///
/// Later download code can share this list with the ONNX graph fetch.
const List<String> multilingualCompanionFileNames = <String>[
  'tokenizer.json',
  'tokenizer_config.json',
  'rl_agent_config.json',
];

/// Whether a session's input and output name lists match the ONNX agent contract.
///
/// Order matters. A graph with a different I/O layout is rejected even if it
/// claims Laya lineage.
bool matchesOnnxAgentContract(
  List<String> inputNames,
  List<String> outputNames,
) {
  return _nameListsEqual(inputNames, onnxAgentInputNames) &&
      _nameListsEqual(outputNames, onnxAgentOutputNames);
}

bool _nameListsEqual(List<String> actual, List<String> expected) {
  if (actual.length != expected.length) {
    return false;
  }
  for (var i = 0; i < expected.length; i++) {
    if (actual[i] != expected[i]) {
      return false;
    }
  }
  return true;
}
