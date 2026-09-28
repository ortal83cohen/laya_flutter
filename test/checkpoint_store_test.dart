import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:laya_flutter/src/checkpoint_store.dart';

/// Writes a sparse file whose logical length is [byteLength].
Future<void> writeSizedFile(File file, int byteLength) async {
  final raf = await file.open(mode: FileMode.write);
  try {
    if (byteLength > 0) {
      await raf.setPosition(byteLength - 1);
      await raf.writeByte(0);
    }
  } finally {
    await raf.close();
  }
}

/// Writes the four required multilingual artifacts into [directory].
Future<void> writeCompleteArtifacts(Directory directory) async {
  await directory.create(recursive: true);
  await writeSizedFile(
    File('${directory.path}/${CheckpointStore.onnxFileName}'),
    CheckpointStore.expectedOnnxBytes,
  );
  for (final name in const <String>[
    CheckpointStore.tokenizerFileName,
    CheckpointStore.tokenizerConfigFileName,
    CheckpointStore.rlAgentConfigFileName,
  ]) {
    await File('${directory.path}/$name').writeAsString('{}');
  }
}

void main() {
  late Directory cache;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('laya_checkpoint_store_');
  });

  tearDown(() async {
    if (await cache.exists()) {
      await cache.delete(recursive: true);
    }
  });

  test('required artifact list excludes model.safetensors', () {
    expect(
      CheckpointStore.requiredArtifactNames,
      isNot(contains(CheckpointStore.modelSafetensorsFileName)),
    );
    expect(
      CheckpointStore.requiredArtifactNames,
      containsAll(<String>[
        CheckpointStore.onnxFileName,
        CheckpointStore.tokenizerFileName,
        CheckpointStore.tokenizerConfigFileName,
        CheckpointStore.rlAgentConfigFileName,
      ]),
    );
  });

  test(
    'first call on empty directory invokes download and stores artifacts',
    () async {
      var downloadCalls = 0;
      final store = CheckpointStore(
        cacheDirectory: cache,
        download: (directory) async {
          downloadCalls += 1;
          await writeCompleteArtifacts(directory);
        },
      );

      await store.ensureLocal();

      expect(downloadCalls, 1);
      expect(await store.isComplete(), isTrue);
      for (final name in CheckpointStore.requiredArtifactNames) {
        expect(await File('${cache.path}/$name').exists(), isTrue);
      }
      expect(
        await File('${cache.path}/${CheckpointStore.onnxFileName}').length(),
        CheckpointStore.expectedOnnxBytes,
      );
      expect(
        await File('${cache.path}/${CheckpointStore.modelSafetensorsFileName}')
            .exists(),
        isFalse,
      );
    },
  );

  test('second call with complete directory skips download even when it would throw', () async {
    await writeCompleteArtifacts(cache);
    var downloadCalls = 0;
    final store = CheckpointStore(
      cacheDirectory: cache,
      download: (directory) async {
        downloadCalls += 1;
        throw StateError('network unavailable');
      },
    );

    await store.ensureLocal();

    expect(downloadCalls, 0);
    expect(await store.isComplete(), isTrue);
  });

  test('incomplete directory fails when download throws and does not report success', () async {
    await File('${cache.path}/${CheckpointStore.tokenizerFileName}')
        .create(recursive: true);
    await File('${cache.path}/${CheckpointStore.tokenizerFileName}')
        .writeAsString('{}');

    var downloadCalls = 0;
    final store = CheckpointStore(
      cacheDirectory: cache,
      download: (directory) async {
        downloadCalls += 1;
        throw StateError('network unavailable');
      },
    );

    await expectLater(store.ensureLocal(), throwsStateError);
    expect(downloadCalls, 1);
    expect(await store.isComplete(), isFalse);
  });

  test('download that leaves cache incomplete fails after download', () async {
    final store = CheckpointStore(
      cacheDirectory: cache,
      download: (directory) async {
        await directory.create(recursive: true);
        await File('${directory.path}/${CheckpointStore.tokenizerFileName}')
            .writeAsString('{}');
      },
    );

    await expectLater(store.ensureLocal(), throwsStateError);
    expect(await store.isComplete(), isFalse);
  });
}
