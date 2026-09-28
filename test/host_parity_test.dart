import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Path to the committed parity fixture set (package root as cwd).
File parityFixtureFile() => File('test/fixtures/parity_fixtures.json');

/// Loads the committed fixture document.
Map<String, dynamic> loadParityFixtures() {
  final File file = parityFixtureFile();
  expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
  final Object? decoded = jsonDecode(file.readAsStringSync());
  expect(decoded, isA<Map<String, dynamic>>());
  return decoded! as Map<String, dynamic>;
}

/// Fixture list from the committed document.
List<Map<String, dynamic>> parityFixtureEntries(Map<String, dynamic> doc) {
  final Object? raw = doc['fixtures'];
  expect(raw, isA<List<dynamic>>());
  return <Map<String, dynamic>>[
    for (final Object? item in raw! as List<dynamic>)
      item! as Map<String, dynamic>,
  ];
}

/// True when the set has at least one English and one non-English state.
///
/// An English-only set is incomplete for U6 / AC-006.
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

/// Compares library choice label to the committed Python choice label.
bool choiceLabelMatches(String libraryChoice, String pythonChoiceLabel) {
  return libraryChoice == pythonChoiceLabel;
}

/// Compares library outputs to committed Python outputs for AC-004 fields.
bool matchesPythonOutputs({
  required String libraryChoice,
  required double libraryScore,
  required String libraryNoulSide,
  required String pythonChoiceLabel,
  required double pythonScoreLevel,
  required String pythonNoulSide,
}) {
  return libraryChoice == pythonChoiceLabel &&
      libraryScore == pythonScoreLevel &&
      libraryNoulSide == pythonNoulSide;
}

void main() {
  test('fixture set includes English and non-English with question maps', () {
    final Map<String, dynamic> doc = loadParityFixtures();
    final List<Map<String, dynamic>> fixtures = parityFixtureEntries(doc);

    expect(fixtures, isNotEmpty);
    expect(
      hasEnglishAndNonEnglish(fixtures),
      isTrue,
      reason: 'need at least one English and one non-English fixture',
    );

    for (final Map<String, dynamic> fx in fixtures) {
      expect(fx['state'], isA<String>());
      expect((fx['state'] as String).isNotEmpty, isTrue);
      expect(fx['questions'], isA<Map>(), reason: 'fixture ${fx['id']}');
      final Map<String, dynamic> questions =
          fx['questions']! as Map<String, dynamic>;
      expect(questions.containsKey('color'), isTrue);
      expect(questions.containsKey('severity'), isTrue);
      expect(questions.containsKey('ok'), isTrue);
      expect(fx['python'], isA<Map>());
      final Map<String, dynamic> python = fx['python']! as Map<String, dynamic>;
      expect(python['choice_label'], isA<String>());
      expect(python['score_level'], isA<num>());
      expect(python['noul_side'], isA<String>());
    }
  });

  test('English-only fixture set is rejected', () {
    final List<Map<String, dynamic>> englishOnly = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'only_en',
        'language': 'en',
        'state': 'short english state',
        'questions': <String, dynamic>{},
        'python': <String, dynamic>{
          'choice_label': 'red',
          'score_level': 0.0,
          'noul_side': 'true',
        },
      },
    ];
    expect(hasEnglishAndNonEnglish(englishOnly), isFalse);
  });

  test('tampered committed choice label fails label comparison', () {
    final Map<String, dynamic> doc = loadParityFixtures();
    final Map<String, dynamic> first = parityFixtureEntries(doc).first;
    final Map<String, dynamic> python = Map<String, dynamic>.from(
      first['python']! as Map<String, dynamic>,
    );
    final String original = python['choice_label']! as String;
    // Library side holds the true committed label; Python side is altered.
    final String tampered = 'tampered_$original';
    expect(choiceLabelMatches(original, tampered), isFalse);
    expect(
      matchesPythonOutputs(
        libraryChoice: original,
        libraryScore: (python['score_level'] as num).toDouble(),
        libraryNoulSide: python['noul_side']! as String,
        pythonChoiceLabel: tampered,
        pythonScoreLevel: (python['score_level'] as num).toDouble(),
        pythonNoulSide: python['noul_side']! as String,
      ),
      isFalse,
    );
  });
}
