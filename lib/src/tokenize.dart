import 'dart:convert';
import 'dart:typed_data';

import 'package:hf_tokenizers/hf_tokenizers.dart';

import 'answers.dart';

/// Encodes text the way upstream `encode_text` does for sequence building.
abstract interface class TextEncoder {
  /// Token ids for [text]. When [maxLength] is set, keep the first N ids.
  List<int> encode(
    String text, {
    bool addSpecialTokens = false,
    int? maxLength,
  });

  /// `[CLS]` / `<bos>` id.
  int get clsTokenId;

  /// `[SEP]` / `<eos>` id.
  int get sepTokenId;

  /// `[MASK]` / `<mask>` id.
  int get maskTokenId;

  /// Pad token id used by collation.
  int get padTokenId;

  /// Mask token string replaced with a space in prompts (upstream).
  String get maskToken;
}

/// HuggingFace `tokenizer.json` encoder via the Rust tokenizers crate.
final class HfTextEncoder implements TextEncoder {
  /// Loads special-token ids from an already-parsed [tokenizer].
  HfTextEncoder(this._tokenizer)
    : clsTokenId = _requireId(_tokenizer, '<bos>'),
      sepTokenId = _requireId(_tokenizer, '<eos>'),
      maskTokenId = _requireId(_tokenizer, '<mask>'),
      padTokenId = _requireId(_tokenizer, '<pad>'),
      maskToken = '<mask>';

  /// Loads from a `tokenizer.json` path on disk.
  factory HfTextEncoder.fromFile(String path) {
    return HfTextEncoder(Tokenizer.fromFile(path));
  }

  /// Loads from raw `tokenizer.json` bytes.
  factory HfTextEncoder.fromBytes(List<int> bytes) {
    final Uint8List data = bytes is Uint8List
        ? bytes
        : Uint8List.fromList(bytes);
    return HfTextEncoder(Tokenizer.fromBytes(data));
  }

  final Tokenizer _tokenizer;

  @override
  final int clsTokenId;

  @override
  final int sepTokenId;

  @override
  final int maskTokenId;

  @override
  final int padTokenId;

  @override
  final String maskToken;

  static int _requireId(Tokenizer tok, String token) {
    final int? id = tok.tokenToId(token);
    if (id == null) {
      throw StateError('tokenizer.json missing special token $token');
    }
    return id;
  }

  @override
  List<int> encode(
    String text, {
    bool addSpecialTokens = false,
    int? maxLength,
  }) {
    final List<int> ids = _tokenizer.encode(
      text,
      addSpecialTokens: addSpecialTokens,
    );
    if (maxLength == null || ids.length <= maxLength) {
      return ids;
    }
    return ids.sublist(0, maxLength);
  }
}

/// Serialize state the way upstream `serialize_state` does.
///
/// Locked API: a [String] or a [Map] of [String] to [String].
String serializeState(Object state) {
  if (state is String) {
    return state;
  }
  if (state is Map) {
    return jsonEncode(state);
  }
  throw ArgumentError('state must be a String or a Map of String to String');
}

String _renderCriterion(Object? value) {
  if (value is String) {
    return value;
  }
  return jsonEncode(value);
}

int _maxInt(int a, int b) => a > b ? a : b;

/// Render option texts in label-index order (upstream `render_options`).
List<String> renderOptions(LayaQuestion q) {
  switch (q.type) {
    case LayaQuestionType.choice:
      final Object? crit = q.criteria;
      if (crit is! Map) {
        throw ArgumentError('choice criteria must be a map');
      }
      return <String>[
        for (final MapEntry<dynamic, dynamic> e in crit.entries)
          (e.value == null || e.value == '')
              ? '${e.key}'
              : '${e.key}: ${_renderCriterion(e.value)}',
      ];
    case LayaQuestionType.score:
      final Object? crit = q.criteria;
      if (crit is! List) {
        throw ArgumentError('score criteria must be a list');
      }
      return <String>[
        for (var i = 0; i < crit.length; i++)
          'level $i: ${_renderCriterion(crit[i])}',
      ];
    case LayaQuestionType.noul:
      final Map<dynamic, dynamic> crit = q.criteria is Map
          ? q.criteria as Map<dynamic, dynamic>
          : const {};
      final Object? falseCrit = crit['false'];
      final Object? trueCrit = crit['true'];
      return <String>[
        'false: ${falseCrit == null || falseCrit == '' ? 'no, the statement does not hold' : _renderCriterion(falseCrit)}',
        'true: ${trueCrit == null || trueCrit == '' ? 'yes, the statement holds' : _renderCriterion(trueCrit)}',
      ];
  }
}

/// One question's token ids and marker positions before collation.
final class SequenceItem {
  /// Creates a collatable item.
  const SequenceItem({
    required this.ids,
    required this.markers,
    required this.qtype,
  });

  /// Token id sequence.
  final List<int> ids;

  /// Marker positions (MASK indices) per option.
  final List<int> markers;

  /// Upstream qtype code.
  final int qtype;
}

/// Five ONNX agent input tensors for a batch of questions.
final class OnnxInputTensors {
  /// Creates the five named tensors.
  const OnnxInputTensors({
    required this.inputIds,
    required this.attentionMask,
    required this.markerPos,
    required this.markerMask,
    required this.qtype,
  });

  /// `input_ids` [n, L].
  final List<List<int>> inputIds;

  /// `attention_mask` [n, L].
  final List<List<int>> attentionMask;

  /// `marker_pos` [n, kmax].
  final List<List<int>> markerPos;

  /// `marker_mask` [n, kmax].
  final List<List<bool>> markerMask;

  /// `qtype` [n].
  final List<int> qtype;
}

