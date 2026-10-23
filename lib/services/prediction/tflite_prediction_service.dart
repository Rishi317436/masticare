import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../models/prediction_model.dart';
import 'prediction_service.dart';
import 'tflite/model_loader.dart';
import 'tflite/image_preprocessor.dart';
import 'tflite/model_config.dart';

/// TflitePredictionService implements inference using the provided
/// assets/models/mastitis.tflite model when available on native platforms.
///
/// This implementation:
///  - Detects the asset and loads an Interpreter (native-only).
///  - Uses a centralized ImagePreprocessor (normalization is UNCONFIRMED and
///    exposed through ModelConfig).
///  - Produces a PredictionModel with clear UNCONFIRMED labels and summary.
class TflitePredictionService implements PredictionService {
  final dynamic _interpreter;
  final ModelConfig _config;
  final ImagePreprocessor _preprocessor;

  TflitePredictionService._(this._interpreter, this._config) : _preprocessor = ImagePreprocessor(config: _config);

  /// Attempt to create the TFLite service if the model asset exists and the
  /// runtime is supported. Returns null when not available; callers should
  /// handle absence explicitly (the app requires this model for production).
  static Future<TflitePredictionService?> createIfAvailable({String modelAsset = 'assets/models/mastitis.tflite'}) async {
    if (kIsWeb) return null; // tflite_flutter native runtime not available on web here

    try {
      // Verify asset is bundled by attempting to load it from the asset bundle
      await rootBundle.load(modelAsset);
    } catch (_) {
      // Asset not present in bundle
      return null;
    }

    final loader = ModelLoader();
    final loaded = await loader.loadModel(modelAsset);
    if (!loaded || loader.interpreter == null || loader.config == null) return null;

    return TflitePredictionService._(loader.interpreter!, loader.config!);
  }

  @override
  Future<PredictionModel> predict({required String imagePath}) async {
    // Preprocess image into nested list matching [1,h,w,c]
    final input = await _preprocessor.preprocess(imagePath);

    // Prepare output buffer matching [1,1]
    final output = List.generate(1, (_) => List.filled(1, 0.0));

    // Run inference. Interpreter.run accepts nested Lists for non-typed
    // inputs in tflite_flutter; this is a straightforward approach for
    // small inputs and keeps the code simple and explicit.
    try {
      _interpreter.run(input, output);
    } catch (e) {
      throw StateError('TFLite interpreter run failed: $e');
    }

    // Read the sigmoid output
    final rawValue = (output[0][0] as num).toDouble();
    final probability = rawValue.clamp(0.0, 1.0);

    // Apply configured threshold
    final isMastitis = probability >= _config.threshold;

    final positiveLabel = _config.labels[1] ?? 'Mastitis (UNCONFIRMED)';
    final negativeLabel = _config.labels[0] ?? 'Healthy (UNCONFIRMED)';

    final label = isMastitis ? positiveLabel : negativeLabel;

    return PredictionModel(
      label: label,
      confidence: probability,
      healthyProbability: isMastitis ? (1.0 - probability) : probability,
      mastitisProbability: isMastitis ? probability : (1.0 - probability),
      isMastitis: isMastitis,
      summary:
          'MODEL (mastitis.tflite) RESULT — NOTE: preprocessing, label polarity and threshold are UNCONFIRMED. See ModelConfig for configurable values.',
    );
  }
}
