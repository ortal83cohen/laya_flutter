import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:laya_flutter/laya_flutter.dart';

/// Host cache used by the session-load probe and this offline predict test.
Directory resolveHostCache() {
  final String? fromEnv = Platform.environment['LAYA_CACHE_DIR'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return Directory(fromEnv);
  }
  final String? home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    throw StateError('HOME unset and LAYA_CACHE_DIR unset');
  }
  return Directory('$home/.cache/laya_flutter');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'offline predict returns choice, score, and noul with probabilities',
    (WidgetTester tester) async {
      final Directory cache = resolveHostCache();
      late LoadedRuntime runtime;
      try {
        runtime = await LayaFlutter.open(cache);
      } catch (e, st) {
        fail('open failed (companions or graph unavailable): $e\n$st');
      }

      addTearDown(() async {
        await runtime.close();
      });

      final Map<String, LayaQuestion> questions = <String, LayaQuestion>{
        'color': LayaQuestion(
          id: 'color',
          type: LayaQuestionType.choice,
          instructions: 'Pick the best matching color word',
          criteria: <String, String>{
            'red': 'warm primary',
            'green': 'cool primary',
            'blue': 'cold primary',
          },
        ),
        'severity': LayaQuestion(
          id: 'severity',
          type: LayaQuestionType.score,
          instructions: 'Rate how severe the situation is',
          criteria: <String>['low', 'medium', 'high'],
        ),
        'ok': LayaQuestion(
          id: 'ok',
          type: LayaQuestionType.noul,
          instructions: 'Is the situation acceptable?',
          criteria: <String, String>{
            'false': 'not acceptable',
            'true': 'acceptable',
          },
        ),
      };

      final Map<String, LayaAnswer> answers = await runtime.predict(
        'The light is warm and the room feels calm.',
        questions,
      );

      expect(answers.containsKey('color'), isTrue);
      expect(answers['color']!.choice, isNotNull);
      expect(answers['color']!.probabilities, isNotEmpty);
      expect(answers['color']!.confidence, isNotNull);

      expect(answers.containsKey('severity'), isTrue);
      expect(answers['severity']!.score, isNotNull);
      expect(answers['severity']!.probabilities, isNotEmpty);
      expect(answers['severity']!.confidence, isNotNull);

      expect(answers.containsKey('ok'), isTrue);
      expect(answers['ok']!.noul, isNotNull);
      expect(answers['ok']!.side, isNotNull);
      expect(answers['ok']!.probabilities, isNotEmpty);
      expect(answers['ok']!.confidence, isNotNull);
    },
  );
}