/// Build one sequence: [CLS] instructions [SEP] [MASK] opt… [SEP] state [SEP].
(List<int> ids, List<int> markers) buildSequence({
  required TextEncoder tok,
  required Object state,
  required LayaQuestion q,
  int maxLen = 512,
  int headMaxLen = 192,
  bool truncateLeft = false,
  List<int>? stateIds,
}) {
  final String maskTok = tok.maskToken;
  final List<String> opts = renderOptions(q);
  final String ins = q.instructions.replaceAll(maskTok, ' ');
  List<int> headIds = tok.encode(
    '${q.type.name} question: $ins',
    addSpecialTokens: false,
  );
  final List<List<int>> optIds = <List<int>>[];
  for (final String opt in opts) {
    final List<int> optTokens = tok.encode(
      ' ${opt.replaceAll(maskTok, ' ')}',
      addSpecialTokens: false,
      maxLength: 48,
    );
    optIds.add(<int>[tok.maskTokenId, ...optTokens]);
  }
  var optBudget =
      headMaxLen - optIds.fold<int>(0, (int a, List<int> o) => a + o.length);
  if (optBudget < 16) {
    final int per = _maxInt(4, (headMaxLen - 16) ~/ _maxInt(1, optIds.length));
    for (var i = 0; i < optIds.length; i++) {
      if (optIds[i].length > per) {
        optIds[i] = optIds[i].sublist(0, per);
      }
    }
    optBudget =
        headMaxLen - optIds.fold<int>(0, (int a, List<int> o) => a + o.length);
  }
  final int headKeep = _maxInt(8, optBudget);
  if (headIds.length > headKeep) {
    headIds = headIds.sublist(0, headKeep);
  }
  final List<int> ids = <int>[tok.clsTokenId, ...headIds, tok.sepTokenId];
  final List<int> markers = <int>[];
  for (final List<int> o in optIds) {
    markers.add(ids.length);
    ids.addAll(o);
  }
  ids.add(tok.sepTokenId);
  final int room = _maxInt(0, maxLen - ids.length - 1);
  final List<int> resolvedStateIds =
      stateIds ??
      tok.encode(
        serializeState(state).replaceAll(maskTok, ' '),
        addSpecialTokens: false,
      );
  final List<int> st;
  if (truncateLeft) {
    final int start = _maxInt(0, resolvedStateIds.length - room);
    st = resolvedStateIds.sublist(start);
  } else {
    st = resolvedStateIds.length > room
        ? resolvedStateIds.sublist(0, room)
        : resolvedStateIds;
  }
  ids.addAll(st);
  ids.add(tok.sepTokenId);
  final List<int> clipped = ids.length > maxLen ? ids.sublist(0, maxLen) : ids;
  return (
    clipped,
    <int>[
      for (final int m in markers)
        if (m < maxLen) m,
    ],
  );
}

/// Collate sequence items into the five ONNX tensors (upstream `collate_items`).
OnnxInputTensors? collateItems(List<SequenceItem> items, int padId) {
  if (items.isEmpty) {
    return null;
  }
  final int n = items.length;
  final int L = items.map((SequenceItem it) => it.ids.length).reduce(_maxInt);
  final int kmax = items
      .map((SequenceItem it) => it.markers.length)
      .reduce(_maxInt);
  final List<List<int>> ids = List<List<int>>.generate(
    n,
    (_) => List<int>.filled(L, padId),
  );
  final List<List<int>> att = List<List<int>>.generate(
    n,
    (_) => List<int>.filled(L, 0),
  );
  final List<List<int>> mpos = List<List<int>>.generate(
    n,
    (_) => List<int>.filled(kmax, 0),
  );
  final List<List<bool>> mmask = List<List<bool>>.generate(
    n,
    (_) => List<bool>.filled(kmax, false),
  );
  final List<int> qtypes = <int>[];
  for (var i = 0; i < n; i++) {
    final SequenceItem it = items[i];
    for (var j = 0; j < it.ids.length; j++) {
      ids[i][j] = it.ids[j];
      att[i][j] = 1;
    }
    final int k = it.markers.length;
    for (var j = 0; j < k; j++) {
      mpos[i][j] = it.markers[j];
      mmask[i][j] = true;
    }
    qtypes.add(it.qtype);
  }
  return OnnxInputTensors(
    inputIds: ids,
    attentionMask: att,
    markerPos: mpos,
    markerMask: mmask,
    qtype: qtypes,
  );
}

/// Tokenize one state and a question map into the five ONNX input tensors.
///
/// Mirrors `ONNXAgent._infer` tokenization and collation. An empty question
/// map yields null (no tensors), matching upstream's empty-answers path.
OnnxInputTensors? tokenizeForOnnx({
  required TextEncoder tok,
  required Object state,
  required Map<String, LayaQuestion> questions,
  int maxLen = 512,
  int headMaxLen = 192,
}) {
  if (questions.isEmpty) {
    return null;
  }
  final bool truncateLeft = state is List;
  final List<int> stateIds = tok.encode(
    serializeState(state).replaceAll(tok.maskToken, ' '),
    addSpecialTokens: false,
  );
  final List<SequenceItem> items = <SequenceItem>[];
  for (final LayaQuestion q in questions.values) {
    final (List<int> seq, List<int> markers) = buildSequence(
      tok: tok,
      state: state,
      q: q,
      maxLen: maxLen,
      headMaxLen: headMaxLen,
      truncateLeft: truncateLeft,
      stateIds: stateIds,
    );
    final List<String> opts = renderOptions(q);
    if (markers.length != opts.length) {
      throw StateError(
        'question ${q.id} options exceed head_max_len=$headMaxLen',
      );
    }
    items.add(SequenceItem(ids: seq, markers: markers, qtype: q.qtypeCode));
  }
  return collateItems(items, tok.padTokenId);
}
