import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tugas1_login/pages/login.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  late String user;
  late String email;
  late String password;
  late String password0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          title: const Text('SignUp Screen'),
        ),
        body: Center(
          child: Column(
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
                    labelText: 'Username',
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
                    labelText: 'Create Password',
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
                    labelText: 'Re-Enter Password',
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
                  child: const Text('SignUp'),
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
                          'user': user,
                          'email': email,
                          // Add more fields as needed
                        });
                        // Create a subcollection named 'medicines' inside the user's document
                       // await _firestore.collection('users').doc(email).collection('medicines').add({
                        //  'brand': 'a',
                       //   'cost': 0,
                     //     'expire': '0',
                      //    'name': 'a',
                      //    'price': 0,
                          // Add more fields as needed
                    //    });
                    //     await _firestore.collection('users').doc(email).collection('sales').add({
                    //       'name': 'a',
                    //       'pharmacist': 0,
                    //       'price': '0',
                    //       'date': 'a',
                    //
                    //       // Add more fields as needed
                    //     });
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
                  'LogIn',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
