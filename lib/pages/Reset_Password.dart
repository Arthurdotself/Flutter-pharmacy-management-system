import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:tugas1_login/pages/login.dart';

import '../backend/functions.dart';

class Reset_Password extends StatefulWidget {
  const Reset_Password({Key? key}) : super(key: key);

  @override
  State<Reset_Password> createState() => _Reset_PasswordState();
}

class _Reset_PasswordState extends State<Reset_Password>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String email;
  late String msg = "";
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
          title:  Text(getTranslations()['password_reset']!),
        ),
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildResetPasswordForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildResetPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 50),
          child: Image.asset(
            'assets/pharmassist11.png',
            width: 100,
            height: 100,
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child:  Text(
          getTranslations()['enter_email_for_password_reset']!),
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
              labelText:  getTranslations()['email']!,
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
            child:  Text( getTranslations()['send_reset_password_email']!),
            onPressed: () async {
              try {
                if (email.isEmpty) {
                  msg = getTranslations()['enter_email']!;
                } else if (email.isNotEmpty) {
                  msg = getTranslations()['no_account_found']!;
                }
                var user =
                await _auth.sendPasswordResetEmail(email: email);
                // Show success message using AwesomeDialog
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.success,
                  animType: AnimType.bottomSlide,
                  title: getTranslations()['success']!,
                  desc:
                  getTranslations()['password_reset_email_sent']!,
                  btnOkOnPress: () {
                    // Navigate to another page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  },
                ).show();
              } catch (error) {
                // Show error message using AwesomeDialog
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.error,
                  animType: AnimType.rightSlide,
                  title: getTranslations()['error']!,
                  desc: msg,
                ).show();
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
