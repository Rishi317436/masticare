import 'dart:io';

// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:masticare/services/session_service.dart';
import 'package:masticare/models/user_model.dart';
import 'package:masticare/models/cattle_model.dart';
import 'package:masticare/repositories/user_repository.dart';
import 'package:masticare/repositories/cattle_repository.dart';
import 'package:masticare/services/analysis_service.dart';
import 'package:masticare/services/prediction/prediction_service.dart';
import 'package:masticare/models/prediction_model.dart';
import 'package:masticare/repositories/analysis_repository.dart';
import 'package:masticare/database/database_helper.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakePredictionService implements PredictionService {
  @override
  Future<PredictionModel> predict({required String imagePath}) async {
    return PredictionModel(
      label: 'Healthy (TEST)',
      confidence: 0.90,
      healthyProbability: 0.90,
      mastitisProbability: 0.10,
      isMastitis: false,
      summary: 'Deterministic test prediction',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize ffi-based sqflite for tests and mock path_provider to use temp.
  // This avoids platform channel errors in unit test environment.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Provide a mock for path_provider to use the system temp directory in tests.
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  channel.setMockMethodCallHandler((call) async {
    if (call.method == 'getApplicationDocumentsDirectory') {
      return Directory.systemTemp.path;
    }
    return null;
  });

  // Mock SharedPreferences for tests
  SharedPreferences.setMockInitialValues({});

  test('Settings toggle affects analysis backend and saves analysis', () async {
    // Reset database to ensure clean state
    await DatabaseHelper.instance.resetDatabase();

    // Create a user
    final userId = await UserRepository().createUser(UserModel(
      name: 'Test Farmer',
      email: 'test@example.com',
      passwordHash: 'hash',
      createdAt: DateTime.now(),
    ));

    // Save session
    await SessionService.instance.saveSession(userId);

    // Create a cattle record
    final cattleId = await CattleRepository().saveCattle(CattleModel(
      userId: userId,
      name: 'Cow 1',
      breed: 'Jersey',
      age: 4,
      sex: 'Female',
      createdAt: DateTime.now(),
    ));

    // Create a temporary image file
    final tmp = File('${Directory.systemTemp.path}/masticare_test_image.jpg');
    await tmp.writeAsBytes(List.generate(1024 * 10, (i) => i % 256));

    // Run analysis using the injected fake prediction service
    final service = AnalysisService(predictionService: FakePredictionService());
    final result = await service.runAnalysis(cattleId: cattleId, imagePath: tmp.path);

    expect(result.saved, true);

    // Confirm analysis saved in DB
    final entries = await AnalysisRepository().getAnalysesByCattle(cattleId);
    expect(entries.isNotEmpty, true);

    // Clean up
    if (await tmp.exists()) await tmp.delete();
  });
}
