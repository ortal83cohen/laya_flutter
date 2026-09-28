import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:laya_flutter/laya_flutter.dart';
import 'package:laya_flutter_example/snake_controller.dart';

void main() {
  group('classic board', () {
    test('default snake starts in the center, facing east', () {
      final SnakeController controller = SnakeController(
        width: 40,
        height: 40,
        predict: _unusedPredict,
        random: math.Random(0),
        initialFood: const GridCell(0, 0),
      );
      expect(controller.heading, CardinalHeading.east);
      expect(controller.snakeCells, const <GridCell>[
        GridCell(20, 20),
        GridCell(19, 20),
        GridCell(18, 20),
      ]);
    });

    test('food spawns on an empty cell and reports a full board', () {
      final SnakeController controller = SnakeController(
        width: 3,
        height: 3,
        predict: _unusedPredict,
        random: _ScriptedRandom(<int>[1, 4]),
        initialSnake: const <GridCell>[
          GridCell(0, 0),
          GridCell(1, 0),
          GridCell(2, 0),
        ],
        initialFood: const GridCell(0, 2),
      );
      expect(controller.spawnFood(), isTrue);
      expect(controller.food, const GridCell(1, 1));
      expect(controller.snakeCells.contains(controller.food), isFalse);

      final SnakeController full = SnakeController(
        width: 2,
        height: 2,
        predict: _unusedPredict,
        random: math.Random(0),
        initialSnake: const <GridCell>[
          GridCell(0, 0),
          GridCell(1, 0),
          GridCell(0, 1),
          GridCell(1, 1),
        ],
        initialFood: const GridCell(0, 0),
      );
      expect(full.spawnFood(), isFalse);
      expect(full.foodPlacementFailed, isTrue);
    });
  });

  group('four absolute moves', () {
    for (final (String key, CardinalHeading heading, GridCell cell)
        in <(String, CardinalHeading, GridCell)>[
          ('up', CardinalHeading.north, const GridCell(2, 0)),
          ('down', CardinalHeading.south, const GridCell(2, 2)),
          ('right', CardinalHeading.east, const GridCell(3, 1)),
        ]) {
      test('east-facing snake applies $key literally', () async {
        final SnakeController controller = _board(predict: _choicePredict(key));
        await controller.step();
        expect(controller.heading, heading);
        expect(controller.head, cell);
        expect(controller.ended, isFalse);
      });
    }

    test(
      'left from east enters the neck and ends without substitution',
      () async {
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        final SnakeController controller = _board(
          predict: _choicePredict('left'),
          onChoiceRecord: records.add,
        );
        final List<GridCell> before = controller.snakeCells;
        await controller.step();
        expect(controller.ended, isTrue);
        expect(controller.snakeCells, before);
        expect(records.single.choice, 'left');
        expect(records.single.attemptedCell, const GridCell(1, 1));
        expect(records.single.validation, SnakeChoiceValidation.bodyCollision);
        expect(records.single.reason, SnakeChoiceNoChoiceReason.bodyCollision);
        await controller.step();
        expect(records, hasLength(1));
      },
    );

    test('wall move ends the run and preserves the head', () async {
      final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
      final SnakeController controller = SnakeController(
        width: 5,
        height: 3,
        predict: _choicePredict('right'),
        random: math.Random(0),
        onChoiceRecord: records.add,
        initialSnake: const <GridCell>[
          GridCell(4, 1),
          GridCell(3, 1),
          GridCell(2, 1),
        ],
        initialFood: const GridCell(0, 0),
      );
      await controller.step();
      expect(controller.ended, isTrue);
      expect(controller.head, const GridCell(4, 1));
      expect(records.single.choice, 'right');
      expect(records.single.attemptedCell, const GridCell(5, 1));
      expect(records.single.validation, SnakeChoiceValidation.wallCollision);
    });

    test('eating grows the snake and spawns food off the body', () async {
      final SnakeController controller = SnakeController(
        width: 6,
        height: 4,
        predict: _choicePredict('right'),
        random: _ScriptedRandom(<int>[0]),
        initialSnake: const <GridCell>[
          GridCell(2, 1),
          GridCell(1, 1),
          GridCell(0, 1),
        ],
        initialFood: const GridCell(3, 1),
      );
      await controller.step();
      expect(controller.snakeCells, hasLength(4));
      expect(controller.head, const GridCell(3, 1));
      expect(controller.snakeCells.contains(controller.food), isFalse);
    });

    test('moving into the vacating tail is legal', () async {
      final SnakeController controller = SnakeController(
        width: 4,
        height: 4,
        predict: _choicePredict('down'),
        random: math.Random(0),
        initialSnake: const <GridCell>[
          GridCell(1, 1),
          GridCell(2, 1),
          GridCell(2, 2),
          GridCell(1, 2),
        ],
        initialFood: const GridCell(0, 0),
      );
      await controller.step();
      expect(controller.ended, isFalse);
      expect(controller.head, const GridCell(1, 2));
    });
  });

  group('checkpoint input', () {
    test('question matches the published four-direction contract exactly', () {
      final LayaQuestion question = _board(predict: _unusedPredict)
          .buildTurnQuestion();
      expect(question.id, 'move');
      expect(question.type, LayaQuestionType.choice);
      expect(
        question.instructions,
        'Which direction should the snake move next to reach the food safely?',
      );
      expect(question.criteria, const <String, String>{
        'up': 'move up',
        'down': 'move down',
        'left': 'move left',
        'right': 'move right',
      });
      expect(
        (question.criteria! as Map<String, String>).containsKey('straight'),
        isFalse,
      );
    });

    test(
      'state follows public heading, length, food, room and tail format',
      () {
        final SnakeController controller = SnakeController(
          width: 5,
          height: 4,
          predict: _unusedPredict,
          random: math.Random(0),
          initialSnake: const <GridCell>[
            GridCell(2, 1),
            GridCell(1, 1),
            GridCell(0, 1),
          ],
          initialFood: const GridCell(3, 1),
        );
        final String state = controller.buildStateString();
        expect(
          state,
          startsWith('heading: right | length: 3 | food: 1 right | '),
        );
        expect(state, contains('up: free, room 19 open, tail yes'));
        expect(state, contains('down: free, room 19 open, tail yes'));
        expect(state, contains('left: body'));
        expect(state, contains('right: food, room 18 open, tail yes'));
        expect(state, isNot(contains('Recent model choices')));
      },
    );

    test('model receives the encoded state and move question', () async {
      Object? sentState;
      Object? sentQuestions;
      final SnakeController controller = _board(
        predict: (Object state, Object questions) async {
          sentState = state;
          sentQuestions = questions;
          return _answersFor('right');
        },
      );
      final String expectedState = controller.buildStateString();
      await controller.step();
      expect(sentState, expectedState);
      final Map<String, LayaQuestion> questions =
          sentQuestions! as Map<String, LayaQuestion>;
      expect(questions.keys, <String>['move']);
      expect(
        questions['move']!.criteria,
        controller.buildTurnQuestion().criteria,
      );
    });
  });

  group('one record per finished prediction', () {
    test('accepted move records full pre-step input and progress', () async {
      final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
      final SnakeController controller = _board(
        predict: _choicePredict('right'),
        onChoiceRecord: records.add,
      );
      final String before = controller.buildStateString();
      await controller.step();
      expect(records, hasLength(1));
      final SnakeChoiceRecord record = records.single;
      expect(record.state, before);
      expect(record.instructions, controller.buildTurnQuestion().instructions);
      expect(record.options.keys, <String>['up', 'down', 'left', 'right']);
      expect(record.choice, 'right');
      expect(record.attemptedCell, const GridCell(3, 1));
      expect(record.validation, SnakeChoiceValidation.accepted);
      expect(record.progressBefore, 5);
      expect(record.progressAfter, 4);
      expect(record.progressDelta, 1);
      expect(record.reason, isNull);
      final Map<String, dynamic> json = jsonDecode(
        record.toString().substring('snake_choice '.length),
      ) as Map<String, dynamic>;
      expect(json['modelChoice'], 'right');
      expect(json['validation'], 'accepted');
      expect(json['attemptedCell'], <String, dynamic>{'col': 3, 'row': 1});
    });

    test(
      'missing or unknown answer preserves the board and logs the key',
      () async {
        for (final String? key in <String?>[null, 'straight']) {
          final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
          final SnakeController controller = _board(
            predict: (Object state, Object questions) async =>
                key == null ? <String, LayaAnswer>{} : _answersFor(key),
            onChoiceRecord: records.add,
          );
          final List<GridCell> before = controller.snakeCells;
          await controller.step();
          expect(controller.snakeCells, before);
          expect(controller.ended, isFalse);
          expect(records.single.choice, key);
          expect(
            records.single.validation,
            SnakeChoiceValidation.missingOrNonAbsoluteKey,
          );
          expect(records.single.progressAfter, isNull);
        }
      },
    );

    test('predict failure logs input and does not advance', () async {
      final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
      final SnakeController controller = _board(
        predict: (Object state, Object questions) async =>
            throw StateError('failed'),
        onChoiceRecord: records.add,
      );
      final String before = controller.buildStateString();
      await controller.step();
      expect(controller.head, const GridCell(2, 1));
      expect(records.single.state, before);
      expect(records.single.choice, isNull);
      expect(records.single.validation, SnakeChoiceValidation.predictFailure);
    });

    test(
      'alternating absolute choices are diagnosed without intervention',
      () async {
        const List<String> choices = <String>['up', 'right', 'up', 'right'];
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        var index = 0;
        final SnakeController controller = SnakeController(
          width: 20,
          height: 20,
          predict: (Object state, Object questions) async =>
              _answersFor(choices[index++]),
          random: math.Random(0),
          onChoiceRecord: records.add,
          initialSnake: const <GridCell>[
            GridCell(10, 10),
            GridCell(9, 10),
            GridCell(8, 10),
          ],
          initialFood: const GridCell(15, 15),
        );
        for (var i = 0; i < choices.length; i++) {
          await controller.step();
        }
        expect(records, hasLength(4));
        expect(records.last.repeatedTurn, isTrue);
        expect(records.last.choice, 'right');
        expect(controller.head, const GridCell(12, 8));
      },
    );
  });

  testWidgets('await-gated step never advances on a clock', (
    WidgetTester tester,
  ) async {
    final Completer<Map<String, LayaAnswer>> pendingAnswer =
        Completer<Map<String, LayaAnswer>>();
    final SnakeController controller = _board(
      predict: (Object state, Object questions) => pendingAnswer.future,
    );
    final List<GridCell> before = controller.snakeCells;
    final Future<void> pending = controller.step();
    await tester.pump(const Duration(seconds: 30));
    expect(controller.snakeCells, before);
    pendingAnswer.complete(_answersFor('right'));
    await pending;
    expect(controller.head, const GridCell(3, 1));
  });

  test('screen logs records and controller tests open no native session', () {
    final String screen = File('lib/snake_screen.dart').readAsStringSync();
    expect(screen, contains('onChoiceRecord'));
    expect(screen, contains('debugPrint'));
    for (final String path in <String>[
      'lib/snake_controller.dart',
      'test/snake_controller_test.dart',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(
        source.contains(
          'LayaFlutter'
          '.open(',
        ),
        isFalse,
      );
      expect(
        source.contains(
          'create'
          'Session(',
        ),
        isFalse,
      );
    }
  });
}

SnakeController _board({
  required SnakePredict predict,
  SnakeChoiceRecordCallback? onChoiceRecord,
}) => SnakeController(
  width: 6,
  height: 4,
  predict: predict,
  random: math.Random(0),
  onChoiceRecord: onChoiceRecord,
  initialSnake: const <GridCell>[
    GridCell(2, 1),
    GridCell(1, 1),
    GridCell(0, 1),
  ],
  initialFood: const GridCell(5, 3),
);

SnakePredict _choicePredict(String key) =>
    (Object state, Object questions) async => _answersFor(key);

Map<String, LayaAnswer> _answersFor(String key) => <String, LayaAnswer>{
  'move': LayaAnswer.choice(
    choice: key,
    probabilities: <String, double>{
      for (final String direction in <String>['up', 'down', 'left', 'right'])
        direction: key == direction ? 1.0 : 0.0,
    },
    confidence: 1.0,
  ),
};

Future<Map<String, LayaAnswer>> _unusedPredict(
  Object state,
  Object questions,
) async {
  fail('predict should not be called');
}

final class _ScriptedRandom implements math.Random {
  _ScriptedRandom(this.values);

  final List<int> values;
  int index = 0;

  @override
  int nextInt(int max) => values[index++];

  @override
  bool nextBool() => nextInt(2) == 1;

  @override
  double nextDouble() => nextInt(1000) / 1000;
}
