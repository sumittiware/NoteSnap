import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:ocr_editior/config.dart';
import 'package:ocr_editior/models/app_user.dart';
import 'package:ocr_editior/services/notes_services.dart';
import 'package:ocr_editior/widgets/scnackbar.dart';

class ShareNotesDialog extends StatefulWidget {
  final String docId;
  const ShareNotesDialog({
    Key? key,
    required this.docId,
  }) : super(key: key);

  @override
  State<ShareNotesDialog> createState() => _ShareNotesDialogState();
}

class _ShareNotesDialogState extends State<ShareNotesDialog> {
  final _emailController = TextEditingController();
  bool _sharing = false;

  List<AppUser> users = [];
  List<AppUser> displayUsers = [];

  Future<void> _fetchUsers() async {
    final url = Uri.parse('${DATABASE_API}users.json');
    final response = await http.get(url);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    data.values.forEach((user) {
      users.add(
        AppUser.fromJson(user),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void onValueChanged(String prefix) {
    setState(() {
      displayUsers.clear();
      users.forEach((user) {
        if (user.email.startsWith(prefix)) {
          displayUsers.add(user);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Share Notes",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('Share your notes with your friends!')
        ],
      ),
      content: SizedBox(
        height: 450,
        child: Column(
          children: [
            // email text field
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  width: 1,
                  color: Colors.grey,
                ),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: 'Add Email',
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onChanged: onValueChanged,
              ),
            ),
            // list of users based on email
            SizedBox(
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  children: displayUsers.map((user) {
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(user.email),
                      tileColor: (user.isSelected)
                          ? Colors.blue.shade100
                          : Colors.white,
                      onTap: () {
                        setState(() {
                          user.isSelected = !user.isSelected;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            // add button
            GestureDetector(
              onTap: () async {
                setState(() {
                  _sharing = true;
                });
                displayUsers.removeWhere((user) => !user.isSelected);
                await NotesServices().updateAllowedUser(
                  widget.docId,
                  displayUsers,
                );
                setState(() {
                  _sharing = false;
                });
                showSnackBar(
                  context,
                  "Notes Shared!",
                  isSuccess: true,
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Color(0xff6A3EA1)),
                child: (_sharing)
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Share",
                        style: TextStyle(
                          fontFamily: 'nunito',
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
