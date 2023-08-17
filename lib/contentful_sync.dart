/// Support for doing something awesome.
///
/// More dartdocs go here.
library contentful_sync;

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ContentfulSync {
  final String spaceId;
  final String accessToken;
  late SharedPreferences _prefs;

  ContentfulSync({required this.spaceId, required this.accessToken});

  Future<void> sync() async {
    // Initialize _prefs before proceeding with the sync
    _prefs = await SharedPreferences.getInstance();

    print("Get content");
    String initialSyncUrl =
        'https://cdn.contentful.com/spaces/$spaceId/sync?access_token=$accessToken&initial=true';
    String syncUrl = _prefs.getString('nextSyncUrl') ?? initialSyncUrl;

    final response = await http.get(Uri.parse(syncUrl));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON
      print("Got something");
      print(response.body);

      Map<String, dynamic> responseJSON = jsonDecode(response.body);

      if (syncUrl != initialSyncUrl) {
        print("Syncing content");
        // Get the current content
        List<dynamic> content = getContent();

        // Iterate over the items in the response and update the content accordingly
        for (var item in responseJSON['items']) {
          String type = item['sys']['type'];
          String id = item['sys']['id'];

          if (type == 'DeletedEntry') {
            // Remove the deleted entry from the content
            print("Deleted entry: $id");
            content.removeWhere((entry) => entry['sys']['id'] == id);
          } else {
            // Find the existing entry with the same ID
            int index = content.indexWhere((entry) => entry['sys']['id'] == id);

            if (index != -1) {
              // Replace the existing entry with the updated entry
              print("Amended entry: $id");
              content[index] = item;
            } else {
              // Add the new entry to the content
              print("New entry: $id");
              content.add(item);
            }
          }
        }

        // Store the content locally
        _prefs.setString('content', jsonEncode(content));
      } else {
        // This is the initial sync, so just store the content locally
        _prefs.setString('content', jsonEncode(responseJSON['items']));
      }

      // Store the nextSyncUrl for the next sync.
      String nextSyncUrl =
          '${responseJSON['nextSyncUrl']}&access_token=$accessToken';
      _prefs.setString('nextSyncUrl', nextSyncUrl);

      print(nextSyncUrl);
    } else {
      // If the server returns an error response, throw an exception.
      throw Exception('Failed to load data');
    }
  }

  List<dynamic> getContent() {
    String? contentString = _prefs.getString('content');
    return contentString != null ? jsonDecode(contentString) : [];
  }
}

