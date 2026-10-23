// Native (IO) implementation of ModelLoader that uses tflite_flutter.

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'model_config.dart';

class ModelLoader {
  Interpreter? _interpreter;
  ModelConfig? _config;

  ModelLoader();

  Interpreter? get interpreter => _interpreter;
  ModelConfig? get config => _config;

  Future<bool> loadModel(String assetPath) async {
    if (kIsWeb) return false;

    Object? lastError;
    try {
      _interpreter = await Interpreter.fromAsset(assetPath);
      _config = ModelConfig.defaults();
      return true;
    } catch (e) {
      lastError = e;
    }

    if (assetPath.startsWith('assets/')) {
      final candidate = assetPath.replaceFirst('assets/', '');
      try {
        _interpreter = await Interpreter.fromAsset(candidate);
        _config = ModelConfig.defaults();
        return true;
      } catch (e) {
        lastError = e;
      }
    }

    _interpreter = null;
    _config = null;
    throw StateError('Failed to load TFLite model "$assetPath": $lastError');
  }

  Future<void> close() async {
    _interpreter?.close();
    _interpreter = null;
    _config = null;
  }
}
