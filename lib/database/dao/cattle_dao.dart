import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';
import '../database_schema.dart';

class CattleDao {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<int> insertCattle(Map<String, dynamic> cattle) async {
    final db = await _db;
    return db.insert(DatabaseSchema.cattleTable, cattle,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<Map<String, dynamic>>> fetchCattleByUser(int userId) async {
    final db = await _db;
    return db.query(
      DatabaseSchema.cattleTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> fetchCattle() async {
    final db = await _db;
    return db.query(DatabaseSchema.cattleTable, orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getCattleById(int id) async {
    final db = await _db;
    final result = await db.query(
      DatabaseSchema.cattleTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateCattle(Map<String, dynamic> cattle) async {
    final db = await _db;
    return db.update(
      DatabaseSchema.cattleTable,
      cattle,
      where: 'id = ?',
      whereArgs: [cattle['id']],
    );
  }

  Future<int> deleteCattle(int id) async {
    final db = await _db;
    return db.delete(
      DatabaseSchema.cattleTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
