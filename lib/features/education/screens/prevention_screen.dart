import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../widgets/information_section.dart';

class PreventionScreen extends StatelessWidget {
  const PreventionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prevention & Care'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: const [
              AppCard(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Good husbandry practices and regular monitoring help support udder health. This guide is educational and should be used alongside veterinarian guidance.',
                  style: AppTypography.bodyLarge,
                ),
              ),
              SizedBox(height: 18),
              InformationSection(
                title: 'Practical prevention tips',
                icon: Icons.shield_outlined,
                items: [
                  'Keep milking and udder hygiene routines consistent and clean.',
                  'Monitor animals regularly for swells, heat, or changes in behavior.',
                  'Track patterns over time with screening records and follow-up notes.',
                  'Report unusual findings promptly to a veterinarian for assessment.',
                ],
              ),
              SizedBox(height: 18),
              InformationSection(
                title: 'A balanced approach',
                items: [
                  'Routine screening can help flag unusually high-risk patterns early.',
                  'The app is a decision-support tool for locally tracking observations and screening data.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
