import 'package:flutter/material.dart';
import 'package:tugas1_login/pages/login.dart';
import 'package:tugas1_login/pages/signup.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:tugas1_login/pages/home.dart';
import 'package:tugas1_login/pages/Reset_Password.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(

          primarySwatch: Colors.blue,
        ),
        //home: const MyHomePage());
        home: const Dashbord(userEmail: 'admin@pms.com',));
  }
}