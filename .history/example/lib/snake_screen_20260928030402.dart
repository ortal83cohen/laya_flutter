import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:laya_flutter/laya_flutter.dart';

import 'snake_controller.dart';

/// Classic Snake board driven by an already-loaded [LoadedRuntime].
///
/// Constructs [SnakeController] with a predict closure that calls the real
/// [LoadedRuntime.predict]. Steps are await-gated: each [SnakeController.step]
/// finishes before [setState] redraws, and the next step starts only after that.
class SnakeScreen extends StatefulWidget {
  /// Creates a Snake screen backed by [runtime].
  const SnakeScreen({super.key, required this.runtime});

  /// Loaded offline runtime used for every step's predict call.
  final LoadedRuntime runtime;

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  late final SnakeController _controller;
  bool _loopStarted = false;

  @override
  void initState() {
    super.initState();
    final LoadedRuntime runtime = widget.runtime;
    _controller = SnakeController(
      width: 40,
      height: 40,
      random: math.Random(),
      // Real offline predict — not a local turn table.
      predict: (Object state, Object questions) =>
          runtime.predict(state, questions),
    );
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
  /// Starts the next step only after the await finishes and the game is not
  /// ended. When a step returns without ending and without moving cells
  /// (predict failure or missing choice), stop further steps so the loop
  /// does not spin. Predict failure leaves the board as the controller left it.
  Future<void> _runSteps() async {
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
      if (!_controller.ended &&
          _sameSnakeCells(cellsBefore, _controller.snakeCells)) {
        return;
      }
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
