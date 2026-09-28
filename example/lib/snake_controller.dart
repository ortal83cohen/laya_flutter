import 'dart:convert';
import 'dart:math' as math;

import 'package:laya_flutter/laya_flutter.dart';

/// Cardinal heading on the board.
enum CardinalHeading {
  /// Negative row direction.
  north,

  /// Positive column direction.
  east,

  /// Positive row direction.
  south,

  /// Negative column direction.
  west,
}

/// One playable or neighbour cell by column and row.
final class GridCell {
  /// Creates a cell at [col], [row].
  const GridCell(this.col, this.row);

  /// Column index.
  final int col;

  /// Row index.
  final int row;

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => '($col,$row)';
}

/// Injectable predict seam matching [LoadedRuntime.predict]'s observable shape.
typedef SnakePredict = Future<Map<String, LayaAnswer>> Function(
  Object state,
  Object questions,
);

/// Optional notification after a finished living-step predict outcome.
typedef SnakeChoiceRecordCallback = void Function(SnakeChoiceRecord record);

/// Why a living step finished without an accepted relative turn.
enum SnakeChoiceNoChoiceReason {
  /// Predict threw before a turn answer was available.
  predictFailure,

  /// Turn choice missing, or not left / right / straight.
  missingOrNonRelativeKey,

  /// The returned relative turn would enter a wall.
  wallCollision,

  /// The returned relative turn would enter the snake body.
  bodyCollision,
}

/// Classification of the model-owned result after one living attempt.
enum SnakeChoiceValidation {
  /// The returned relative key was legal and advanced the snake.
  accepted,

  /// The returned relative key entered a wall and ended the run.
  wallCollision,

  /// The returned relative key entered the snake body and ended the run.
  bodyCollision,

  /// The answer did not contain one of the relative keys.
  missingOrNonRelativeKey,

  /// Predict threw before producing an answer.
  predictFailure,
}

/// One finished living-step attempt with model-owned choice diagnostics.
final class SnakeChoiceRecord {
  /// Creates a record without inventing an applied or fallback choice.
  SnakeChoiceRecord({
    required this.instructions,
    required this.options,
    required this.state,
    required this.heading,
    required this.head,
    required this.food,
    required this.goal,
    required this.progressMetric,
    required this.progressBefore,
    required this.progressAfter,
    required this.progressDelta,
    required this.recentChoices,
    required this.reason,
    required this.choice,
    required this.attemptedCell,
    required this.validation,
    required this.repeatedTurn,
    required this.probabilities,
    required this.confidence,
  });

  /// Turn-question instruction text sent as the choice-question head.
  final String instructions;

  /// Option key to description, in the order scored by the model.
  final Map<String, String> options;

  /// Pre-step English state string built before predict.
  final String state;

  /// Heading before the model attempt.
  final CardinalHeading heading;

  /// Head before the model attempt.
  final GridCell head;

  /// Food before the model attempt.
  final GridCell? food;

  /// Objective supplied to the model and used for diagnostics.
  final String goal;

  /// Name of the progress measurement.
  final String progressMetric;

  /// Manhattan distance before the attempted move, or null without food.
  final int? progressBefore;

  /// Manhattan distance at the attempted next cell, or null without food/key.
  final int? progressAfter;

  /// Progress as before minus after, or null when either distance is absent.
  final int? progressDelta;

  /// Valid model keys before this attempt, newest last.
  final List<String> recentChoices;

  /// The exact relative key returned by the model, or null when absent.
  final String? choice;

  /// Cell selected by the returned relative key, including an unsafe cell.
  final GridCell? attemptedCell;

  /// Diagnostic classification; it never replaces the model key.
  final SnakeChoiceValidation validation;

  /// True when the current key completes a repeated or alternating pattern.
  final bool repeatedTurn;

  /// Probability map from the turn answer; null without a choice answer.
  final Map<String, double>? probabilities;

  /// Confidence from the turn answer; null without a choice answer.
  final double? confidence;

  /// Present when the attempt has a failure or collision explanation.
  final SnakeChoiceNoChoiceReason? reason;

