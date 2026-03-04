import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'driver_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 1. If not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 2. If logged in, check role from Firestore (admins or drivers collection)
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('admins').doc(snapshot.data!.uid).get(),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));

            if (adminSnap.hasData && adminSnap.data!.exists) {
              return const AdminDashboard();
            }

            // If not in admins, check drivers
            return const DriverDashboard();
          },
        );
      },
    );
  }
}