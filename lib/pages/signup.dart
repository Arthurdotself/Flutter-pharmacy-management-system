import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tugas1_login/pages/login.dart';

import '../backend/functions.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> with SingleTickerProviderStateMixin {
  late String user;
  late String email;
  late String password;
  late String password0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title:  Text(getTranslations()['sign_up_screen']!),
        ),
        body: SingleChildScrollView( // Wrap with SingleChildScrollView
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildSignupForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
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
              user = value;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(90.0),
              ),
              labelText: getTranslations()['name']!,
            ),
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
              labelText: getTranslations()['create_password']!,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: TextField(
            onChanged: (value) {
              password0 = value;
            },
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(90.0),
              ),
              labelText: getTranslations()['re_enter_password']!,
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
            child:  Text(getTranslations()['sign_up']!),
            onPressed: () async {
              if (password == password0 &&
                  email.isNotEmpty &&
                  password.isNotEmpty &&
                  user.isNotEmpty) {
                try {
                  // Create user in Firebase Authentication
                  var newUser = await _auth.createUserWithEmailAndPassword(
                      email: email, password: password);

                  // Create a new document in Firestore with the email as document ID
                  await _firestore.collection('users').doc(email).set({
                    'name': user,
                    'email': email,
                    'pharmacyId': ''
                    // Add more fields as needed
                  });
                  _showAccountCreatedDialog();

                  print('User signed up and document created in Firestore.');
                } catch (error) {
                  print('Error signing up: $error');
                }
              } else {
                // Handle validation errors
              }
            },
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          },
          child: Text(
            getTranslations()['log_in']!,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
  void _showAccountCreatedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Account Created"),
          content: Text("Your account has been created successfully."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                //Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
            ),
          ],
        );
      },
    );
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
