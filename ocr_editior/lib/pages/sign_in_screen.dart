import 'package:flutter/material.dart';
import 'package:ocr_editior/pages/home_screen.dart';
import 'package:ocr_editior/services/auth_services.dart';
import 'package:ocr_editior/widgets/responsive_widget.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
    });
    try {
      await AuthServices().handleGoogleAuth();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) {
        return HomeScreen();
      }));
    } catch (_) {
      print("Error : SIng in error $_");
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff6A3EA1),
      body: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 32,
        ),
        width: double.infinity,
        child: ResponsiveWidget(
          largeScreen: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Image.asset(
                    'assets/images/home_logo.png',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "NoteSnap",
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'pacifico'),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      "Snap, save, and soar",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'nunito',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    GestureDetector(
                      onTap: _signInWithGoogle,
                      child: Container(
                        width: 480,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: Colors.white,
                        ),
                        child: (_loading)
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff6A3EA1),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/google.png',
                                    height: 24,
                                    width: 24,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    "Login with Google",
                                    style: TextStyle(
                                      fontFamily: 'nunito',
                                      fontSize: 18,
                                    ),
                                  )
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
              ),
            ],
          ),
          smallScreen: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Image.asset('assets/images/home_logo.png'),
              Text(
                "NoteSnap",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'pacifico'),
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                "Snap, save, and soar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'nunito',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 16,
              ),
              GestureDetector(
                onTap: _signInWithGoogle,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Colors.white,
                  ),
                  child: (_loading)
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xff6A3EA1),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google.png',
                              height: 24,
                              width: 24,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              "Login with Google",
                              style: TextStyle(
                                fontFamily: 'nunito',
                                fontSize: 18,
                              ),
                            )
                          ],
                        ),
                ),
              ),
              SizedBox(
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
