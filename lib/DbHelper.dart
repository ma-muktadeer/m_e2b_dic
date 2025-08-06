import 'dart:io';

import 'package:brotli/brotli.dart' as brotli;
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  // Future initDb() async {
  //   final String fileName = '.nomedia';
  //   final dbPath = await getDatabasesPath();
  //   final path = join(dbPath, fileName);
  //
  //   final exist = await databaseExists(path);
  //
  //   if (exist) {
  //     print('database already exits.');
  //     final db = await openDatabase(path);
  //     return db;
  //   } else {
  //     print('database not exits.');
  //     try {
  //       await Directory(dirname(path)).create(recursive: true);
  //     } catch (_) {}
  //
  //     ByteData data = await rootBundle.load(join("assets", fileName));
  //     List<int> bytes =
  //         data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  //
  //     await File(path).writeAsBytes(bytes, flush: true);
  //
  //     print('database copied.');
  //   }
  //
  //   await openDatabase(path);
  // }

  Future<Database> initDb() async {
    const String compressedFileName = '.nomedia.br';
    const String dbFileName = '.nomedia';
    final dbPath = await getDatabasesPath();
    final compressedPath = join(dbPath, compressedFileName);
    final dbPathFinal = join(dbPath, dbFileName);

    // Check if uncompressed database already exists
    if (await databaseExists(dbPathFinal)) {
      print('Database already exists');
      return await openDatabase(dbPathFinal);
    }

    print('Setting up database from compressed asset...');
    try {
      await Directory(dirname(dbPathFinal)).create(recursive: true);
    } catch (e) {
      print('Error creating directory: $e');
    }

    try {
      // Load the compressed asset
      final ByteData compressedData = await rootBundle.load(
          join("assets", compressedFileName));
      final Uint8List compressedBytes = compressedData.buffer.asUint8List(
        compressedData.offsetInBytes,
        compressedData.lengthInBytes,
      );

      // Decompress using brotli 0.6.0
      final decompressedBytes = brotli.brotliDecode(compressedBytes);
      if (decompressedBytes == null) {
        throw Exception('Brotli decompression failed');
      }

      // Write the decompressed database file
      await File(dbPathFinal).writeAsBytes(decompressedBytes, flush: true);
      print('Database successfully decompressed and initialized');

      return await openDatabase(dbPathFinal);
    } catch (e) {
      print('Database initialization error: $e');
      // Clean up potentially corrupted file
      try {
        if (await File(dbPathFinal).exists()) {
          await File(dbPathFinal).delete();
        }
      } catch (_) {}
      rethrow;
    }
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
