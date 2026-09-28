// Public constructor parameters stay named session/encoder/... while fields are
// private; initializing formals would force private parameter names.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'answers.dart';
import 'onnx_graph.dart';
import 'tokenize.dart';

/// Loaded multilingual checkpoint ready for offline [predict].
final class LoadedRuntime {
  /// Creates a runtime backed by an open ONNX [session].
  LoadedRuntime({
    required OrtSession session,
    required TextEncoder encoder,
    required List<double> temperature,
    required Map<String, double> temperatureByOptions,
    required this.maxLen,
    required this.headMaxLen,
  }) : _session = session,
       _encoder = encoder,
       _temperature = temperature,
       _temperatureByOptions = temperatureByOptions;

  /// Test-only runtime that validates inputs without an ONNX session.
  ///
  /// Used by VM tests that must not call [OnnxRuntime.createSession].
  @visibleForTesting
  LoadedRuntime.validationOnly({
    TextEncoder? encoder,
    List<double> temperature = const <double>[1.0, 1.0, 1.0],
    Map<String, double> temperatureByOptions = const <String, double>{},
    this.maxLen = 512,
    this.headMaxLen = 192,
  }) : _session = null,
       _encoder = encoder ?? _UnusedEncoder(),
       _temperature = temperature,
       _temperatureByOptions = temperatureByOptions;

  final OrtSession? _session;
  final TextEncoder _encoder;
  final List<double> _temperature;
  final Map<String, double> _temperatureByOptions;

  /// Sequence max length from `rl_agent_config.json`.
  final int maxLen;

  /// Question-head max length from `rl_agent_config.json`.
  final int headMaxLen;

  /// Runs offline inference for one [state] and a non-empty question map or list.
  ///
  /// [state] is a [String] or a [Map] of [String] to [String].
  /// [questions] is a [Map] of id to [LayaQuestion], or a [List] of [LayaQuestion].
  Future<Map<String, LayaAnswer>> predict(
    Object state,
    Object questions,
  ) async {
    final Map<String, LayaQuestion> qmap = normalizeQuestions(questions);
    if (qmap.isEmpty) {
      throw ArgumentError('questions must not be empty');
    }
    final OrtSession? session = _session;
    if (session == null) {
      throw StateError('LoadedRuntime has no ONNX session');
    }

    final OnnxInputTensors? tensors = tokenizeForOnnx(
      tok: _encoder,
      state: state,
      questions: qmap,
      maxLen: maxLen,
      headMaxLen: headMaxLen,
    );
    if (tensors == null) {
      throw ArgumentError('questions must not be empty');
    }

    if (!matchesOnnxAgentContract(session.inputNames, session.outputNames)) {
      throw StateError(
        'ONNX session I/O does not match the upstream agent contract',
      );
    }

    final int n = tensors.inputIds.length;
    final int L = tensors.inputIds.first.length;
    final int kmax = tensors.markerPos.first.length;

    final List<OrtValue> owned = <OrtValue>[];
    try {
      final OrtValue inputIds = await OrtValue.fromList(
        Int64List.fromList(
          tensors.inputIds.expand((List<int> r) => r).toList(),
        ),
        <int>[n, L],
      );
      owned.add(inputIds);
      final OrtValue attentionMask = await OrtValue.fromList(
        Int64List.fromList(
          tensors.attentionMask.expand((List<int> r) => r).toList(),
        ),
        <int>[n, L],
      );
      owned.add(attentionMask);
      final OrtValue markerPos = await OrtValue.fromList(
        Int64List.fromList(
          tensors.markerPos.expand((List<int> r) => r).toList(),
        ),
        <int>[n, kmax],
      );
      owned.add(markerPos);
      final OrtValue markerMask = await OrtValue.fromList(
        tensors.markerMask.expand((List<bool> r) => r).toList(),
        <int>[n, kmax],
      );
      owned.add(markerMask);
      final OrtValue qtype = await OrtValue.fromList(
        Int64List.fromList(tensors.qtype),
        <int>[n],
      );
      owned.add(qtype);

      final Map<String, OrtValue> outputs = await session.run(
        <String, OrtValue>{
          onnxAgentInputNames[0]: inputIds,
          onnxAgentInputNames[1]: attentionMask,
          onnxAgentInputNames[2]: markerPos,
          onnxAgentInputNames[3]: markerMask,
          onnxAgentInputNames[4]: qtype,
        },
      );
      owned.addAll(outputs.values);

      final OrtValue logitsValue = outputs[onnxAgentOutputNames[0]]!;
      final List<dynamic> flatLogits = await logitsValue.asFlattenedList();
      final List<int> logitsShape = logitsValue.shape;
      final int logitWidth = logitsShape.length >= 2 ? logitsShape[1] : kmax;

      final Map<String, List<double>> logitsById = <String, List<double>>{};
      var row = 0;
      for (final MapEntry<String, LayaQuestion> entry in qmap.entries) {
        final int k = renderOptions(entry.value).length;
        final int base = row * logitWidth;
        logitsById[entry.key] = <double>[
          for (var j = 0; j < k; j++) (flatLogits[base + j] as num).toDouble(),
        ];
        row += 1;
      }

      return shapeAnswers(
        questions: qmap,
        logitsById: logitsById,
        temperature: _temperature,
        temperatureByOptions: _temperatureByOptions,
      );
    } finally {
      for (final OrtValue v in owned) {
        await v.dispose();
      }
    }
  }

