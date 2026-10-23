import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';
import '../database_schema.dart';

class UserDao {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await _db;
    return db.insert(DatabaseSchema.usersTable, user,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final db = await _db;
    return db.query(DatabaseSchema.usersTable, orderBy: 'id ASC');
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await _db;
    final result = await db.query(
      DatabaseSchema.usersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await _db;
    final result = await db.query(
      DatabaseSchema.usersTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
}
