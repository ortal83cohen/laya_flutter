import 'dart:math' as math;

/// Upstream `QTYPES` codes: choice=0, score=1, noul=2.
const Map<String, int> qtypeCodes = <String, int>{
  'choice': 0,
  'score': 1,
  'noul': 2,
};

/// Upstream `TEMP_MIN`: temperatures below this are clamped up.
const double tempMin = 0.5;

/// Upstream `TEMP_MAX`: temperatures above this are clamped down.
const double tempMax = 5.0;

/// Question types accepted by predict and by the ONNX agent.
enum LayaQuestionType {
  /// Discrete option key at softmax argmax.
  choice,

  /// Expected level over ordered score criteria.
  score,

  /// Binary true/false; value is P(true).
  noul,
}

/// One typed question: id, type, instructions, and criteria.
final class LayaQuestion {
  /// Creates a question with a caller-chosen [id].
  const LayaQuestion({
    required this.id,
    required this.type,
    required this.instructions,
    required this.criteria,
  });

  /// Caller-chosen question id.
  final String id;

  /// choice, score, or noul.
  final LayaQuestionType type;

  /// Instruction text for the question head.
  final String instructions;

  /// Choice: label → description. Score: ordered level descriptions.
  /// Noul: optional map with false/true descriptions.
  final Object? criteria;

  /// Upstream qtype integer.
  int get qtypeCode => qtypeCodes[type.name]!;
}

/// Typed answer after temperature, softmax, and upstream shaping.
final class LayaAnswer {
  /// Choice answer: [choice] is the option key at argmax.
  LayaAnswer.choice({
    required this.choice,
    required this.probabilities,
    required this.confidence,
  }) : type = LayaQuestionType.choice,
       score = null,
       noul = null,
       side = null,
       legend = null;

  /// Score answer: [score] is the expected level.
  LayaAnswer.score({
    required this.score,
    required this.legend,
    required this.probabilities,
    required this.confidence,
  }) : type = LayaQuestionType.score,
       choice = null,
       noul = null,
       side = null;

  /// Noul answer: [noul] is P(true); [side] is the higher-probability slot.
  LayaAnswer.noul({
    required this.noul,
    required this.side,
    required this.probabilities,
    required this.confidence,
  }) : type = LayaQuestionType.noul,
       choice = null,
       score = null,
       legend = null;

  /// Answer type.
  final LayaQuestionType type;

  /// Chosen option key when [type] is choice.
  final String? choice;

  /// Expected level when [type] is score.
  final double? score;

  /// P(true) when [type] is noul.
  final double? noul;

  /// Higher-probability noul slot: `true` or `false`.
  final String? side;

  /// Score level legend (index → description), score answers only.
  final Map<String, String>? legend;

  /// Probability distribution used to form the answer.
  final Map<String, double> probabilities;

  /// Upstream `confidence` field (entropy form for choice/score; max side for noul).
  final double confidence;
}

/// Clamp a temperature the way upstream `clamp_temperature` does.
double clampTemperature(num? raw, {double lo = tempMin, double hi = tempMax}) {
  if (raw == null) {
    return 1.0;
  }
  final double t = raw.toDouble();
  if (t.isNaN || t.isInfinite) {
    return 1.0;
  }
  return math.min(hi, math.max(lo, t));
}

/// Upstream `temp_bucket(qtype, k)`.
String tempBucket(int qtype, int k) {
  final String size = k <= 2
      ? '2'
      : k <= 5
      ? '3-5'
      : k <= 10
      ? '6-10'
      : '11+';
  final String name = qtypeCodes.entries
      .firstWhere((MapEntry<String, int> e) => e.value == qtype)
      .key;
  return '$name:$size';
}

/// Upstream `confidence_from_probs`: 1 - H(p) / log(k).
double confidenceFromProbs(List<double> p, int k) {
  if (k < 2) {
    return 1.0;
  }
  final List<double> slice = p.take(k).toList();
  double ent = 0.0;
  for (final double x in slice) {
    ent -= x * math.log(math.max(x, 1e-12));
  }
  return _clip01(1.0 - ent / math.log(k));
}

/// Upstream `answer_confidence`: max(p).
double answerConfidence(List<double> p, int k) {
  if (k < 1) {
    return 1.0;
  }
  return _clip01(p.take(k).reduce(math.max));
}

double _clip01(double x) => math.min(1.0, math.max(0.0, x));

double _round4(double x) => (x * 10000).roundToDouble() / 10000;

