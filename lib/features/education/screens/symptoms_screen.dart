import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../widgets/information_section.dart';

class SymptomsScreen extends StatelessWidget {
  const SymptomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Symptoms / Signs'),
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
                  'Mastitis may appear as changes in the udder or milk, and symptoms can vary between animals. Local screening can help flag possible concern areas, but confirming symptoms requires veterinary assessment.',
                  style: AppTypography.bodyLarge,
                ),
              ),
              SizedBox(height: 18),
              InformationSection(
                title: 'Common signs to review',
                icon: Icons.warning_amber_rounded,
                items: [
                  'Changes in milk appearance, consistency, or color.',
                  'Heat, swelling, or discomfort in the udder or teat area.',
                  'Reduced appetite or reduced comfort during milking or handling.',
                  'Visible changes in the animal’s behavior when the udder is touched.',
                ],
              ),
              SizedBox(height: 18),
              InformationSection(
                title: 'What the application is for',
                items: [
                  'The app screens thermal image inputs for potential mastitis indicators as a supporting tool.',
                  'It is intended for local monitoring and veterinary workflow support, not a substitute for professional diagnosis.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
