/// Local settings for the example application.
///
/// Keep machine- and device-specific paths in this file only. The Android
/// debug app stores the prepared Snake bundle in its private files directory.
final class AppSettings {
  const AppSettings._();

  /// Directory containing `laya.onnx`, its external data file, and companions.
  static const String snakeCheckpointDir =
      '/data/user/0/com.example.laya_flutter_example/files/laya-snake-bundle';
}
