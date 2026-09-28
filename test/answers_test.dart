import 'package:flutter_test/flutter_test.dart';
import 'package:laya_flutter/src/answers.dart';
import 'package:laya_flutter/src/tokenize.dart';

void main() {
  const List<double> referenceTemperature = <double>[1.0, 1.0, 1.0];
  const List<double> wrongTemperature = <double>[5.0, 5.0, 5.0];

  final Map<String, LayaQuestion> questions = <String, LayaQuestion>{
    'color': LayaQuestion(
      id: 'color',
      type: LayaQuestionType.choice,
      instructions: 'Pick a color',
      criteria: <String, String>{
        'red': 'warm',
        'green': 'cool',
        'blue': 'cold',
      },
    ),
    'severity': LayaQuestion(
      id: 'severity',
      type: LayaQuestionType.score,
      instructions: 'Rate severity',
      criteria: <String>['low', 'medium', 'high'],
    ),
    'ok': LayaQuestion(
      id: 'ok',
      type: LayaQuestionType.noul,
      instructions: 'Is it ok?',
      criteria: <String, String>{'false': 'not ok', 'true': 'ok'},
    ),
  };

  // Known logits chosen so reference T=1.0 yields stable upstream-shaped answers.
  final Map<String, List<double>> logits = <String, List<double>>{
    'color': <double>[2.0, 0.5, 1.0],
    'severity': <double>[0.0, 1.0, 3.0],
    'ok': <double>[0.2, 1.5],
  };

  test('known logits become choice label, expected score, and noul side', () {
    final Map<String, LayaAnswer> answers = shapeAnswers(
      questions: questions,
      logitsById: logits,
      temperature: referenceTemperature,
    );

    expect(answers.containsKey('color'), isTrue);
    expect(answers['color']!.choice, 'red');
    expect(answers['color']!.probabilities['red'], 0.6285);
    expect(answers['color']!.probabilities['green'], 0.1402);
    expect(answers['color']!.probabilities['blue'], 0.2312);
    expect(answers['color']!.confidence, 0.1754);

    expect(answers['severity']!.score, 1.8018);
    expect(answers['severity']!.probabilities['0'], 0.042);
    expect(answers['severity']!.probabilities['1'], 0.1142);
    expect(answers['severity']!.probabilities['2'], 0.8438);
    expect(answers['severity']!.confidence, 0.5228);

    expect(answers['ok']!.noul, 0.7858);
    expect(answers['ok']!.side, 'true');
    expect(answers['ok']!.probabilities['false'], 0.2142);
    expect(answers['ok']!.probabilities['true'], 0.7858);
    expect(answers['ok']!.confidence, 0.7858);
  });

  test(
    'wrong temperature disagrees with reference temperature score level',
    () {
      final Map<String, LayaAnswer> reference = shapeAnswers(
        questions: questions,
        logitsById: logits,
        temperature: referenceTemperature,
      );
      final Map<String, LayaAnswer> wrong = shapeAnswers(
        questions: questions,
        logitsById: logits,
        temperature: wrongTemperature,
      );

      // Scalar temperature preserves choice argmax and noul side; the score
      // expected level (and its nearest integer) must move, or temperature is
      // not part of the shaping contract.
      expect(
        wrong['severity']!.score,
        isNot(equals(reference['severity']!.score)),
      );
      expect(
        wrong['severity']!.score!.round(),
        isNot(equals(reference['severity']!.score!.round())),
      );
      expect(reference['severity']!.score, 1.8018);
      expect(wrong['severity']!.score, 1.2033);
      expect(wrong['ok']!.noul, isNot(equals(reference['ok']!.noul)));
    },
  );

  test('shaping omits a question when it has no logits', () {
    final Map<String, LayaAnswer> answers = shapeAnswers(
      questions: questions,
      logitsById: <String, List<double>>{
        'color': <double>[2.0, 0.5, 1.0],
        'severity': <double>[],
      },
      temperature: referenceTemperature,
    );
    expect(answers.keys, <String>['color']);
  });

  test('empty question map yields no answers and no tensors', () {
    final Map<String, LayaAnswer> answers = shapeAnswers(
      questions: const <String, LayaQuestion>{},
      logitsById: logits,
      temperature: referenceTemperature,
    );
    expect(answers, isEmpty);

    final OnnxInputTensors? tensors = tokenizeForOnnx(
      tok: _FakeEncoder(),
      state: 'hello',
      questions: const <String, LayaQuestion>{},
    );
    expect(tensors, isNull);
  });

  test('tokenize packs one state and questions into five ONNX tensors', () {
    final OnnxInputTensors? tensors = tokenizeForOnnx(
      tok: _FakeEncoder(),
      state: 'short state',
      questions: questions,
      maxLen: 64,
      headMaxLen: 48,
    );
    expect(tensors, isNotNull);
    expect(tensors!.inputIds.length, 3);
    expect(tensors.attentionMask.length, 3);
    expect(tensors.markerPos.length, 3);
    expect(tensors.markerMask.length, 3);
    expect(tensors.qtype, <int>[0, 1, 2]);
    expect(tensors.markerMask[0].where((bool m) => m).length, 3);
    expect(tensors.markerMask[1].where((bool m) => m).length, 3);
    expect(tensors.markerMask[2].where((bool m) => m).length, 2);
    for (var r = 0; r < 3; r++) {
      expect(tensors.inputIds[r].first, 2); // cls / bos
      expect(tensors.attentionMask[r].contains(1), isTrue);
    }
  });
}

/// Minimal encoder so packing tests do not need a 34 MB tokenizer.json.
final class _FakeEncoder implements TextEncoder {
  @override
  int get clsTokenId => 2;

  @override
  int get sepTokenId => 1;

  @override
  int get maskTokenId => 4;

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
    // Deterministic stand-in ids derived from code units; not HF-parity.
    final List<int> ids = <int>[
      for (final int c in text.codeUnits) 100 + (c % 50),
    ];
    if (maxLength != null && ids.length > maxLength) {
      return ids.sublist(0, maxLength);
    }
    return ids;
  }
}
