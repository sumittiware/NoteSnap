import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;

import 'package:ocr_editior/config.dart';
import 'package:ocr_editior/models/app_user.dart';
import 'package:ocr_editior/models/notes.dart';

class NotesServices {
  Future<List<Notes>> fetchNotesFromDb() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final url = Uri.parse(
      '$DATABASE_API/notes.json',
    );
    final result = await http.get(url);

    final data = jsonDecode(result.body);

    List<Notes> formattedData = [];

    data.forEach(
      (k, v) => {formattedData.add(Notes.fromJson(k, v))},
    );

    formattedData.removeWhere((notes) => !notes.allowedUsers.contains(userId));

    return formattedData;
  }

  Future<void> saveChangesToFirebase(
    String noteId,
    List<Operation> data,
  ) async {
    final url = Uri.parse(
      '$DATABASE_API/notes/$noteId/data.json',
    );

    final quilldata = {};
    for (var i = 0; i < data.length; i++) {
      quilldata[i.toString()] = data[i].toJson();
    }

    try {
      await http.put(
        url,
        body: jsonEncode(quilldata),
      );
    } catch (_) {
      throw Exception();
    }
  }

  Future<void> updateAllowedUser(String docId, List<AppUser> users) async {
    final url =
        Uri.parse('${DATABASE_API}notes/$docId/info/allowed_users.json');
    final currentUser = FirebaseAuth.instance.currentUser!.uid;

    final response = await http.get(url);

    final data = jsonDecode(response.body);
    print("Data : $data");

    data.addAll(users.map((e) => e.uid));

    for (var user in users) {
      if (user.uid != currentUser) {
        data.add(user.uid);
      }
    }

    try {
      await http.put(url, body: jsonEncode(data));
    } catch (_) {
      print("Error occured : _");
    }

    return;
  }

  Future<void> updateNoteName(String docId, String name) async {
    final url = Uri.parse('${DATABASE_API}notes/$docId/info.json');

    final data = {
      'name': name,
    };

    try {
      await http.put(url, body: jsonEncode(data));
    } catch (_) {
      print("Error occured : _");
    }

    return;
  }
}
