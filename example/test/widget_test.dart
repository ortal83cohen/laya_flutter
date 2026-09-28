import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:laya_flutter_example/main.dart';

void main() {
  testWidgets('autostart without bundle shows actionable setup guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ExampleApp(autostart: true, snakeCheckpointDir: ''),
    );
    await tester.pump();

    expect(
      find.textContaining('Snake checkpoint is not configured.'),
      findsOneWidget,
    );
    expect(find.textContaining('app_settings.dart'), findsOneWidget);
    expect(find.text('Opening…'), findsNothing);
  });

  testWidgets('idle example home shows Laya without opening a session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    // A second frame runs a post-frame callback if mount scheduled one.
    // Autostart off must still not show the opening label.
    await tester.pump();

    expect(find.text('Laya'), findsWidgets);
    // Idle pump must not require or trigger ONNX session open.
    expect(find.text('Opening…'), findsNothing);
  });

  test('production entry enables autostart without open before runApp', () {
    final String source = File('lib/main.dart').readAsStringSync();

    expect(
      source.contains('runApp(const ExampleApp(autostart: true))'),
      isTrue,
      reason: 'production entry must construct the root with autostart on',
    );
    expect(
      RegExp(r'void main\(\)\s*\{[^}]*await').hasMatch(source),
      isFalse,
      reason: 'runApp must stay synchronous; do not await open before runApp',
    );
    expect(
      source.contains("this.autostart = false"),
      isTrue,
      reason: 'ExampleApp autostart must default off',
    );
  });

  test('autostart path has no play button and reuses open chrome', () {
    final String source = File('lib/main.dart').readAsStringSync();

    expect(
      source.contains('Play Snake'),
      isFalse,
      reason: 'autostart path must not present a Play Snake control',
    );
    expect(
      source.contains('Opening…'),
      isTrue,
      reason: 'existing opening label must remain',
    );
    expect(
      source.contains('Could not open runtime:'),
      isTrue,
      reason: 'existing open-failure text must remain',
    );
    expect(
      source.contains('SnakeScreen'),
      isTrue,
      reason: 'Snake is reached via navigation after a successful open',
    );

    // Failure sets error chrome and does not push Snake in the catch path.
    final int catchIndex = source.indexOf('} catch (e) {');
    expect(catchIndex, greaterThan(-1));
    final String catchBlock = source.substring(catchIndex);
    final int finallyIndex = catchBlock.indexOf('} finally {');
    expect(finallyIndex, greaterThan(-1));
    final String failureBody = catchBlock.substring(0, finallyIndex);
    expect(
      failureBody.contains('Could not open runtime:'),
      isTrue,
      reason: 'open failure must set the existing failure text',
    );
    expect(
      failureBody.contains('SnakeScreen'),
      isFalse,
      reason: 'open failure must not navigate to Snake',
    );
    expect(
      failureBody.contains('Navigator'),
      isFalse,
      reason: 'open failure must not navigate away from home',
    );
  });
}
