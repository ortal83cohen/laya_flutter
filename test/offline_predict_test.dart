import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:laya_flutter/laya_flutter.dart';
import 'package:laya_flutter/src/checkpoint_store.dart';

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
