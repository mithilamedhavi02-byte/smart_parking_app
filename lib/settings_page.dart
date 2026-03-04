import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
// MyAppIcon එක අමතක නොකර import කරගන්න
import 'my_app_icon.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notif = true;
  String _selectedLanguage = "English";
  final Color primaryBlue = const Color(0xFF0D47A1);

  // --- Password වෙනස් කිරීමේ Logic එක ---
  void _changePassword() {
    TextEditingController _passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white12)),
          title: const Text("Update Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _passController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter new password",
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha:0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                try {
                  if (_passController.text.length < 6) throw "At least 6 characters needed";
                  await FirebaseAuth.instance.currentUser!.updatePassword(_passController.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Updated! ✨"), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  // --- Language Select Logic එක ---
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: SimpleDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Select Language", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          children: [
            _buildLanguageOption("English", "English"),
            _buildLanguageOption("Sinhala", "සිංහල"),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String value, String label) {
    return SimpleDialogOption(
      onPressed: () { setState(() => _selectedLanguage = value); Navigator.pop(context); },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("SETTINGS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
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
              image: DecorationImage(image: AssetImage('assets/bg1.webp'), fit: BoxFit.cover),
            ),
          ),
          Container(color: Colors.black.withValues(alpha:0.85)),

          // 2. Content
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                _buildSectionHeader("ACCOUNT PROFILE"),
                const SizedBox(height: 15),
                _buildGlassCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const MyAppIcon(iconData: Icons.admin_panel_settings_rounded, color: Colors.blueAccent, size: 30),
                    ),
                    title: const Text("Authorized Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(user?.email ?? "Not Available", style: const TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                ),

                const SizedBox(height: 35),
                _buildSectionHeader("APPLICATION SETTINGS"),
                const SizedBox(height: 15),
                _buildGlassCard(
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: Icons.lock_reset_rounded,
                        color: Colors.blueAccent,
                        title: "Change Password",
                        onTap: _changePassword,
                      ),
                      _buildDivider(),
                      _buildSettingTile(
                        icon: Icons.translate_rounded,
                        color: Colors.orangeAccent,
                        title: "App Language",
                        subtitle: _selectedLanguage,
                        onTap: _showLanguageDialog,
                      ),
                      _buildDivider(),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        secondary: const MyAppIcon(iconData: Icons.notifications_active_outlined, color: Colors.greenAccent, size: 22),
                        title: const Text("Push Notifications", style: TextStyle(color: Colors.white, fontSize: 15)),
                        value: _notif,
                        activeColor: Colors.greenAccent,
                        onChanged: (v) => setState(() => _notif = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // --- Logout Button ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha:0.1),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    },
                    icon: const MyAppIcon(iconData: Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    label: const Text("SIGN OUT FROM SYSTEM", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 25),
                const Center(child: Text("ParkPro Management v1.0.4", style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        title,
        style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.06),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha:0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required Color color, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: MyAppIcon(iconData: icon, color: color, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
      trailing: const MyAppIcon(iconData: Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.white.withValues(alpha:0.05), indent: 20, endIndent: 20);
  }
}