  @override
  String toString() {
    return 'snake_choice ${jsonEncode(<String, Object?>{'heading': heading.name, 'head': _cellJson(head), 'food': _cellJson(food), 'goal': goal, 'progressMetric': progressMetric, 'progressBefore': progressBefore, 'progressAfter': progressAfter, 'progressDelta': progressDelta, 'recentChoices': recentChoices, 'instructions': instructions, 'options': options, 'state': state, 'modelChoice': choice, 'attemptedCell': _cellJson(attemptedCell), 'validation': validation.name, 'reason': reason?.name, 'repeatedTurn': repeatedTurn, 'probabilities': probabilities, 'confidence': confidence})}';
  }
}

Map<String, int>? _cellJson(GridCell? cell) =>
    cell == null ? null : <String, int>{'col': cell.col, 'row': cell.row};

/// Classic Snake rules and await-gated step for the example app.
///
/// Pure Dart: no Timer, Future.delayed, or Ticker. Tests inject [predict] and
/// [random]; the screen wires real [LoadedRuntime.predict].
final class SnakeController {
  /// Creates a controller for a board of [width] by [height].
  ///
  /// Playable cells are column in `[0, width)` and row in `[0, height)`.
  /// When [initialSnake] is omitted, the snake is three cells on the center
  /// row (`height ~/ 2`), head at column `width ~/ 2`, trailing west.
  /// That default needs [width] of at least 3. When [onChoiceRecord] is
  /// omitted, finished steps record nothing.
  SnakeController({
    required this.width,
    required this.height,
    required this.predict,
    required this.random,
    this.onChoiceRecord,
    List<GridCell>? initialSnake,
    CardinalHeading initialHeading = CardinalHeading.east,
    GridCell? initialFood,
  }) : heading = initialHeading,
       _snake = List<GridCell>.from(
         initialSnake ?? _centeredOpeningSnake(width, height),
       ) {
    if (width < 1 || height < 1) {
      throw ArgumentError('width and height must be positive');
    }
    if (initialFood != null) {
      food = initialFood;
    } else {
      spawnFood();
    }
  }

  /// Board width in cells.
  final int width;

  /// Board height in cells.
  final int height;

  /// Injected predict seam (tests use a double; the screen uses LoadedRuntime).
  final SnakePredict predict;

  /// Optional choice-record callback; null means record nothing.
  final SnakeChoiceRecordCallback? onChoiceRecord;

  /// Random source for food placement.
  final math.Random random;

  /// Snake cells head-first.
  final List<GridCell> _snake;

  /// Recent valid model keys, newest last, retained as model context.
  final List<String> _recentChoices = <String>[];

  /// Fixed objective shared by the prompt and diagnostic records.
  static const String _goal = 'Reach food while avoiding walls and body.';

  /// Progress measurement shared by the prompt and diagnostic records.
  static const String _progressMetric = 'Manhattan distance to food';

  /// Current cardinal heading.
  CardinalHeading heading;

  /// Food cell, or null when none is placed.
  GridCell? food;

  /// True after a wall or body collision.
  bool ended = false;

  /// True when the last [spawnFood] could not place food on an empty cell.
  bool foodPlacementFailed = false;

  /// Three-cell opening snake centered on the board, head facing east.
  ///
  /// Head is `(width ~/ 2, height ~/ 2)`. The body occupies the two cells
  /// immediately west of the head.
  static List<GridCell> _centeredOpeningSnake(int width, int height) {
    final int headCol = width ~/ 2;
    final int row = height ~/ 2;
    return <GridCell>[
      GridCell(headCol, row),
      GridCell(headCol - 1, row),
      GridCell(headCol - 2, row),
    ];
  }

  /// Unmodifiable view of snake cells, head first.
  List<GridCell> get snakeCells => List<GridCell>.unmodifiable(_snake);

  /// Head cell.
  GridCell get head => _snake.first;

  /// Places food on a random empty cell.
  ///
  /// Samples board indices from [random], skipping body cells. Returns true
  /// when food was placed. When no empty cell remains, sets
  /// [foodPlacementFailed] and does not place food on the body.
  bool spawnFood() {
    foodPlacementFailed = false;
    final Set<GridCell> body = _snake.toSet();
    final int capacity = width * height;
    if (body.length >= capacity) {
      foodPlacementFailed = true;
      return false;
    }
    // Rejection sampling so a sequence that first yields a body index then an
    // empty index still ends on empty, never on body.
    for (var attempt = 0; attempt < capacity * 4; attempt++) {
      final int index = random.nextInt(capacity);
      final GridCell candidate = GridCell(index % width, index ~/ width);
      if (!body.contains(candidate)) {
        food = candidate;
        return true;
      }
    }
    foodPlacementFailed = true;
    return false;
  }

