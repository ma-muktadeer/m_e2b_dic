import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  Future initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, '.nomedia');

    final exist = await databaseExists(path);

    if (exist) {
      print('database already exits.');
      final db = await openDatabase(path);
      return db;
    } else {
      print('database not exits.');
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets", '.nomedia'));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);

      print('database copied.');
    }

    await openDatabase(path);
  }

  static const _databaseName = "dictionary.db";
  static const _databaseVersion = 2; // Incremented version

  // Add history table creation SQL
  static const createHistoryTable = "CREATE TABLE IF NOT EXISTS search_history ( "
      " id INTEGER PRIMARY KEY AUTOINCREMENT,"
      " term TEXT NOT NULL,"
      "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);";

  Future<Database> createDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute(createHistoryTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(createHistoryTable);
        }
      },
    );
  }

  Future<void> insertSearchTerm(String term) async {
    final db = await createDatabase();
    await db.insert(
      'search_history',
      {'term': term},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getSearchHistory({int limit = 20}) async {
    final db = await createDatabase();
    final results = await db.query(
      'search_history',
      columns: ['term'],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return results.map((row) => row['term'] as String).toList();
  }

  Future<void> clearSearchHistory() async {
    final db = await createDatabase();
    await db.delete('search_history');
  }
}
