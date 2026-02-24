import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// ඔයාගේ Screen files වල නම් මේවාට සමානදැයි නැවත බලන්න
import 'login_screen.dart';
import 'driver_dashboard.dart';
import 'admin_dashboard.dart';

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
      title: 'Smart Parking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Firebase Auth දත්ත එනතුරු Loading පෙන්වීම
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // යූසර් ලොග් වෙලා ඉන්නවා නම් (User Session exists)
        if (authSnapshot.hasData && authSnapshot.data != null) {
          final String uid = authSnapshot.data!.uid;

          // 1. මුලින්ම 'drivers' collection එක පරීක්ෂා කිරීම
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('drivers').doc(uid).get(),
            builder: (context, driverSnapshot) {
              if (driverSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // 'drivers' ඇතුළේ මෙම UID එක තිබේ නම්
              if (driverSnapshot.hasData && driverSnapshot.data!.exists) {
                return const DriverDashboard();
              }

              // 2. එතන නැත්නම් 'admins' collection එක පරීක්ෂා කිරීම
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('admins').doc(uid).get(),
                builder: (context, adminSnapshot) {
                  if (adminSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }

                  // 'admins' ඇතුළේ මෙම UID එක තිබේ නම්
                  if (adminSnapshot.hasData && adminSnapshot.data!.exists) {
                    return const AdminDashboard();
                  }

                  // කිසිම තැනක නැත්නම් Login එකට (Security check)
                  return const LoginScreen();
                },
              );
            },
          );
        }

        // ලොග් වෙලා නැත්නම් කෙලින්ම Login පේජ් එකට
        return const LoginScreen();
      },
    );
  }
}