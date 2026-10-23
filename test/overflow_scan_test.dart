import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masticare/features/alerts/alerts_screen.dart';
import 'package:masticare/features/analysis/analysis_screen.dart';
import 'package:masticare/features/auth/auth_screen.dart';
import 'package:masticare/features/cattle/cattle_screen.dart';
import 'package:masticare/features/dashboard/dashboard_screen.dart';
import 'package:masticare/features/education/education_screen.dart';
import 'package:masticare/features/profile/profile_screen.dart';
import 'package:masticare/features/reports/screens/reports_screen.dart';
import 'package:masticare/features/settings/settings_screen.dart';
import 'package:masticare/features/history/history_screen.dart';

void main() {
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };

  final screens = <(String, Widget)>[
    ('Sign In', const AuthScreen()),
    ('Dashboard', const DashboardScreen()),
    ('My Cattle', const CattleScreen()),
    ('Analysis', const AnalysisScreen()),
    ('Previous Results', const HistoryScreen()),
    ('Alerts', const AlertsScreen()),
    ('Reports', const ReportsScreen()),
    ('Mastitis Guide', const EducationScreen()),
    ('Profile', const ProfileScreen()),
    ('Settings', const SettingsScreen()),
  ];

  for (final size in [
    const Size(360, 800),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('no overflow on all screens at ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      for (final entry in screens) {
        final name = entry.$1;
        final widget = entry.$2;

        await tester.pumpWidget(MaterialApp(home: widget));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final exception = tester.takeException();
        expect(exception, isNull, reason: 'Overflow or render error on $name at ${size.width}x${size.height}');
      }
    });
  }
}