  /// English situation for one step, including candidate facts and loop context.
  String buildStateString() {
    final GridCell h = head;
    final String foodSentence = food == null
        ? 'There is no food cell.'
        : 'The food cell is column ${food!.col}, row ${food!.row}.';
    final int? progressBefore = _distanceToFood(h);
    final String progressSentence = progressBefore == null
        ? 'There is no food-distance metric.'
        : 'The Manhattan distance to food is $progressBefore.';
    final String relativeFood = food == null
        ? 'none'
        : _relativeFoodPosition(h, food!);
    final String recent = _recentChoices.isEmpty
        ? 'none'
        : _recentChoices.join(', ');
    final String leftKind = _classify(
      _cellInHeading(head, _rotate(heading, 'left')),
    );
    final String rightKind = _classify(
      _cellInHeading(head, _rotate(heading, 'right')),
    );
    final String aheadKind = _classify(
      _cellInHeading(head, _rotate(heading, 'straight')),
    );
    final String snakeCells = _snake
        .map((GridCell cell) => '(${cell.col},${cell.row})')
        .join(' ');
    final String candidates = <String>[
      'left',
      'right',
      'straight',
    ].map(_candidateDescription).join(' ');
    return 'Board width $width columns, height $height rows. '
        'Column 0 is west; higher columns are east. '
        'Row 0 is north; higher rows are south. '
        'The head faces ${heading.name}. '
        'The head cell is column ${h.col}, row ${h.row}. '
        '$foodSentence '
        'The cell to the left is $leftKind. '
        'The cell to the right is $rightKind. '
        'The cell ahead is $aheadKind. '
        'Food is $relativeFood relative to the current facing. '
        '$progressSentence '
        'Recent model choices: $recent. '
        '$_goal '
        'The candidate facts are: $candidates '
        'Snake cells from head to tail: $snakeCells.';
  }

  /// One choice question: id turn, keys left/right/straight as relative turns.
  ///
  /// Instructions make the typed relative output and model ownership explicit.
  LayaQuestion buildTurnQuestion() {
    return LayaQuestion(
      id: 'turn',
      type: LayaQuestionType.choice,
      instructions:
          'This is the game Snake. Return exactly one key: left, right, or straight. '
          'Do not return a sentence or an absolute direction. '
          'The goal is to reach the food while avoiding walls and the snake body. '
          'Moving onto a wall or onto the snake body ends the game. '
          'Use the candidate facts and the Manhattan distance to food. '
          'Recent model choices are included so a repeated pattern is visible. '
          'The application executes exactly the returned key and does not correct or replace it. '
          'The board is a grid. Column 0 is the west edge, and a higher column is farther east. '
          'Row 0 is the north edge, and a higher row is farther south. '
          'A cell past an edge is a wall. '
          'The snake is a chain of cells, and the first cell is the head. '
          'The head faces north, east, south, or west. '
          'Left, right, and straight are turns relative to that facing. '
          'Left rotates the facing 90 degrees to its left. '
          'Right rotates the facing 90 degrees to its right. '
          'Straight keeps the facing. '
          'The head then moves one cell in the new facing. '
          'A candidate describes its next cell, cell kind, and distance to food. '
          'A cell kind is empty, wall, body, or food.',
      criteria: <String, String>{
        'left': _candidateDescription('left'),
        'right': _candidateDescription('right'),
        'straight': _candidateDescription('straight'),
      },
    );
  }

