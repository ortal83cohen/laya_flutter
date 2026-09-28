import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:laya_flutter/laya_flutter.dart';

/// Host cache used by offline predict and this parity test.
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

/// Frozen fixture JSON (must match `test/fixtures/parity_fixtures.json`).
///
/// Embedded because the macOS integration_test app sandbox cannot read the
/// package tree; see `tool/freeze_fixtures.md`.
const String kParityFixturesJson = r'''
{
  "checkpoint": "convaiinnovations/laya-multilingual",
  "python_runtime": "laya.onnx_agent.ONNXAgent",
  "python_laya_version": "0.3.20",
  "fixtures": [
    {
      "id": "en_short",
      "language": "en",
      "state": "The light is warm and the room feels calm.",
      "questions": {
        "color": {
          "type": "choice",
          "instructions": "Pick the best matching color word",
          "criteria": {
            "red": "warm primary",
            "green": "cool primary",
            "blue": "cold primary"
          }
        },
        "severity": {
          "type": "score",
          "instructions": "Rate how severe the situation is",
          "criteria": [
            "low",
            "medium",
            "high"
          ]
        },
        "ok": {
          "type": "noul",
          "instructions": "Is the situation acceptable?",
          "criteria": {
            "false": "not acceptable",
            "true": "acceptable"
          }
        }
      },
      "python": {
        "choice_label": "green",
        "score_level": 0.0537,
        "noul_side": "true",
        "choice_question_id": "color",
        "score_question_id": "severity",
        "noul_question_id": "ok"
      }
    },
    {
      "id": "he_short",
      "language": "he",
      "state": "האור חם והחדר מרגיש רגוע.",
      "questions": {
        "color": {
          "type": "choice",
          "instructions": "Pick the best matching color word",
          "criteria": {
            "red": "warm primary",
            "green": "cool primary",
            "blue": "cold primary"
          }
        },
        "severity": {
          "type": "score",
          "instructions": "Rate how severe the situation is",
          "criteria": [
            "low",
            "medium",
            "high"
          ]
        },
        "ok": {
          "type": "noul",
          "instructions": "Is the situation acceptable?",
          "criteria": {
            "false": "not acceptable",
            "true": "acceptable"
          }
        }
      },
      "python": {
        "choice_label": "red",
        "score_level": 0.3417,
        "noul_side": "false",
        "choice_question_id": "color",
        "score_question_id": "severity",
        "noul_question_id": "ok"
      }
    }
  ]
}
''';

Map<String, dynamic> loadParityFixtures() {
  final Object? decoded = jsonDecode(kParityFixturesJson);
  expect(decoded, isA<Map<String, dynamic>>());
  return decoded! as Map<String, dynamic>;
}

List<Map<String, dynamic>> parityFixtureEntries(Map<String, dynamic> doc) {
  final Object? raw = doc['fixtures'];
  expect(raw, isA<List<dynamic>>());
  return <Map<String, dynamic>>[
    for (final Object? item in raw! as List<dynamic>)
      item! as Map<String, dynamic>,
  ];
}

bool hasEnglishAndNonEnglish(Iterable<Map<String, dynamic>> fixtures) {
  var hasEnglish = false;
  var hasNonEnglish = false;
  for (final Map<String, dynamic> fx in fixtures) {
    final String lang = (fx['language'] as String? ?? '').toLowerCase();
    if (lang == 'en' || lang.startsWith('en-')) {
      hasEnglish = true;
    } else if (lang.isNotEmpty) {
      hasNonEnglish = true;
    }
  }
  return hasEnglish && hasNonEnglish;
}

Map<String, LayaQuestion> questionsFromFixture(Map<String, dynamic> raw) {
  final Map<String, LayaQuestion> out = <String, LayaQuestion>{};
  for (final MapEntry<String, dynamic> e in raw.entries) {
    final Map<String, dynamic> q = e.value as Map<String, dynamic>;
    final String typeName = q['type']! as String;
    final LayaQuestionType type = LayaQuestionType.values.firstWhere(
      (LayaQuestionType t) => t.name == typeName,
    );
    Object? criteria = q['criteria'];
    if (type == LayaQuestionType.choice || type == LayaQuestionType.noul) {
      if (criteria is Map) {
        criteria = <String, String>{
          for (final MapEntry<dynamic, dynamic> c in criteria.entries)
            c.key.toString(): c.value.toString(),
        };
      }
    } else if (type == LayaQuestionType.score) {
      if (criteria is List) {
        criteria = <String>[for (final Object? c in criteria) c.toString()];
      }
    }
    out[e.key] = LayaQuestion(
      id: e.key,
      type: type,
      instructions: q['instructions']! as String,
      criteria: criteria,
    );
  }
  return out;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'host Dart predict matches committed Python outputs on every fixture',
    (WidgetTester tester) async {
      final Map<String, dynamic> doc = loadParityFixtures();
      final List<Map<String, dynamic>> fixtures = parityFixtureEntries(doc);
      expect(hasEnglishAndNonEnglish(fixtures), isTrue);

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

      for (final Map<String, dynamic> fx in fixtures) {
        final String id = fx['id']! as String;
        final Map<String, dynamic> python =
            fx['python']! as Map<String, dynamic>;
        final Map<String, LayaQuestion> questions = questionsFromFixture(
          fx['questions']! as Map<String, dynamic>,
        );

        final Map<String, LayaAnswer> answers = await runtime.predict(
          fx['state']!,
          questions,
        );

        final String choiceId = python['choice_question_id']! as String;
        final String scoreId = python['score_question_id']! as String;
        final String noulId = python['noul_question_id']! as String;

        expect(
          answers[choiceId]?.choice,
          python['choice_label'],
          reason: '$id choice label',
        );
        expect(
          answers[scoreId]?.score,
          (python['score_level'] as num).toDouble(),
          reason: '$id score level',
        );
        expect(
          answers[noulId]?.side,
          python['noul_side'],
          reason: '$id noul side',
        );
      }

      // Negative: altering a committed Python choice label must disagree.
      final Map<String, dynamic> first = fixtures.first;
      final Map<String, dynamic> python = Map<String, dynamic>.from(
        first['python']! as Map<String, dynamic>,
      );
      final String choiceId = python['choice_question_id']! as String;
      final Map<String, LayaQuestion> questions = questionsFromFixture(
        first['questions']! as Map<String, dynamic>,
      );
      final Map<String, LayaAnswer> answers = await runtime.predict(
        first['state']!,
        questions,
      );
      final String tampered = 'tampered_${python['choice_label']}';
      expect(
        answers[choiceId]?.choice == tampered,
        isFalse,
        reason: 'tampered Python choice label must not match library output',
      );
    },
  );
}
