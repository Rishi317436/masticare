import 'dart:io';

import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../models/cattle_model.dart';
import '../../repositories/analysis_repository.dart';
import '../../repositories/cattle_repository.dart';
import '../../services/image_storage_service.dart';
import '../../services/session_service.dart';
import 'cattle_form_dialog.dart';
import 'cattle_image_widget.dart';

class CattleScreen extends StatefulWidget {
  const CattleScreen({super.key});

  @override
  State<CattleScreen> createState() => _CattleScreenState();
}

class _CattleScreenState extends State<CattleScreen> {
  late Future<List<_CattleDisplayItem>> _cattleFuture;

  @override
  void initState() {
    super.initState();
    _cattleFuture = _loadCattle();
  }

  Future<List<_CattleDisplayItem>> _loadCattle() async {
    final userId = await SessionService.instance.getSessionUserId();
    if (userId == null || userId <= 0) {
      return const [];
    }

    final cattleRepo = CattleRepository();
    final analysisRepo = AnalysisRepository();
    final cattleList = await cattleRepo.getCattleByUser(userId);

    final displayItems = <_CattleDisplayItem>[];
    for (final cattle in cattleList) {
      final analyses = await analysisRepo.getAnalysesByCattle(cattle.id ?? -1);
      final latest = analyses.isNotEmpty ? analyses.first : null;
      displayItems.add(
        _CattleDisplayItem(
          cattle: cattle,
          screenings: analyses.length,
          latestStatus: latest == null
              ? 'No screening'
              : (latest.prediction == null || latest.prediction!.isEmpty
                  ? 'Pending'
                  : latest.prediction!),
        ),
      );
    }

    return displayItems;
  }

  Future<void> _refresh() async {
    setState(() {
      _cattleFuture = _loadCattle();
    });
  }

  Future<void> _openForm([CattleModel? cattle]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CattleFormDialog(cattle: cattle),
    );

    if (result == true) {
      await _refresh();
    }
  }

  Future<void> _deleteCattle(CattleModel cattle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete cattle?'),
        content: Text('Delete ${cattle.name}? This will remove the record and local image file.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final imagePath = cattle.imagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      await ImageStorageService().deleteImage(imagePath);
    }

    await CattleRepository().deleteCattle(cattle.id ?? -1);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Register Cattle'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const Text('My Cattle', style: AppTypography.titleLarge),
                  AppButton(
                    label: 'Register Cattle',
                    variant: AppButtonVariant.primary,
                    onPressed: () => _openForm(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<_CattleDisplayItem>>(
                  future: _cattleFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final cattle = snapshot.data ?? const [];
                    if (cattle.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.pets_outlined,
                        title: 'No cattle registered',
                        subtitle: 'Add your first cattle to begin tracking health screenings.',
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        // Compute a responsive crossAxisCount based on available
                        // width so grid items don't become too narrow in small
                        // viewports (which caused the RenderFlex overflow).
                        int crossAxisCount = (constraints.maxWidth / 220).floor();
                        if (crossAxisCount < 1) crossAxisCount = 1;
                        if (crossAxisCount > 3) crossAxisCount = 3;

                        return GridView.builder(
                          itemCount: cattle.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemBuilder: (context, index) {
                            final item = cattle[index];
                            return _CattleCard(
                              item: item,
                              onEdit: () => _openForm(item.cattle),
                              onDelete: () => _deleteCattle(item.cattle),
                              onView: () => _showDetails(item.cattle),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(CattleModel cattle) async {
    final analyses = await AnalysisRepository().getAnalysesByCattle(cattle.id ?? -1);
    final latest = analyses.isNotEmpty ? analyses.first : null;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cattle.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cattle.imagePath != null && cattle.imagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(cattle.imagePath!),
                    width: 260,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text('Breed: ${cattle.breed ?? '—'}'),
              Text('Age: ${cattle.age ?? '—'}'),
              Text('Sex: ${cattle.sex ?? '—'}'),
              Text('Notes: ${cattle.notes?.isNotEmpty == true ? cattle.notes : 'No notes'}'),
              const SizedBox(height: 8),
              Text('Screenings: ${analyses.length}'),
              if (latest != null) Text('Latest status: ${latest.prediction ?? 'Pending'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openForm(cattle);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _CattleCard extends StatelessWidget {
  const _CattleCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  final _CattleDisplayItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onView,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: item.cattle.imagePath != null && item.cattle.imagePath!.isNotEmpty
                     ? CattleImage(path: item.cattle.imagePath!)
                     : Container(
                         color: AppColors.primarySoft,
                         child: const Center(
                           child: Icon(Icons.pets_outlined, size: 48, color: AppColors.primary),
                         ),
                       ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.cattle.name,
                  style: AppTypography.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Breed: ${item.cattle.breed ?? '—'}', style: AppTypography.bodySmall),
          Text('Age: ${item.cattle.age ?? '—'}', style: AppTypography.bodySmall),
          Text('Sex: ${item.cattle.sex ?? '—'}', style: AppTypography.bodySmall),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${item.screenings} screenings',
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.latestStatus.toLowerCase().contains('mastitis')
                          ? AppColors.dangerSoft
                          : AppColors.successSoft,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      item.latestStatus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.badge.copyWith(
                        color: item.latestStatus.toLowerCase().contains('mastitis')
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CattleDisplayItem {
  const _CattleDisplayItem({
    required this.cattle,
    required this.screenings,
    required this.latestStatus,
  });

  final CattleModel cattle;
  final int screenings;
  final String latestStatus;
}
