import 'package:firebase_auth/firebase_auth.dart';
import 'package:ocr_editior/models/notes.dart';
import 'package:ocr_editior/pages/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:ocr_editior/pages/sign_in_screen.dart';
import 'package:ocr_editior/services/notes_services.dart';
import 'package:ocr_editior/widgets/confirm_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Notes> _items = [];
  late User appUser;
  @override
  void initState() {
    super.initState();
    loadNotes();
    appUser = FirebaseAuth.instance.currentUser!;
  }

  Future<void> loadNotes() async {
    final data = await NotesServices().fetchNotesFromDb();
    setState(() {
      _items = data;
      _items.sort((a, b) {
        return a.createdAt!.isAfter(b.createdAt!) ? -1 : 1;
      });
    });
  }

  void _showSignOutDailog() {
    showDialog(
      context: context,
      builder: (_) {
        return ConfirmDialog(
          title: 'Are you sure ?',
          body: 'Do you want to log-out',
          onSuccess: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => SignInScreen()),
                (Route<dynamic> route) => false);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff6A3EA1),
        elevation: 0,
        centerTitle: false,
        title: Text(
          "NoteSnap",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'pacifico',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showSignOutDailog,
            icon: Icon(Icons.logout_rounded),
          )
        ],
      ),
      body: FutureBuilder(
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  color: Color(0xff6A3EA1),
                ),
                child: Text(
                  "Welcome!, ${appUser.email} you can access all your notes here",
                  style: TextStyle(
                    fontFamily: 'nunito',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView(
                    children: List.generate(
                      _items.length,
                      (index) => ListTile(
                        tileColor: (index % 2 == 0)
                            ? Colors.transparent
                            : Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) {
                            return EditorScreen(
                              note: _items[index],
                              index: index,
                            );
                          }));
                        },
                        title: Text(
                          (_items[index].title != null)
                              ? _items[index].title!
                              : 'Notes ${index + 1}',
                        ),
                        subtitle: Text('id : ${_items[index].id}'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
