import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_typography.dart';

enum AppBadgeStyle { success, danger, warning, neutral }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.style = AppBadgeStyle.neutral,
  });

  final String label;
  final AppBadgeStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = switch (style) {
      AppBadgeStyle.success => (
          bg: AppColors.successSoft,
          fg: AppColors.success,
        ),
      AppBadgeStyle.danger => (
          bg: AppColors.dangerSoft,
          fg: AppColors.danger,
        ),
      AppBadgeStyle.warning => (
          bg: AppColors.warningSoft,
          fg: AppColors.warning,
        ),
      AppBadgeStyle.neutral => (
          bg: AppColors.primarySoft,
          fg: AppColors.primary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(color: colors.fg),
      ),
    );
  }
}
