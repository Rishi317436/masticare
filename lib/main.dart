import 'package:flutter/material.dart';

import 'app.dart';
import 'database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseHelper.initialize();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'Database initialization',
        context: ErrorDescription('SQLite initialization failed before the app launched.'),
      ),
    );
  }

  runApp(const MastiCareApp());
}
