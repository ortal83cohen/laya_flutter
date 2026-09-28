import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';

/// Example-only stand-in for `package:hf_tokenizers` on Android and iOS.
///
/// The published package has no mobile prebuilt and its build hook fails on
/// those platforms. This override loads the same Hugging Face `tokenizer.json`
/// with `dart_sentencepiece_tokenizer` so [Tokenizer.fromFile], [tokenToId],
/// and [encode] work for `LayaFlutter.open` without changing library APIs.
final class Tokenizer {
  Tokenizer._(this._inner);

  final SentencePieceTokenizer _inner;

  /// Loads a Hugging Face `tokenizer.json` from [json] bytes.
  factory Tokenizer.fromBytes(Uint8List json) {
    return Tokenizer._(
      HuggingFaceTokenizerLoader.fromJsonString(utf8.decode(json)),
    );
  }

  /// Loads a Hugging Face `tokenizer.json` from [path].
  factory Tokenizer.fromFile(String path) {
    return Tokenizer._(HuggingFaceTokenizerLoader.fromJsonFileSync(path));
  }

  /// Vocabulary id for [token], or null when the piece is not in the vocab.
  int? tokenToId(String token) {
    final int id = _inner.convertTokensToIds(<String>[token]).first;
    final String piece = _inner.convertIdsToTokens(<int>[id]).first;
    if (piece != token) {
      return null;
    }
    return id;
  }

  /// Encodes [text] to token ids.
  ///
  /// Library sequence building passes [addSpecialTokens] false; that flag is
  /// honoured here the same way as the pure-Dart loader.
  List<int> encode(String text, {bool addSpecialTokens = true}) {
    return _inner.encode(text, addSpecialTokens: addSpecialTokens).ids.toList();
  }
}
