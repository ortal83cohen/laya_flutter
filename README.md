# laya_flutter

[![pub package](https://img.shields.io/pub/v/laya_flutter.svg)](https://pub.dev/packages/laya_flutter)
[![checks](https://github.com/ortal83cohen/laya_flutter/actions/workflows/checks.yml/badge.svg)](https://github.com/ortal83cohen/laya_flutter/actions/workflows/checks.yml)
[![pub points](https://img.shields.io/pub/points/laya_flutter)](https://pub.dev/packages/laya_flutter/score)
[![popularity](https://img.shields.io/pub/popularity/laya_flutter)](https://pub.dev/packages/laya_flutter/score)
[![likes](https://img.shields.io/pub/likes/laya_flutter)](https://pub.dev/packages/laya_flutter/score)
[![platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20windows%20%7C%20macos%20%7C%20linux-blue)](https://pub.dev/packages/laya_flutter)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Run the multilingual **Laya** reinforcement-learning agent on device with ONNX.
The library downloads the published checkpoint on first open, tokenizes state and
questions, and returns typed answers for **choice**, **score**, and **noul**
items—no cloud round trip.

![Snake example driven by offline Laya predict](https://raw.githubusercontent.com/ortal83cohen/laya_flutter/main/screenshots/example.gif)

Please [open an issue](https://github.com/ortal83cohen/laya_flutter/issues/new)
if something breaks or the docs should say more; fixes and copy improvements
are welcome.

## Features

- **Offline inference** through `flutter_onnxruntime` and Hugging Face
  tokenizers.
- **`LayaFlutter.open`** — ensures the multilingual ONNX graph and companion
  files live under a cache directory (downloads missing artifacts once).
- **`LayaFlutter.openLocalBundle`** — loads an existing directory that already
  contains `laya.onnx`, `tokenizer.json`, and `rl_agent_config.json` (used by
  task-specific agents such as Snake).
- **`LoadedRuntime.predict`** — batch inference with upstream-aligned
  temperature, softmax shaping, and typed [`LayaAnswer`](lib/src/answers.dart)
  results.
- **Runnable example** — classic Snake where each move is chosen by the local
  agent (`example/`).

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  laya_flutter: ^0.1.1
```

On first use, `LayaFlutter.open` needs network access to fetch the multilingual
checkpoint from Hugging Face (`mariojcr/laya-onnx` and
`convaiinnovations/laya-multilingual`). Later runs reuse the cache directory.

## Quick start

```dart
import 'dart:io';

import 'package:laya_flutter/laya_flutter.dart';

Future<void> runLaya(Directory cache) async {
  final LoadedRuntime runtime = await LayaFlutter.open(cache);

  final Map<String, LayaAnswer> answers = await runtime.predict(
    'Player level 3, inventory: key',
    <LayaQuestion>[
      LayaQuestion(
        id: 'door',
        type: LayaQuestionType.choice,
        instructions: 'Which door do you open?',
        criteria: <String, String>{
          'left': 'A wooden door',
          'right': 'An iron gate',
        },
      ),
    ],
  );

  print(answers['door']?.choice);
  await runtime.close();
}
```

### Local ONNX bundle

When you already ship a prepared bundle (different graph size or task weights),
point at the directory instead of the multilingual cache:

```dart
final LoadedRuntime runtime = await LayaFlutter.openLocalBundle(
  Directory('/path/to/bundle'),
);
```

The directory must contain the three required files and an ONNX graph whose
input and output names match the Laya agent contract.

## Example app

The repository root is a **library**, not an application. Run the demo from
`example/`:

```bash
cd example
flutter run
```

In Android Studio, open this repository and select the **example** run
configuration (`example/lib/main.dart`).

The example autostarts Snake on a device that has a prepared Snake checkpoint.
Set the bundle path in [`example/lib/app_settings.dart`](example/lib/app_settings.dart)
(`snakeCheckpointDir`). The bundled multilingual download path is separate;
Snake uses `openLocalBundle` only.

## Question types

| Type | `LayaQuestionType` | Answer field |
| --- | --- | --- |
| Multiple choice | `choice` | `choice` (option key at argmax) |
| Ordered score | `score` | `score` (expected level) |
| True / false | `noul` | `noul` (P(true)) |

See [`LayaQuestion`](lib/src/answers.dart) and [`LayaAnswer`](lib/src/answers.dart)
for criteria maps and probability details.

## Development layout

| Path | Role |
| --- | --- |
| `lib/` | Public API (`laya_flutter.dart`) |
| `example/` | Flutter app entry point |
| `test/` | Unit and integration tests |
| `wiki/` | Planning and workflow artifacts |

## License

MIT — see [LICENSE](LICENSE).
