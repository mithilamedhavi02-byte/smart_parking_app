import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Import correctly
import 'login_screen.dart';
import 'auth_wrapper.dart'; // මෙතනින් තමයි AuthWrapper එක එන්නේ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Park-Pro',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(), // auth_wrapper.dart එකේ තියෙන එක පාවිච්චි කරයි
    );
  }
}