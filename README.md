# Laya

Flutter library. The package root is not an application and is not a run target.

The runnable example application is in `example/`.

## Layout

- `lib/` - public library implementation. There is no application entry point here.
- `example/` - the Flutter application. Its entry point is `example/lib/main.dart`.
- `wiki/` - reusable planning, validation, and workflow guidance.
- `.claude/`, `.cursor/` - model instructions and automation guidance.

## Running the example

In Android Studio, open this repository and select the **example** run configuration. It launches `example/lib/main.dart` on the chosen device.

From a terminal, run the example project itself:

```
cd example
flutter run
```
