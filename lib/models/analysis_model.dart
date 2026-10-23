class AnalysisModel {
  const AnalysisModel({
    this.id,
    required this.cattleId,
    this.thermalImagePath,
    this.prediction,
    this.healthyProbability,
    this.mastitisProbability,
    this.confidence,
    required this.timestamp,
  });

  final int? id;
  final int cattleId;
  final String? thermalImagePath;
  final String? prediction;
  final double? healthyProbability;
  final double? mastitisProbability;
  final double? confidence;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cattle_id': cattleId,
      'thermal_image_path': thermalImagePath,
      'prediction': prediction,
      'healthy_probability': healthyProbability,
      'mastitis_probability': mastitisProbability,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AnalysisModel.fromMap(Map<String, dynamic> map) {
    return AnalysisModel(
      id: map['id'] as int?,
      cattleId: map['cattle_id'] as int? ?? 0,
      thermalImagePath: map['thermal_image_path'] as String?,
      prediction: map['prediction'] as String?,
      healthyProbability: (map['healthy_probability'] as num?)?.toDouble(),
      mastitisProbability: (map['mastitis_probability'] as num?)?.toDouble(),
      confidence: (map['confidence'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
