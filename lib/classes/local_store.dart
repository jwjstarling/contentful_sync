import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class LocalStore {
  Database _db;

  // Open the database
  Future<void> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/contentful.db';
    _db = await openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> save(String table, ContentModel model) async {
    await _ensureTableExists(table, model);
    await _db.insert(table, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _ensureTableExists(String table, ContentModel model) async {
    // Check if the table exists
    var result = await _db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?", [table]);
    var tableExists = result.isNotEmpty;

    // If the table does not exist, create it
    if (!tableExists) {
      var columns = model.toMap().keys.map((key) => '$key TEXT').join(', ');
      await _db.execute('CREATE TABLE $table (id TEXT PRIMARY KEY, localeCode TEXT, createdAt TEXT, updatedAt TEXT, $columns)');
    }
  }

  Future<List<Map<String, dynamic>>> fetch(String table) async {
    return await _db.query(table);
  }

  Future<void> delete(String table, String id) async {
    await _db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryByField(String table, String field, String value) async {
  return await _db.query(table, where: '$field = ?', whereArgs: [value]);
}

  // Seed the local storage from a directory of JSON files
  Future<void> seedFromJsonFiles(String directoryPath) async {
    final dir = Directory(directoryPath);
    final files = dir.listSync();

    for (var file in files) {
      final content = await File(file.path).readAsString();
      final data = json.decode(content);
      final table = file.uri.pathSegments.last.split('.').first;
      await save(table, data);
    }
  }
}
