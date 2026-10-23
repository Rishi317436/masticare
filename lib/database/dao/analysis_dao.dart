import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';
import '../database_schema.dart';

class AnalysisDao {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<int> insertAnalysis(Map<String, dynamic> analysis) async {
    final db = await _db;
    return db.insert(DatabaseSchema.analysesTable, analysis,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<Map<String, dynamic>>> fetchAnalyses() async {
    final db = await _db;
    return db.query(DatabaseSchema.analysesTable, orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> fetchAnalysesByCattle(int cattleId) async {
    final db = await _db;
    return db.query(
      DatabaseSchema.analysesTable,
      where: 'cattle_id = ?',
      whereArgs: [cattleId],
      orderBy: 'timestamp DESC',
    );
  }
}
