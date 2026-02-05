import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard.dart';
import 'driver_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isDriver = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("කරුණාකර සියලු විස්තර ඇතුළත් කරන්න.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String collection = isDriver ? 'drivers' : 'admins';
      var doc = await FirebaseFirestore.instance.collection(collection).doc(userCredential.user!.uid).get();

      if (doc.exists) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => isDriver ? const DriverDashboard() : const AdminDashboard()),
              (route) => false,
        );
      } else {
        await FirebaseAuth.instance.signOut();
        _showError("ඔබ තෝරාගත් අංශයේ මෙම ගිණුම නොමැත.");
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login අසාර්ථකයි.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.local_parking_rounded, color: Color(0xFF2B65A3), size: 80),
              const Text("Smart Parking", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Color(0xFF2B65A3))),
              const SizedBox(height: 40),
              Row(
                children: [
                  _buildRoleTab("Driver", isDriver, () => setState(() => isDriver = true)),
                  _buildRoleTab("Admin", !isDriver, () => setState(() => isDriver = false)),
                ],
              ),
              const SizedBox(height: 30),
              buildModernField("Email", Icons.email_outlined, _emailController, TextInputType.emailAddress),
              buildModernField("Password", Icons.lock_outline, _passwordController, TextInputType.text, isPass: true),
              const SizedBox(height: 25),
              buildMainButton(isDriver ? "Driver Login" : "Admin Login", _isLoading ? null : _handleLogin, _isLoading),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => isDriver ? const DriverRegisterScreen() : const AdminRegisterScreen()
                  ));
                },
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(text: "Register Now", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF2B65A3) : Colors.transparent, width: 2))
          ),
          child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF2B65A3) : Colors.grey))),
        ),
      ),
    );
  }
}

// --- DRIVER REGISTER SCREEN ---
class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});
  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('drivers').doc(user.user!.uid).set({
        'uid': user.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'driver',
      });
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DriverDashboard()), (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Registration")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            buildModernField("Full Name", Icons.person, _nameController, TextInputType.name),
            buildModernField("Email", Icons.email, _emailController, TextInputType.emailAddress),
            buildModernField("Password", Icons.lock, _passwordController, TextInputType.text, isPass: true),
            const SizedBox(height: 20),
            buildMainButton("Register as Driver", _isLoading ? null : _register, _isLoading),
          ],
        ),
      ),
    );
  }
}

// --- ADMIN REGISTER SCREEN ---
class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});
  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('admins').doc(user.user!.uid).set({
        'uid': user.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'admin',
      });
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminDashboard()), (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Registration")),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            buildModernField("Full Name", Icons.person, _nameController, TextInputType.name),
            buildModernField("Email", Icons.email, _emailController, TextInputType.emailAddress),
            buildModernField("Password", Icons.lock, _passwordController, TextInputType.text, isPass: true),
            const SizedBox(height: 20),
            buildMainButton("Register as Admin", _isLoading ? null : _register, _isLoading, color: Colors.indigo),
          ],
        ),
      ),
    );
  }
}

// --- HELPER WIDGETS ---
Widget buildModernField(String hint, IconData icon, TextEditingController controller, TextInputType type, {bool isPass = false}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: controller,
      obscureText: isPass,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2B65A3)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    ),
  );
}

Widget buildMainButton(String label, VoidCallback? onPressed, bool isLoading, {Color color = const Color(0xFF2B65A3)}) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}