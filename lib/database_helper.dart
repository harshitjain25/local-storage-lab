import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String tableName = 'my_table';

  static const String columnId = '_id';
  static const String columnName = 'name';
  static const String columnAge = 'age';

  late Database _db;

  Future<void> init() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();

    final String path = join(
      documentsDirectory.path,
      'MyDatabase.db',
    );

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insert(
    Map<String, dynamic> row,
  ) async {
    return await _db.insert(
      tableName,
      row,
    );
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(
      tableName,
      orderBy: '$columnId ASC',
    );
  }

  Future<int> queryRowCount() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) FROM $tableName',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(
    Map<String, dynamic> row,
  ) async {
    final int id = row[columnId];

    return await _db.update(
      tableName,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}