// MockPredictionService has been removed from the production codebase.
// The application now requires the real TFLite model (assets/models/mastitis.tflite).
// This file remains as a placeholder and will throw if referenced.

import '../../models/prediction_model.dart';
import 'prediction_service.dart';

class MockPredictionService implements PredictionService {
  @override
  Future<PredictionModel> predict({required String imagePath}) async {
    throw StateError('MockPredictionService is removed. The app must use the real TFLite model.');
  }
}
