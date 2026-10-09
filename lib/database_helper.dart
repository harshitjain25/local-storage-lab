import 'dart:io';

import 'models/folder.dart';
import 'models/card.dart';
import 'card_validation.dart';

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

    final String path = join(documentsDirectory.path, 'MyDatabase.db');

    _db = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: _onUpgrade,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
    ''');
    await _createCatalogue(db);
  }

  // Upgrade adds only new tables: the original roster is never rewritten.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createCatalogue(db);
  }

  Future<void> _createCatalogue(Database db) async {
    await db.execute('''CREATE TABLE folders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      created_at TEXT NOT NULL
    )''');
    await db.execute('''CREATE TABLE cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      suit TEXT NOT NULL,
      notes TEXT NOT NULL DEFAULT '',
      image_ref TEXT,
      folder_id INTEGER NOT NULL,
      FOREIGN KEY(folder_id) REFERENCES folders(id) ON DELETE CASCADE
    )''');
    await db.execute('CREATE INDEX idx_cards_folder_id ON cards(folder_id)');
  }

  Future<List<FolderWithCount>> getFoldersWithCounts() async {
    final rows = await _db.rawQuery(
      '''SELECT folders.*, COUNT(cards.id) AS card_count
      FROM folders LEFT JOIN cards ON cards.folder_id = folders.id
      GROUP BY folders.id ORDER BY folders.id''',
    );
    return rows
        .map(
          (row) => FolderWithCount(
            folder: Folder.fromMap(row),
            count: row['card_count'] as int,
          ),
        )
        .toList();
  }

  Future<List<Card>> getCards(int folderId) async {
    final rows = await _db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'id ASC',
    );
    return rows.map(Card.fromMap).toList();
  }

  Future<int> insertFolder(Folder folder) async {
    if (folder.name.trim().isEmpty) {
      throw ArgumentError('Folder name is required.');
    }
    return _db.insert('folders', {
      ...folder.toMap()..remove('id'),
      'name': folder.name.trim(),
    });
  }

  Future<int> deleteFolder(int id) =>
      _db.delete('folders', where: 'id = ?', whereArgs: [id]);

  Map<String, Object?> _cardValues(Card card) {
    if (validateTitle(card.title) != null || !cardSuits.contains(card.suit)) {
      throw ArgumentError('A title and supported suit are required.');
    }
    return {...card.toMap()..remove('id'), 'title': card.title.trim()};
  }

  Future<int> insertCard(Card card) => _db.insert('cards', _cardValues(card));

  Future<int> updateCard(Card card) {
    if (card.id == null) throw ArgumentError('Card ID is required.');
    return _db.update(
      'cards',
      _cardValues(card),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) =>
      _db.delete('cards', where: 'id = ?', whereArgs: [id]);

  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(tableName, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(tableName, orderBy: '$columnId ASC');
  }

  Future<int> queryRowCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) FROM $tableName');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    final int id = row[columnId];

    return await _db.update(
      tableName,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
  }
}
