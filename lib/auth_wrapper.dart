import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

        if (!snapshot.hasData) return const LoginScreen();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('admins').doc(snapshot.data!.uid).get(),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // User admins collection එකේ ඉන්නවා නම් AdminDashboard පෙන්වයි
            if (adminSnap.hasData && adminSnap.data!.exists) {
              return const AdminDashboard();
            } else {
              // නැතිනම් DriverDashboard පෙන්වයි
              return const DriverDashboard();
            }
          },
        );
      },
    );
  }
}