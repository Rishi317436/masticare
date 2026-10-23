import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_routes.dart';
import '../features/alerts/alerts_screen.dart';
import '../services/session_service.dart';
import '../features/analysis/analysis_screen.dart';
import '../features/cattle/cattle_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/education/education_screen.dart';
import '../features/history/history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import 'bottom_navigation.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  static const List<NavigationRailItem> _navItems = [
    NavigationRailItem(label: 'Dashboard', icon: Icons.home_outlined),
    NavigationRailItem(label: 'My Cattle', icon: Icons.pets_outlined),
    NavigationRailItem(label: 'Analysis', icon: Icons.analytics_outlined),
    NavigationRailItem(label: 'Previous Results', icon: Icons.history_outlined),
    NavigationRailItem(label: 'Alerts', icon: Icons.notifications_outlined),
    NavigationRailItem(label: 'Reports', icon: Icons.receipt_long_outlined),
    NavigationRailItem(label: 'Mastitis Guide', icon: Icons.menu_book_outlined),
    NavigationRailItem(label: 'Profile', icon: Icons.person_outline),
  ];

  static const List<Widget> _screens = [
    DashboardScreen(),
    CattleScreen(),
    AnalysisScreen(),
    HistoryScreen(),
    AlertsScreen(),
    ReportsScreen(),
    EducationScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _navItems.length - 1);
  }

  void _handleTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(
                  currentIndex: _currentIndex,
                  items: _navItems,
                  onTap: _handleTap,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBarWidget(
            currentIndex: _currentIndex,
            items: _navItems,
            onTap: _handleTap,
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<NavigationRailItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 245,
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🐄',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'MastiCare Pro',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Workspace',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textMuted,
                textBaseline: TextBaseline.alphabetic,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == currentIndex;

                return TextButton(
                  onPressed: () => onTap(index),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    backgroundColor: selected ? AppColors.primarySoft : Colors.transparent,
                    foregroundColor: selected ? AppColors.primary : AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(item.icon, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: selected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              foregroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.settings_outlined, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await SessionService.instance.clearSession();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.auth,
                (route) => false,
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              foregroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.logout_outlined, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
