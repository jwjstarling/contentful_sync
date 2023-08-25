import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'content_model.dart';
import '../utils/logger.dart';

class LocalStore {
  late Database? _db;

  // Open the database
  Future<void> open() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/contentful.db';
      _db = await openDatabase(path, version: 1);

      await _ensureInventoryTableExists(); // Creates an inventory table which contains ID and ContentType so we can use this to work out which items to delete from correct table if necessary
    } catch (e) {
      logger.e("Error opening database: $e");
      // Handle the error or rethrow
    }
  }

  Future<void> save(String table, ContentModel model) async {
    if (_db == null) {
      throw Exception("Database not initialized!");
    }
    await _ensureTableExists(table, model);
    await _db!.insert(table, model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    logger.i('Item with ID ${model.id} added/updated in $table');
  }

  Future<void> _ensureInventoryTableExists() async {
    final tables = await _db!.query('sqlite_master',
        where: 'type = ? AND name = ?', whereArgs: ['table', 'inventory']);

    if (tables.isEmpty) {
      // Create the inventory table
      await _db!.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        contentType TEXT
      )
    ''');
    }
  }

  Future<void> _ensureTableExists(String table, ContentModel model) async {
    // Check if the table exists
    var result = await _db!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table]);
    var tableExists = result.isNotEmpty;

    // If the table does not exist, create it
    if (!tableExists) {
      var columns = model.toMap().keys.map((key) {
        if (key == 'id') {
          return '$key TEXT PRIMARY KEY';
        } else {
          return '$key TEXT';
        }
      }).join(', ');
      await _db!.execute('CREATE TABLE $table ($columns)');
      logger.i('New table created: $table');
    }
  }

  Future<List<Map<String, dynamic>>> fetch(String table) async {
    if (_db == null) {
      throw Exception("Database not initialized!");
    }
    return await _db!.query(table);
  }

  Future<void> delete(String table, String id) async {
    await _db!.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEntryById(String id, String table) async {
    // Assuming you have a method to delete an entry by its ID
    await _db!.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryByField(
      String table, String field, String value) async {
    return await _db!.query(table, where: '$field = ?', whereArgs: [value]);
  }

  Future<void> addToInventory(String id, String contentType) async {
    await _db!.insert('inventory', {'id': id, 'contentType': contentType},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFromInventory(String id) async {
    await _db!.delete('inventory', where: 'id = ?', whereArgs: [id]);
    logger.w(
        'Item with ID $id deleted from Table:Inventory'); // Warning level for deletions
  }

  Future<void> logInventory() async {
    final inventoryItems = await _db!.query('inventory');
    logger.i('Total items in inventory: ${inventoryItems.length}');
  }

  Future<List<Map>> queryInventory(String id) async {
    return await _db!.query('inventory', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> printAllTables() async {
    var tables = await _db!
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    logger.i('Existing tables: ${tables.map((t) => t['name']).join(', ')}');
  }
}
