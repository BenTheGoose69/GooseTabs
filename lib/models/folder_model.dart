import 'dart:convert';

class TabFolder {
  final String id;
  String name;
  DateTime createdAt;

  TabFolder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TabFolder.fromJson(Map<String, dynamic> json) => TabFolder(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory TabFolder.fromJsonString(String jsonString) =>
      TabFolder.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
