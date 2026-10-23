import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database_migrations.dart';
import 'database_schema.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;
  static bool _initializationStarted = false;

  static const int _databaseVersion = 1;

  static Future<void> initialize() async {
    if (_database != null || _initializationStarted) {
      return;
    }

    _initializationStarted = true;

    try {
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      await instance.database;
    } finally {
      // Keep the initialization idempotent: once the factory is configured and
      // the DB has been opened, future calls should not re-enter setup.
      _initializationStarted = false;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return openDatabase(
        'masticare.db',
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/masticare.db';

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(DatabaseSchema.createUsersTable);
    await db.execute(DatabaseSchema.createCattleTable);
    await db.execute(DatabaseSchema.createAnalysisTable);
    await db.execute(DatabaseSchema.createForeignKeyIndex);
    await db.execute(DatabaseSchema.createAnalysisCattleIndex);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      for (final migration in DatabaseMigrations.migrations) {
        await db.execute(migration);
      }
    }
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    _database = null;

    final directory = await getApplicationDocumentsDirectory();
    final dbFile = File('${directory.path}/masticare.db');
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
  }
}
