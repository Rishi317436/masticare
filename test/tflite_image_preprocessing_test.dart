import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:masticare/services/prediction/tflite/image_preprocessor.dart';
import 'package:masticare/services/prediction/tflite/model_config.dart';
import 'package:masticare/services/prediction/tflite_prediction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Real image preprocessing and TFLite inference test without RangeError', () async {
    final testImage = img.Image(width: 300, height: 300, numChannels: 3);
    for (var y = 0; y < 300; y++) {
      for (var x = 0; x < 300; x++) {
        testImage.setPixelRgb(x, y, 200, 100, 50);
      }
    }

    final tempDir = Directory.systemTemp.createTempSync('tflite_test');
    final tempImagePath = '${tempDir.path}/test_thermal_image.jpg';
    final jpgBytes = img.encodeJpg(testImage);
    File(tempImagePath).writeAsBytesSync(jpgBytes);

    final preprocessor = ImagePreprocessor(config: ModelConfig.defaults());
    final input4d = await preprocessor.preprocess(tempImagePath);

    expect(input4d.length, equals(1));
    expect(input4d[0].length, equals(128));
    expect(input4d[0][0].length, equals(128));
    expect(input4d[0][0][0].length, equals(3));

    final service = await TflitePredictionService.createIfAvailable();
    expect(service, isNotNull);

    final prediction = await service!.predict(imagePath: tempImagePath);

    expect(prediction.label, isNotEmpty);
    expect(prediction.confidence, isNotNull);
    expect(prediction.healthyProbability, isNotNull);
    expect(prediction.mastitisProbability, isNotNull);

    tempDir.deleteSync(recursive: true);
  });
}
