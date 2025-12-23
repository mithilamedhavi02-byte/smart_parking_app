import 'package:flutter/material.dart';
import 'package:smart_parking_finder/screens/auth/role_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Parking Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const RoleSelectionScreen(), // මෙතන role selection screen set කරන්න
      debugShowCheckedModeBanner: false,
    );
  }
}
