# laya_flutter

[![pub package](https://img.shields.io/pub/v/laya_flutter.svg)](https://pub.dev/packages/laya_flutter)
[![checks](https://github.com/ortal83cohen/laya_flutter/actions/workflows/checks.yml/badge.svg)](https://github.com/ortal83cohen/laya_flutter/actions/workflows/checks.yml)
[![pub points](https://img.shields.io/pub/points/laya_flutter)](https://pub.dev/packages/laya_flutter/score)
[![popularity](https://img.shields.io/pub/popularity/laya_flutter)](https://pub.dev/packages/laya_flutter/score)
[![likes](https://img.shields.io/pub/likes/laya_flutter)](https://pub.dev/packages/laya_flutter/score)
[![platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20web%20%7C%20windows%20%7C%20macos%20%7C%20linux-blue)](https://pub.dev/packages/laya_flutter)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**An offline decision model for Flutter.** Describe a situation in ordinary language, ask a question with a clear shape, and get an answer your app can act on. The first open downloads the published multilingual model. After that, every decision stays on the device.

![Snake chooses its next move from an offline Laya decision](https://raw.githubusercontent.com/ortal83cohen/laya_flutter/main/screenshots/example.gif)

The picture is the included example: classic Snake. Each step waits for the model to pick a direction. Please [open an issue](https://github.com/ortal83cohen/laya_flutter/issues/new) if something breaks or the docs should say more.

## How a decision works

You do not ask the model to write a paragraph. You hand it two things:

1. **A situation** — a short description of what is going on right now.
2. **One or more questions** — each with an id, a kind of answer, instructions, and the options or scale you want used.

The model returns a typed answer for every question, in one call. Your app reads the choice, the score, or the yes/no and continues. Several questions can share the same situation.

## What you can ask

| You want | Ask with | You get back |
| --- | --- | --- |
| Pick one option you named | `LayaQuestionType.choice` | The chosen key, such as `left` |
| Place the situation on a scale you wrote | `LayaQuestionType.score` | A level on that scale |
| A yes or no | `LayaQuestionType.noul` | How likely “true” is, and which side is stronger |

A choice is a door, a direction, a next step in a flow. A score is “how urgent is this?” on levels you defined. A yes/no is a gate: show the screen, or don’t. The wording of the situation and the questions is yours. The published model is multilingual, so that wording can be in the languages it was built for.

## What you can build

Anything that needs a small, structured decision and should keep working after the model is on the device:

- A character, opponent, or guide that picks its next action from options you wrote.
- A rating of the current situation on a scale your product already uses.
- A yes/no branch that does not call a server for every tap.
- Several of those at once, about the same moment.

The library does not write essays, and it does not train a new model. It answers the questions you asked.

## See it in Snake

The repository includes a playable game in `example/`. That is the clearest picture of the decision loop:

- Every step, the game describes the board and asks which way to go: `up`, `down`, `left`, or `right`.
- The snake moves when the model answers. A clock does not push it forward.
- Food appears on an empty cell.
- A wall or the snake’s own body ends the run. A new game starts on its own.

The Snake screen uses a Snake-specific checkpoint that you prepare locally. Your own app can instead call `LayaFlutter.open` and use the general multilingual model. Setup for the demo is in [`example/README.md`](example/README.md). The bundle path for a device lives in [`example/lib/app_settings.dart`](example/lib/app_settings.dart) (`snakeCheckpointDir`).

```bash
cd example
flutter run
```

In Android Studio, open this repository and select the **example** run configuration (`example/lib/main.dart`).

## Ask for a decision

```yaml
dependencies:
  laya_flutter: ^0.1.1
```

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

`LayaFlutter.open` needs the network once, to fetch the multilingual checkpoint. Later opens reuse the cache directory you passed in.

If you already have a prepared checkpoint for a specific task (Snake is one), open that folder instead:

```dart
final LoadedRuntime runtime = await LayaFlutter.openLocalBundle(
  Directory('/path/to/bundle'),
);
```

That folder needs `laya.onnx`, `tokenizer.json`, and `rl_agent_config.json` from the same checkpoint.

Field names and probability maps are documented on [`LayaQuestion`](lib/src/answers.dart) and [`LayaAnswer`](lib/src/answers.dart).

## License

MIT — see [LICENSE](LICENSE).
