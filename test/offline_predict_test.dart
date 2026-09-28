import 'dart:convert';
import 'dart:io';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laya_flutter/laya_flutter.dart';
import 'package:laya_flutter/src/checkpoint_store.dart';
import 'package:laya_flutter/src/onnx_graph.dart';

void main() {
  test('empty question list throws and does not invent answers', () async {
    final LoadedRuntime runtime = LoadedRuntime.validationOnly();

    await expectLater(
      runtime.predict('short state', <LayaQuestion>[]),
      throwsA(
        isA<ArgumentError>().having(
          (ArgumentError e) => e.message,
          'message',
          contains('empty'),
        ),
      ),
    );

    await expectLater(
      runtime.predict('short state', <String, LayaQuestion>{}),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'missing local checkpoint fails without calling remote inference',
    () async {
      final Directory cache = await Directory.systemTemp.createTemp(
        'laya_offline_predict_missing_',
      );
      addTearDown(() async {
        if (await cache.exists()) {
          await cache.delete(recursive: true);
        }
      });

      var downloadCalls = 0;
      // Network-disabled downloader: records the ensureLocal attempt and fails.
      // No Hugging Face HTTP and no remote inference API are reached.
      Future<void> disabledNetwork(Directory directory) async {
        downloadCalls += 1;
        throw StateError('network unavailable');
      }

      await expectLater(
        LayaFlutter.open(cache, download: disabledNetwork),
        throwsA(isA<StateError>()),
      );
      expect(downloadCalls, 1);
      expect(
        await CheckpointStore(
          cacheDirectory: cache,
          download: disabledNetwork,
        ).isComplete(),
        isFalse,
      );
    },
  );

  test(
    'complete cache with disabled network does not invoke the downloader',
    () async {
      final Directory cache = await Directory.systemTemp.createTemp(
        'laya_offline_predict_complete_',
      );
      addTearDown(() async {
        if (await cache.exists()) {
          await cache.delete(recursive: true);
        }
      });

      await _writeCompleteArtifacts(cache);

      var downloadCalls = 0;
      Future<void> mustNotRun(Directory directory) async {
        downloadCalls += 1;
        throw StateError('network unavailable');
      }

      // createSession is forced to fail so the VM never needs the ONNX plugin.
      // ensureLocal must still skip download because the cache is complete.
      await expectLater(
        LayaFlutter.open(
          cache,
          download: mustNotRun,
          createSession: (String path) async {
            throw StateError('createSession disabled in VM test');
          },
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('createSession disabled'),
          ),
        ),
      );
      expect(downloadCalls, 0);
    },
  );

  test(
    'local bundle reports missing files without opening a session',
    () async {
      final Directory bundle = await Directory.systemTemp.createTemp(
        'laya_local_missing_',
      );
      addTearDown(() => bundle.delete(recursive: true));
      var sessionCalls = 0;
      Future<OrtSession> mustNotOpen(String path) async {
        sessionCalls += 1;
        throw StateError('session should not open');
      }

      await expectLater(
        LayaFlutter.openLocalBundle(bundle, createSession: mustNotOpen),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('laya.onnx'),
          ),
        ),
      );
      await File('${bundle.path}/laya.onnx').writeAsBytes(<int>[1]);
      await expectLater(
        LayaFlutter.openLocalBundle(bundle, createSession: mustNotOpen),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('tokenizer.json'),
          ),
        ),
      );
      expect(sessionCalls, 0);
    },
  );

  test(
    'local bundle rejects malformed companions before session open',
    () async {
      final Directory bundle = await Directory.systemTemp.createTemp(
        'laya_local_malformed_',
      );
      addTearDown(() => bundle.delete(recursive: true));
      await _writeLocalArtifacts(bundle);
      var sessionCalls = 0;
      Future<OrtSession> mustNotOpen(String path) async {
        sessionCalls += 1;
        throw StateError('session should not open');
      }

      await File('${bundle.path}/tokenizer.json').writeAsString('{bad json');
      await expectLater(
        LayaFlutter.openLocalBundle(bundle, createSession: mustNotOpen),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Invalid local tokenizer.json'),
          ),
        ),
      );

      await File('${bundle.path}/tokenizer.json').writeAsString(_testTokenizer);
      await File('${bundle.path}/rl_agent_config.json').writeAsString('[]');
      await expectLater(
        LayaFlutter.openLocalBundle(bundle, createSession: mustNotOpen),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Invalid local rl_agent_config.json'),
          ),
        ),
      );
      expect(sessionCalls, 0);
    },
  );

  test('local bundle uses its graph and rejects incompatible names', () async {
    final Directory bundle = await Directory.systemTemp.createTemp(
      'laya_local_contract_',
    );
    addTearDown(() => bundle.delete(recursive: true));
    await _writeLocalArtifacts(bundle);
    final List<String> openedPaths = <String>[];
    Future<OrtSession> compatible(String path) async {
      openedPaths.add(path);
      return OrtSession.fromMap(<String, Object>{
        'sessionId': 'metadata-only',
        'inputNames': onnxAgentInputNames,
        'outputNames': onnxAgentOutputNames,
      });
    }

    final LoadedRuntime runtime = await LayaFlutter.openLocalBundle(
      bundle,
      createSession: compatible,
    );
    expect(openedPaths, <String>['${bundle.path}/laya.onnx']);
    expect(runtime.maxLen, 128);
    expect(runtime.headMaxLen, 64);

    Future<OrtSession> incompatible(String path) async {
      openedPaths.add(path);
      return OrtSession.fromMap(<String, Object>{
        'sessionId': 'metadata-only',
        'inputNames': <String>['wrong_input'],
        'outputNames': onnxAgentOutputNames,
      });
    }

    await expectLater(
      LayaFlutter.openLocalBundle(bundle, createSession: incompatible),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('Incompatible local ONNX graph'),
        ),
      ),
    );
    Future<OrtSession> wrongOutputs(String path) async {
      openedPaths.add(path);
      return OrtSession.fromMap(<String, Object>{
        'sessionId': 'metadata-only',
        'inputNames': onnxAgentInputNames,
        'outputNames': <String>['wrong_output'],
      });
    }

    await expectLater(
      LayaFlutter.openLocalBundle(bundle, createSession: wrongOutputs),
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('Incompatible local ONNX graph'),
        ),
      ),
    );
    expect(openedPaths, hasLength(3));
  });

  test('real example uses the centralized local Snake bundle setting', () {
    final String source = File('example/lib/main.dart').readAsStringSync();
    final String settings = File(
      'example/lib/app_settings.dart',
    ).readAsStringSync();
    expect(settings, contains('static const String snakeCheckpointDir'));
    expect(source, contains('AppSettings.snakeCheckpointDir'));
    expect(source, contains('LayaFlutter.openLocalBundle('));
    expect(source, isNot(contains('LayaFlutter.open(')));
    expect(
      source,
      contains(
        'Snake checkpoint is not configured. Set it in app_settings.dart.',
      ),
    );
  });
}

