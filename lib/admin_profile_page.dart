import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'my_app_icon.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  final Color primaryBlue = const Color(0xFF0D47A1);

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
        title: const Text("ADMIN PROFILE",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Background UI
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/b4.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),

          // 2. Profile Content using StreamBuilder for Auto-Updates
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              // 'admins' collection එකෙන් current user ගේ දත්ත ලබා ගැනීම
              stream: FirebaseFirestore.instance
                  .collection('admins')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading profile", style: TextStyle(color: Colors.white)));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                Map<String, dynamic>? data = snapshot.data?.data() as Map<String, dynamic>?;

                // දත්ත auto-update වන පරිදි variables වලට ලබා ගැනීම
                String adminName = data?['name'] ?? "Admin";
                String adminEmail = data?['email'] ?? user?.email ?? "Not Set";
                String adminRole = (data?['role'] ?? "Admin").toString().toUpperCase();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                  child: Column(
                    children: [
                      _buildProfileHeader(adminName),
                      const SizedBox(height: 40),

                      // තොරතුරු පෙන්වන Glassy Cards
                      _buildGlassInfoCard("Full Name", adminName, Icons.person_outline_rounded),
                      _buildGlassInfoCard("Email Address", adminEmail, Icons.email_outlined),
                      _buildGlassInfoCard("User Role", adminRole, Icons.admin_panel_settings_outlined),

                      const SizedBox(height: 20),

                      // අමතර විකල්ප (Action Rows)
                      _buildSimpleActionRow(Icons.security, "Security Settings"),
                      _buildSimpleActionRow(Icons.help_outline, "Help & Support"),

                      const SizedBox(height: 40),

                      // Logout Button (දැන් මෙය නිවැරදිව පෙනෙනු ඇත)
                      _buildLogoutButton(context),

                      const SizedBox(height: 20),
                      const Text("App Version 1.0.0",
                          style: TextStyle(color: Colors.white24, fontSize: 12)),
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

  // --- UI Helper Widgets ---

  Widget _buildProfileHeader(String name) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: const CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white10,
                backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryBlue,
              child: const MyAppIcon(iconData: Icons.camera_alt_rounded, size: 18, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          name.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          ),
          child: const Text(
            "VERIFIED ADMIN",
            style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassInfoCard(String label, String value, IconData iconData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MyAppIcon(iconData: iconData, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleActionRow(IconData iconData, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          MyAppIcon(iconData: iconData, color: Colors.white38, size: 20),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const Spacer(),
          const MyAppIcon(iconData: Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const MyAppIcon(iconData: Icons.power_settings_new_rounded),
        label: const Text("LOG OUT", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to exit? You will need to login again.",
              style: TextStyle(color: Colors.white60, fontSize: 14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Stay", style: TextStyle(color: Colors.white38))
            ),
            ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }
}