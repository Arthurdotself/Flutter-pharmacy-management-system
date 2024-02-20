import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:tugas1_login/pages/reset_password.dart';
import 'package:tugas1_login/pages/signup.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:tugas1_login/pages/home.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late String email;
  late String password;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((event) {
      setState(() {
        _user = event;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Login Screen'),
        ),
       // body: _user != null ? _userInfo() : _loginForm(),
        body: _loginForm(),
      ),
    );
  }

  Widget _loginForm() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 70),
            child: const FlutterLogo(
              size: 40,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: TextField(
              onChanged: (value) {
                email = value;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(90.0),
                ),
                labelText: 'Email',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: TextField(
              onChanged: (value) {
                password = value;
              },
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(90.0),
                ),
                labelText: 'Password',
              ),
            ),
          ),
          Container(
              height: 80,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Log In'),
                onPressed: () async {
                  try {
                    var user = await _auth.signInWithEmailAndPassword(
                        email: email, password: password);

                    // Pass user email to Dashbord widget
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Dashbord(userEmail: email),
                      ),
                    );
                  } catch (Error) {
                    AwesomeDialog(
                        context: context,
                        dialogType: DialogType.error,
                        animType: AnimType.rightSlide,
                        title: 'Error',
                        desc: 'No user found for that email.')
                      .show();
                  }
                },
              )),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Reset_Password()),
              );
            },
            child: Text(
              'Forgot Password?',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Signup()),
              );
            },
            child: Text(
              'Sign Up',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(
            height: 50,
            child: SignInButton(
              Buttons.google,
              text: "Sign in with Google",
              onPressed: _handleGoogleSinIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userInfo() {
    return const SizedBox();
  }

  void _handleGoogleSinIn() {
    try {
      GoogleAuthProvider _GoogleAuthProvider = GoogleAuthProvider();
      _auth.signInWithProvider(_GoogleAuthProvider);
    } catch (error) {
      print(error);
    }
  }
}
