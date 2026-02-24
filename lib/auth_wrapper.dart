import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        // ලෝඩ් වන අතරතුර පෙන්වන UI එක
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 1. යූසර් ලොග් වෙලා නැත්නම් Login එකට යවනවා
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // 2. යූසර් ලොග් වෙලා ඉන්නවා නම් Role එක බලන්න
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              // Firestore එකේ 'role' කියන field එක හරියටම තියෙන්න ඕනේ
              String role = userSnapshot.data!.get('role') ?? 'Driver';

              if (role == 'Admin') {
                return const AdminDashboard();
              } else {
                return const DriverDashboard();
              }
            }

            // දත්ත වල ගැටලුවක් තිබේ නම් ආරක්ෂිතව Login එකට
            return const LoginScreen();
          },
        );
      },
    );
  }
}