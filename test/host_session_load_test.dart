import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Resolves the on-disk multilingual graph path.
///
/// Prefers [LAYA_ONNX_PATH]. Falls back to the host cache under the user home
/// (never a path inside the package tree).
String? resolveMultilingualOnnxPath() {
  final fromEnv = Platform.environment['LAYA_ONNX_PATH'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    return null;
  }
  return '$home/.cache/laya_flutter/onnx/multilingual/laya-multilingual.onnx';
}

void main() {
  test('multilingual Laya ONNX graph is present with expected size', () async {
    final path = resolveMultilingualOnnxPath();
    expect(path, isNotNull, reason: 'LAYA_ONNX_PATH or HOME must be set');
    final file = File(path!);
    expect(await file.exists(), isTrue, reason: 'graph missing at $path');
    expect(
      await file.length(),
      1290466290,
      reason: 'unexpected graph byte size',
    );
  });
}
