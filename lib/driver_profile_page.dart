import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // Glass effect එක සඳහා
import 'login_screen.dart';
// අමතක නොකර MyAppIcon එක import කරන්න
import 'my_app_icon.dart';

class DriverProfilePage extends StatelessWidget {
  const DriverProfilePage({super.key});

  // Logout Function
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("MY PROFILE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg2.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay
          Container(color: Colors.black.withValues(alpha:0.75)),

          // 3. Main Content
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }

                var data = snapshot.data?.data() as Map<String, dynamic>?;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  child: Column(
                    children: [
                      // Profile Header with Glass Effect
                      _buildProfileHeader(data?['name'] ?? "Driver Name"),

                      const SizedBox(height: 30),

                      // Info Section (Glass Card)
                      _buildGlassCard(
                        children: [
                          _buildInfoRow("Full Name", data?['name'] ?? "Not Set", Icons.person_rounded),
                          _buildInfoRow("Email", data?['email'] ?? user?.email ?? "Not Set", Icons.email_rounded),
                          _buildInfoRow("Phone", data?['phone'] ?? "Not Set", Icons.phone_android_rounded),
                          _buildInfoRow("Account Role", data?['role']?.toString().toUpperCase() ?? "DRIVER", Icons.verified_user_rounded),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Logout Button
                      _buildLogoutButton(context),

                      const SizedBox(height: 30),
                      const Text("v1.0.2 - ParkPro App", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildProfileHeader(String name) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent.withValues(alpha:0.5), width: 2),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withValues(alpha:0.1),
                  // MyAppIcon පාවිච්චි කළා Icons error එක එන්නේ නැති වෙන්න
                  child: const MyAppIcon(iconData: Icons.person, size: 55, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const MyAppIcon(iconData: Icons.check, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Text("Verified Driver Account", style: TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  Widget _buildGlassCard({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha:0.15)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          MyAppIcon(iconData: iconData, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const MyAppIcon(iconData: Icons.logout_rounded, size: 20, color: Colors.white),
        label: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withValues(alpha:0.8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Logout", style: TextStyle(color: Colors.white)),
          content: const Text("Are you sure you want to sign out?", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => _logout(context),
              child: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}