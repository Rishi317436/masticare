import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_radio_group.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PredictionMode? _mode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await SettingsService.instance.getPredictionMode();
    if (!mounted) return;
    setState(() => _mode = mode);
  }

  Future<void> _save(PredictionMode mode) async {
    await SettingsService.instance.setPredictionMode(mode);
    if (!mounted) return;
    setState(() => _mode = mode);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prediction backend saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prediction backend', style: AppTypography.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Choose which prediction implementation to use for analyses. Auto will use TFLite when bundled. This app requires a local TFLite model for production analyses.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Use a small internal radio group widget to avoid deprecated RadioListTile APIs
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: AppRadioGroup<PredictionMode>(
                        options: const [
                          RadioOption(
                            value: PredictionMode.auto,
                            title: 'Auto (Recommended)',
                            subtitle: 'Use TFLite if available',
                          ),
                          RadioOption(
                            value: PredictionMode.tflite,
                            title: 'TFLite (Local model)',
                            subtitle:
                                'Use a local TFLite model if one is bundled in assets/models/',
                          ),
                        ],
                        groupValue: _mode,
                        onChanged: (v) => _save(v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Open model folder',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Model files go to assets/models/ in the project.')),
                  );
                },
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Reset to Auto',
                variant: AppButtonVariant.outline,
                onPressed: () => _save(PredictionMode.auto),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
