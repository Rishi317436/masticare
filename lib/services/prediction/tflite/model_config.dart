// Model configuration for the mastitis.tflite model.
//
// Notes:
// - The user-provided, verified model has the following confirmed specs:
//   * Input shape: [1, 128, 128, 3]
//   * Datatype: float32
//   * Output shape: [1, 1], float32, final activation sigmoid
// - Certain preprocessing details (normalization, thermal preprocessing,
//   class polarity and threshold) are NOT confirmed. These are exposed as
//   configurable values and are explicitly marked UNCONFIRMED below.

class ModelConfig {
  /// Confirmed model input shape: [1, height, width, channels]
  final List<int> inputShape;

  /// Confirmed input dtype ("float32")
  final String inputDtype;

  /// Confirmed color space ("RGB")
  final String colorSpace;

  /// Label mapping for binary output. For a sigmoid model the mapping is
  /// configurable: index 0 -> negative, index 1 -> positive. Labels should
  /// be marked UNCONFIRMED until model provider confirms which side the
  /// sigmoid represents.
  final Map<int, String> labels;

  /// Classification threshold for the sigmoid output into positive class.
  /// UNCONFIRMED: default 0.5. Make configurable until confirmed by model
  /// provider.
  final double threshold;

  const ModelConfig({
    required this.inputShape,
    required this.inputDtype,
    required this.colorSpace,
    required this.labels,
    required this.threshold,
  });

  /// Default config based on the provided/verified model file. Note that
  /// normalization and final label polarity remain UNCONFIRMED and are
  /// exposed via the labels and threshold fields so they can be adjusted
  /// without code changes.
  factory ModelConfig.defaults() {
    return const ModelConfig(
      inputShape: [1, 128, 128, 3],
      inputDtype: 'float32',
      colorSpace: 'RGB',
      // Labels are intentionally marked UNCONFIRMED in their text so UI and
      // logs make it clear these mappings are not yet validated by the
      // model provider.
      labels: {0: 'Healthy (UNCONFIRMED)', 1: 'Mastitis (UNCONFIRMED)'},
      threshold: 0.5,
    );
  }

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    final inputShape = (json['input_shape'] as List<dynamic>?)?.map((e) => e as int).toList() ?? <int>[];
    final inputDtype = json['input_dtype'] as String? ?? 'float32';
    final colorSpace = json['color_space'] as String? ?? 'RGB';
    final threshold = (json['threshold'] as num?)?.toDouble() ?? 0.5;

    final labelsMap = <int, String>{};
    final labelsJson = json['labels'] as Map<String, dynamic>?;
    if (labelsJson != null) {
      labelsJson.forEach((k, v) {
        final idx = int.tryParse(k);
        if (idx != null) labelsMap[idx] = v.toString();
      });
    }

    return ModelConfig(
      inputShape: inputShape,
      inputDtype: inputDtype,
      colorSpace: colorSpace,
      labels: labelsMap.isNotEmpty ? labelsMap : const {0: 'Healthy (UNCONFIRMED)', 1: 'Mastitis (UNCONFIRMED)'},
      threshold: threshold,
    );
  }
}
