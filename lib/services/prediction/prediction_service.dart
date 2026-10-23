import '../../models/prediction_model.dart';
import 'tflite_prediction_service.dart' as tflite_impl;

abstract class PredictionService {
  Future<PredictionModel> predict({required String imagePath});
}

/// Returns the TFLite prediction service implementation if available.
/// The application no longer falls back to a mock implementation. If the
/// TFLite service cannot be created (missing asset or unsupported platform)
/// a StateError is thrown so callers clearly know the production model is
/// required.
Future<PredictionService> getDefaultPredictionService() async {
  final t = await tflite_impl.TflitePredictionService.createIfAvailable();
  if (t != null) return t;
  throw StateError('TFLite model (assets/models/mastitis.tflite) is not available on this platform or not bundled.');
}
