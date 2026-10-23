import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../widgets/information_section.dart';

class EffectsScreen extends StatelessWidget {
  const EffectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Effects'),
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
                  'The effect of mastitis can vary by animal and stage of infection. Early awareness helps support better management and follow-up decisions.',
                  style: AppTypography.bodyLarge,
                ),
              ),
              SizedBox(height: 18),
              InformationSection(
                title: 'Potential impacts',
                icon: Icons.health_and_safety_outlined,
                items: [
                  'Changes in milk quality or consistency may affect herd management and routine monitoring.',
                  'An affected animal may show stress or reduced comfort when the udder is touched or handled.',
                  'Delayed review can reduce the opportunity for timely management decisions and follow-up.',
                ],
              ),
              SizedBox(height: 18),
              InformationSection(
                title: 'Why monitoring matters',
                items: [
                  'Routine screening and record keeping can support veterinarians and farmers in tracking patterns over time.',
                  'The app helps support local observation, but it does not replace a veterinary examination or diagnosis.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
