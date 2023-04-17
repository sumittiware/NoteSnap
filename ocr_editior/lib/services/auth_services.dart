import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:ocr_editior/config.dart';

class AuthServices {
  Future<void> handleGoogleAuth() async {
    UserCredential credentials;

    if (kIsWeb) {
      credentials =
          await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } else {
      final GoogleSignInAccount? googleSignInAccount =
          await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      credentials = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
    }

    final url = Uri.parse('${DATABASE_API}users/${credentials.user!.uid}.json');
    http.put(
      url,
      body: jsonEncode({
        'uid': credentials.user!.uid,
        'email': credentials.user!.email,
      }),
    );
  }
}
