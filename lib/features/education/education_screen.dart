import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../core/widgets/app_card.dart';
import 'screens/effects_screen.dart';
import 'screens/prevention_screen.dart';
import 'screens/symptoms_screen.dart';
import 'widgets/education_card.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guides = [
      (
        title: 'Symptoms / Signs',
        subtitle: 'Learn the common signs and what to review during screening.',
        icon: Icons.warning_amber_rounded,
        target: const SymptomsScreen(),
      ),
      (
        title: 'Effects',
        subtitle: 'Understand how mastitis can affect herd management and cattle comfort.',
        icon: Icons.health_and_safety_outlined,
        target: const EffectsScreen(),
      ),
      (
        title: 'Prevention & Care',
        subtitle: 'Review practical prevention and follow-up care guidance.',
        icon: Icons.shield_outlined,
        target: const PreventionScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text('Mastitis Guide', style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Educational information for monitoring and follow-up support.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ...guides.map(
                (guide) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: EducationCard(
                    title: guide.title,
                    subtitle: guide.subtitle,
                    icon: guide.icon,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => guide.target),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Important note', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'This guide is for general educational support only. It does not replace veterinary advice or diagnosis.',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
