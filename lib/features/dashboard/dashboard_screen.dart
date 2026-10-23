import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_routes.dart';
import '../../config/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../models/analysis_model.dart';
import '../../repositories/analysis_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/session_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    final userId = await SessionService.instance.getSessionUserId();
    if (userId == null || userId <= 0) {
      return const _DashboardData(
        userName: 'Farmer',
        userRole: 'User',
        totalCattle: 0,
        totalAnalyses: 0,
        mastitisAlerts: 0,
        healthyScreenings: 0,
        recentAnalyses: [],
      );
    }

    final user = await UserRepository().getUserById(userId);
    final cattleList = await CattleRepository().getCattleByUser(userId);
    final cattleById = {for (final cattle in cattleList) cattle.id ?? -1: cattle};

    final allAnalyses = <AnalysisModel>[];
    for (final cattle in cattleList) {
      final cattleId = cattle.id ?? -1;
      if (cattleId <= 0) continue;
      final cattleAnalyses = await AnalysisRepository().getAnalysesByCattle(cattleId);
      allAnalyses.addAll(cattleAnalyses);
    }

    allAnalyses.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final recentAnalyses = allAnalyses.take(5).map((analysis) {
      final cattleName = cattleById[analysis.cattleId]?.name ?? 'Cattle';
      return _RecentAnalysis(
        cattleName: cattleName,
        prediction: analysis.prediction ?? 'Pending',
        timestamp: analysis.timestamp,
      );
    }).toList();

    final mastitisAlerts = allAnalyses.where((analysis) {
      final prediction = analysis.prediction?.toLowerCase() ?? '';
      return prediction.contains('mastitis');
    }).length;

    final healthyScreenings = allAnalyses.where((analysis) {
      final prediction = analysis.prediction?.toLowerCase() ?? '';
      return prediction == 'healthy';
    }).length;

    return _DashboardData(
      userName: user?.name ?? 'Farmer',
      userRole: user?.role ?? 'Farmer',
      totalCattle: cattleList.length,
      totalAnalyses: allAnalyses.length,
      mastitisAlerts: mastitisAlerts,
      healthyScreenings: healthyScreenings,
      recentAnalyses: recentAnalyses,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<_DashboardData>(
            future: _dashboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data ?? const _DashboardData(
                userName: 'Farmer',
                userRole: 'User',
                totalCattle: 0,
                totalAnalyses: 0,
                mastitisAlerts: 0,
                healthyScreenings: 0,
                recentAnalyses: [],
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _WelcomeCard(
                            userName: data.userName,
                            userRole: data.userRole,
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: isWide ? 4 : 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: isWide ? 1.5 : 1.1,
                            children: [
                              _StatCard(
                                title: 'Total cattle',
                                value: '${data.totalCattle}',
                                icon: Icons.pets_outlined,
                                color: AppColors.primary,
                                backgroundColor: AppColors.primarySoft,
                              ),
                              _StatCard(
                                title: 'Total analyses',
                                value: '${data.totalAnalyses}',
                                icon: Icons.analytics_outlined,
                                color: AppColors.accent,
                                backgroundColor: const Color(0xFFEAF8F5),
                              ),
                              _StatCard(
                                title: 'Mastitis alerts',
                                value: '${data.mastitisAlerts}',
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.danger,
                                backgroundColor: AppColors.dangerSoft,
                              ),
                              _StatCard(
                                title: 'Healthy screenings',
                                value: '${data.healthyScreenings}',
                                icon: Icons.check_circle_outline,
                                color: AppColors.success,
                                backgroundColor: AppColors.successSoft,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _QuickActionsCard(
                                    onRegisterCattle: () => _openRoute(AppRoutes.cattle),
                                    onNewAnalysis: () => _openRoute(AppRoutes.analysis),
                                    onAlerts: () => _openRoute(AppRoutes.alerts),
                                    onReports: () => _openRoute(AppRoutes.reports),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  flex: 3,
                                  child: _RecentAnalysesCard(analyses: data.recentAnalyses),
                                ),
                              ],
                            )
                          else ...[
                            _QuickActionsCard(
                              onRegisterCattle: () => _openRoute(AppRoutes.cattle),
                              onNewAnalysis: () => _openRoute(AppRoutes.analysis),
                              onAlerts: () => _openRoute(AppRoutes.alerts),
                              onReports: () => _openRoute(AppRoutes.reports),
                            ),
                            const SizedBox(height: 18),
                            _RecentAnalysesCard(analyses: data.recentAnalyses),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _openRoute(String route) {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(route);
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.userName,
    required this.userRole,
  });

  final String userName;
  final String userRole;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName',
                  style: AppTypography.titleLarge.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        userRole,
                        style: AppTypography.badge.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Farm health overview',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 8),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Live',
                    style: AppTypography.badge.copyWith(color: color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.titleLarge.copyWith(fontSize: 30),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onRegisterCattle,
    required this.onNewAnalysis,
    required this.onAlerts,
    required this.onReports,
  });

  final VoidCallback onRegisterCattle;
  final VoidCallback onNewAnalysis;
  final VoidCallback onAlerts;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(label: 'Register Cattle', icon: Icons.add_circle_outline, onPressed: onRegisterCattle),
      _QuickAction(label: 'New Analysis', icon: Icons.analytics_outlined, onPressed: onNewAnalysis),
      _QuickAction(label: 'Alerts', icon: Icons.notifications_outlined, onPressed: onAlerts),
      _QuickAction(label: 'Reports', icon: Icons.receipt_long_outlined, onPressed: onReports),
    ];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return AppButton(
                label: action.label,
                icon: action.icon,
                variant: AppButtonVariant.secondary,
                onPressed: action.onPressed,
                fullWidth: true,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentAnalysesCard extends StatelessWidget {
  const _RecentAnalysesCard({required this.analyses});

  final List<_RecentAnalysis> analyses;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent analyses', style: AppTypography.titleMedium),
              const Spacer(),
              Text('Latest', style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          if (analyses.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              child: Text(
                'No analyses recorded yet',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ...analyses.map((analysis) {
              final statusColor = analysis.prediction.toLowerCase().contains('mastitis')
                  ? AppColors.danger
                  : analysis.prediction.toLowerCase() == 'healthy'
                      ? AppColors.success
                      : AppColors.warning;
              final statusBg = analysis.prediction.toLowerCase().contains('mastitis')
                  ? AppColors.dangerSoft
                  : analysis.prediction.toLowerCase() == 'healthy'
                      ? AppColors.successSoft
                      : AppColors.warningSoft;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            analysis.cattleName,
                            style: AppTypography.titleSmall,
                          ),
                          Text(
                            _formatDateTime(analysis.timestamp),
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        analysis.prediction,
                        style: AppTypography.badge.copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _DashboardData {
  const _DashboardData({
    required this.userName,
    required this.userRole,
    required this.totalCattle,
    required this.totalAnalyses,
    required this.mastitisAlerts,
    required this.healthyScreenings,
    required this.recentAnalyses,
  });

  final String userName;
  final String userRole;
  final int totalCattle;
  final int totalAnalyses;
  final int mastitisAlerts;
  final int healthyScreenings;
  final List<_RecentAnalysis> recentAnalyses;
}

class _RecentAnalysis {
  const _RecentAnalysis({
    required this.cattleName,
    required this.prediction,
    required this.timestamp,
  });

  final String cattleName;
  final String prediction;
  final DateTime timestamp;
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
