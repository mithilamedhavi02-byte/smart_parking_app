import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notif = true;
  String _selectedLanguage = "English";

  // --- Password වෙනස් කිරීමේ Logic එක ---
  void _changePassword() {
    TextEditingController _passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Password"),
        content: TextField(
          controller: _passController,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Enter new password"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                if (_passController.text.length < 6) throw "At least 6 characters needed";
                await FirebaseAuth.instance.currentUser!.updatePassword(_passController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Updated!")));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // --- Language Select Logic එක ---
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Select Language"),
        children: [
          SimpleDialogOption(onPressed: () { setState(() => _selectedLanguage = "English"); Navigator.pop(context); }, child: const Text("English")),
          SimpleDialogOption(onPressed: () { setState(() => _selectedLanguage = "Sinhala"); Navigator.pop(context); }, child: const Text("සිංහල")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF0D47A1), child: Icon(Icons.person, color: Colors.white)),
              title: const Text("Admin Account"),
              subtitle: Text(user?.email ?? "No Email Found"),
            ),
          ),
          const SizedBox(height: 25),
          const Text("App Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.blue),
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _changePassword,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.orange),
                  title: const Text("Language"),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showLanguageDialog,
                ),
                const Divider(height: 0),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: Colors.green),
                  title: const Text("Notifications"),
                  value: _notif,
                  onChanged: (v) => setState(() => _notif = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // --- නිවැරදි Logout බොත්තම ---//
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                // මෙතනින් Stack එකේ තියෙන පරණ පේජ් ඔක්කොම අයින් කරලා Login එකට යවනවා
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}