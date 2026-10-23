import 'package:flutter/material.dart';

import '../features/auth/auth_screen.dart';
import '../navigation/main_navigation.dart';

class AppRoutes {
  AppRoutes._();

  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
  static const String cattle = '/cattle';
  static const String analysis = '/analysis';
  static const String history = '/history';
  static const String alerts = '/alerts';
  static const String reports = '/reports';
  static const String education = '/education';
  static const String profile = '/profile';

  static const List<String> all = [
    dashboard,
    cattle,
    analysis,
    history,
    alerts,
    reports,
    education,
    profile,
  ];

  static Map<String, WidgetBuilder> get routes => {
        auth: (context) => const AuthScreen(),
        dashboard: (context) => const MainNavigation(initialIndex: 0),
        cattle: (context) => const MainNavigation(initialIndex: 1),
        analysis: (context) => const MainNavigation(initialIndex: 2),
        history: (context) => const MainNavigation(initialIndex: 3),
        alerts: (context) => const MainNavigation(initialIndex: 4),
        reports: (context) => const MainNavigation(initialIndex: 5),
        education: (context) => const MainNavigation(initialIndex: 6),
        profile: (context) => const MainNavigation(initialIndex: 7),
      };

  static int indexForRoute(String route) {
    final index = all.indexOf(route);
    return index >= 0 ? index : 0;
  }
}
