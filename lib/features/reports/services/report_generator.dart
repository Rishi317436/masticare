import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/analysis_model.dart';
import '../../../models/cattle_model.dart';
import '../../../repositories/analysis_repository.dart';
import '../../../repositories/cattle_repository.dart';
import '../../../services/session_service.dart';

class TrendPoint {
  const TrendPoint({required this.label, required this.value});

  final String label;
  final int value;
}

class ReportCattleEntry {
  const ReportCattleEntry({
    required this.name,
    required this.breed,
    required this.sex,
    required this.age,
    required this.screenings,
  });

  final String name;
  final String breed;
  final String sex;
  final String age;
  final int screenings;
}

class ReportAnalysisEntry {
  const ReportAnalysisEntry({
    required this.cattleName,
    required this.prediction,
    required this.healthyProbability,
    required this.mastitisProbability,
    required this.confidence,
    required this.timestamp,
  });

  final String cattleName;
  final String prediction;
  final double healthyProbability;
  final double mastitisProbability;
  final double confidence;
  final DateTime timestamp;
}

class ReportSummary {
  const ReportSummary({
    required this.totalScreenings,
    required this.healthyScreenings,
    required this.mastitisScreenings,
    required this.healthyPercentage,
    required this.mastitisPercentage,
    required this.trend,
    required this.cattleEntries,
    required this.analysisEntries,
    required this.generatedAt,
    required this.reportPath,
  });

  final int totalScreenings;
  final int healthyScreenings;
  final int mastitisScreenings;
  final double healthyPercentage;
  final double mastitisPercentage;
  final List<TrendPoint> trend;
  final List<ReportCattleEntry> cattleEntries;
  final List<ReportAnalysisEntry> analysisEntries;
  final DateTime generatedAt;
  final String reportPath;
}

class ReportGenerator {
  Future<ReportSummary> generateSummary() async {
    final userId = await SessionService.instance.getSessionUserId();
    if (userId == null || userId <= 0) {
      return ReportSummary(
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
    }

    final cattleList = await CattleRepository().getCattleByUser(userId);
    final cattleMap = {for (final cattle in cattleList) cattle.id ?? -1: cattle};
    final allAnalyses = await AnalysisRepository().getAnalyses();
    final analyses = allAnalyses
        .where((analysis) => cattleMap.containsKey(analysis.cattleId))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final healthyScreenings = analyses.where((a) => (a.prediction ?? '').toLowerCase().contains('healthy')).length;
    final mastitisScreenings = analyses.where((a) => (a.prediction ?? '').toLowerCase().contains('mastitis')).length;
    final totalScreenings = analyses.length;

    final cattleEntries = cattleList.map((cattle) {
      final cattleAnalyses = analyses.where((analysis) => analysis.cattleId == cattle.id).toList();
      return ReportCattleEntry(
        name: cattle.name,
        breed: cattle.breed ?? '—',
        sex: cattle.sex ?? '—',
        age: cattle.age != null ? '${cattle.age} yrs' : '—',
        screenings: cattleAnalyses.length,
      );
    }).toList();

    final analysisEntries = analyses.map((analysis) {
      final cattle = cattleMap[analysis.cattleId] ?? CattleModel(userId: userId, name: 'Unknown', createdAt: analysis.timestamp);
      return ReportAnalysisEntry(
        cattleName: cattle.name,
        prediction: analysis.prediction ?? 'Pending',
        healthyProbability: (analysis.healthyProbability ?? 0).clamp(0.0, 1.0),
        mastitisProbability: (analysis.mastitisProbability ?? 0).clamp(0.0, 1.0),
        confidence: (analysis.confidence ?? 0).clamp(0.0, 1.0),
        timestamp: analysis.timestamp,
      );
    }).toList();

    final trend = _buildTrend(analyses);
    final generatedAt = DateTime.now();

    return ReportSummary(
      totalScreenings: totalScreenings,
      healthyScreenings: healthyScreenings,
      mastitisScreenings: mastitisScreenings,
      healthyPercentage: totalScreenings == 0 ? 0 : (healthyScreenings / totalScreenings) * 100,
      mastitisPercentage: totalScreenings == 0 ? 0 : (mastitisScreenings / totalScreenings) * 100,
      trend: trend,
      cattleEntries: cattleEntries,
      analysisEntries: analysisEntries,
      generatedAt: generatedAt,
      reportPath: '',
    );
  }

  Future<String> generateLocalReportFile() async {
    final summary = await generateSummary();

    if (kIsWeb) {
      final reportName = 'masticare_report_${DateTime.now().millisecondsSinceEpoch}.txt';
      return 'web://reports/$reportName';
    }

    final dir = await getApplicationDocumentsDirectory();
    final reportDir = Directory('${dir.path}/reports');
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }

    final file = File('${reportDir.path}/masticare_report_${DateTime.now().millisecondsSinceEpoch}.txt');
    final contents = _buildReportText(summary);
    await file.writeAsString(contents, flush: true);
    return file.path;
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
    if (summary.cattleEntries.isEmpty) {
      buffer.writeln('No cattle registered.');
    } else {
      for (final cattle in summary.cattleEntries) {
        buffer.writeln('- ${cattle.name} | Breed: ${cattle.breed} | Sex: ${cattle.sex} | Age: ${cattle.age} | Screenings: ${cattle.screenings}');
      }
    }
    buffer.writeln('');
    buffer.writeln('Analysis History');
    if (summary.analysisEntries.isEmpty) {
      buffer.writeln('No analysis records available.');
    } else {
      for (final analysis in summary.analysisEntries) {
        buffer.writeln('- ${_formatDateTime(analysis.timestamp)} | ${analysis.cattleName} | ${analysis.prediction}');
        buffer.writeln('  Healthy probability: ${(analysis.healthyProbability * 100).toStringAsFixed(1)}%');
        buffer.writeln('  Mastitis probability: ${(analysis.mastitisProbability * 100).toStringAsFixed(1)}%');
        buffer.writeln('  Confidence: ${(analysis.confidence * 100).toStringAsFixed(1)}%');
      }
    }
    return buffer.toString();
  }

  List<TrendPoint> _buildTrend(List<AnalysisModel> analyses) {
    if (analyses.isEmpty) {
      return const [];
    }

    final now = DateTime.now();
    final points = <TrendPoint>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final label = _shortWeekday(day.weekday);
      final count = analyses.where((analysis) {
        final timestamp = analysis.timestamp.toLocal();
        return timestamp.year == day.year &&
            timestamp.month == day.month &&
            timestamp.day == day.day;
      }).length;
      points.add(TrendPoint(label: label, value: count));
    }
    return points;
  }

  String _shortWeekday(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1) % 7];
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
