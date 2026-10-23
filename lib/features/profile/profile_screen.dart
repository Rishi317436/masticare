import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_routes.dart';
import '../../config/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../models/user_model.dart';
import '../../repositories/analysis_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/session_service.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final userId = await SessionService.instance.getSessionUserId();
    if (userId == null || userId <= 0) {
      return const _ProfileData(
        user: null,
        cattleCount: 0,
        analysisCount: 0,
      );
    }

    final user = await UserRepository().getUserById(userId);
    final cattle = await CattleRepository().getCattleByUser(userId);

    var analysisCount = 0;
    for (final cattleItem in cattle) {
      final cattleId = cattleItem.id ?? -1;
      if (cattleId <= 0) continue;
      final analyses = await AnalysisRepository().getAnalysesByCattle(cattleId);
      analysisCount += analyses.length;
    }

    return _ProfileData(
      user: user,
      cattleCount: cattle.length,
      analysisCount: analysisCount,
    );
  }

  Future<void> _signOut() async {
    await SessionService.instance.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.auth,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<_ProfileData>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data ?? const _ProfileData(
                user: null,
                cattleCount: 0,
                analysisCount: 0,
              );

              final user = data.user;
              if (user == null) {
                return Center(
                  child: AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('No active session', style: AppTypography.titleMedium),
                        const SizedBox(height: 12),
                        Text(
                          'Please sign in to view your account details.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: 'Go to login',
                          variant: AppButtonVariant.primary,
                          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.auth,
                            (route) => false,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final initials = user.name.split(RegExp(r'\s+')).take(2).map((part) => part.isNotEmpty ? part[0].toUpperCase() : '').join();

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _profileFuture = _loadProfile();
                  });
                },
                child: ListView(
                  children: [
                    Text('Profile', style: AppTypography.titleLarge),
                    const SizedBox(height: 20),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    initials.isEmpty ? 'M' : initials,
                                    style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.name, style: AppTypography.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.role ?? 'Farmer',
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const AppBadge(label: 'Offline', style: AppBadgeStyle.neutral),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStatCard(
                                  label: 'Cattle',
                                  value: '${data.cattleCount}',
                                  icon: Icons.pets_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MiniStatCard(
                                  label: 'Analyses',
                                  value: '${data.analysisCount}',
                                  icon: Icons.analytics_outlined,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account details', style: AppTypography.titleMedium),
                          const SizedBox(height: 14),
                          _InfoRow(label: 'Email', value: user.email),
                          _InfoRow(label: 'Phone', value: user.phone ?? 'Not provided'),
                          _InfoRow(label: 'Village / City', value: user.location ?? 'Not provided'),
                          _InfoRow(label: 'Role', value: user.role ?? 'Farmer'),
                          if (user.createdAt != null)
                            _InfoRow(
                              label: 'Member since',
                              value: '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Session', style: AppTypography.titleMedium),
                          const SizedBox(height: 12),
                          Text(
                            'This account is stored locally on this device and remains fully offline.',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 18),
                          Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      label: 'Settings',
                                      variant: AppButtonVariant.secondary,
                                      icon: Icons.settings_outlined,
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppButton(
                                      label: 'Sign out',
                                      variant: AppButtonVariant.outline,
                                      icon: Icons.logout_outlined,
                                      fullWidth: true,
                                      onPressed: _signOut,
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.user,
    required this.cattleCount,
    required this.analysisCount,
  });

  final UserModel? user;
  final int cattleCount;
  final int analysisCount;
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.12).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.titleMedium, overflow: TextOverflow.ellipsis),
                Text(label, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
