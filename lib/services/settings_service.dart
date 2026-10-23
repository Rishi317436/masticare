import 'package:shared_preferences/shared_preferences.dart';

enum PredictionMode { auto, tflite }

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const String _predictionModeKey = 'masticare_prediction_mode';

  Future<void> setPredictionMode(PredictionMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_predictionModeKey, mode.name);
  }

  Future<PredictionMode> getPredictionMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_predictionModeKey);
    if (raw == null) return PredictionMode.auto;
    switch (raw) {
      case 'mock':
        // Legacy saved value — map it to tflite to preserve behavior without the mock.
        return PredictionMode.tflite;
      case 'tflite':
        return PredictionMode.tflite;
      default:
        return PredictionMode.auto;
    }
  }
}
