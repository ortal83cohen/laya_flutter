# Research: Mobile tokenizer path for LayaFlutter.open

## Question

What can make LayaFlutter.open's existing Tokenizer.fromFile / HfTextEncoder path succeed on Android
and iOS, given that hf_tokenizers 1.2.2 has no mobile prebuilts and the example third_party stub
throws UnsupportedError?

## Answer

The published `hf_tokenizers` 1.2.2 path cannot tokenize on Android or iOS: the build hook refuses
those OS targets, and the example’s `third_party` stand-in throws on every `Tokenizer` call so
`HfTextEncoder.fromFile` never returns. A viable path that keeps the public `LayaFlutter.open` and
`LoadedRuntime.predict` signatures closed is to back `TextEncoder` with
`dart_sentencepiece_tokenizer` 1.4.1, which is pure Dart, supports Android and iOS, and loads
Hugging Face `tokenizer.json`. A second viable path is to ship or wait for cross-compiled
`hf_tokenizers` mobile natives so the existing Rust FFI `Tokenizer.fromFile` works without a
reimplementation. Keeping the throw stub (or the published package alone) cannot succeed.

## Findings

### GOAL and prior stream: open needs a real tokenizer after the ONNX session

- Claim: SC-005 requires Snake on Android and iOS. Inference runtime stays ONNX /
  `flutter_onnxruntime` (closed; not reopened). `LayaFlutter.open` creates the ONNX session, then
  builds `HfTextEncoder.fromFile` via `Tokenizer.fromFile`; the example navigates to Snake only
  after open returns. The example override lets the app compile but every stub `Tokenizer` call
  throws `UnsupportedError`.
- Evidence: SC-005 and required platforms at `wiki/product/GOAL.md:17-19` and
  `wiki/product/GOAL.md:45`; session then encoder at `lib/src/library.dart:45-58`;
  `HfTextEncoder.fromFile` at `lib/src/tokenize.dart:44-45`; stub throws at
  `example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:9-34`; prior stream conclusion at
  `wiki/work/0006-snake-platform-launch/research/mobile-session.md:7-9`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0006-snake-platform-launch/research/mobile-session.md`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/third_party/hf_tokenizers/lib/hf_tokenizers.dart`

### HfTextEncoder only needs encode plus special-token ids; LoadedRuntime uses TextEncoder

- Claim: `HfTextEncoder` wraps `Tokenizer` for `tokenToId` of `<bos>`, `<eos>`, `<mask>`, `<pad>`
  and `encode(..., addSpecialTokens:)` (library calls use `addSpecialTokens: false` in sequence
  building). `LoadedRuntime.predict` takes `TextEncoder` through collation, not the `hf_tokenizers`
  type name. Public `open(Directory cache, …)` and `predict(Object state, Object questions)` do not
  expose `Tokenizer`.
- Evidence: Constructor and encode at `lib/src/tokenize.dart:34-95`; `buildSequence` /
  `tokenizeForOnnx` encode calls at `lib/src/tokenize.dart:215-256` and
  `lib/src/tokenize.dart:343-346`; `LoadedRuntime` fields and `predict` at
  `lib/src/loaded_runtime.dart:15-63` and `lib/src/loaded_runtime.dart:73-78`; `open` at
  `lib/src/library.dart:25-58`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/loaded_runtime.dart`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`

### Published hf_tokenizers 1.2.2 API and mobile refusal

- Claim: Published `Tokenizer.fromFile` / `fromBytes`, `encode`, and `tokenToId` are the surface
  `HfTextEncoder` uses. Platforms are linux/macos/windows only. The hook throws for `OS.android` /
  `OS.iOS` because no cross-compiled prebuilts exist. The README marks Android/iOS “not supported
  yet” and points phone users at pure-Dart `dart_sentencepiece_tokenizer` for Gemma/Llama-shaped
  BPE/Unigram `tokenizer.json` pipelines (not WordPiece/BERT).
- Evidence: API at `~/.pub-cache/hosted/pub.dev/hf_tokenizers-1.2.2/lib/hf_tokenizers.dart:97-192`;
  `platforms:` at that package’s `pubspec.yaml:25-28`; hook throw at `hook/build.dart:143-149`;
  mobile table and “When to use something else” naming `dart_sentencepiece_tokenizer` in the package
  README (pub.dev / cached README around the Android/iOS row and lines 361-373).
