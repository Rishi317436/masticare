class PredictionModel {
  const PredictionModel({
    required this.label,
    required this.confidence,
    required this.healthyProbability,
    required this.mastitisProbability,
    this.isMastitis,
    this.summary,
  });

  final String label;
  final double confidence;
  final double healthyProbability;
  final double mastitisProbability;
  final bool? isMastitis;
  final String? summary;

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'confidence': confidence,
      'healthy_probability': healthyProbability,
      'mastitis_probability': mastitisProbability,
      'isMastitis': isMastitis,
      'summary': summary,
    };
  }

  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    return PredictionModel(
      label: map['label'] as String? ?? 'unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      healthyProbability: (map['healthy_probability'] as num?)?.toDouble() ?? 0.0,
      mastitisProbability: (map['mastitis_probability'] as num?)?.toDouble() ?? 0.0,
      isMastitis: map['isMastitis'] as bool?,
      summary: map['summary'] as String?,
    );
  }
}