  /// Releases the ONNX session when this runtime owns one.
  Future<void> close() async {
    await _session?.close();
  }
}

/// Normalizes a caller question map or list into id → question.
Map<String, LayaQuestion> normalizeQuestions(Object questions) {
  if (questions is Map<String, LayaQuestion>) {
    return Map<String, LayaQuestion>.from(questions);
  }
  if (questions is Map) {
    final Map<String, LayaQuestion> out = <String, LayaQuestion>{};
    for (final MapEntry<dynamic, dynamic> e in questions.entries) {
      final Object? value = e.value;
      if (value is! LayaQuestion) {
        throw ArgumentError('questions map values must be LayaQuestion');
      }
      out[e.key.toString()] = value;
    }
    return out;
  }
  if (questions is List<LayaQuestion>) {
    return <String, LayaQuestion>{
      for (final LayaQuestion q in questions) q.id: q,
    };
  }
  if (questions is List) {
    final Map<String, LayaQuestion> out = <String, LayaQuestion>{};
    for (final Object? item in questions) {
      if (item is! LayaQuestion) {
        throw ArgumentError('questions list entries must be LayaQuestion');
      }
      out[item.id] = item;
    }
    return out;
  }
  throw ArgumentError(
    'questions must be a Map of LayaQuestion or a List of LayaQuestion',
  );
}

/// Loads temperature and length settings from [rlAgentConfigFile].
({
  List<double> temperature,
  Map<String, double> temperatureByOptions,
  int maxLen,
  int headMaxLen,
})
readAgentConfig(File rlAgentConfigFile) {
  final Object? decoded = jsonDecode(rlAgentConfigFile.readAsStringSync());
  if (decoded is! Map) {
    throw StateError('rl_agent_config.json must be a JSON object');
  }
  final Object? rawTemp = decoded['temperature'];
  final List<double> temperature;
  if (rawTemp is List && rawTemp.length == 3) {
    temperature = <double>[
      for (final Object? t in rawTemp) (t as num).toDouble(),
    ];
  } else {
    temperature = <double>[1.0, 1.0, 1.0];
  }
  final Object? rawByOpts = decoded['temperature_by_options'];
  final Map<String, double> temperatureByOptions = <String, double>{};
  if (rawByOpts is Map) {
    for (final MapEntry<dynamic, dynamic> e in rawByOpts.entries) {
      temperatureByOptions[e.key.toString()] = (e.value as num).toDouble();
    }
  }
  final int maxLen = (decoded['max_len'] as num?)?.toInt() ?? 512;
  final int headMaxLen = (decoded['head_max_len'] as num?)?.toInt() ?? 192;
  return (
    temperature: temperature,
    temperatureByOptions: temperatureByOptions,
    maxLen: maxLen,
    headMaxLen: headMaxLen,
  );
}

/// Encoder stub for validation-only runtimes; never used for tokenization.
final class _UnusedEncoder implements TextEncoder {
  @override
  int get clsTokenId => 0;

  @override
  int get sepTokenId => 0;

  @override
  int get maskTokenId => 0;

  @override
  int get padTokenId => 0;

  @override
  String get maskToken => '<mask>';

  @override
  List<int> encode(
    String text, {
    bool addSpecialTokens = false,
    int? maxLength,
  }) {
    throw UnsupportedError('validation-only runtime has no tokenizer');
  }
}
