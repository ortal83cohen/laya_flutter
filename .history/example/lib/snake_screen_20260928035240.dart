import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:laya_flutter/laya_flutter.dart';

import 'snake_controller.dart';

/// Classic Snake board driven by an already-loaded [LoadedRuntime].
///
/// Constructs [SnakeController] with a predict closure that calls the real
/// [LoadedRuntime.predict] when [predictOverride] is absent. Steps are
/// await-gated: each [SnakeController.step] finishes before [setState]
/// redraws, and the next step starts only after that. After wall or body
/// death, replaces the controller and continues the same loop.
class SnakeScreen extends StatefulWidget {
  /// Creates a Snake screen backed by [runtime].
  ///
  /// When [predictOverride] is set, every step uses that closure only and
  /// never calls [LoadedRuntime.predict] or open.
  const SnakeScreen({
    super.key,
    required this.runtime,
    @visibleForTesting this.predictOverride,
  });

  /// Loaded offline runtime used for every step's predict call in production.
  final LoadedRuntime runtime;

  /// Optional predict seam for session-free tests. Absent in production.
  @visibleForTesting
  final SnakePredict? predictOverride;

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  late SnakeController _controller;
  late final math.Random _random;
  bool _loopStarted = false;

  @override
  void initState() {
    super.initState();
    _random = math.Random();
    _controller = _createController();
  }

  /// Builds a fresh controller matching production construction defaults.
  SnakeController _createController() {
    final SnakePredict? override = widget.predictOverride;
    return SnakeController(
      width: 40,
      height: 40,
      random: _random,
      // Production: real offline predict. Tests: override only, never runtime.
      predict:
          override ??
          (Object state, Object questions) =>
              widget.runtime.predict(state, questions),
      // One console line per finished attempt; no on-screen log chrome.
      onChoiceRecord: (SnakeChoiceRecord record) {
        debugPrint(record.toString());
      },
    );
  }

  /// Replaces the ended controller with a newly constructed one.
  void _startNewRun() {
    _controller = _createController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loopStarted) {
      _loopStarted = true;
      _runSteps();
    }
  }

  /// Awaits each controller step, then redraws from controller state.
  ///
  /// Starts the next step only after the await finishes. When a step returns
  /// without ending and without moving cells (predict failure or missing
  /// choice), stop further steps so the loop does not spin — and do not start
  /// a new run. When the run ends on wall or body, start a new run in this
  /// same loop and continue await-gated steps without open, timer, or a
  /// second concurrent loop.
  Future<void> _runSteps() async {
    while (mounted) {
      while (mounted && !_controller.ended) {
        final List<GridCell> cellsBefore = List<GridCell>.from(
          _controller.snakeCells,
        );
        await _controller.step();
        if (!mounted) {
          return;
        }
        setState(() {});
        // No ended flag and no cell change means the step did not advance;
        // keep the board and do not call step again in a tight loop.
        // Predict failure must not trigger a new run.
        if (!_controller.ended &&
            _sameSnakeCells(cellsBefore, _controller.snakeCells)) {
          return;
        }
      }
      if (!mounted) {
        return;
      }
      if (!_controller.ended) {
        return;
      }
      // Wall or body death: constructor replacement, then continue this loop.
      setState(_startNewRun);
    }
  }

  bool _sameSnakeCells(List<GridCell> before, List<GridCell> after) {
    if (before.length != after.length) {
      return false;
    }
    for (var i = 0; i < before.length; i++) {
      if (before[i] != after[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_controller.ended ? 'Snake — ended' : 'Snake'),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _BoardView(
              width: _controller.width,
              height: _controller.height,
              snakeCells: _controller.snakeCells,
              food: _controller.food,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple grid of empty, snake, and food cells.
class _BoardView extends StatelessWidget {
  const _BoardView({
    required this.width,
    required this.height,
    required this.snakeCells,
    required this.food,
  });

  final int width;
  final int height;
  final List<GridCell> snakeCells;
  final GridCell? food;

  @override
  Widget build(BuildContext context) {
    final Set<GridCell> body = snakeCells.toSet();
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width,
      ),
      itemCount: width * height,
      itemBuilder: (BuildContext context, int index) {
        final GridCell cell = GridCell(index % width, index ~/ width);
        final Color color;
        if (body.contains(cell)) {
          color = Colors.green.shade700;
        } else if (food != null && cell == food) {
          color = Colors.red.shade600;
        } else {
          color = Colors.grey.shade200;
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade400, width: 0.5),
          ),
        );
      },
    );
  }
}
