// Image preprocessor for the verified mastitis.tflite model.
//
// This implementation performs the following (configurable) steps:
//  - decode image bytes (JPEG/PNG)
//  - convert to RGB
//  - resize to 128x128
//  - convert to float32 and normalize by dividing by 255.0
//
// IMPORTANT: The normalization step and thermal-image specific preprocessing
// are UNCONFIRMED. These choices are centralized here and can be adjusted
// later when the model provider confirms the exact preprocessing.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'model_config.dart';

class ImagePreprocessor {
  final ModelConfig config;

  ImagePreprocessor({required this.config});

  /// Preprocess [imagePath] and return a nested List matching the interpreter
  /// expected input shape: [1, height, width, channels] of float values.
  ///
  /// Returns a nested 4D List (shape: 1 x height x width x channels) which
  /// is compatible with tflite_flutter Interpreter.run for a single-input,
  /// single-output model.
  Future<List<List<List<List<double>>>>> preprocess(String imagePath) async {
    // Web and native file handling differences: on web callers should avoid
    // calling this preprocessor (createIfAvailable guards web). Here we
    // assume a native file path.
    if (kIsWeb) throw UnsupportedError('ImagePreprocessor is not supported on web in this configuration.');

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw StateError('Unable to decode image at $imagePath');

    final height = config.inputShape[1];
    final width = config.inputShape[2];
    final channels = config.inputShape[3];

    final resized = img.copyResize(decoded, width: width, height: height, interpolation: img.Interpolation.cubic);

    // Build nested list [1][h][w][c]
    final result = List.generate(1, (_) {
      return List.generate(height, (y) {
        return List.generate(width, (x) {
          final pixel = resized.getPixel(x, y);
          final nr = pixel.r / 255.0;
          final ng = pixel.g / 255.0;
          final nb = pixel.b / 255.0;

          return List.generate(channels, (c) {
            if (c == 0) return nr;
            if (c == 1) return ng;
            return nb;
          });
        });
      });
    });

    return result;
  }
}
