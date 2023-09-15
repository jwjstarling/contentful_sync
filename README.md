
<!--

This README describes the package. If you publish this package to pub.dev,

this README's contents appear on the landing page for your package.

  

For information about how to write a good package README, see the guide for

[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

  

For general information about developing packages, see the Dart guide for

[creating packages](https://dart.dev/guides/libraries/create-library-packages)

and the Flutter guide for

[developing packages and plugins](https://flutter.dev/developing-packages).

-->

  

## Introduction

  

# Contentful Sync

Contentful Sync is a Flutter package designed to facilitate the seamless integration of Contentful with your Flutter applications. Leveraging the power of Contentful's Content Infrastructure, this package allows you to fetch, cache, and display content in a structured manner, providing a robust solution for content management in your Flutter projects.

  

## Features

  

TODO: List what your package can do. Maybe include images, gifs, or videos.

  

## Getting Started

  

### Installation

To add Contentful Sync to your Flutter project, add the following line to your `pubspec.yaml` file:
```yaml

dependencies:
contentful_sync: ^0.1.0

```


## Initial Setup


### Usage

Contentful Sync provides a set of classes and methods that allow you to interact with your Contentful space and fetch content in a structured manner. Here, we outline the basic usage of the package with a simple example.

Before you start using the package, ensure that you have set up your Contentful space and have the necessary credentials including the Space ID and Access Token.

Initialize the Contentful Sync in your Flutter project as follows:

### Step 1: Add Dependencies

First, add the necessary dependencies to your `pubspec.yaml` file. This includes the Dart package for Contentful syncing (let's assume it is named `contentful_sync`), as well as any other necessary packages like `sqflite` for local storage.

```yaml

`dependencies:
  flutter:
    sdk: flutter
  contentful_sync: ^1.0.0
  sqflite: ^2.0.0+3
  path_provider: ^2.0.2` 
  ```

### Step 2: Define Content Models

In your app, define classes that implement the `ContentModel` interface for each of your Contentful content types. These classes will specify how fields in Contentful map to properties in your app.

Example for a Blog Post content model:
```dart
dartCopy code

`import 'package:contentful_sync/contentful_sync.dart';

class BlogPost implements ContentModel {
  final String id;
  final String title;
  final String body;

  BlogPost(this.id, this.title, this.body);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
    };
  }

  static BlogPost fromContentful(Map<String, dynamic> entry) {
    final fields = entry['fields'];
    return BlogPost(
      entry['sys']['id'],
      fields['title'],
      fields['body'],
    );
  }
}` 
```
### Step 3: Initialize the Sync Manager

Create an instance of the `SynchronizationManager` class from the package, and register your content model definitions with it.

```dart

`import 'package:contentful_sync/contentful_sync.dart';

void main() {
  final contentfulClient = ContentfulClient('spaceId', 'accessToken');
  final localStore = LocalStore();

  final syncManager = SynchronizationManager(contentfulClient, localStore);

  // Register the content model definitions
  syncManager.registerContentModel('blogPost', BlogPost.fromContentful);
  
  // ... other setup code
}` 
```

### Step 4: Open the Local Database

Before you can start syncing data, you need to open the local SQLite database. This is typically done at app startup.

```dart

`void main() async {
  // ... other setup code
  
  await localStore.open();
  
  // ... other setup code
}` 
```

### Step 5: Start the Initial Sync

Trigger the initial sync to fetch the latest content model from Contentful and save it to the local SQLite database.

```dart

`void main() async {
  // ... other setup code
  
  await syncManager.initialSync();
  
  // ... other setup code
}` 
```

### Step 6: Perform Subsequent Syncs

To keep the local data up-to-date with Contentful, you can perform subsequent syncs, which will fetch only the updated content based on the `nextSyncUrl`.

```dart

`void someFunction() async {
  // ... other code
  
  await syncManager.sync();
  
  // ... other code
}` 
```

### Step 7: Query the Local Database

Use the `LocalStore` class to query the local SQLite database and retrieve the synced data when you need it in your app.

```dart

`void someFunction() async {
  // ... other code
  
  List<Map<String, dynamic>> blogPosts = await localStore.fetch('blogPost');
  
  // ... other code
}` 
```

### Summary:

1.  **Add Dependencies:** Add the necessary packages to your `pubspec.yaml` file.
2.  **Define Content Models:** Create classes in your app that implement the `ContentModel` interface for each Contentful content type.
3.  **Initialize the Sync Manager:** Create an instance of the `SynchronizationManager` class and register your content model definitions with it.
4.  **Open the Local Database:** Open the local SQLite database at app startup.
5.  **Start the Initial Sync:** Trigger the initial sync to fetch the latest content model from Contentful and save it to the local SQLite database.
6.  **Perform Subsequent Syncs:** Regularly sync with Contentful to keep the local data up-to-date.
7.  **Query the Local Database:** Use the `LocalStore` class to query the local SQLite database and retrieve the synced data when needed.

With these steps, the Flutter app will be set up to sync data from Contentful, define the content models, and interact with the local SQLite database

 

### Fetching Content

To fetch content from your Contentful space, you can use the `ContentfulClient` method as above.

When this is initialized, the method will check to see if a `nextSyncUrl` value already exists within shared preferences - this value is a URL which is the sync url used for subsequent updates.

Once the client is set up, the following line

```dart
await syncManager.initialSync();
```
Performs the first sync of content from Contentful.

Firstly, it checks to see if a local JSON file already exists - if so then the `_seedFromJsonFile()` function is run to pull in a static content file rather than calling the remote endpoint.

If no local file is found, then the content model is fetched from the remote server via `final  contentModel  =  await  contentfulClient.fetchContentModel();` 

The function...

```dart
Future<Map<String, dynamic>> fetchContentModel() async {
final  url  =  nextSyncUrl  ??
'https://cdn.contentful.com/spaces/$spaceId/environments/master/sync?initial=true&access_token=$accessToken';

logger.i("Checking URL: $url");

final  response  =  await  http.get(Uri.parse(url));
	if (response.statusCode  ==  200) {
		final  data  =  json.decode(response.body);
		nextSyncUrl  =  data['nextSyncUrl'];
		_storeNextSyncUrl(nextSyncUrl!); // Store the nextSyncUrl for future use
		return  data;
	} else {
		throw  Exception('Failed to load content model');
	}
}

```
...should successfully return the data, but also save the `nextSyncUrl` into shared preferences for next time

The returned content is then save to a local database via `await  _saveToLocalStore(contentModel)`

### Sync Characteristics

When we call the syncAPI, it will either pull in the full detail of content (the first time) or it will return a subset of the latest changed content. This could include and `Entry` (ie content) an `Asset` (a binary file such as an image) or a `DeletedEntry`  which represents an item to be deleted from the local database.

```dart

await  localStore.queryByField('TABLE', 'COLUMN', 'COLUMN_VALUE');

```

This method returns a ContentModel object, which you can then use to access the individual fields of the content.

  

### Displaying Content

  

Once you have fetched the content, you can display it in your Flutter app using standard Flutter widgets. For example, to display a text field, you can use the Text widget as follows:

  
  

### 4. Advanced Usage

  

```markdown

## Advanced Usage

  

As your project grows, you might find yourself needing to implement more advanced features. Here we discuss some advanced use cases and best practices for using the Contentful Sync package.

  

### Caching Content

  

Contentful Sync allows you to cache content locally, reducing the number of network requests and improving the performance of your app. To enable caching, set the `enableCaching` parameter to `true` when initializing the Contentful Sync:

  

```dart

ContentfulSync.initialize(

spaceId: 'YOUR_SPACE_ID',

accessToken: 'YOUR_ACCESS_TOKEN',

enableCaching: true,

);

  
  

## Additional information

  

TODO: Tell users more about the package: where to find more information, how to

contribute to the package, how to file issues, what response they can expect

from the package authors, and more.