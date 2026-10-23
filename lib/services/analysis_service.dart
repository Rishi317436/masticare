import 'dart:io';

import '../models/analysis_model.dart';
import '../repositories/analysis_repository.dart';
import 'image_storage_service.dart';
import 'prediction/prediction_service.dart';
import 'prediction/tflite_prediction_service.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.label,
    required this.confidence,
    required this.isMastitis,
    required this.summary,
    required this.saved,
    required this.inputQuality,
    required this.modelStatus,
    required this.saveStatus,
  });

  final String label;
  final double confidence;
  final bool isMastitis;
  final String summary;
  final bool saved;
  final String inputQuality;
  final String modelStatus;
  final String saveStatus;
}

class AnalysisService {
  AnalysisService({PredictionService? predictionService}) : _predictionService = predictionService;

  PredictionService? _predictionService;

  Future<AnalysisResult> runAnalysis({int? cattleId, String? imagePath}) async {
    // Ensure we have a prediction service (lazy async factory). Production
    // requires the TFLite model; do not fall back to a mock implementation.
    if (_predictionService == null) {
      final t = await TflitePredictionService.createIfAvailable();
      if (t == null) {
        throw StateError('TFLite model not available on this platform. Analysis requires assets/models/mastitis.tflite');
      }
      _predictionService = t;
    }

    final predictionService = _predictionService!;
        if (cattleId == null || imagePath == null || cattleId <= 0) {
      throw const FormatException('A registered cattle record and a valid image are required.');
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw const FormatException('Selected image was not found on this device.');
    }

    final fileSize = await file.length();
    if (fileSize <= 0) {
      throw const FormatException('Selected image is empty. Please choose a valid thermal image.');
    }

    final lowerPath = imagePath.toLowerCase();
    final isValidImage = lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.bmp');

    if (!isValidImage) {
      throw const FormatException('Unsupported image format. Use JPG, JPEG, PNG, or BMP.');
    }

    final extension = lowerPath.contains('.') ? lowerPath.substring(lowerPath.lastIndexOf('.')) : '.jpg';
    final storedImagePath = await ImageStorageService().saveImage(
      fileName: 'analysis_${cattleId}_${DateTime.now().millisecondsSinceEpoch}$extension',
      sourcePath: imagePath,
    );

    final prediction = await predictionService.predict(imagePath: storedImagePath);
    final confidence = prediction.confidence.clamp(0.0, 1.0);
    final isMastitis = prediction.isMastitis ?? prediction.label.toLowerCase().contains('mastitis');

    final analysis = AnalysisModel(
      cattleId: cattleId,
      thermalImagePath: storedImagePath,
      prediction: prediction.label,
      healthyProbability: prediction.healthyProbability.clamp(0.0, 1.0),
      mastitisProbability: prediction.mastitisProbability.clamp(0.0, 1.0),
      confidence: confidence,
      timestamp: DateTime.now(),
    );

    await AnalysisRepository().saveAnalysis(analysis);

    return AnalysisResult(
      label: prediction.label,
      confidence: confidence,
      isMastitis: isMastitis,
      summary: prediction.summary ?? 'Prediction completed successfully.',
      saved: true,
      inputQuality: _describeQuality(fileSize),
      modelStatus: 'Model: ${_predictionService.runtimeType}',
      saveStatus: 'Saved locally',
    );
  }

  String _describeQuality(int fileSize) {
    if (fileSize > 2 * 1024 * 1024) {
      return 'Optimal';
    }
    if (fileSize > 200 * 1024) {
      return 'Good';
    }
    return 'Acceptable';
  }
}
