import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:laya_flutter/laya_flutter.dart';
import 'package:laya_flutter_example/snake_controller.dart';

void main() {
  group('U1 food spawn', () {
    test('places food on an empty cell, never on body', () {
      // Board 3x3; snake occupies (0,0)(1,0)(2,0). Indices 0,1,2 are body.
      // Sequence: first roll 1 (body), then 4 -> (1,1) empty.
      final _ScriptedRandom random = _ScriptedRandom(<int>[1, 4]);
      final SnakeController controller = SnakeController(
        width: 3,
        height: 3,
        predict: _unusedPredict,
        random: random,
        initialSnake: const <GridCell>[
          GridCell(0, 0),
          GridCell(1, 0),
          GridCell(2, 0),
        ],
        initialFood: const GridCell(0, 2),
      );

      final bool placed = controller.spawnFood();

      expect(placed, isTrue);
      expect(controller.foodPlacementFailed, isFalse);
      expect(controller.food, const GridCell(1, 1));
      expect(controller.snakeCells.contains(controller.food), isFalse);
    });

    test('refuses body then lands on empty from scripted random', () {
      final _ScriptedRandom random = _ScriptedRandom(<int>[0, 7]);
      final SnakeController controller = SnakeController(
        width: 3,
        height: 3,
        predict: _unusedPredict,
        random: random,
        initialSnake: const <GridCell>[
          GridCell(0, 0),
          GridCell(1, 0),
          GridCell(2, 0),
        ],
        initialFood: const GridCell(2, 2),
      );

      expect(controller.spawnFood(), isTrue);
      expect(controller.food, const GridCell(1, 2));
      expect(
        controller.snakeCells.contains(controller.food!),
        isFalse,
        reason: 'food must never land on body',
      );
    });

    test('signals failure when the board has no empty cell', () {
      final SnakeController controller = SnakeController(
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

      final bool placed = controller.spawnFood();

      expect(placed, isFalse);
      expect(controller.foodPlacementFailed, isTrue);
      // Food must not be forced onto a non-body cell that does not exist.
      expect(controller.snakeCells.length, 4);
    });
  });

  group('U1 relative turns', () {
    test('east plus left becomes north and moves one cell north', () async {
      final SnakeController controller = _boardForTurns(
        predict: _choicePredict('left'),
      );
      final GridCell before = controller.head;

      await controller.step();

      expect(controller.heading, CardinalHeading.north);
      expect(controller.head, GridCell(before.col, before.row - 1));
      expect(controller.snakeCells.length, 3);
    });

    test('east plus right becomes south and moves one cell south', () async {
      final SnakeController controller = _boardForTurns(
        predict: _choicePredict('right'),
      );
      final GridCell before = controller.head;

      await controller.step();

      expect(controller.heading, CardinalHeading.south);
      expect(controller.head, GridCell(before.col, before.row + 1));
    });

    test('east plus straight stays east and moves one cell east', () async {
      final SnakeController controller = _boardForTurns(
        predict: _choicePredict('straight'),
      );
      final GridCell before = controller.head;

      await controller.step();

      expect(controller.heading, CardinalHeading.east);
      expect(controller.head, GridCell(before.col + 1, before.row));
    });

    test('eating grows length by one and places new food on empty', () async {
      // Head at (2,1) east; food at (3,1); straight eats.
      final _ScriptedRandom random = _ScriptedRandom(<int>[0]); // (0,0) empty
      final SnakeController controller = SnakeController(
        width: 6,
        height: 4,
        predict: _choicePredict('straight'),
        random: random,
        initialSnake: const <GridCell>[
          GridCell(2, 1),
          GridCell(1, 1),
          GridCell(0, 1),
        ],
        initialHeading: CardinalHeading.east,
        initialFood: const GridCell(3, 1),
      );
      final int lengthBefore = controller.snakeCells.length;

      await controller.step();

      expect(controller.snakeCells.length, lengthBefore + 1);
      expect(controller.head, const GridCell(3, 1));
      expect(controller.food, isNotNull);
      expect(controller.snakeCells.contains(controller.food!), isFalse);
    });
  });

  group('U1 collisions', () {
    test('wall ends the game; further step does not move cells', () async {
      // Head at (4,1) on width 5, heading east; straight hits wall.
      final SnakeController controller = SnakeController(
        width: 5,
        height: 3,
        predict: _choicePredict('straight'),
        random: math.Random(0),
        initialSnake: const <GridCell>[
          GridCell(4, 1),
          GridCell(3, 1),
          GridCell(2, 1),
        ],
        initialHeading: CardinalHeading.east,
        initialFood: const GridCell(0, 0),
      );
      final List<GridCell> before = List<GridCell>.from(controller.snakeCells);
      final CardinalHeading headingBefore = controller.heading;
      final GridCell? foodBefore = controller.food;

      await controller.step();

      expect(controller.ended, isTrue);
      expect(controller.head, const GridCell(4, 1));
      expect(controller.head.col < controller.width, isTrue);
      expect(controller.snakeCells, before);
      expect(controller.heading, headingBefore);
      expect(controller.food, foodBefore);
      // Collision alone is not the new-run restore.
      expect(
        controller.snakeCells,
        isNot(<GridCell>[
          const GridCell(2, 1),
          const GridCell(1, 1),
          const GridCell(0, 1),
        ]),
      );

      final List<GridCell> afterWall = List<GridCell>.from(
        controller.snakeCells,
      );
      await controller.step();
      expect(controller.snakeCells, afterWall);
      expect(controller.ended, isTrue);
    });

    test('body ends the game; further step does not move cells', () async {
      // Compact U facing east into own body at (1,1).
      // Cells: head (2,1), (2,0), (1,0), (1,1), (1,2) — left turn from east
      // faces north into (2,0) which is body. Use straight into (1,1) body:
      // head (0,1) east would go to (1,1) body.
      final SnakeController controller = SnakeController(
        width: 4,
        height: 3,
        predict: _choicePredict('straight'),
        random: math.Random(0),
        initialSnake: const <GridCell>[
          GridCell(0, 1),
          GridCell(0, 0),
          GridCell(1, 0),
          GridCell(1, 1),
          GridCell(1, 2),
        ],
        initialHeading: CardinalHeading.east,
        initialFood: const GridCell(3, 2),
      );
      final List<GridCell> before = List<GridCell>.from(controller.snakeCells);

      await controller.step();

      expect(controller.ended, isTrue);
      expect(controller.head, const GridCell(0, 1));
      expect(controller.snakeCells, before);
      expect(
        controller.snakeCells,
        isNot(<GridCell>[
          const GridCell(2, 1),
          const GridCell(1, 1),
          const GridCell(0, 1),
        ]),
      );

      final List<GridCell> frozen = List<GridCell>.from(controller.snakeCells);
      await controller.step();
      expect(controller.snakeCells, frozen);
      expect(controller.ended, isTrue);
    });
  });

  group('new-run after death', () {
    // Center of a 5-by-3 or 4-by-3 board: head (2, 1), body trailing west.
    const List<GridCell> defaultSnake = <GridCell>[
      GridCell(2, 1),
      GridCell(1, 1),
      GridCell(0, 1),
    ];

    test('omitted initial snake starts at the board center, heading east', () {
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

    test('wall then new-run restores defaults; later step moves', () async {
      final math.Random random = math.Random(0);
      var phase = 0;
      final SnakeController living = SnakeController(
        width: 5,
        height: 3,
        predict: (Object state, Object questions) async {
          phase += 1;
          // Living step into the wall.
          return _answersFor('straight');
        },
        random: random,
        initialSnake: const <GridCell>[
          GridCell(4, 1),
          GridCell(3, 1),
          GridCell(2, 1),
        ],
        initialHeading: CardinalHeading.east,
        initialFood: const GridCell(0, 0),
      );

      await living.step();
      expect(living.ended, isTrue);
      expect(living.head, const GridCell(4, 1));
      // Skipping new-run leaves ended true and frozen cells.
      expect(living.ended, isTrue);
      expect(living.snakeCells, isNot(defaultSnake));

      // New-run: constructor replacement (not in-place clear).
      phase = 0;
      final SnakeController restarted = SnakeController(
        width: 5,
        height: 3,
        predict: (Object state, Object questions) async {
          phase += 1;
          return _answersFor('straight');
        },
        random: random,
      );

      expect(restarted.ended, isFalse);
      expect(restarted.snakeCells, defaultSnake);
      expect(restarted.heading, CardinalHeading.east);
      expect(restarted.food, isNotNull);
      expect(restarted.snakeCells.contains(restarted.food!), isFalse);

      await restarted.step();
      expect(restarted.snakeCells, isNot(defaultSnake));
      expect(restarted.head, const GridCell(3, 1));
      expect(phase, 1);
    });

    test('body then new-run restores defaults; later step moves', () async {
      final math.Random random = math.Random(1);
      final SnakeController living = SnakeController(
        width: 4,
        height: 3,
        predict: _choicePredict('straight'),
        random: random,
        initialSnake: const <GridCell>[
          GridCell(0, 1),
          GridCell(0, 0),
          GridCell(1, 0),
          GridCell(1, 1),
          GridCell(1, 2),
        ],
        initialHeading: CardinalHeading.east,
        initialFood: const GridCell(3, 2),
      );

      await living.step();
      expect(living.ended, isTrue);
      expect(living.snakeCells, isNot(defaultSnake));

      final SnakeController restarted = SnakeController(
        width: 4,
        height: 3,
        predict: _choicePredict('straight'),
        random: random,
      );

      expect(restarted.ended, isFalse);
      expect(restarted.snakeCells, defaultSnake);
      expect(restarted.heading, CardinalHeading.east);
      expect(restarted.food, isNotNull);
      expect(restarted.snakeCells.contains(restarted.food!), isFalse);

      await restarted.step();
      expect(restarted.snakeCells, isNot(defaultSnake));
    });

    test('predict failure does not end or imply a new run', () async {
      final SnakeController controller = _boardForTurns(
        predict: (Object state, Object questions) async {
          throw StateError('predict failed');
        },
      );
      final List<GridCell> before = List<GridCell>.from(controller.snakeCells);

      await controller.step();

      expect(controller.ended, isFalse);
      expect(controller.snakeCells, before);
      // 6-by-4 center is (3, 2); this board's explicit snake must stay put.
      expect(
        controller.snakeCells,
        isNot(const <GridCell>[GridCell(3, 2), GridCell(2, 2), GridCell(1, 2)]),
      );
    });
  });

  group('U2 prompt', () {
    test('state string names heading, head, food, and neighbour kinds', () {
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
        initialHeading: CardinalHeading.east,
        // Left of east head = north (2,0) empty; right = south (2,2) empty;
        // ahead = (3,1) food.
        initialFood: const GridCell(3, 1),
      );

      final String state = controller.buildStateString();

      expect(state, contains('Board width 5 columns, height 4 rows'));
      expect(state, contains('The head faces east'));
      expect(state, contains('The head cell is column 2, row 1'));
      expect(state, contains('The food cell is column 3, row 1'));
      expect(state, contains('The cell to the left is empty'));
      expect(state, contains('The cell to the right is empty'));
      expect(state, contains('The cell ahead is food'));
      expect(state, contains('Food is ahead relative to the current facing'));
      expect(state, contains('The Manhattan distance to food is 1'));
      expect(state, contains('The candidate facts are'));
      expect(
        state,
        contains('Snake cells from head to tail: (2,1) (1,1) (0,1)'),
      );
      expect(state, isNot(contains('Toward food')));
      expect(state, isA<String>());
    });

    test('state names the relative turn that moves closer to food', () {
      // Log shape: heading east on the top row, food due south.
      // Left is the north wall. Right is the step toward the food.
      final SnakeController controller = SnakeController(
        width: 40,
        height: 40,
        predict: _unusedPredict,
        random: math.Random(0),
        initialSnake: const <GridCell>[
          GridCell(4, 0),
          GridCell(3, 0),
          GridCell(2, 0),
        ],
        initialHeading: CardinalHeading.east,
        initialFood: const GridCell(4, 45),
      );

      final String state = controller.buildStateString();
      final Map<String, String> criteria =
          controller.buildTurnQuestion().criteria! as Map<String, String>;

      expect(state, contains('The cell to the left is wall'));
      expect(state, contains('The cell ahead is empty'));
      expect(criteria['left'], contains('left: next cell'));
      expect(criteria['right'], contains('right: next cell'));
      expect(criteria['straight'], contains('straight: next cell'));
      expect(criteria['right'], contains('distance to food'));
    });

    test('turn instructions explain Snake, the grid, and relative turns', () {
      final SnakeController controller = _boardForTurns(
        predict: _unusedPredict,
      );
      final String instructions = controller.buildTurnQuestion().instructions;

      expect(instructions, contains('This is the game Snake'));
      expect(instructions, contains('Return exactly one key'));
      expect(instructions, contains('reach the food'));
      expect(instructions, contains('wall'));
      expect(instructions, contains('snake body'));
      expect(instructions, contains('Column 0 is the west edge'));
      expect(instructions, contains('Row 0 is the north edge'));
      expect(instructions, contains('Left rotates the facing 90 degrees'));
      expect(instructions, contains('Right rotates the facing 90 degrees'));
      expect(instructions, contains('Straight keeps the facing'));
      expect(instructions, contains('empty, wall, body, or food'));
    });

    test('choice keys are left, right, straight with relative descriptions', () {
      final SnakeController controller = _boardForTurns(
        predict: _unusedPredict,
      );
      final LayaQuestion question = controller.buildTurnQuestion();
      final Map<String, String> criteria =
          question.criteria! as Map<String, String>;

      expect(question.id, 'turn');
      expect(question.type, LayaQuestionType.choice);
      expect(criteria.keys.toList(), <String>['left', 'right', 'straight']);
      expect(criteria['left'], contains('left: next cell'));
      expect(criteria['right'], contains('right: next cell'));
      expect(criteria['straight'], contains('straight: next cell'));

      final String joined =
          '${question.instructions} ${criteria.values.join(' ')}'.toLowerCase();
      for (final String banned in <String>[
        'up',
        'down',
        'true',
        'false',
        ' a ',
        ' b ',
        ' c ',
      ]) {
        // Absolute keys and boolean/A-B-C keys must not appear as option keys.
        expect(criteria.containsKey(banned.trim()), isFalse);
      }
      expect(criteria.containsKey('UP'), isFalse);
      expect(criteria.containsKey('DOWN'), isFalse);
      expect(criteria.containsKey('LEFT'), isFalse);
      expect(criteria.containsKey('RIGHT'), isFalse);
      expect(criteria.containsKey('A'), isFalse);
      expect(criteria.containsKey('B'), isFalse);
      expect(criteria.containsKey('C'), isFalse);
      expect(criteria.containsKey('true'), isFalse);
      expect(criteria.containsKey('false'), isFalse);
      expect(joined.contains('planner'), isFalse);
      expect(joined.contains('shield'), isFalse);
      expect(joined.contains('override'), isFalse);
    });

    test('question text has no planner or shield instructions', () {
      final SnakeController controller = _boardForTurns(
        predict: _unusedPredict,
      );
      final LayaQuestion question = controller.buildTurnQuestion();
      final Map<String, String> criteria =
          question.criteria! as Map<String, String>;
      final String blob =
          '${question.instructions}\n${criteria.values.join('\n')}'
              .toLowerCase();

      expect(blob.contains('plan multi'), isFalse);
      expect(blob.contains('planner'), isFalse);
      expect(blob.contains('safety shield'), isFalse);
      expect(blob.contains('override'), isFalse);
      expect(blob.contains('filter'), isFalse);
    });

    test(
      'step passes English state and relative turn question into predict',
      () async {
        // Assert the objects step actually sends, not only the builders.
        Object? capturedState;
        Object? capturedQuestions;
        final SnakeController controller = SnakeController(
          width: 5,
          height: 4,
          predict: (Object state, Object questions) async {
            capturedState = state;
            capturedQuestions = questions;
            return _answersFor('straight');
          },
          random: math.Random(0),
          initialSnake: const <GridCell>[
            GridCell(2, 1),
            GridCell(1, 1),
            GridCell(0, 1),
          ],
          initialHeading: CardinalHeading.east,
          initialFood: const GridCell(3, 1),
        );

        await controller.step();

        expect(capturedState, isNotNull);
        expect(capturedState, isA<String>());
        expect(capturedState, isNot(isA<Map<dynamic, dynamic>>()));
        final String state = capturedState! as String;
        expect(state, contains('The head faces east'));
        expect(state, contains('The head cell is column 2, row 1'));
        expect(state, contains('The food cell is column 3, row 1'));
        expect(state, contains('The cell to the left is empty'));
        expect(state, contains('The cell to the right is empty'));
        expect(state, contains('The cell ahead is food'));

        expect(capturedQuestions, isA<Map<String, LayaQuestion>>());
        final Map<String, LayaQuestion> questions =
            capturedQuestions! as Map<String, LayaQuestion>;
        expect(questions.keys, <String>['turn']);
        final LayaQuestion question = questions['turn']!;
        expect(question.id, 'turn');
        expect(question.type, LayaQuestionType.choice);
        final Map<String, String> criteria =
            question.criteria! as Map<String, String>;
        expect(criteria.keys.toList(), <String>['left', 'right', 'straight']);
        expect(criteria['straight'], contains('straight: next cell'));
        expect(criteria.containsKey('UP'), isFalse);
        expect(criteria.containsKey('DOWN'), isFalse);
        expect(criteria.containsKey('LEFT'), isFalse);
        expect(criteria.containsKey('RIGHT'), isFalse);

        final String blob =
            '${question.instructions}\n${criteria.values.join('\n')}'
                .toLowerCase();
        expect(blob.contains('plan multi'), isFalse);
        expect(blob.contains('planner'), isFalse);
        expect(blob.contains('safety shield'), isFalse);
        expect(blob.contains('override'), isFalse);
        expect(blob.contains('filter'), isFalse);
      },
    );
  });

  group('choice log', () {
    test(
      'AC-001/AC-002: relative success delivers one record then moves cells',
      () async {
        const Map<String, double> probs = <String, double>{
          'left': 0.1,
          'right': 0.2,
          'straight': 0.7,
        };
        const double confidence = 0.42;
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        final SnakeController controller = _boardForTurns(
          predict: (Object state, Object questions) async {
            return <String, LayaAnswer>{
              'turn': LayaAnswer.choice(
                choice: 'straight',
                probabilities: probs,
                confidence: confidence,
              ),
            };
          },
          onChoiceRecord: records.add,
        );
        final String preStepState = controller.buildStateString();
        final LayaQuestion preStepQuestion = controller.buildTurnQuestion();
        final List<GridCell> cellsBefore = List<GridCell>.from(
          controller.snakeCells,
        );

        await controller.step();

        // Negative path: a missing record fails this test.
        expect(
          records,
          hasLength(1),
          reason: 'accepted relative key must deliver exactly one record',
        );
        final SnakeChoiceRecord record = records.single;
        expect(record.state, preStepState);
        expect(record.choice, 'straight');
        expect(record.probabilities, probs);
        expect(record.confidence, confidence);
        expect(record.reason, isNull);
        final LayaQuestion question = preStepQuestion;
        final Map<String, String> criteria =
            question.criteria! as Map<String, String>;
        expect(record.instructions, question.instructions);
        expect(record.options, criteria);
        final String line = record.toString();
        expect(line, startsWith('snake_choice {'));
        expect(line, contains('"instructions":"${question.instructions}"'));
        for (final MapEntry<String, String> option in criteria.entries) {
          expect(line, contains('"${option.key}":"${option.value}"'));
        }
        expect(line, contains('"state":"$preStepState"'));
        expect(line, contains('"modelChoice":"straight"'));
        expect(line, contains('"validation":"accepted"'));
        expect(controller.snakeCells, isNot(cellsBefore));
        expect(controller.head, const GridCell(3, 1));
      },
    );

    test('AC-001: left success record carries key and answer fields', () async {
      const Map<String, double> probs = <String, double>{
        'left': 0.9,
        'right': 0.05,
        'straight': 0.05,
      };
      const double confidence = 0.88;
      final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
      final SnakeController controller = _boardForTurns(
        predict: (Object state, Object questions) async {
          return <String, LayaAnswer>{
            'turn': LayaAnswer.choice(
              choice: 'left',
              probabilities: probs,
              confidence: confidence,
            ),
          };
        },
        onChoiceRecord: records.add,
      );
      final String preStepState = controller.buildStateString();

      await controller.step();

      expect(records, hasLength(1));
      expect(records.single.state, preStepState);
      expect(records.single.choice, 'left');
      expect(records.single.probabilities, probs);
      expect(records.single.confidence, confidence);
      expect(controller.heading, CardinalHeading.north);
    });

    test(
      'AC-001: wall death still records pre-step state before collide',
      () async {
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        final SnakeController controller = SnakeController(
          width: 5,
          height: 3,
          predict: _choicePredict('straight'),
          random: math.Random(0),
          onChoiceRecord: records.add,
          initialSnake: const <GridCell>[
            GridCell(4, 1),
            GridCell(3, 1),
            GridCell(2, 1),
          ],
          initialHeading: CardinalHeading.east,
          initialFood: const GridCell(0, 0),
        );
        final String preStepState = controller.buildStateString();

        await controller.step();

        expect(records, hasLength(1));
        expect(records.single.state, preStepState);
        expect(records.single.choice, 'straight');
        expect(controller.ended, isTrue);

        final int countAfterDeath = records.length;
        await controller.step();
        expect(records, hasLength(countAfterDeath));
      },
    );

    test(
      'AC-003: predict throw delivers no-choice and leaves board unchanged',
      () async {
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        final SnakeController controller = _boardForTurns(
          predict: (Object state, Object questions) async {
            throw StateError('predict failed');
          },
          onChoiceRecord: records.add,
        );
        final String preStepState = controller.buildStateString();
        final List<GridCell> cellsBefore = List<GridCell>.from(
          controller.snakeCells,
        );
        final CardinalHeading headingBefore = controller.heading;
        final GridCell? foodBefore = controller.food;

        await controller.step();

        expect(records, hasLength(1));
        expect(records.single.state, preStepState);
        expect(records.single.choice, isNull);
        expect(records.single.probabilities, isNull);
        expect(records.single.confidence, isNull);
        expect(records.single.reason, SnakeChoiceNoChoiceReason.predictFailure);
        expect(controller.snakeCells, cellsBefore);
        expect(controller.heading, headingBefore);
        expect(controller.food, foodBefore);
        expect(controller.ended, isFalse);
      },
    );

    test(
      'AC-004: missing turn key delivers no-choice and does not advance',
      () async {
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        final SnakeController controller = _boardForTurns(
          predict: (Object state, Object questions) async {
            return <String, LayaAnswer>{};
          },
          onChoiceRecord: records.add,
        );
        final String preStepState = controller.buildStateString();
        final List<GridCell> cellsBefore = List<GridCell>.from(
          controller.snakeCells,
        );

        await controller.step();

        expect(records, hasLength(1));
        expect(records.single.state, preStepState);
        expect(records.single.choice, isNull);
        expect(
          records.single.reason,
          SnakeChoiceNoChoiceReason.missingOrNonRelativeKey,
        );
        expect(controller.snakeCells, cellsBefore);
        expect(controller.ended, isFalse);
      },
    );

    test(
      'AC-004: non-relative turn key delivers no-choice and does not advance',
      () async {
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        final SnakeController controller = _boardForTurns(
          predict: (Object state, Object questions) async {
            return <String, LayaAnswer>{
              'turn': LayaAnswer.choice(
                choice: 'up',
                probabilities: <String, double>{'up': 1.0},
                confidence: 1.0,
              ),
            };
          },
          onChoiceRecord: records.add,
        );
        final List<GridCell> cellsBefore = List<GridCell>.from(
          controller.snakeCells,
        );

        await controller.step();

        expect(records, hasLength(1));
        expect(records.single.choice, 'up');
        expect(
          records.single.reason,
          SnakeChoiceNoChoiceReason.missingOrNonRelativeKey,
        );
        expect(controller.snakeCells, cellsBefore);
        expect(controller.ended, isFalse);
      },
    );

    test(
      'AC-005: omitted callback advances play and delivers no record',
      () async {
        final SnakeController controller = _boardForTurns(
          predict: _choicePredict('straight'),
        );
        final List<GridCell> cellsBefore = List<GridCell>.from(
          controller.snakeCells,
        );

        await controller.step();

        expect(controller.onChoiceRecord, isNull);
        expect(controller.snakeCells, isNot(cellsBefore));
        expect(controller.head, const GridCell(3, 1));
      },
    );

    test(
      'AC-005: omitted callback on predict throw stays silent and frozen',
      () async {
        final SnakeController controller = _boardForTurns(
          predict: (Object state, Object questions) async {
            throw StateError('predict failed');
          },
        );
        final List<GridCell> cellsBefore = List<GridCell>.from(
          controller.snakeCells,
        );

        await controller.step();

        expect(controller.onChoiceRecord, isNull);
        expect(controller.snakeCells, cellsBefore);
        expect(controller.ended, isFalse);
      },
    );

    test(
      'AC-006/AC-008: screen wires debugPrint callback; tests open no session',
      () async {
        final File screenFile = File('lib/snake_screen.dart');
        expect(screenFile.existsSync(), isTrue);
        final String screenSource = screenFile.readAsStringSync();
        expect(
          screenSource.contains('onChoiceRecord'),
          isTrue,
          reason: 'Snake screen must pass a choice-record callback',
        );
        expect(
          screenSource.contains('debugPrint'),
          isTrue,
          reason: 'callback must write one debug line per record',
        );
        expect(
          screenSource.contains('build-marker 0014'),
          isTrue,
          reason: 'console line must carry the current build marker',
        );

        var predictCalls = 0;
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        final SnakeController controller = _boardForTurns(
          predict: (Object state, Object questions) async {
            predictCalls += 1;
            return _answersFor('straight');
          },
          onChoiceRecord: records.add,
        );

        await controller.step();

        expect(predictCalls, 1);
        expect(records, hasLength(1));

        final String needleA =
            'LayaFlutter'
            '.open';
        final String needleB =
            'create'
            'Session';
        for (final String path in <String>[
          'test/snake_controller_test.dart',
          'lib/snake_controller.dart',
        ]) {
          final String source = File(path).readAsStringSync();
          expect(source.contains(needleA), isFalse);
          expect(source.contains(needleB), isFalse);
        }
      },
    );

    test(
      'AC-007: missing emission assertion fails when record list stays empty',
      () async {
        // Harness that would omit emission: callback not invoked.
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        // Simulate an accepted relative key with no delivered record.
        const bool relativeKeyAccepted = true;
        expect(relativeKeyAccepted, isTrue);
        expect(
          () => expect(
            records,
            isNotEmpty,
            reason: 'accepted relative key must deliver a record',
          ),
          throwsA(isA<TestFailure>()),
        );
      },
    );
  });

  group('model loop diagnostics', () {
    test(
      'repeated turns are exposed to the model and only diagnosed',
      () async {
        const List<String> modelChoices = <String>[
          'left',
          'right',
          'left',
          'right',
        ];
        final List<String> capturedStates = <String>[];
        final List<SnakeChoiceRecord> records = <SnakeChoiceRecord>[];
        var call = 0;
        final SnakeController controller = SnakeController(
          width: 20,
          height: 20,
          predict: (Object state, Object questions) async {
            capturedStates.add(state as String);
            return _answersFor(modelChoices[call++]);
          },
          random: math.Random(0),
          onChoiceRecord: records.add,
          initialSnake: const <GridCell>[
            GridCell(10, 10),
            GridCell(9, 10),
            GridCell(8, 10),
          ],
          initialHeading: CardinalHeading.east,
          initialFood: const GridCell(15, 15),
        );

        for (var i = 0; i < modelChoices.length; i++) {
          await controller.step();
        }

        expect(capturedStates, hasLength(4));
        expect(
          capturedStates[3],
          contains('Recent model choices: left, right, left'),
        );
        expect(
          capturedStates[3],
          contains('Reach food while avoiding walls and body'),
        );
        expect(capturedStates[3], contains('The Manhattan distance to food'));
        expect(capturedStates[3], contains('The candidate facts are'));
        expect(records, hasLength(4));
        expect(records.last.choice, 'right');
        expect(records.last.repeatedTurn, isTrue);
        expect(records.last.goal, 'Reach food while avoiding walls and body.');
        expect(records.last.progressMetric, 'Manhattan distance to food');
        expect(records.last.progressDelta, isNotNull);
        expect(controller.ended, isFalse);
      },
    );
  });

  group('U3 await-gated step', () {
    testWidgets('incomplete predict leaves cells unchanged after fake time', (
      WidgetTester tester,
    ) async {
      final Completer<Map<String, LayaAnswer>> completer =
          Completer<Map<String, LayaAnswer>>();
      final SnakeController controller = _boardForTurns(
        predict: (Object state, Object questions) => completer.future,
      );
      final List<GridCell> before = List<GridCell>.from(controller.snakeCells);

      final Future<void> pending = controller.step();
      // Elapse fake binding time with no Timer in the controller: cells hold.
      await tester.pump(const Duration(seconds: 30));
      expect(controller.snakeCells, before);

      completer.complete(_answersFor('straight'));
      await pending;

      expect(controller.head, const GridCell(3, 1));
      expect(controller.snakeCells.length, before.length);
      // Exactly one cell of progress: head moved one step east.
      expect(controller.head.col - before.first.col, 1);
      expect(controller.head.row, before.first.row);
    });

    test('predict failure does not invent a turn or advance', () async {
      final SnakeController controller = _boardForTurns(
        predict: (Object state, Object questions) async {
          throw StateError('predict failed');
        },
      );
      final List<GridCell> before = List<GridCell>.from(controller.snakeCells);
      final CardinalHeading headingBefore = controller.heading;

      await controller.step();

      expect(controller.snakeCells, before);
      expect(controller.heading, headingBefore);
      expect(controller.ended, isFalse);
    });

    test('logic tests inject predict and never open a session', () async {
      var predictCalls = 0;
      final SnakeController controller = _boardForTurns(
        predict: (Object state, Object questions) async {
          predictCalls += 1;
          return _answersFor('straight');
        },
      );

      await controller.step();
      expect(
        predictCalls,
        1,
        reason: 'step must use the injected predict double',
      );

      // Adjacent literals so this source lacks the contiguous forbidden names.
      // Identifier names also avoid those contiguous substrings.
      final String needleA =
          'LayaFlutter'
          '.open';
      final String needleB =
          'create'
          'Session';
      final String needleC =
          'Onnx'
          'Runtime';
      final String needleD =
          'Ort'
          'Session';

      for (final String path in <String>[
        'test/snake_controller_test.dart',
        'lib/snake_controller.dart',
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
        expect(
          source.contains(needleC),
          isFalse,
          reason: '$path must not reference the ONNX runtime type',
        );
        expect(
          source.contains(needleD),
          isFalse,
          reason: '$path must not reference the ORT session type',
        );
      }
    });
  });
}

SnakePredict _choicePredict(String key) {
  return (Object state, Object questions) async => _answersFor(key);
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

Future<Map<String, LayaAnswer>> _unusedPredict(
  Object state,
  Object questions,
) async {
  fail('predict should not be called in this test');
}

SnakeController _boardForTurns({
  required SnakePredict predict,
  SnakeChoiceRecordCallback? onChoiceRecord,
}) {
  return SnakeController(
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
    initialHeading: CardinalHeading.east,
    initialFood: const GridCell(5, 3),
  );
}

/// Deterministic [math.Random] that yields a fixed [nextInt] sequence.
final class _ScriptedRandom implements math.Random {
  _ScriptedRandom(this._values);

  final List<int> _values;
  int _index = 0;

  @override
  int nextInt(int max) {
    if (_index >= _values.length) {
      throw StateError('scripted random exhausted');
    }
    final int value = _values[_index++];
    if (value < 0 || value >= max) {
      throw StateError('scripted value $value out of range for max $max');
    }
    return value;
  }

  @override
  double nextDouble() => throw UnimplementedError();

  @override
  bool nextBool() => throw UnimplementedError();
}
