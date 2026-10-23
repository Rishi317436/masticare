// Stub ModelLoader used for web/testing where tflite_flutter native runtime
// is not available. This ensures the package can be compiled in test and web
// environments without pulling native tflite symbols.

import 'model_config.dart';

class ModelLoader {
  ModelLoader();

  dynamic get interpreter => null;
  ModelConfig? get config => null;

  Future<bool> loadModel(String assetPath) async {
    return false;
  }

  Future<void> close() async {}
}
