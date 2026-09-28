import 'dart:io';

/// Fills [directory] with the multilingual artifacts needed for offline inference.
///
/// The real Hugging Face client is supplied by a later task. Tests pass a
/// local writer so behaviour can be proven without the network.
typedef CheckpointDownloader = Future<void> Function(Directory directory);

/// Caller-chosen cache for the multilingual Laya ONNX graph and companions.
///
/// Required on-disk names (never [modelSafetensorsFileName]):
/// - [onnxFileName] from Hugging Face [onnxRepoId] at [onnxRepoPath]
/// - [tokenizerFileName], [tokenizerConfigFileName], [rlAgentConfigFileName]
///   from Hugging Face [companionsRepoId]
final class CheckpointStore {
  /// Creates a store for [cacheDirectory] that uses [download] when incomplete.
  CheckpointStore({required this.cacheDirectory, required this.download});

  /// Hugging Face repo that publishes the multilingual ONNX graph.
  static const String onnxRepoId = 'mariojcr/laya-onnx';

  /// Path inside [onnxRepoId] for the multilingual graph.
  static const String onnxRepoPath = 'multilingual/laya-multilingual.onnx';

  /// Hugging Face repo for tokenizer and temperature companions.
  static const String companionsRepoId = 'convaiinnovations/laya-multilingual';

  /// ONNX graph file name stored under the cache directory.
  static const String onnxFileName = 'laya-multilingual.onnx';

  /// Expected byte length of a complete [onnxFileName].
  static const int expectedOnnxBytes = 1290466290;

  /// Tokenizer vocabulary file name.
  static const String tokenizerFileName = 'tokenizer.json';

  /// Tokenizer settings file name.
  static const String tokenizerConfigFileName = 'tokenizer_config.json';

  /// Agent temperature and decoding config file name.
  static const String rlAgentConfigFileName = 'rl_agent_config.json';

  /// Official Hub weights file — not required and must not be downloaded.
  static const String modelSafetensorsFileName = 'model.safetensors';

  /// Filenames that must exist for a complete local copy.
  static const List<String> requiredArtifactNames = <String>[
    onnxFileName,
    tokenizerFileName,
    tokenizerConfigFileName,
    rlAgentConfigFileName,
  ];

  /// Directory that holds the local multilingual artifacts.
  final Directory cacheDirectory;

  /// Writer used when the cache is incomplete.
  final CheckpointDownloader download;

  /// Ensures a complete local copy exists under [cacheDirectory].
  ///
  /// Invokes [download] only when the copy is incomplete. After a successful
  /// download the directory must be complete; otherwise this call fails.
  Future<void> ensureLocal() async {
    if (await isComplete()) {
      return;
    }
    await cacheDirectory.create(recursive: true);
    await download(cacheDirectory);
    if (!await isComplete()) {
      throw StateError(
        'Multilingual checkpoint cache is still incomplete at '
        '${cacheDirectory.path}',
      );
    }
  }

  /// Whether every required artifact is present and the ONNX size matches.
  Future<bool> isComplete() async {
    for (final name in requiredArtifactNames) {
      final file = File('${cacheDirectory.path}${Platform.pathSeparator}$name');
      if (!await file.exists()) {
        return false;
      }
      if (name == onnxFileName && await file.length() != expectedOnnxBytes) {
        return false;
      }
    }
    return true;
  }
}
