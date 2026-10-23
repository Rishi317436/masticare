import '../database/dao/cattle_dao.dart';
import '../models/cattle_model.dart';

class CattleRepository {
  CattleRepository({CattleDao? dao}) : _dao = dao ?? CattleDao();

  final CattleDao _dao;

  Future<int> saveCattle(CattleModel cattle) async {
    final row = cattle.toMap();
    if (cattle.id != null) {
      row['updated_at'] ??= DateTime.now().toIso8601String();
      return _dao.updateCattle(row);
    }
    row.remove('id');
    return _dao.insertCattle(row);
  }

  Future<List<CattleModel>> getAllCattle() async {
    final rows = await _dao.fetchCattle();
    return rows.map(CattleModel.fromMap).toList();
  }

  Future<List<CattleModel>> getCattleByUser(int userId) async {
    final rows = await _dao.fetchCattleByUser(userId);
    return rows.map(CattleModel.fromMap).toList();
  }

  Future<CattleModel?> getCattleById(int id) async {
    final row = await _dao.getCattleById(id);
    if (row == null) return null;
    return CattleModel.fromMap(row);
  }

  Future<int> deleteCattle(int id) async {
    return _dao.deleteCattle(id);
  }
}
