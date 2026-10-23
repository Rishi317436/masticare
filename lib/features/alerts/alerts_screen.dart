import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/stored_image.dart';
import '../../models/analysis_model.dart';
import '../../models/cattle_model.dart';
import '../../repositories/analysis_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../services/session_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<_AlertItem>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _loadAlerts();
  }

  Future<List<_AlertItem>> _loadAlerts() async {
    final userId = await SessionService.instance.getSessionUserId();
    if (userId == null || userId <= 0) {
      return const [];
    }

    final cattleList = await CattleRepository().getCattleByUser(userId);
    final cattleMap = {for (final cattle in cattleList) cattle.id ?? -1: cattle};
    final analyses = await AnalysisRepository().getAnalyses();

    final alertItems = <_AlertItem>[];
    for (final analysis in analyses) {
      final prediction = analysis.prediction ?? '';
      if (!prediction.toLowerCase().contains('mastitis')) {
        continue;
      }

      final cattle = cattleMap[analysis.cattleId] ??
          CattleModel(userId: userId, name: 'Unknown cattle', createdAt: analysis.timestamp);

      alertItems.add(
        _AlertItem(
          analysis: analysis,
          cattle: cattle,
          recommendation: _buildRecommendation(analysis),
        ),
      );
    }

    alertItems.sort((a, b) => b.analysis.timestamp.compareTo(a.analysis.timestamp));
    return alertItems;
  }

  Future<void> _refresh() async {
    setState(() {
      _alertsFuture = _loadAlerts();
    });
  }

  String _buildRecommendation(AnalysisModel analysis) {
    final confidence = analysis.confidence ?? 0;
    if (confidence >= 0.8) {
      return 'Schedule a veterinary follow-up and inspect the quarter closely.';
    }
    if (confidence >= 0.6) {
      return 'Repeat screening and review the animal for visible changes.';
    }
    return 'Monitor closely and arrange a follow-up review as needed.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<List<_AlertItem>>(
            future: _alertsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final alerts = snapshot.data ?? const <_AlertItem>[];

              return RefreshIndicator(
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Health Alerts', style: AppTypography.titleLarge),
                      const SizedBox(height: 18),
                      if (alerts.isEmpty)
                        Center(
                          child: AppCard(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('No Alerts', style: AppTypography.titleMedium),
                                const SizedBox(height: 8),
                                Text(
                                  'No positive mastitis screening alerts at this time.',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            final alert = alerts[index];
                            return _AlertCard(
                              alert: alert,
                              onView: () => _showResult(alert),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showResult(_AlertItem alert) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.cattle.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alert.analysis.thermalImagePath != null && alert.analysis.thermalImagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: StoredImage(
                    path: alert.analysis.thermalImagePath!,
                    width: 260,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text('Prediction: ${alert.analysis.prediction ?? 'Pending'}'),
              Text('Confidence: ${((alert.analysis.confidence ?? 0) * 100).toStringAsFixed(1)}%'),
              Text('Date: ${_formatDateTime(alert.analysis.timestamp)}'),
              const SizedBox(height: 8),
              Text('Recommendation: ${alert.recommendation}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onView,
  });

  final _AlertItem alert;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final confidence = ((alert.analysis.confidence ?? 0) * 100).toStringAsFixed(1);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.cattle.name,
                  style: AppTypography.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    alert.analysis.prediction ?? 'Mastitis',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.badge.copyWith(color: AppColors.danger),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Confidence: $confidence%', style: AppTypography.bodyMedium),
          Text('Date / time: ${_formatDateTime(alert.analysis.timestamp)}', style: AppTypography.bodyMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Follow-up recommendation: ${alert.recommendation}',
              style: AppTypography.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'View Result',
            variant: AppButtonVariant.secondary,
            onPressed: onView,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _AlertItem {
  const _AlertItem({
    required this.analysis,
    required this.cattle,
    required this.recommendation,
  });

  final AnalysisModel analysis;
  final CattleModel cattle;
  final String recommendation;
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
