import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// පහත imports නිවැරදිව තියෙන්න ඕනේ
import 'admin_dashboard.dart';
import 'driver_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLogin = true;
  String _selectedRole = 'driver'; // 'driver' හෝ 'admin'
  bool _isLoading = false;

  // --- පිරිසිදු කරන ලද Navigation Method එක ---
  void _navigate(String role) {
    // මෙතනදී Widget එකක් බව නිශ්චිතවම පවසනවා (Object error එක නැති කිරීමට)
    Widget nextScreen;

    if (role == 'owner') {
      nextScreen = const AdminDashboard();
    } else {
      nextScreen = const DriverDashboard();
    }

    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen)
    );
  }

  Future<void> _processAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMsg("කරුණාකර සියලු විස්තර ඇතුළත් කරන්න", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // --- LOGIN ---
        UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String uid = userCred.user!.uid;

        if (_selectedRole == 'admin') {
          var adminDoc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
          if (adminDoc.exists) {
            _navigate('owner');
          } else {
            await FirebaseAuth.instance.signOut();
            _showMsg("Admin ගිණුමක් හමු නොවීය!", Colors.orange);
          }
        } else {
          var driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
          if (driverDoc.exists) {
            _navigate('driver');
          } else {
            await FirebaseAuth.instance.signOut();
            _showMsg("Driver ගිණුමක් හමු නොවීය!", Colors.orange);
          }
        }
      } else {
        // --- REGISTER ---
        UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String uid = userCred.user!.uid;
        String collection = (_selectedRole == 'admin') ? 'admins' : 'drivers';

        await FirebaseFirestore.instance.collection(collection).doc(uid).set({
          'uid': uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': (_selectedRole == 'admin') ? 'owner' : 'driver',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showMsg("ලියාපදිංචිය සාර්ථකයි!", Colors.green);
        setState(() => _isLogin = true);
      }
    } on FirebaseAuthException catch (e) {
      _showMsg("දෝෂයකි: ${e.message}", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(padding: const EdgeInsets.all(30), child: Column(children: [
              _buildRoleSelector(),
              const SizedBox(height: 30),
              if (!_isLogin) ...[
                _buildInput(_nameController, "සම්පූර්ණ නම", Icons.person),
                const SizedBox(height: 15),
                _buildInput(_phoneController, "දුරකථන අංකය", Icons.phone),
                const SizedBox(height: 15),
              ],
              _buildInput(_emailController, "ඊමේල් ලිපිනය", Icons.email),
              const SizedBox(height: 15),
              _buildInput(_passwordController, "මුරපදය", Icons.lock, hide: true),
              const SizedBox(height: 40),
              _isLoading ? const CircularProgressIndicator() : _buildSubmitBtn(),
              const SizedBox(height: 15),
              _buildToggleBtn(),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 230, width: double.infinity,
      decoration: const BoxDecoration(
          color: Color(0xFF0D47A1),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80))
      ),
      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.local_parking, size: 70, color: Colors.white),
        SizedBox(height: 10),
        Text("PARK-PRO", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildRoleSelector() {
    return Row(children: [
      _roleTab("driver", Icons.directions_car, "Driver"),
      const SizedBox(width: 15),
      _roleTab("admin", Icons.admin_panel_settings, "Admin (Owner)"),
    ]);
  }

  Widget _roleTab(String role, IconData icon, String label) {
    bool sel = _selectedRole == role;
    return Expanded(child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: sel ? const Color(0xFF0D47A1) : Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
          child: Column(children: [
            Icon(icon, color: sel ? Colors.white : Colors.grey),
            Text(label, style: TextStyle(color: sel ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))
          ]),
        )
    ));
  }

  Widget _buildInput(TextEditingController c, String l, IconData i, {bool hide = false}) {
    return TextField(
        controller: c,
        obscureText: hide,
        decoration: InputDecoration(
            labelText: l,
            prefixIcon: Icon(i),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
        )
    );
  }

  Widget _buildSubmitBtn() {
    return SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      onPressed: _processAuth,
      child: Text(_isLogin ? "LOGIN" : "REGISTER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ));
  }

  Widget _buildToggleBtn() {
    return TextButton(
        onPressed: () => setState(() => _isLogin = !_isLogin),
        child: Text(_isLogin ? "Don't have an account? Register" : "Already have an account? Login")
    );
  }
}

// ❌ මචං, මම ඔයා යටින්ම ලියලා තිබුණු හිස් "class DriverDashboard" එක අයින් කළා.
// ඒක තමයි "Ambiguous Import" error එකට හේතුව.
// DriverDashboard එක තියෙන්න ඕනේ වෙනම ෆයිල් එකක් වන 'driver_dashboard.dart' එකේ විතරයි.