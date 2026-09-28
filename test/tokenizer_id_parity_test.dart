import 'dart:convert';
import 'dart:io';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hf_tokenizers/hf_tokenizers.dart';

/// Resolves the host `tokenizer.json` used for id-parity checks.
///
/// Prefers [LAYA_TOKENIZER_PATH], otherwise `$HOME/.cache/laya_flutter/tokenizer.json`.
File tokenizerJsonFile() {
  final String? fromEnv = Platform.environment['LAYA_TOKENIZER_PATH'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return File(fromEnv);
  }
  final String? home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    fail(
      'tokenizer.json path unset: set LAYA_TOKENIZER_PATH or HOME '
      '(expected \$HOME/.cache/laya_flutter/tokenizer.json)',
    );
  }
  return File('$home/.cache/laya_flutter/tokenizer.json');
}

void main() {
  test(
    'fixture state strings encode equal ids with addSpecialTokens false',
    () {
      final File tokenizerFile = tokenizerJsonFile();
      if (!tokenizerFile.existsSync()) {
        fail(
          'Missing tokenizer.json at ${tokenizerFile.path}. '
          'Place the Laya tokenizer there or set LAYA_TOKENIZER_PATH.',
        );
      }

      final File fixturesFile = File('test/fixtures/parity_fixtures.json');
      expect(
        fixturesFile.existsSync(),
        isTrue,
        reason: 'frozen parity fixtures must be present',
      );
      final Map<String, dynamic> root =
          jsonDecode(fixturesFile.readAsStringSync()) as Map<String, dynamic>;
      final List<dynamic> fixtures = root['fixtures'] as List<dynamic>;
      expect(fixtures, isNotEmpty);

      final String path = tokenizerFile.path;
      final Tokenizer hf = Tokenizer.fromFile(path);
      final SentencePieceTokenizer dartSp =
          HuggingFaceTokenizerLoader.fromJsonFileSync(path);

      // Same specials the example override must resolve for open.
      for (final String token in <String>[
        '<bos>',
        '<eos>',
        '<mask>',
        '<pad>',
      ]) {
        final int? hfId = hf.tokenToId(token);
        expect(hfId, isNotNull, reason: 'hf_tokenizers missing $token');
        final int dartId = dartSp.convertTokensToIds(<String>[token]).first;
        expect(dartId, hfId, reason: 'pure-Dart id mismatch for $token');
      }

      for (final dynamic raw in fixtures) {
        final Map<String, dynamic> fx = raw as Map<String, dynamic>;
        final String id = fx['id'] as String;
        final String state = fx['state'] as String;
        final List<int> hfIds = hf.encode(state, addSpecialTokens: false);
        final List<int> dartIds = dartSp
            .encode(state, addSpecialTokens: false)
            .ids
            .toList();
        expect(
          dartIds,
          hfIds,
          reason:
              'id sequences differ for fixture $id with addSpecialTokens false',
        );
      }

      hf.close();
    },
  );
}
