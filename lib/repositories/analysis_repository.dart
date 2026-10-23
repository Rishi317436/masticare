import '../database/dao/analysis_dao.dart';
import '../models/analysis_model.dart';

class AnalysisRepository {
  AnalysisRepository({AnalysisDao? dao}) : _dao = dao ?? AnalysisDao();

  final AnalysisDao _dao;

  Future<int> saveAnalysis(AnalysisModel analysis) async {
    final row = analysis.toMap();
    row.remove('id');
    return _dao.insertAnalysis(row);
  }

  Future<List<AnalysisModel>> getAnalyses() async {
    final rows = await _dao.fetchAnalyses();
    return rows.map(AnalysisModel.fromMap).toList();
  }

  Future<List<AnalysisModel>> getAnalysesByCattle(int cattleId) async {
    final rows = await _dao.fetchAnalysesByCattle(cattleId);
    return rows.map(AnalysisModel.fromMap).toList();
  }
}
