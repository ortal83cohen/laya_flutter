import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readSnakeScreenSource() {
  // flutter test for the example runs with cwd = example/.
  final File file = File('lib/snake_screen.dart');
  expect(file.existsSync(), isTrue, reason: 'snake_screen.dart must exist');
  return file.readAsStringSync();
}

void main() {
  test(
    'AC-005: Snake screen sources have no Timer, Future.delayed, or Ticker',
    () {
      final String source = _readSnakeScreenSource();
      expect(source.contains('Timer'), isFalse);
      expect(source.contains('Future.delayed'), isFalse);
      expect(source.contains('Ticker'), isFalse);
      expect(source.contains('AnimationController'), isFalse);
    },
  );

  test('example Snake board is 40 by 40', () {
    final String source = _readSnakeScreenSource();
    expect(source.contains('width: 40'), isTrue);
    expect(source.contains('height: 40'), isTrue);
  });

  test(
    'AC-009: Snake screen predict closure delegates to LoadedRuntime.predict',
    () {
      final String source = _readSnakeScreenSource();
      expect(
        source.contains('LoadedRuntime'),
        isTrue,
        reason: 'screen must take a LoadedRuntime',
      );
      expect(
        source.contains('runtime.predict'),
        isTrue,
        reason: 'predict closure must call LoadedRuntime.predict',
      );
      // Reject a local turn table that never reaches the model.
      expect(source.contains("'left', 'right', 'straight'"), isFalse);
      expect(source.contains('hard-coded'), isFalse);
    },
  );
}
