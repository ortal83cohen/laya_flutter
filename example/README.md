# laya_flutter example

Runnable Flutter application for the `laya_flutter` library.

The parent directory is the library. It is not an application, and Android Studio should not launch it. This folder is the run target. The entry point is `lib/main.dart`.

The Snake screen uses the public [OwaisAli10/laya-snake checkpoint](https://huggingface.co/OwaisAli10/laya-snake) at revision `21057b19696fb3e27c4f4c644e6cb872ed866486`. The app expects a local directory with these three files from the **same** checkpoint/export:

- `laya.onnx` — exported Snake graph, with any ONNX external-data file beside it
- `tokenizer.json` — checkpoint tokenizer
- `rl_agent_config.json` — checkpoint question and calibration settings

The Hub revision publishes safetensors, not ONNX. The [upstream Laya exporter](https://github.com/NandhaKishorM/laya/blob/main/scripts/export_onnx.py) accepts a local model directory and an output path. Its compatibility with this exact Snake revision has not yet been verified by an export or same-checkpoint inference test. No weights are included in this repository, and running the app does not download them. Obtain and export the weights separately with appropriate authorization, then point the app at the prepared bundle.

From this directory, after preparing the bundle on a macOS host:

```sh
fvm flutter run --dart-define=LAYA_SNAKE_CHECKPOINT_DIR=/absolute/path/to/snake-onnx-bundle
```

Without this setting, startup shows setup guidance instead of opening the generic base graph. A present bundle still needs a compatible Laya ONNX graph; startup reports missing or incompatible files. The path must exist on the device running the app: a Mac host path is not an Android emulator or iOS device path. Copying a bundle into a mobile app-accessible directory and launching it there has not been verified in this work item. Source tests and builds do not prove that the tuned model loads or plays well. The example's board is 40-by-40, while the checkpoint card's reported games used 15-by-15.

When Android Studio is opened on the repository root, use the `example` run configuration. That configuration points at `example/lib/main.dart`. In **Run > Edit Configurations > example**, put `--dart-define=LAYA_SNAKE_CHECKPOINT_DIR=/absolute/path/to/snake-onnx-bundle` in **Additional run args**, using a path accessible to the selected run device. The checked-in run configuration does not embed a machine-specific path or checkpoint weights.
