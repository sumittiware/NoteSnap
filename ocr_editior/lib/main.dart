import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ocr_editior/config.dart';
import 'package:ocr_editior/pages/sign_in_screen.dart';
import 'package:ocr_editior/widgets/share_dialog.dart';

import 'pages/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NoteSnap',
      theme: ThemeData(
        primaryColor: Color(0xff6A3EA1),
        fontFamily: 'nunito',
      ),
      home: FutureBuilder(
          future: Firebase.initializeApp(
            options: (kIsWeb)
                ? FirebaseOptions(
                    apiKey: API_KEY,
                    appId: APP_ID,
                    messagingSenderId: MESSEGING_SENDER_ID,
                    projectId: PROJECT_ID,
                    authDomain: AUTH_DOMAIN,
                  )
                : null,
          ),
          builder: (context, response) {
            if (response.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (FirebaseAuth.instance.currentUser == null) {
              return SignInScreen();
            }

            return HomeScreen();
          }),
    );
  }
}