final String _testTokenizer = jsonEncode(<String, Object?>{
  'version': '1.0',
  'truncation': null,
  'padding': null,
  'added_tokens': <Object>[],
  'normalizer': null,
  'pre_tokenizer': <String, String>{'type': 'Whitespace'},
  'post_processor': null,
  'decoder': null,
  'model': <String, Object>{
    'type': 'WordLevel',
    'vocab': <String, int>{
      '<pad>': 0,
      '<bos>': 1,
      '<eos>': 2,
      '<mask>': 3,
      '<unk>': 4,
    },
    'unk_token': '<unk>',
  },
});

Future<void> _writeLocalArtifacts(Directory directory) async {
  await File('${directory.path}/laya.onnx').writeAsBytes(<int>[1]);
  await File('${directory.path}/tokenizer.json').writeAsString(_testTokenizer);
  await File('${directory.path}/rl_agent_config.json').writeAsString(
    '{"temperature":[1.0,1.0,1.0],"temperature_by_options":{},'
    '"max_len":128,"head_max_len":64}',
  );
}

Future<void> _writeCompleteArtifacts(Directory directory) async {
  await directory.create(recursive: true);
  final File onnx = File('${directory.path}/${CheckpointStore.onnxFileName}');
  final RandomAccessFile raf = await onnx.open(mode: FileMode.write);
  try {
    await raf.setPosition(CheckpointStore.expectedOnnxBytes - 1);
    await raf.writeByte(0);
  } finally {
    await raf.close();
  }
  for (final String name in const <String>[
    CheckpointStore.tokenizerFileName,
    CheckpointStore.tokenizerConfigFileName,
    CheckpointStore.rlAgentConfigFileName,
  ]) {
    if (name == CheckpointStore.rlAgentConfigFileName) {
      await File('${directory.path}/$name').writeAsString(
        '{"temperature":[1.0,1.0,1.0],"temperature_by_options":{},'
        '"max_len":512,"head_max_len":192}',
      );
    } else {
      await File('${directory.path}/$name').writeAsString('{}');
    }
  }
}
