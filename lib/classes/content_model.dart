abstract class ContentModel {
  String get id;
  DateTime get createdAt;
  DateTime get updatedAt;
  Map<String, dynamic> toMap();

  factory ContentModel.fromContentful(Map<String, dynamic> entry) {
    throw UnimplementedError(
        'fromContentful must be implemented in subclasses');
  }
}
