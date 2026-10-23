import 'package:flutter/material.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'features/auth/auth_screen.dart';

class MastiCareApp extends StatelessWidget {
  const MastiCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MastiCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: AppRoutes.routes,
      home: const AuthScreen(),
    );
  }
}