- Source: `https://pub.dev/packages/hf_tokenizers` (1.2.2, consulted 2026-09-27);
  `/Users/ortalcohen/.pub-cache/hosted/pub.dev/hf_tokenizers-1.2.2/`

### Example stub matches the API names but intentionally fails

- Claim: `example/pubspec.yaml` overrides `hf_tokenizers` to `third_party/hf_tokenizers` so
  Android/iOS builds avoid the published hook. The stand-in declares `Tokenizer.fromFile` /
  `fromBytes` / `tokenToId` / `encode` and throws `UnsupportedError` stating there is no mobile
  binary and that `LayaFlutter.open` cannot tokenize on the device yet.
- Evidence: Comment and override at `example/pubspec.yaml:20-25`; stub at
  `example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:1-34`.
- Source: `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/pubspec.yaml`;
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/third_party/hf_tokenizers/lib/hf_tokenizers.dart`

### Host tokenizer.json is SentencePiece-oriented BPE that matches the pure-Dart loader’s stated pipeline

- Claim: The local multilingual companion `$HOME/.cache/laya_flutter/tokenizer.json` (structure
  only; not committed) is Hugging Face format version `1.0` with `model.type` `BPE`, vocab size
  256000, `byte_fallback` true, `pre_tokenizer` `Metaspace`, `normalizer` `Replace` (space → `▁`),
  `post_processor` `TemplateProcessing` with `<bos>`/`<eos>`, and special tokens `<pad>`=0, `<eos>`
  =1, `<bos>`=2, `<mask>`=4 in `added_tokens` / vocab. That shape is in the SentencePiece-oriented
  set `dart_sentencepiece_tokenizer` documents (`BPE`/`Unigram`, `Metaspace`, `Replace`,
  `TemplateProcessing`).
- Evidence: Parsed fields from the host file on 2026-09-27; loader docs at
  `https://pub.dev/packages/dart_sentencepiece_tokenizer` and
  `https://pub.dev/documentation/dart_sentencepiece_tokenizer/latest/dart_sentencepiece_tokenizer/HuggingFaceTokenizerLoader-class.html` (
  consulted 2026-09-27).
- Source: `$HOME/.cache/laya_flutter/tokenizer.json` (read-only structure); those pub.dev pages

### dart_sentencepiece_tokenizer 1.4.1: pub.dev package that loads tokenizer.json on Android and iOS

- Claim: `dart_sentencepiece_tokenizer` 1.4.1 is pure Dart, zero runtime dependencies, and pub.dev
  scores it as supporting Android and iOS (not web, because of `dart:io`). It accepts Hugging Face
  `tokenizer.json` via `TokenizerJsonLoader` / `HuggingFaceTokenizerLoader.fromJsonFile` /
  `fromJsonFileSync`. Encode returns ids; `convertTokensToIds` covers special-token lookup. The
  package page states Hugging Face `tokenizer.json` loading for SentencePiece BPE/Unigram pipelines
  including Metaspace.
- Evidence: Package metadata and README at `https://pub.dev/packages/dart_sentencepiece_tokenizer` (
  1.4.1); platform score at `https://pub.dev/packages/dart_sentencepiece_tokenizer/score` (Android
  ✓, iOS ✓, consulted 2026-09-27); loader API at the HuggingFaceTokenizerLoader dartdoc URL above.
- Source: those URLs

### Probe: same host tokenizer.json encodes equal to hf_tokenizers on sample strings

- Claim: On this host, `HuggingFaceTokenizerLoader.fromJsonFileSync` loaded the Laya
  `tokenizer.json` (`vocabSize` 256000). Special ids for `<bos>`, `<eos>`, `<mask>`, `<pad>`,
  `<unk>` matched `hf_tokenizers` `tokenToId`. Several `encode(..., addSpecialTokens: false)`
  samples (including Snake-like option/state strings) and empty-string `addSpecialTokens: true` (
  `[2, 1]`) matched id-for-id against `Tokenizer.fromFile` from `hf_tokenizers` 1.2.2.
