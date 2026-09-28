import 'package:flutter_test/flutter_test.dart';
import 'package:laya_flutter/laya_flutter.dart';

void main() {
  test('library facade can be constructed', () {
    const library = LayaFlutter();
    expect(library, isA<LayaFlutter>());
  });
}
