abstract class ContentModel {
  String get id;
  String get localeCode;
  DateTime get createdAt;
  DateTime get updatedAt;
  Map<String, dynamic> toMap();
  static fromContentful(Map<String, dynamic> entry);
}