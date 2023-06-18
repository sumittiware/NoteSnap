import 'package:flutter_quill/flutter_quill.dart';

class Notes {
  String id;
  String? title;
  DateTime? createdAt;
  Document data;
  List<dynamic> allowedUsers;

  Notes({
    required this.id,
    required this.data,
    required this.allowedUsers,
    this.title,
    this.createdAt,
  });

  factory Notes.fromJson(String id, Map<String, dynamic> json) {
    print("Recived data : $id");

    return Notes(
      id: id,
      data: _documentFromJson(json['data']),
      allowedUsers: json['info']['allowed_users'] ?? [],
      title: json['info']['title'],
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
          json['info']['created_at'] * 1000),
    );
  }

  static Document _documentFromJson(dynamic jsonData) {
    List<Map<String, dynamic>> data;
    if (jsonData is List) {
      data = List<Map<String, dynamic>>.from(jsonData);
    } else if (jsonData is Map) {
      data = jsonData.values.cast<Map<String, dynamic>>().toList();
    } else {
      throw const FormatException('Invalid JSON data');
    }

    final insertList = [];

    data.forEach((value) {
      final insertValue = value['insert'];
      final insertMap = {'insert': insertValue};

      if (value['attributes'] != null) {
        insertMap['attributes'] = value['attributes'];
      }

      insertList.add(insertMap);
    });

    return Document.fromJson(insertList);
  }
}
