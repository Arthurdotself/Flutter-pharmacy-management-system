import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tugas1_login/pages/home.dart';
import 'package:provider/provider.dart';
import 'package:tugas1_login/backend/user_provider.dart'; // Import your UserProvider class
import 'firebase_options.dart';
import 'package:tugas1_login/pages/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()), // Provide UserProvider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            String? userId = userProvider.userId;
            String? pharmacyId = userProvider.PharmacyId;
            if (userId != null && userId.isNotEmpty) {
              return Dashbord(userId: userId , PharmacyId: pharmacyId,);
            } else {
              return const Login();
            }
          },
        ),
      ),
    );
  }
}
