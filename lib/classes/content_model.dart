abstract class ContentModel {
  String get id;
  String get localeCode;
  DateTime get createdAt;
  DateTime get updatedAt;
  Map<String, dynamic> toMap();

  factory ContentModel.fromContentful(Map<String, dynamic> entry) {
    throw UnimplementedError(
        'fromContentful must be implemented in subclasses');
  }
}