  /// Awaits injected [predict], applies the turn choice, advances one cell.
  ///
  /// While the future is incomplete, snake cells do not change. On predict
  /// failure, does not invent a turn and does not advance. After [ended], a
  /// further call leaves cells unchanged and emits no new choice record.
  /// When [onChoiceRecord] is set, delivers exactly one record per finished
  /// living-step predict outcome, including diagnostic-only collisions.
  Future<void> step() async {
    if (ended) {
      return;
    }
    final String state = buildStateString();
    final LayaQuestion question = buildTurnQuestion();
    final Map<String, String> options = Map<String, String>.from(
      question.criteria! as Map<String, String>,
    );
    final Map<String, LayaQuestion> questions = <String, LayaQuestion>{
      question.id: question,
    };
    final CardinalHeading headingBefore = heading;
    final GridCell headBefore = head;
    final GridCell? foodBefore = food;
    final int? progressBefore = _distanceToFood(headBefore);
    final List<String> recentBefore = List<String>.unmodifiable(_recentChoices);
    final Map<String, LayaAnswer> answers;
    try {
      answers = await predict(state, questions);
    } catch (_) {
      _notifyChoiceRecord(
        SnakeChoiceRecord(
          instructions: question.instructions,
          options: options,
          state: state,
          heading: headingBefore,
          head: headBefore,
          food: foodBefore,
          goal: _goal,
          progressMetric: _progressMetric,
          progressBefore: progressBefore,
          progressAfter: null,
          progressDelta: null,
          recentChoices: recentBefore,
          choice: null,
          attemptedCell: null,
          validation: SnakeChoiceValidation.predictFailure,
          repeatedTurn: false,
          reason: SnakeChoiceNoChoiceReason.predictFailure,
          probabilities: null,
          confidence: null,
        ),
      );
      return;
    }
    final LayaAnswer? turn = answers['turn'];
    final String? choice = turn?.choice;
    if (choice == null || !_isRelativeTurnKey(choice)) {
      _notifyChoiceRecord(
        SnakeChoiceRecord(
          instructions: question.instructions,
          options: options,
          state: state,
          heading: headingBefore,
          head: headBefore,
          food: foodBefore,
          goal: _goal,
          progressMetric: _progressMetric,
          progressBefore: progressBefore,
          progressAfter: null,
          progressDelta: null,
          recentChoices: recentBefore,
          choice: choice,
          attemptedCell: null,
          validation: SnakeChoiceValidation.missingOrNonRelativeKey,
          repeatedTurn: false,
          reason: SnakeChoiceNoChoiceReason.missingOrNonRelativeKey,
          probabilities: turn?.probabilities,
          confidence: turn?.confidence,
        ),
      );
      return;
    }
    final CardinalHeading nextHeading = _rotate(headingBefore, choice);
    final GridCell attemptedCell = _cellInHeading(headBefore, nextHeading);
    final bool wall = _isWall(attemptedCell);
    final bool body = !wall && _isBody(attemptedCell);
    final SnakeChoiceValidation validation = wall
        ? SnakeChoiceValidation.wallCollision
        : body
        ? SnakeChoiceValidation.bodyCollision
        : SnakeChoiceValidation.accepted;
    final SnakeChoiceNoChoiceReason? reason = wall
        ? SnakeChoiceNoChoiceReason.wallCollision
        : body
        ? SnakeChoiceNoChoiceReason.bodyCollision
        : null;
    final int? progressAfter = _distanceToFood(attemptedCell);
    final List<String> recentWithChoice = <String>[...recentBefore, choice];
    final bool repeatedTurn = _hasRepeatedPattern(recentWithChoice);
    _recentChoices
      ..add(choice)
      ..removeRange(
        0,
        _recentChoices.length > 4 ? _recentChoices.length - 4 : 0,
      );
    _notifyChoiceRecord(
      SnakeChoiceRecord(
        instructions: question.instructions,
        options: options,
        state: state,
        heading: headingBefore,
        head: headBefore,
        food: foodBefore,
        goal: _goal,
        progressMetric: _progressMetric,
        progressBefore: progressBefore,
        progressAfter: progressAfter,
        progressDelta: progressBefore == null || progressAfter == null
            ? null
            : progressBefore - progressAfter,
        recentChoices: recentBefore,
        choice: choice,
        attemptedCell: attemptedCell,
        validation: validation,
        repeatedTurn: repeatedTurn,
        reason: reason,
        probabilities: turn!.probabilities,
        confidence: turn.confidence,
      ),
    );
    _applyChoiceAndAdvance(nextHeading: nextHeading, next: attemptedCell);
  }

  void _notifyChoiceRecord(SnakeChoiceRecord record) {
    final SnakeChoiceRecordCallback? callback = onChoiceRecord;
    if (callback == null) {
      return;
    }
    callback(record);
  }