- Evidence: Temporary probe under `/tmp/dspt_probe` using packages `dart_sentencepiece_tokenizer`
  1.4.1 and `hf_tokenizers` 1.2.2 against `$HOME/.cache/laya_flutter/tokenizer.json` on 2026-09-27 (
  not committed).
- Source: probe command output 2026-09-27; packages from pub.dev as cited above
-
Note: [UNVERIFIED: byte-exact encode parity on the full frozen fixture set used for SC-002, and encode/load behaviour under Android/iOS memory limits for this ~34 MB JSON with ~580k merges.]

### Public open / predict signatures can stay closed

- Claim: Neither viable option requires changing the public signatures of `LayaFlutter.open` or
  `LoadedRuntime.predict`. Wiring can stay behind `TextEncoder` / `HfTextEncoder.fromFile`
  internals (library dependency swap or a mobile `TextEncoder` implementation), or behind an example
  `dependency_overrides` that implements the `Tokenizer` surface without throwing. No finding in
  this stream showed that tokenization is impossible without changing those two public signatures.
- Evidence: Closed surfaces at `lib/src/library.dart:25-28` and `lib/src/loaded_runtime.dart:60-63`;
  abstraction at `lib/src/tokenize.dart:9-15`.
- Source: those paths

### flutter_embedder is not a clean dual-platform tokenizer-only fix

- Claim: `flutter_embedder` documents `HfTokenizer` loading from `tokenizer.json` assets/paths, but
  it is an FFI plugin bundling Hugging Face tokenizers with ONNX Runtime embeddings; platform docs
  state Android as primary for embeddings and that other platforms may need extra ORT setup. It
  would add a second native ORT stack beside the closed `flutter_onnxruntime` choice and does not
  establish iOS tokenizer support as clearly as the pure-Dart package.
- Evidence: `https://pub.dev/packages/flutter_embedder` (0.1.7, consulted 2026-09-27), sections
  Usage / Platform support / Android setup.
- Source: that pub.dev page

## Options considered

| Option                                                                                                                                     | How it works                                                                                                                                                                                             | Cost                                                                                                                                                                  | Why rejected / chosen                                                                                                                                                                                                                                                            |
|--------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| A. Pure-Dart `dart_sentencepiece_tokenizer` behind `TextEncoder` / `HfTextEncoder` (or a non-throwing override of the `Tokenizer` surface) | Load the same on-disk `tokenizer.json` with `HuggingFaceTokenizerLoader` / `TokenizerJsonLoader`; map `encode` and special-token ids into the existing `TextEncoder` contract used by `open` → `predict` | New dependency; must prove fixture-level id parity (SC-002) and mobile load cost for ~34 MB JSON; library or example wiring change under the closed public signatures | **Chosen** for making open succeed on Android and iOS without waiting on Rust mobile prebuilts: pub.dev documents Android/iOS + `tokenizer.json`; host probe matched `hf_tokenizers` on Laya samples; `hf_tokenizers` README itself points phone users here for this model class |
| B. Ship or wait for cross-compiled `hf_tokenizers` Android/iOS natives (upstream release or a maintained fork/hook with prebuilts)         | Keep `Tokenizer.fromFile` / Rust `tokenizers` crate so `HfTextEncoder` stays as written; remove or replace the throw stub once binaries exist                                                            | Cross-compile + package hook/CI for Android and iOS ABIs; until then published 1.2.2 still fails the hook; engineering and release ownership                          | **Viable** when byte-exact Rust parity is mandatory and someone owns mobile prebuilts; not available in 1.2.2 today (`hook/build.dart:143-149`, README platform table)                                                                                                           |
| C. Keep example `third_party` stub or published `hf_tokenizers` 1.2.2 alone                                                                | Stub: no hook, throws at runtime. Published: hook throws at build on mobile                                                                                                                              | Zero new tokenizer work                                                                                                                                               | **Rejected** — neither path produces token ids on Android/iOS; open cannot finish (`example/third_party/hf_tokenizers/lib/hf_tokenizers.dart:9-34`; published hook throw)                                                                                                        |

## Constraints discovered

