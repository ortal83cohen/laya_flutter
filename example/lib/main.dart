// Example application for the laya_flutter library.
//
// This file is the application entry point. Run it from the example
// project. The package root is a library and is not a run target. In
// Android Studio, opened on the repository root, use the example run
// configuration.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:laya_flutter/laya_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'snake_screen.dart';

void main() {
  runApp(const ExampleApp(autostart: true));
}

/// Host cache directory already allowed by the macOS sandbox solution.
///
/// Matches `$HOME/.cache/laya_flutter` (or `LAYA_CACHE_DIR` when set).
/// Used for non-mobile launches only.
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

/// Cache directory passed into [LayaFlutter.open].
///
/// On Android and iOS this is the application support directory plus a
/// `laya_flutter` child so the process can read and write artifacts. Incomplete
/// caches still use the library first-run download into that directory.
/// Non-mobile launches keep [resolveHostCache].
Future<Directory> resolveExampleCache() async {
  if (Platform.isAndroid || Platform.isIOS) {
    final Directory support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}laya_flutter');
  }
  return resolveHostCache();
}

/// Root widget for the example app.
///
/// [autostart] defaults to off so a bare construction stays idle: mounting does
/// not open an ONNX session. Production entry passes [autostart] on.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  ///
  /// When [autostart] is false (the default), the home does not begin session
  /// open on mount. When true, the home starts the open-then-navigate path once.
  const ExampleApp({super.key, this.autostart = false});

  /// When true, the home begins opening the runtime without a play control.
  final bool autostart;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'laya_flutter example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: ExampleHomePage(autostart: autostart),
    );
  }
}

/// Home: title chrome and optional autostart of open-then-navigate to Snake.
class ExampleHomePage extends StatefulWidget {
  /// Creates the home page.
  ///
  /// When [autostart] is true, starts the existing open path once after mount.
  const ExampleHomePage({super.key, this.autostart = false});

  /// When true, begin open without a play button.
  final bool autostart;

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  bool _opening = false;
  String? _error;
  bool _autostartScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.autostart || _autostartScheduled) {
      return;
    }
    _autostartScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openSnake();
      }
    });
  }

  Future<void> _openSnake() async {
    if (_opening) {
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final LoadedRuntime runtime = await LayaFlutter.open(
        await resolveExampleCache(),
      );
      if (!mounted) {
        await runtime.close();
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => SnakeScreen(runtime: runtime),
        ),
      );
      await runtime.close();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not open runtime: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laya')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Laya', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              const Text('Classic Snake driven by offline Laya predict.'),
              if (_opening) ...<Widget>[
                const SizedBox(height: 24),
                const Text('Opening…'),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
