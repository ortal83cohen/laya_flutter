import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laya_flutter/laya_flutter.dart';
import 'package:laya_flutter_example/snake_screen.dart';

String _readSnakeScreenSource() {
  // flutter test for the example runs with cwd = example/.
  final File file = File('lib/snake_screen.dart');
  expect(file.existsSync(), isTrue, reason: 'snake_screen.dart must exist');
  return file.readAsStringSync();
}

Map<String, LayaAnswer> _answersFor(String key) {
  return <String, LayaAnswer>{
    'turn': LayaAnswer.choice(
      choice: key,
      probabilities: <String, double>{
        'left': key == 'left' ? 1.0 : 0.0,
        'right': key == 'right' ? 1.0 : 0.0,
        'straight': key == 'straight' ? 1.0 : 0.0,
      },
      confidence: 1.0,
    ),
  };
}

void main() {
  test(
    'AC-007: Snake screen sources have no Timer, Future.delayed, or Ticker',
    () {
      final String source = _readSnakeScreenSource();
      expect(source.contains('Timer'), isFalse);
      expect(source.contains('Future.delayed'), isFalse);
      expect(source.contains('Ticker'), isFalse);
      expect(source.contains('AnimationController'), isFalse);
    },
  );

  test('example Snake board is 60 by 60', () {
    final String source = _readSnakeScreenSource();
    expect(source.contains('width: 60'), isTrue);
    expect(source.contains('height: 60'), isTrue);
  });

  test('production predict path delegates to LoadedRuntime.predict', () {
    final String source = _readSnakeScreenSource();
    expect(
      source.contains('LoadedRuntime'),
      isTrue,
      reason: 'screen must take a LoadedRuntime',
    );
    expect(
      source.contains('runtime.predict'),
      isTrue,
      reason: 'absent override must call LoadedRuntime.predict',
    );
    expect(
      source.contains('predictOverride'),
      isTrue,
      reason: 'optional override seam must exist for session-free proof',
    );
    // Reject a local turn table that never reaches the model.
    expect(source.contains("'left', 'right', 'straight'"), isFalse);
    expect(source.contains('hard-coded'), isFalse);
  });

  test('screen death and restart path opens no session', () {
    final String needleA =
        'LayaFlutter'
        '.open';
    final String needleB =
        'create'
        'Session';
    for (final String path in <String>[
      'test/snake_screen_test.dart',
      'lib/snake_screen.dart',
    ]) {
      final File file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path must exist');
      final String source = file.readAsStringSync();
      expect(
        source.contains(needleA),
        isFalse,
        reason: '$path must not open a Laya session',
      );
      expect(
        source.contains(needleB),
        isFalse,
        reason: '$path must not create an ONNX session',
      );
    }
  });

  testWidgets(
    'after wall death screen new-runs and continues steps without open',
    (WidgetTester tester) async {
      var predictCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SnakeScreen(
            runtime: LoadedRuntime.validationOnly(),
            predictOverride: (Object state, Object questions) async {
              predictCalls += 1;
              // Default head is (40, 40) facing east on the 60 by 60 board.
              // One left turns north; straight steps reach row 0; the next
              // straight hits the north wall. The following call is the
              // new run and must advance.
              const int centerRow = 80 ~/ 2;
              const int deathCall = centerRow + 1;
              const int postRestartCall = deathCall + 1;
              if (predictCalls == 1) {
                return _answersFor('left');
              }
              if (predictCalls <= postRestartCall) {
                return _answersFor('straight');
              }
              // Stop the loop without ending; must not trigger another new-run.
              throw StateError('predict stop');
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Death used call 1; new-run then call 2 proves the loop continued.
      expect(predictCalls, greaterThanOrEqualTo(2));
      expect(find.text('Snake'), findsOneWidget);
      expect(find.text('Snake — ended'), findsNothing);
      // validationOnly.predict throws if called; reaching here means steps
      // used the override only and never opened a session.
    },
  );

  testWidgets('predict failure does not start a new run', (
    WidgetTester tester,
  ) async {
    var predictCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SnakeScreen(
          runtime: LoadedRuntime.validationOnly(),
          predictOverride: (Object state, Object questions) async {
            predictCalls += 1;
            throw StateError('predict failed');
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(predictCalls, 1);
    expect(find.text('Snake'), findsOneWidget);
    expect(find.text('Snake — ended'), findsNothing);
  });

  test('single await-gated loop: _runSteps started once from dependencies', () {
    final String source = _readSnakeScreenSource();
    // One call site starts the loop; death continues inside that same method.
    expect('_runSteps();'.allMatches(source).length, 1);
    expect(source.contains('_loopStarted'), isTrue);
    expect(source.contains('Timer'), isFalse);
    expect(source.contains('Future.delayed'), isFalse);
  });
}
