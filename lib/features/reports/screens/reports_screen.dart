import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../services/report_generator.dart';
import 'report_details_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<ReportSummary> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = ReportGenerator().generateSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh reports every time screen dependencies change or view is shown
    _reportFuture = ReportGenerator().generateSummary();
  }

  Future<void> _refresh() async {
    setState(() {
      _reportFuture = ReportGenerator().generateSummary();
    });
  }

  Future<void> _generateReport() async {
    final generator = ReportGenerator();
    final filePath = await generator.generateLocalReportFile();
    final summary = await generator.generateSummary();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report saved locally at $filePath'),
        backgroundColor: AppColors.primary,
      ),
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportDetailsScreen(
          generatedAt: summary.generatedAt,
          reportContent: _buildReportBody(summary),
          filePath: filePath,
        ),
      ),
    );
  }

  String _buildReportBody(ReportSummary summary) => _buildReportText(summary);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<ReportSummary>(
            future: _reportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final summary = snapshot.data ?? ReportSummary(
                totalScreenings: 0,
                healthyScreenings: 0,
                mastitisScreenings: 0,
                healthyPercentage: 0,
                mastitisPercentage: 0,
                trend: const [],
                cattleEntries: const [],
                analysisEntries: const [],
                generatedAt: DateTime(2000),
                reportPath: '',
              );

              final hasData = summary.totalScreenings > 0;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Health Analytics & Reports', style: AppTypography.titleLarge),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Real-time herd screening metrics, diagnostic trends, and summary reports.',
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              AppButton(
                                label: 'Export Report',
                                variant: AppButtonVariant.primary,
                                icon: Icons.download_outlined,
                                onPressed: hasData ? _generateReport : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (!hasData)
                            Center(
                              child: AppCard(
                                padding: const EdgeInsets.all(36),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.assessment_outlined, size: 56, color: AppColors.primary),
                                    const SizedBox(height: 16),
                                    Text('No Report Data Available', style: AppTypography.titleMedium),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Perform thermal screening analyses to generate automatic reports.',
                                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: isWide ? 4 : 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: isWide ? 1.4 : 1.1,
                              children: [
                                _SummaryStatCard(
                                  title: 'Total Screenings',
                                  value: '${summary.totalScreenings}',
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.primarySoft,
                                ),
                                _SummaryStatCard(
                                  title: 'Normal Results',
                                  value: '${summary.healthyScreenings}',
                                  color: AppColors.success,
                                  backgroundColor: AppColors.successSoft,
                                ),
                                _SummaryStatCard(
                                  title: 'Infected Alerts',
                                  value: '${summary.mastitisScreenings}',
                                  color: AppColors.danger,
                                  backgroundColor: AppColors.dangerSoft,
                                ),
                                _SummaryStatCard(
                                  title: 'Herd Health Rate',
                                  value: '${summary.healthyPercentage.toStringAsFixed(1)}%',
                                  color: AppColors.accent,
                                  backgroundColor: const Color(0xFFEAF8F5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        _buildTrendCard(summary),
                                        const SizedBox(height: 18),
                                        _buildHealthSummaryCard(summary),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 1,
                                    child: _buildRecentDataCard(summary),
                                  ),
                                ],
                              )
                            else ...[
                              _buildTrendCard(summary),
                              const SizedBox(height: 18),
                              _buildHealthSummaryCard(summary),
                              const SizedBox(height: 18),
                              _buildRecentDataCard(summary),
                            ],
                          ],
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

  Widget _buildTrendCard(ReportSummary summary) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Screening Trend (7 Days)', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _TrendChartPainter(summary.trend),
              size: const Size(double.infinity, 180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard(ReportSummary summary) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Herd Diagnostic Breakdown', style: AppTypography.titleMedium),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Total Screenings Evaluated', value: '${summary.totalScreenings}'),
          _SummaryRow(label: 'Normal (Healthy) Screenings', value: '${summary.healthyScreenings}'),
          _SummaryRow(label: 'Infected (Mastitis) Screenings', value: '${summary.mastitisScreenings}'),
          _SummaryRow(label: 'Normal Rate', value: '${summary.healthyPercentage.toStringAsFixed(1)}%'),
          _SummaryRow(label: 'Infection Rate', value: '${summary.mastitisPercentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildRecentDataCard(ReportSummary summary) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Analysis History', style: AppTypography.titleMedium),
              Text(
                '${summary.analysisEntries.length} total',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (summary.analysisEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No analysis entries recorded yet.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ...summary.analysisEntries.take(10).map((entry) {
              final isInfected = entry.prediction.toLowerCase().contains('mastitis');
              final statusText = isInfected ? 'Infected' : 'Normal';
              final badgeColor = isInfected ? AppColors.danger : AppColors.success;
              final badgeBg = isInfected ? AppColors.dangerSoft : AppColors.successSoft;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isInfected ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                          size: 20,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.cattleName, style: AppTypography.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(entry.timestamp),
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusText,
                          style: AppTypography.badge.copyWith(
                            color: badgeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _buildReportText(ReportSummary summary) {
    final buffer = StringBuffer();
    buffer.writeln('MastiCare Report');
    buffer.writeln('Generated: ${_formatDateTime(summary.generatedAt)}');
    buffer.writeln('');
    buffer.writeln('Health Summary');
    buffer.writeln('Total screenings: ${summary.totalScreenings}');
    buffer.writeln('Healthy screenings: ${summary.healthyScreenings}');
    buffer.writeln('Mastitis screenings: ${summary.mastitisScreenings}');
    buffer.writeln('Healthy percentage: ${summary.healthyPercentage.toStringAsFixed(1)}%');
    buffer.writeln('Mastitis percentage: ${summary.mastitisPercentage.toStringAsFixed(1)}%');
    buffer.writeln('');
    buffer.writeln('Cattle');
    for (final cattle in summary.cattleEntries) {
      buffer.writeln('- ${cattle.name} | Breed: ${cattle.breed} | Sex: ${cattle.sex} | Age: ${cattle.age} | Screenings: ${cattle.screenings}');
    }
    buffer.writeln('');
    buffer.writeln('Analysis History');
    for (final analysis in summary.analysisEntries) {
      buffer.writeln('- ${_formatDateTime(analysis.timestamp)} | ${analysis.cattleName} | ${analysis.prediction}');
      buffer.writeln('  Healthy probability: ${(analysis.healthyProbability * 100).toStringAsFixed(1)}%');
      buffer.writeln('  Mastitis probability: ${(analysis.mastitisProbability * 100).toStringAsFixed(1)}%');
      buffer.writeln('  Confidence: ${(analysis.confidence * 100).toStringAsFixed(1)}%');
    }
    return buffer.toString();
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
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          const SizedBox(width: 8),
          Text(value, style: AppTypography.titleSmall),
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final String value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insights_outlined, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.titleLarge.copyWith(fontSize: 26)),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter(this.points);

  final List<TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final chartRect = Rect.fromLTWH(0, 20, size.width, size.height - 30);

    canvas.drawRect(chartRect, paint);

    if (points.isEmpty) {
      return;
    }

    final maxValue = points.fold<int>(0, (prev, point) => point.value > prev ? point.value : prev);
    final stepX = size.width / points.length;

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final barHeight = maxValue == 0 ? 0.0 : (point.value / maxValue) * (size.height - 60);
      final left = i * stepX + 14;
      final top = size.height - 24 - barHeight;
      final rect = Rect.fromLTWH(left, top, stepX - 20, barHeight.toDouble());

      final barPaint = Paint()
        ..color = i % 2 == 0 ? AppColors.primary : AppColors.accent
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, barPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: point.label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(left, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
