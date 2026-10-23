import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/stored_image.dart';
import '../../models/cattle_model.dart';
import '../../repositories/cattle_repository.dart';
import '../../services/analysis_service.dart';
import '../../services/session_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _picker = ImagePicker();
  final _analysisService = AnalysisService();

  late Future<List<CattleModel>> _cattleFuture;
  int? _selectedCattleId;
  String? _imagePath;
  bool _isAnalyzing = false;
  AnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    _cattleFuture = _loadCattle();
  }

  Future<List<CattleModel>> _loadCattle() async {
    final userId = await SessionService.instance.getSessionUserId();
    if (userId == null || userId <= 0) {
      return const [];
    }
    return CattleRepository().getCattleByUser(userId);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _imagePath = picked.path;
    });
  }

  Future<void> _analyze() async {
    if (_selectedCattleId == null) {
      _showMessage('Please select a cattle record first.');
      return;
    }
    if (_imagePath == null || _imagePath!.isEmpty) {
      _showMessage('Please upload a thermal image before analysis.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _analysisService.runAnalysis(
        cattleId: _selectedCattleId,
        imagePath: _imagePath!,
      );

      if (!mounted) return;
      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });
      _showMessage(_friendlyErrorMessage(error));
    }
  }

  String _friendlyErrorMessage(Object error) {
    if (error is StateError) {
      return error.message;
    }
    final text = error.toString();
    return text.replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<List<CattleModel>>(
            future: _cattleFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final cattle = snapshot.data ?? const <CattleModel>[];
              if (cattle.isEmpty) {
                return Center(
                  child: AppCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pets_outlined, size: 52, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text('No cattle available', style: AppTypography.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Register cattle before starting analysis.',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final formColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mastitis Analysis', style: AppTypography.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Assess thermal image input and generate a local mastitis screening.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select cattle', style: AppTypography.titleMedium),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _selectedCattleId,
                              decoration: const InputDecoration(labelText: 'Registered cattle'),
                              items: cattle.map((animal) {
                                return DropdownMenuItem<int>(
                                  value: animal.id,
                                  child: Text('${animal.name} • ${animal.breed ?? 'Mixed'}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCattleId = value);
                              },
                              hint: const Text('Choose cattle'),
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
                            Text('Thermal image', style: AppTypography.titleMedium),
                            const SizedBox(height: 12),
                            if (_imagePath != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: AspectRatio(
                                  aspectRatio: 16 / 10,
                                  child: StoredImage(
                                    path: _imagePath!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              AspectRatio(
                                aspectRatio: 16 / 10,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.thermostat_outlined, size: 48, color: AppColors.primary),
                                        SizedBox(height: 12),
                                        Text('No thermal image selected'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Upload image',
                                    variant: AppButtonVariant.secondary,
                                    icon: Icons.upload_file_outlined,
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton(
                                    label: 'Camera',
                                    variant: AppButtonVariant.outline,
                                    icon: Icons.camera_alt_outlined,
                                    onPressed: () => _pickImage(ImageSource.camera),
                                  ),
                                ),
                              ],
                            ),
                            if (_imagePath != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      label: 'Replace image',
                                      variant: AppButtonVariant.secondary,
                                      onPressed: () => _pickImage(ImageSource.gallery),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppButton(
                                      label: 'Remove',
                                      variant: AppButtonVariant.outline,
                                      onPressed: () {
                                        setState(() {
                                          _imagePath = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: _isAnalyzing ? 'Analyzing...' : 'Analyse / Make Prediction',
                        icon: Icons.auto_fix_high_outlined,
                        onPressed: _isAnalyzing ? null : _analyze,
                        isLoading: _isAnalyzing,
                        fullWidth: true,
                      ),
                    ],
                  );

                  final isInfected = _result?.isMastitis ?? false;
                  final resultColor = isInfected ? AppColors.danger : AppColors.success;
                  final resultBgColor = isInfected ? AppColors.dangerSoft : AppColors.successSoft;
                  final statusTitle = isInfected ? 'Infected' : 'Normal';
                  final statusSubtitle = isInfected
                      ? 'Mastitis detected. Medical follow-up recommended.'
                      : 'No mastitis detected. Cattle thermal status is normal.';

                  final resultColumn = AppCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prediction Output', style: AppTypography.titleMedium),
                        const SizedBox(height: 20),
                        if (_result == null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.analytics_outlined, size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  'Results will appear after the thermal image is processed.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: resultBgColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: resultColor.withValues(alpha: 0.3), width: 2),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: resultColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isInfected ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                    size: 38,
                                    color: resultColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  statusTitle,
                                  style: AppTypography.titleLarge.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: resultColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  statusSubtitle,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: resultColor.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: formColumn),
                              const SizedBox(width: 18),
                              Expanded(flex: 1, child: resultColumn),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              formColumn,
                              const SizedBox(height: 18),
                              resultColumn,
                            ],
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
}


