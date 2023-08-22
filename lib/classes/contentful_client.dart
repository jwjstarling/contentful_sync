import 'dart:convert';
import 'package:http/http.dart' as http;

class ContentfulClient {
  final String spaceId;
  final String accessToken;
  String nextSyncUrl;

  ContentfulClient(this.spaceId, this.accessToken);

  // Fetch the latest content model from Contentful
  Future<Map<String, dynamic>> fetchContentModel() async {
    final url = 'https://cdn.contentful.com/spaces/$spaceId/environments/master/sync?initial=true&access_token=$accessToken';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      nextSyncUrl = data['nextSyncUrl'];
      return data;
    } else {
      throw Exception('Failed to load content model');
    }
  }

  // Fetch only the updated content based on the nextSyncUrl
  Future<Map<String, dynamic>> sync() async {
    if (nextSyncUrl == null) {
      throw Exception('Initial sync has not been performed');
    }
    
    final response = await http.get(Uri.parse(nextSyncUrl));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      nextSyncUrl = data['nextSyncUrl'];
      return data;
    } else {
      throw Exception('Failed to sync content');
    }
  }
}