- Public `LayaFlutter.open` and `LoadedRuntime.predict` signatures stay closed; tokenization can
  move behind `TextEncoder` without changing them (`lib/src/library.dart:25-58`;
  `lib/src/loaded_runtime.dart:60-63`).
- Library depends on `hf_tokenizers: ^1.2.2` (`pubspec.yaml:11-15`); example overrides it with a
  throw stub (`example/pubspec.yaml:20-25`).
- `HfTextEncoder` currently constructs `Tokenizer` from `package:hf_tokenizers` (
  `lib/src/tokenize.dart:4`, `lib/src/tokenize.dart:44-54`).
- Published `hf_tokenizers` 1.2.2: no Android/iOS platforms or prebuilts; hook throws (
  `https://pub.dev/packages/hf_tokenizers`; `hook/build.dart:143-149`).
- Host Laya `tokenizer.json` is BPE + Metaspace + Replace + TemplateProcessing, vocab 256000,
  specials `<pad>`/`<eos>`/`<bos>`/`<mask>` (`$HOME/.cache/laya_flutter/tokenizer.json` structure).
- `dart_sentencepiece_tokenizer` 1.4.1 accepts `tokenizer.json`, supports Android and iOS, pure
  Dart (`https://pub.dev/packages/dart_sentencepiece_tokenizer`, score page).
- SC-002 still requires choice/score/noul parity with Python on the frozen fixtures; sample host
  parity is not a full fixture proof (`wiki/product/GOAL.md:41`).
- ONNX runtime choice remains closed; do not replace inference with `flutter_embedder`’s ORT stack
  for this question.

## Unresolved

- [UNRESOLVED: Does `dart_sentencepiece_tokenizer` 1.4.1 match
  `hf_tokenizers` / Python Laya on every frozen SC-002 fixture string and full Snake prompt, not only the host sample strings?]
- [UNRESOLVED: Can Android and iOS load this ~34 MB
  `tokenizer.json` (256k vocab, ~580k merges) within acceptable RAM and cold-start time in the example process?]
- [UNRESOLVED: Will upstream
  `hf_tokenizers` publish Android/iOS prebuilts, and on what timeline, versus maintaining a fork?]
- [UNRESOLVED: Should mobile use a library-level `TextEncoder` implementation (dependency in root
  `pubspec.yaml`) or an example-only non-throwing
  `Tokenizer` override, given desktop already has working `hf_tokenizers`?]
- [UNRESOLVED: Does any other pub.dev package besides
  `dart_sentencepiece_tokenizer` both accept this SentencePiece-oriented
  `tokenizer.json` and support Android and iOS without a second ORT stack? (
  `flutter_embedder` was inspected and not first-choice.)]

## Sources

- `/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/product/GOAL.md`, consulted 2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/work/0006-snake-platform-launch/research/mobile-session.md`,
consulted 2026-09-27
-
`/Users/ortalcohen/Documents/GitHub/laya_flutter/wiki/solutions/2026-09-27-macos-onnx-session-sandbox.md`,
consulted 2026-09-27 (cited by prior stream; not reopened)
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/tokenize.dart`,
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/library.dart`,
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/lib/src/loaded_runtime.dart`, consulted
  2026-09-27
- `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/pubspec.yaml`,
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/example/third_party/hf_tokenizers/lib/hf_tokenizers.dart`,
  `/Users/ortalcohen/Documents/GitHub/laya_flutter/pubspec.yaml`, consulted 2026-09-27
- `$HOME/.cache/laya_flutter/tokenizer.json` (structure only), consulted 2026-09-27
- `https://pub.dev/packages/hf_tokenizers` (1.2.2) and
  `/Users/ortalcohen/.pub-cache/hosted/pub.dev/hf_tokenizers-1.2.2/`, consulted 2026-09-27
- `https://pub.dev/packages/dart_sentencepiece_tokenizer` (1.4.1), score page, and
  HuggingFaceTokenizerLoader dartdoc, consulted 2026-09-27
- `https://pub.dev/packages/flutter_embedder` (0.1.7), consulted 2026-09-27
- Host probe `/tmp/dspt_probe` encode comparison, 2026-09-27
