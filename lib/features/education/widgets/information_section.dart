import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../core/widgets/app_card.dart';

class InformationSection extends StatelessWidget {
  const InformationSection({
    super.key,
    required this.title,
    required this.items,
    this.icon,
  });

  final String title;
  final List<String> items;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(title, style: AppTypography.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(Icons.fiber_manual_record, size: 10, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
