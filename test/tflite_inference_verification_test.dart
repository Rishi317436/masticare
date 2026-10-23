import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify TFLite model load, shapes [1,128,128,3] -> [1,1], and real inference execution', () async {
    final interpreter = await Interpreter.fromAsset('assets/models/mastitis.tflite');
    expect(interpreter, isNotNull);

    final inputTensors = interpreter.getInputTensors();
    expect(inputTensors.length, equals(1));
    final inputTensor = inputTensors.first;
    expect(inputTensor.shape, equals([1, 128, 128, 3]));
    expect(inputTensor.type, equals(TensorType.float32));

    final outputTensors = interpreter.getOutputTensors();
    expect(outputTensors.length, equals(1));
    final outputTensor = outputTensors.first;
    expect(outputTensor.shape, equals([1, 1]));
    expect(outputTensor.type, equals(TensorType.float32));

    final input = List.generate(
      1,
      (_) => List.generate(
        128,
        (_) => List.generate(
          128,
          (_) => List.filled(3, 0.5),
        ),
      ),
    );

    final output = List.generate(1, (_) => List.filled(1, 0.0));

    interpreter.run(input, output);

    final result = output[0][0];
    expect(result, isNotNull);
    expect(result, isA<double>());

    interpreter.close();
  });
}
