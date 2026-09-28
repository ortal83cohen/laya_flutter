# Raise the example macOS deployment target to 14.0

`flutter_onnxruntime` 1.8.5 declares macOS 14.0 in its Swift package. Flutter generates `FlutterGeneratedPluginSwiftPackage` at the tool default of 12.0, then raises that manifest only when the Xcode project's `MACOSX_DEPLOYMENT_TARGET` is higher. The example project was still 12.0, so the generated package stayed at 12.0 and the macOS build failed.

The example project's Debug, Release, and Profile configurations now set the deployment target to 14.0. A config-only macOS build then rewrote the generated manifest to macOS 14.0, and a debug macOS build completed.

## File

`example/macos/Runner.xcodeproj/project.pbxproj`

## Qualifying conditions

1. One file changed: only the example macOS project file.
2. No new dependency: the existing `flutter_onnxruntime` pin is unchanged.
3. No public interface, exported symbol, route, or schema change.
4. No data model, migration, or stored data change.
5. No security, privacy, authentication, authorisation, or payment surface.

## Proof

The failing build reported that `flutter-onnxruntime` requires macOS 14.0 while `FlutterGeneratedPluginSwiftPackage` supported 12.0. After the project change, `flutter build macos --debug` from `example/` produced the app.

There is no Dart test for an Xcode deployment target. The build is the check that fails when the target stays at 12.0.

## Checks

`flutter build macos --debug` in `example/`:

```
Building macOS application...
✓ Built build/macos/Build/Products/Debug/laya_flutter_example.app
```

`dart format --output=none --set-exit-if-changed lib example/lib`:

```
Formatted 10 files (0 changed) in 0.03 seconds.
```

Exit code 0.

`dart analyze --fatal-infos --fatal-warnings`:

```
Analyzing laya_flutter...
No issues found!
```

Exit code 0.

`python3 tools/lint_wiki.py`:

```
lint_wiki: clean (0 warning(s)).
```

Exit code 0.
