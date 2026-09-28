import 'dart:io';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Expected I/O names for the multilingual Laya ONNX agent contract.
const _expectedInputs = <String>[
  'input_ids',
  'attention_mask',
  'marker_pos',
  'marker_mask',
  'qtype',
];
const _expectedOutputs = <String>['logits', 'act_logits'];

/// Resolves the on-disk multilingual graph path.
String resolveMultilingualOnnxPath() {
  final fromEnv = Platform.environment['LAYA_ONNX_PATH'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    throw StateError('HOME unset and LAYA_ONNX_PATH unset');
  }
  return '$home/.cache/laya_flutter/onnx/multilingual/laya-multilingual.onnx';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flutter_onnxruntime opens a session on the multilingual Laya graph', (tester) async {
    final path = resolveMultilingualOnnxPath();
    final file = File(path);
    expect(await file.exists(), isTrue, reason: 'graph missing at $path');
    expect(await file.length(), 1290466290, reason: 'unexpected graph byte size');

    final session = await OnnxRuntime().createSession(path);
    try {
      expect(session.inputNames, _expectedInputs);
      expect(session.outputNames, _expectedOutputs);
    } finally {
      await session.close();
    }
  });
}
