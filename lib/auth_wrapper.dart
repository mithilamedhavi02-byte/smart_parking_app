import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_appauth/flutter_appauth.dart'; // AppAuth භාවිතය
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'driver_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. මුලින්ම Firebase Auth එකේ තත්වය බලන්න
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF020617),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
          );
        }

        // 2. පරිශීලකයා ලොග් වී නැතිනම් LoginScreen එකට යවන්න
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 3. ලොග් වී ඇතිනම්, Firestore හරහා Role එක (Admin/Driver) පරීක්ෂා කරන්න
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users') // 'admins' හෝ 'drivers' වෙනුවට පොදු 'users' collection එකක් පාවිච්චි කිරීම වඩාත් සුදුසුයි
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF020617),
                body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
              );
            }

            if (roleSnap.hasData && roleSnap.data!.exists) {
              var userData = roleSnap.data!.data() as Map<String, dynamic>;
              String role = userData['role'] ?? 'driver'; // Default role එක driver ලෙස

              if (role == 'admin') {
                return const AdminDashboard();
              }
            }

            // කිසිවක් නැතිනම් Driver Dashboard එක පෙන්වන්න
            return const DriverDashboard();
          },
        );
      },
    );
  }
}