/// Softmax after dividing logits by temperature (upstream ONNXAgent).
List<double> softmaxWithTemperature(List<double> logits, double temperature) {
  final double t = clampTemperature(temperature);
  final List<double> z = <double>[for (final double x in logits) x / t];
  final double maxZ = z.reduce(math.max);
  final List<double> exp = <double>[
    for (final double v in z) math.exp(v - maxZ),
  ];
  final double sum = exp.fold<double>(0.0, (double a, double b) => a + b);
  return <double>[for (final double e in exp) e / sum];
}

/// Resolve the temperature scale for one question (upstream bucket then qtype).
double resolveTemperature({
  required int qtype,
  required int optionCount,
  required List<double> temperature,
  Map<String, double> temperatureByOptions = const <String, double>{},
}) {
  final List<double> clamped = <double>[
    for (final double t in temperature) clampTemperature(t),
  ];
  final Map<String, double> byOpts = <String, double>{
    for (final MapEntry<String, double> e in temperatureByOptions.entries)
      e.key: clampTemperature(e.value),
  };
  final String bucket = tempBucket(qtype, optionCount);
  return byOpts[bucket] ?? clamped[qtype];
}

List<String> _choiceKeys(Object? criteria) {
  if (criteria is! Map) {
    throw ArgumentError('choice criteria must map labels to descriptions');
  }
  return <String>[for (final Object? k in criteria.keys) k.toString()];
}

List<String> _scoreLevels(Object? criteria) {
  if (criteria is! List) {
    throw ArgumentError('score criteria must be an ordered list');
  }
  return <String>[for (final Object? c in criteria) c.toString()];
}

/// Shape per-question logits into choice, score, and noul answers.
///
/// Mirrors `ONNXAgent._infer` post-processing. A question with no logits is
/// omitted (no invented answer). An empty [questions] map yields an empty map.
Map<String, LayaAnswer> shapeAnswers({
  required Map<String, LayaQuestion> questions,
  required Map<String, List<double>> logitsById,
  required List<double> temperature,
  Map<String, double> temperatureByOptions = const <String, double>{},
}) {
  if (temperature.length != 3) {
    throw ArgumentError('temperature must be a list of 3 floats');
  }
  final Map<String, LayaAnswer> answers = <String, LayaAnswer>{};
  for (final MapEntry<String, LayaQuestion> entry in questions.entries) {
    final String qid = entry.key;
    final LayaQuestion q = entry.value;
    final List<double>? logits = logitsById[qid];
    if (logits == null || logits.isEmpty) {
      continue;
    }
    final int k = logits.length;
    final double tScale = resolveTemperature(
      qtype: q.qtypeCode,
      optionCount: k,
      temperature: temperature,
      temperatureByOptions: temperatureByOptions,
    );
    final List<double> p = softmaxWithTemperature(logits, tScale);
    final double confScore = _round4(confidenceFromProbs(p, k));
    switch (q.type) {
      case LayaQuestionType.choice:
        final List<String> keys = _choiceKeys(q.criteria);
        if (keys.length != k) {
          throw ArgumentError('choice $qid: ${keys.length} keys but $k logits');
        }
        var best = 0;
        for (var i = 1; i < k; i++) {
          if (p[i] > p[best]) {
            best = i;
          }
        }
        answers[qid] = LayaAnswer.choice(
          choice: keys[best],
          probabilities: <String, double>{
            for (var i = 0; i < k; i++) keys[i]: _round4(p[i]),
          },
          confidence: confScore,
        );
      case LayaQuestionType.score:
        final List<String> levels = _scoreLevels(q.criteria);
        if (levels.length != k) {
          throw ArgumentError(
            'score $qid: ${levels.length} levels but $k logits',
          );
        }
        var expScore = 0.0;
        for (var i = 0; i < k; i++) {
          expScore += i * p[i];
        }
        answers[qid] = LayaAnswer.score(
          score: _round4(expScore),
          legend: <String, String>{for (var i = 0; i < k; i++) '$i': levels[i]},
          probabilities: <String, double>{
            for (var i = 0; i < k; i++) '$i': _round4(p[i]),
          },
          confidence: confScore,
        );
      case LayaQuestionType.noul:
        if (k != 2) {
          throw ArgumentError('noul $qid expects 2 logits, got $k');
        }
        final double pTrue = p[1];
        final double pFalse = p[0];
        // Higher-probability slot; ties follow argmax (first index → false).
        final String side = pTrue > pFalse ? 'true' : 'false';
        answers[qid] = LayaAnswer.noul(
          noul: _round4(pTrue),
          side: side,
          probabilities: <String, double>{
            'false': _round4(pFalse),
            'true': _round4(pTrue),
          },
          // Upstream ONNXAgent noul confidence is max(p_true, 1 - p_true).
          confidence: _round4(math.max(pTrue, 1.0 - pTrue)),
        );
    }
  }
  return answers;
}
