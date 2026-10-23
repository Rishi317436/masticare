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

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> _historyFuture;
  String _search = '';
  String _filter = 'All';
  String _cattleFilter = 'All cattle';

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadData();
  }

  Future<_HistoryData> _loadData() async {
    final userId = await SessionService.instance.getSessionUserId();
    final allCattle = userId == null || userId <= 0 ? const <CattleModel>[] : await CattleRepository().getCattleByUser(userId);
    final cattleMap = {for (final cattle in allCattle) cattle.id ?? -1: cattle};

    final analyses = await AnalysisRepository().getAnalyses();
    final filtered = analyses.where((analysis) {
      final cattle = cattleMap[analysis.cattleId];
      final cattleName = cattle?.name ?? 'Unknown';
      final matchesSearch = _search.trim().isEmpty ||
          cattleName.toLowerCase().contains(_search.toLowerCase()) ||
          (analysis.prediction ?? '').toLowerCase().contains(_search.toLowerCase()) ||
          cattleName.toLowerCase().contains(_search.toLowerCase());

      final matchesFilter = _filter == 'All' ||
          (_filter == 'Healthy' && (analysis.prediction ?? '').toLowerCase().contains('healthy')) ||
          (_filter == 'Mastitis' && (analysis.prediction ?? '').toLowerCase().contains('mastitis')) ||
          (_filter == 'Pending' && ((analysis.prediction ?? '').toLowerCase() == 'pending' || (analysis.prediction ?? '').isEmpty));

      final matchesCattle = _cattleFilter == 'All cattle' || cattleName == _cattleFilter;
      return matchesSearch && matchesFilter && matchesCattle;
    }).toList();

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return _HistoryData(
      analyses: filtered,
      cattle: allCattle,
      cattleNames: ['All cattle', ...allCattle.map((cattle) => cattle.name)],
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<_HistoryData>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final history = snapshot.data ?? const _HistoryData(analyses: [], cattle: [], cattleNames: ['All cattle']);
              final filteredAnalyses = history.analyses.where((analysis) {
                final cattle = history.cattle.firstWhere(
                  (item) => item.id == analysis.cattleId,
                  orElse: () => CattleModel(
                    userId: 0,
                    name: 'Unknown',
                    createdAt: DateTime.now(),
                  ),
                );

                final cattleName = cattle.name;
                final matchesSearch = _search.trim().isEmpty ||
                    cattleName.toLowerCase().contains(_search.toLowerCase()) ||
                    (analysis.prediction ?? '').toLowerCase().contains(_search.toLowerCase());

                final matchesFilter = _filter == 'All' ||
                    (_filter == 'Healthy' && (analysis.prediction ?? '').toLowerCase().contains('healthy')) ||
                    (_filter == 'Mastitis' && (analysis.prediction ?? '').toLowerCase().contains('mastitis')) ||
                    (_filter == 'Pending' && ((analysis.prediction ?? '').toLowerCase() == 'pending' || (analysis.prediction ?? '').isEmpty));

                final matchesCattle = _cattleFilter == 'All cattle' || cattleName == _cattleFilter;
                return matchesSearch && matchesFilter && matchesCattle;
              }).toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Previous Results', style: AppTypography.titleLarge),
                              ),
                              AppButton(
                                label: 'Analyse Now',
                                variant: AppButtonVariant.primary,
                                onPressed: () => Navigator.of(context).pushNamed('/analysis'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          AppCard(
                            padding: const EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final searchField = TextField(
                                  onChanged: (value) => setState(() => _search = value),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText: 'Search by cattle name or result',
                                    border: OutlineInputBorder(),
                                  ),
                                );

                                final filterDropdown = DropdownButtonFormField<String>(
                                  initialValue: _filter,
                                  decoration: const InputDecoration(labelText: 'Filter'),
                                  items: const [
                                    DropdownMenuItem(value: 'All', child: Text('All')),
                                    DropdownMenuItem(value: 'Healthy', child: Text('Healthy')),
                                    DropdownMenuItem(value: 'Mastitis', child: Text('Mastitis')),
                                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) setState(() => _filter = value);
                                  },
                                );

                                final cattleDropdown = DropdownButtonFormField<String>(
                                  initialValue: _cattleFilter,
                                  decoration: const InputDecoration(labelText: 'Cattle'),
                                  items: history.cattleNames.map((name) {
                                    return DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) setState(() => _cattleFilter = value);
                                  },
                                );

                                if (constraints.maxWidth < 500) {
                                  return Column(
                                    children: [
                                      searchField,
                                      const SizedBox(height: 12),
                                      filterDropdown,
                                      const SizedBox(height: 12),
                                      cattleDropdown,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: searchField,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: filterDropdown,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: cattleDropdown,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (filteredAnalyses.isEmpty)
                            Center(
                              child: AppCard(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('No Results', style: AppTypography.titleMedium),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No analysis results are available.',
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 18),
                                    AppButton(
                                      label: 'Analyse Now',
                                      onPressed: () => Navigator.of(context).pushNamed('/analysis'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredAnalyses.length,
                              itemBuilder: (context, index) {
                                final analysis = filteredAnalyses[index];
                                final cattle = history.cattle.firstWhere(
                                  (item) => item.id == analysis.cattleId,
                                  orElse: () => CattleModel(
                                    userId: 0,
                                    name: 'Unknown',
                                    createdAt: analysis.timestamp,
                                  ),
                                );
                                return _HistoryResultCard(
                                  analysis: analysis,
                                  cattle: cattle,
                                  onTap: () => _showDetails(analysis, cattle),
                                );
                              },
                            ),
                        ],
                      ),
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

  Future<void> _showDetails(AnalysisModel analysis, CattleModel cattle) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cattle.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (analysis.thermalImagePath != null && analysis.thermalImagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: StoredImage(
                    path: analysis.thermalImagePath!,
                    width: 260,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Text('No thermal image available'),
              const SizedBox(height: 12),
              Text('Prediction: ${analysis.prediction ?? 'Pending'}'),
              Text('Confidence: ${((analysis.confidence ?? 0) * 100).toStringAsFixed(1)}%'),
              Text('Healthy probability: ${((analysis.healthyProbability ?? 0) * 100).toStringAsFixed(1)}%'),
              Text('Mastitis probability: ${((analysis.mastitisProbability ?? 0) * 100).toStringAsFixed(1)}%'),
              Text('Date: ${_formatDateTime(analysis.timestamp)}'),
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

class _HistoryResultCard extends StatelessWidget {
  const _HistoryResultCard({
    required this.analysis,
    required this.cattle,
    required this.onTap,
  });

  final AnalysisModel analysis;
  final CattleModel cattle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final prediction = analysis.prediction ?? 'Pending';
    final isHealthy = prediction.toLowerCase().contains('healthy');
    final isMastitis = prediction.toLowerCase().contains('mastitis');
    final statusColor = isMastitis ? AppColors.danger : isHealthy ? AppColors.success : AppColors.warning;
    final statusBg = isMastitis ? AppColors.dangerSoft : isHealthy ? AppColors.successSoft : AppColors.warningSoft;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (analysis.thermalImagePath != null && analysis.thermalImagePath!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: StoredImage(
                path: analysis.thermalImagePath!,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.thermostat_outlined, size: 42, color: AppColors.primary),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cattle.name,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        prediction,
                        style: AppTypography.badge.copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Cattle ID: ${cattle.id ?? '—'}', style: AppTypography.bodySmall),
                Text('Confidence: ${((analysis.confidence ?? 0) * 100).toStringAsFixed(1)}%', style: AppTypography.bodySmall),
                Text('Healthy: ${((analysis.healthyProbability ?? 0) * 100).toStringAsFixed(1)}%', style: AppTypography.bodySmall),
                Text('Mastitis: ${((analysis.mastitisProbability ?? 0) * 100).toStringAsFixed(1)}%', style: AppTypography.bodySmall),
                Text('Date: ${_formatDateTime(analysis.timestamp)}', style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryData {
  const _HistoryData({
    required this.analyses,
    required this.cattle,
    required this.cattleNames,
  });

  final List<AnalysisModel> analyses;
  final List<CattleModel> cattle;
  final List<String> cattleNames;
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
