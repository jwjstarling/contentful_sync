import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContentfulClient {
  final String spaceId;
  final String accessToken;
  String? nextSyncUrl; // Make it nullable

  ContentfulClient(this.spaceId, this.accessToken) {
    _loadNextSyncUrl();
  }

  Future<void> _loadNextSyncUrl() async {
    final prefs = await SharedPreferences.getInstance();
    nextSyncUrl = prefs.getString('nextSyncUrl');
  }

  Future<void> _storeNextSyncUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('nextSyncUrl', "$url&access_token=$accessToken");
  }

  // Fetch the latest content model from Contentful
  Future<Map<String, dynamic>> fetchContentModel() async {
    final url = nextSyncUrl ??
        'https://cdn.contentful.com/spaces/$spaceId/environments/master/sync?initial=true&access_token=$accessToken';

    logger.i("Checking URL: $url");
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      nextSyncUrl = data['nextSyncUrl'];
      _storeNextSyncUrl(nextSyncUrl!); // Store the nextSyncUrl for future use
      return data;
    } else {
      throw Exception('Failed to load content model');
    }
  }

  // Fetch only the updated content based on the nextSyncUrl
  Future<Map<String, dynamic>> sync() async {
    if (nextSyncUrl == null) {
      await fetchContentModel(); // Perform initial sync if nextSyncUrl is null
    }

    final response = await http
        .get(Uri.parse(nextSyncUrl!)); // Use ! to assert that it's non-null

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      nextSyncUrl = data['nextSyncUrl'];
      return data;
    } else {
      throw Exception('Failed to sync content');
    }
  }
}
