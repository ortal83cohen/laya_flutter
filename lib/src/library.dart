import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'checkpoint_store.dart';
import 'loaded_runtime.dart';
import 'tokenize.dart';

export 'answers.dart' show LayaAnswer, LayaQuestion, LayaQuestionType;
export 'loaded_runtime.dart' show LoadedRuntime, normalizeQuestions;

/// Public entry for offline multilingual Laya inference.
final class LayaFlutter {
  /// Creates the library facade.
  const LayaFlutter();

  /// Ensures the multilingual checkpoint is local under [cache], then loads it.
  ///
  /// Downloads missing artifacts from Hugging Face on the first successful call.
  /// A later call with a complete cache does not download.
  ///
  /// [download] overrides the Hugging Face fetcher (tests only).
  static Future<LoadedRuntime> open(
    Directory cache, {
    @visibleForTesting CheckpointDownloader? download,
    @visibleForTesting Future<OrtSession> Function(String path)? createSession,
  }) async {
    final CheckpointDownloader effectiveDownload =
        download ?? downloadMultilingualCheckpoint;
    final CheckpointStore store = CheckpointStore(
      cacheDirectory: cache,
      download: effectiveDownload,
    );
    await store.ensureLocal();

    final String onnxPath =
        '${cache.path}${Platform.pathSeparator}${CheckpointStore.onnxFileName}';
    final String tokenizerPath =
        '${cache.path}${Platform.pathSeparator}${CheckpointStore.tokenizerFileName}';
    final String configPath =
        '${cache.path}${Platform.pathSeparator}${CheckpointStore.rlAgentConfigFileName}';

    final Future<OrtSession> Function(String path) sessionFactory =
        createSession ?? (String path) => OnnxRuntime().createSession(path);
    final OrtSession session = await sessionFactory(onnxPath);

    final TextEncoder encoder = HfTextEncoder.fromFile(tokenizerPath);
    final config = readAgentConfig(File(configPath));
    return LoadedRuntime(
      session: session,
      encoder: encoder,
      temperature: config.temperature,
      temperatureByOptions: config.temperatureByOptions,
      maxLen: config.maxLen,
      headMaxLen: config.headMaxLen,
    );
  }
}

/// Downloads the four required multilingual artifacts into [directory].
///
/// ONNX comes from [CheckpointStore.onnxRepoId] at [CheckpointStore.onnxRepoPath].
/// Companions come from [CheckpointStore.companionsRepoId]. Skips the ONNX file
/// when it already exists with [CheckpointStore.expectedOnnxBytes], and reuses
/// the host cache copy under `$HOME/.cache/laya_flutter` when present.
Future<void> downloadMultilingualCheckpoint(Directory directory) async {
  await directory.create(recursive: true);
  final String sep = Platform.pathSeparator;

  final File onnxDest = File(
    '${directory.path}$sep${CheckpointStore.onnxFileName}',
  );
  if (!await _onnxReady(onnxDest)) {
    final File? hostCopy = await _findHostOnnxCopy();
    if (hostCopy != null) {
      await hostCopy.copy(onnxDest.path);
    } else {
      await _downloadHfFile(
        repoId: CheckpointStore.onnxRepoId,
        repoPath: CheckpointStore.onnxRepoPath,
        destination: onnxDest,
      );
    }
    if (!await _onnxReady(onnxDest)) {
      throw StateError(
        'ONNX artifact missing or wrong size at ${onnxDest.path}',
      );
    }
  }

  await _ensureCompanion(
    directory: directory,
    fileName: CheckpointStore.tokenizerFileName,
    repoPath: 'tokenizer/tokenizer.json',
  );
  await _ensureCompanion(
    directory: directory,
    fileName: CheckpointStore.tokenizerConfigFileName,
    repoPath: 'tokenizer/tokenizer_config.json',
  );
  await _ensureCompanion(
    directory: directory,
    fileName: CheckpointStore.rlAgentConfigFileName,
    repoPath: CheckpointStore.rlAgentConfigFileName,
  );
}

Future<bool> _onnxReady(File file) async {
  return await file.exists() &&
      await file.length() == CheckpointStore.expectedOnnxBytes;
}

Future<File?> _findHostOnnxCopy() async {
  final String? home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    return null;
  }
  final List<String> candidates = <String>[
    '$home/.cache/laya_flutter/onnx/multilingual/${CheckpointStore.onnxFileName}',
    '$home/.cache/laya_flutter/${CheckpointStore.onnxFileName}',
  ];
  for (final String path in candidates) {
    final File file = File(path);
    if (await _onnxReady(file)) {
      return file;
    }
  }
  return null;
}

Future<void> _ensureCompanion({
  required Directory directory,
  required String fileName,
  required String repoPath,
}) async {
  final File dest = File('${directory.path}${Platform.pathSeparator}$fileName');
  if (await dest.exists() && await dest.length() > 0) {
    return;
  }
  await _downloadHfFile(
    repoId: CheckpointStore.companionsRepoId,
    repoPath: repoPath,
    destination: dest,
  );
}

Future<void> _downloadHfFile({
  required String repoId,
  required String repoPath,
  required File destination,
}) async {
  final Uri uri = Uri.parse(
    'https://huggingface.co/$repoId/resolve/main/$repoPath',
  );
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.getUrl(uri);
    request.followRedirects = true;
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      final String body = await utf8.decodeStream(response);
      throw StateError(
        'Hugging Face download failed for $repoId/$repoPath '
        '(HTTP ${response.statusCode}): $body',
      );
    }
    final File tmp = File('${destination.path}.partial');
    final IOSink sink = tmp.openWrite();
    try {
      await response.pipe(sink);
    } catch (_) {
      try {
        await sink.close();
      } catch (_) {}
      if (await tmp.exists()) {
        await tmp.delete();
      }
      rethrow;
    }
    await tmp.rename(destination.path);
  } finally {
    client.close(force: true);
  }
}