  void _applyChoiceAndAdvance({
    required CardinalHeading nextHeading,
    required GridCell next,
  }) {
    if (ended) {
      return;
    }
    if (_isWall(next) || _isBody(next)) {
      ended = true;
      return;
    }
    heading = nextHeading;
    final bool ate = food != null && next == food;
    _snake.insert(0, next);
    if (ate) {
      spawnFood();
    } else {
      _snake.removeLast();
    }
  }

  bool _isRelativeTurnKey(String choice) =>
      choice == 'left' || choice == 'right' || choice == 'straight';

  String _candidateDescription(String choice) {
    final GridCell candidate = _cellInHeading(head, _rotate(heading, choice));
    final String distance = _distanceToFood(candidate)?.toString() ?? 'none';
    return '$choice: next cell (${candidate.col},${candidate.row}); '
        'cell kind ${_classify(candidate)}; distance to food $distance.';
  }

  int? _distanceToFood(GridCell cell) {
    final GridCell? target = food;
    if (target == null) {
      return null;
    }
    return (target.col - cell.col).abs() + (target.row - cell.row).abs();
  }

  String _relativeFoodPosition(GridCell from, GridCell target) {
    final int columnDelta = target.col - from.col;
    final int rowDelta = target.row - from.row;
    int forward;
    int right;
    switch (heading) {
      case CardinalHeading.north:
        forward = -rowDelta;
        right = columnDelta;
      case CardinalHeading.east:
        forward = columnDelta;
        right = rowDelta;
      case CardinalHeading.south:
        forward = rowDelta;
        right = -columnDelta;
      case CardinalHeading.west:
        forward = -columnDelta;
        right = -rowDelta;
    }
    final List<String> sides = <String>[];
    if (forward > 0) {
      sides.add('ahead');
    } else if (forward < 0) {
      sides.add('behind');
    }
    if (right > 0) {
      sides.add('right');
    } else if (right < 0) {
      sides.add('left');
    }
    return sides.isEmpty ? 'same cell' : sides.join(' and ');
  }

  bool _hasRepeatedPattern(List<String> choices) {
    if (choices.length >= 3) {
      final int last = choices.length - 1;
      if (choices[last] == choices[last - 1] &&
          choices[last] == choices[last - 2]) {
        return true;
      }
    }
    if (choices.length < 4) {
      return false;
    }
    final int last = choices.length - 1;
    return choices[last] == choices[last - 2] &&
        choices[last - 1] == choices[last - 3] &&
        choices[last] != choices[last - 1];
  }

  CardinalHeading _rotate(CardinalHeading current, String choice) {
    switch (choice) {
      case 'straight':
        return current;
      case 'left':
        switch (current) {
          case CardinalHeading.north:
            return CardinalHeading.west;
          case CardinalHeading.east:
            return CardinalHeading.north;
          case CardinalHeading.south:
            return CardinalHeading.east;
          case CardinalHeading.west:
            return CardinalHeading.south;
        }
      case 'right':
        switch (current) {
          case CardinalHeading.north:
            return CardinalHeading.east;
          case CardinalHeading.east:
            return CardinalHeading.south;
          case CardinalHeading.south:
            return CardinalHeading.west;
          case CardinalHeading.west:
            return CardinalHeading.north;
        }
      default:
        return current;
    }
  }

  GridCell _cellInHeading(GridCell from, CardinalHeading dir) {
    switch (dir) {
      case CardinalHeading.north:
        return GridCell(from.col, from.row - 1);
      case CardinalHeading.east:
        return GridCell(from.col + 1, from.row);
      case CardinalHeading.south:
        return GridCell(from.col, from.row + 1);
      case CardinalHeading.west:
        return GridCell(from.col - 1, from.row);
    }
  }

  bool _isWall(GridCell cell) =>
      cell.col < 0 || cell.col >= width || cell.row < 0 || cell.row >= height;

  bool _isBody(GridCell cell) => _snake.contains(cell);

  String _classify(GridCell cell) {
    if (_isWall(cell)) {
      return 'wall';
    }
    if (_isBody(cell)) {
      return 'body';
    }
    if (food != null && cell == food) {
      return 'food';
    }
    return 'empty';
  }
}
