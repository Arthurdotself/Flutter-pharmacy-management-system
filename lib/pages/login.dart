import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:tugas1_login/pages/reset_password.dart';
import 'package:tugas1_login/pages/signup.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tugas1_login/pages/dashboard.dart';
import '../backend/functions.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  late String email;
  late String password;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  User? _user;

  @override
  void initState() {
    super.initState();
    setUserEmail(context);
    getTranslations();
    _auth.authStateChanges().listen((event) {
      setState(() {
        _user = event;
      });
    });
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {setUserEmail(context);
    return MaterialApp(
      title: 'PMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title:  Text(getTranslations()['login_screen']!),
        ),
        body: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _loginForm(),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() { setUserEmail(context);
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 50),
            child: Image.asset(
              'assets/pharmassist11.png',
              width: 100,
              height: 100,
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
                labelText: getTranslations()['email']!,
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
                labelText: getTranslations()['password']!,
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
              child:  Text(getTranslations()['log_in']!),
              onPressed: () async {
                try {
                  var user = await _auth.signInWithEmailAndPassword(
                      email: email, password: password);
                  // Fetch pharmacyId from user document
                  final userDataSnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(email)
                      .get();
                  final pharmacyId = userDataSnapshot['pharmacyId'];
                  UserProvider userProvider = Provider.of<UserProvider>(
                      context, listen: false);
                  userProvider.setUserId(email);
                  userProvider.setPharmacyId(pharmacyId);
                  // Pass user email to Dashboard widget
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardPage(),
                    ),
                  );
                } catch (Error) {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.error,
                    animType: AnimType.rightSlide,
                    title: getTranslations()['error']!,
                    desc: getTranslations()['user_not_found']!,
                  ).show();
                }
              },
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Reset_Password()),
              );
            },
            child: Text(
              getTranslations()['forgot_password']!,
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
              getTranslations()['sign_up']!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(
            height: 50,
            child: SignInButton(
              Buttons.google,
              text: getTranslations()['sign_in_with_google']!,
              onPressed: _handleGoogleSignIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userInfo() {
    return const SizedBox();
  }

  void _handleGoogleSignIn() {
    try {
      GoogleAuthProvider _googleAuthProvider = GoogleAuthProvider();
      _auth.signInWithProvider(_googleAuthProvider).then(
            (UserCredential userCredential) async {
          // Handle successful sign-in
          User? user = userCredential.user;
          if (user != null) {
            // Retrieve the user's email
            String? email = user.email;
            final userDataSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(email)
                .get();
            final pharmacyId = userDataSnapshot['pharmacyId'];
            UserProvider userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            userProvider.setUserId(email!);
            userProvider.setPharmacyId(pharmacyId);
            // Pass user email to Dashboard widget
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(),
              ),
            );
            if (email != null) {
              // Do something with the email
              print('User ${user.displayName} signed in with email: $email');
            } else {
              // Email is null
              print('User signed in successfully, but email is null.');
            }
          } else {
            // Handle sign-in failure
            print('Sign-in failed. User is null.');
          }
        },
      ).catchError((error) {
        // Handle sign-in errors
        print('Sign-in error: $error');
      });
    } catch (error) {
      // Handle other errors that might occur
      print('Error: $error');
    }
  }
}
