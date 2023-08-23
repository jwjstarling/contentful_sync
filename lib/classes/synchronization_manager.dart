import 'local_store.dart';
import 'content_model.dart';
import 'contentful_client.dart';

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
    final contentModel = await contentfulClient.fetchContentModel();
    await _saveToLocalStore(contentModel);
  }

  Future<void> sync() async {
    final updatedContent = await contentfulClient.sync();
    await _saveToLocalStore(updatedContent);
  }

  Future<void> _saveToLocalStore(Map<String, dynamic> data) async {
    for (var entry in data['entries']) {
      final contentType = entry['sys']['contentType']['sys']['id'];
      final factory = contentModelFactories[contentType];
      if (factory != null) {
        final model = factory(entry);
        await localStore.save(contentType, model);
      }
    }
  }
}
