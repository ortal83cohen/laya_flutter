# Research: Name Jev and improve pub.dev discovery

## Question

How should the package say that Laya is the model people may know through Jev, and which pub.dev
topics actually help someone find it?

## Answer

Say Jev in the package description and in the opening of the README. Jev is TypeSafe's hosted
decision API. Laya is Convai Innovations' open-weight model for the same kind of typed decision.
They are not the same product, and this package does not call Jev. pub.dev indexes the package
name, then the description, then the first 5000 characters of the README. Topics are a separate
filter, and a package may list at most five. Use topics that already have a browse page.

## Findings

### Jev is the familiar name, and it is not Laya

- Claim: Jev is TypeSafe's closed hosted System One API. Laya is Convai Innovations' open-weight
  model for the same job: a situation plus typed choice, score, or yes/no questions, answered in
  one pass. A hosted service can speak the Jev wire protocol while running Laya. The two products
  are compared as alternatives, not as one product with two names.
- Evidence: Comparison pages describe Laya as the open-weight model and Jev as the hosted API, and
  they publish separate makers.
- Source: https://laya.studio/compare/laya-vs-jev and
  https://prolyz.com/blog/jev-vs-laya-hosted-vs-open-weight-decision-models

### Search hits the description and the start of the README, not a sixth topic

- Claim: A text query is matched against the package name, the description (first 500 characters,
  lower weight than the name in the published index notes), and the README (first 5000 characters,
  lower again). The description should be 60 to 180 characters. Topics are listed on the package
  page and can be filtered with `topic:`, and a package may have at most five. A new topic named
  `jev` would not join an existing browse page.
- Evidence: The pubspec reference caps topics at five and asks authors to reuse existing topics.
  The search help page orders name, description, README, then API text, then popularity and pub
  points. The search index notes name the same three text fields and the character windows.
- Source: https://dart.dev/tools/pub/pubspec#topics and https://pub.dev/help/search and
  https://github.com/dart-lang/pub-dev/blob/master/doc/search.md

### The useful existing topics are the ones peer on-device packages already use

- Claim: `machine-learning`, `on-device-ml`, `onnx`, `nlp`, and `ai` already label packages a
  reader would browse for this kind of library. `flutter` is redundant with the Flutter SDK
  constraint and dumps the package into a very large topic. `inference` and `offline` are vaguer
  than `on-device-ml`.
- Evidence: Search for `topic:machine-learning` and `topic:on-device-ml` returns current Flutter
  ML packages, including `flutter_onnxruntime` (`onnx`, `machine-learning`) and `flutter_litert`
  (`machine-learning`, `on-device-ml`). `dart_sentencepiece_tokenizer` uses `nlp`.
- Source: https://pub.dev/packages?q=topic%3Amachine-learning and
  https://pub.dev/packages?q=topic%3Aon-device-ml

## Options considered

| Option | How it works | Cost | Why rejected / chosen |
|--------|--------------|------|-----------------------|
| Put Jev in the description and the opening README, and say it is the hosted API Laya is the open-weight alternative to | Search for Jev matches the two highest text fields after the package name. The sentence stays accurate. | One description rewrite and one README paragraph. | Chosen. |
| Add a `jev` topic and drop an existing one | `topic:jev` would list this package alone. | Spends one of the five topic slots on a topic with no browse traffic. | Rejected. The word belongs in the description. |
| Keep `flutter`, `inference`, and `offline` | Leaves the current five topics. | Those topics are broad or redundant with the Flutter SDK filter. | Rejected. |
| Claim that Jev and Laya are the same product | Shortest sentence. | Contradicts the published comparison. | Rejected. |

## Constraints discovered

- At most five topics. Names are 2–32 characters, lowercase letters, digits, and single hyphens.
- The description is plain text, aimed at 60–180 characters, because that is the length pub.dev
  asks for and the window the index reads.
- The package name stays `laya_flutter`. Renaming it would be a different package.

## Unresolved

- [UNRESOLVED: whether a later pub.dev ranking change raises topic weight above the description.
  The change still puts Jev in the description, which the current index reads.]
