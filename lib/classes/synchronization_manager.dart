import 'local_store.dart';
import 'content_model.dart';
import 'contentful_client.dart';
import '../utils/logger.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SynchronizationManager {
  final ContentfulClient contentfulClient;
  final LocalStore localStore;
  final Map<String, ContentModel Function(Map<String, dynamic>)>
      contentModelFactories = {};

  SynchronizationManager(this.contentfulClient, this.localStore);

  void registerContentModel(
      String contentType, ContentModel Function(Map<String, dynamic>) factory) {
    contentModelFactories[contentType] = factory;
  }

  Future<void> initialSync() async {
    final directory = await getApplicationDocumentsDirectory();
    print(directory.path);

    logger.i("Checking for local JSON file at $directory");
    if (await _localFileExists()) {
      logger.i("Seeding data from local JSON file...");
      await _seedFromJsonFile();
    } else {
      logger.i("No local content available - fetching data from Contentful...");
      final contentModel = await contentfulClient.fetchContentModel();
      await _saveToLocalStore(contentModel);
    }
  }

  Future<void> sync() async {
    final updatedContent = await contentfulClient.sync();
    await _saveToLocalStore(updatedContent);
  }

  Future<bool> _localFileExists() async {
    final file = File(
        '${(await getApplicationDocumentsDirectory()).path}/seeded_content.json');
    return await file.exists();
  }

  Future<void> _saveToLocalStore(Map<String, dynamic> data) async {
    logger.i('Keys in data: ${data.keys}');

    for (var entry in data['items']) {
      final sysType = entry['sys']['type'];

      if (sysType == 'Entry' || sysType == 'Asset') {
        String? contentType;
        if (sysType == 'Entry') {
          contentType = entry['sys']['contentType']['sys']['id'];
        } else if (sysType == 'Asset') {
          contentType = 'Asset';
        }

        if (contentType != null) {
          final factory = contentModelFactories[contentType];
          if (factory != null) {
            final model = factory(entry);
            await localStore.save(contentType, model);
            await localStore.addToInventory(model.id, contentType);
          }
        }
      } else if (sysType == 'DeletedEntry') {
        final deletedId = entry['sys']['id'];
        final results = await localStore.queryInventory(deletedId);
        if (results.isNotEmpty) {
          final tableName = results.first['contentType'];
          await localStore.deleteEntryById(deletedId, tableName);
          await localStore.removeFromInventory(deletedId);
        }
      }
    }

    localStore.logInventory();
  }

  // Seed the local storage from a directory of JSON files
  Future<void> _seedFromJsonFile() async {
    final filePath =
        '${(await getApplicationDocumentsDirectory()).path}/seeded_content.json';
    final file = File(filePath);

    if (await file.exists()) {
      logger.i("Seeding data from local JSON file...");
      final content = await file.readAsString();
      final data = json.decode(content);
      await _saveToLocalStore(data);
    } else {
      logger.w("Local JSON file not found. Skipping seeding.");
    }
  }
}
