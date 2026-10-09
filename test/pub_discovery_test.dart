import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pub.dev listing names Jev and uses the discovery topics', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final String readme = File('README.md').readAsStringSync();
    final String description = _foldedDescription(pubspec);

    expect(description, contains('Jev'));
    expect(description, contains('Laya'));
    expect(description.length, inInclusiveRange(60, 180));
    expect(_topics(pubspec), <String>[
      'machine-learning',
      'on-device-ml',
      'onnx',
      'nlp',
      'ai',
    ]);
    expect(readme, contains('Jev'));
    expect(readme, contains('TypeSafe'));
    expect(readme, contains('open-weight'));
  });
}

/// The folded `description: >-` value pub.dev indexes.
String _foldedDescription(String pubspec) {
  final RegExp block = RegExp(
    r'^description: >-\n((?:  .*\n)+)',
    multiLine: true,
  );
  final Match match = block.firstMatch(pubspec)!;
  return match
      .group(1)!
      .split('\n')
      .where((String line) => line.trim().isNotEmpty)
      .map((String line) => line.trim())
      .join(' ');
}

List<String> _topics(String pubspec) {
  final int start = pubspec.indexOf('topics:\n');
  expect(start, isNonNegative);
  final List<String> topics = <String>[];
  for (final String line in pubspec.substring(start).split('\n').skip(1)) {
    if (!line.startsWith('  - ')) {
      break;
    }
    topics.add(line.substring(4).trim());
  }
  return topics;
}
