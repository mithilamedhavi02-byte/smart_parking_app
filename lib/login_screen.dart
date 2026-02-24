import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard.dart'; // Admin Dashboard එක තියෙන file එක
import 'driver_dashboard.dart'; // Driver Dashboard එක තියෙන file එක

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

  // --- LOGIN FUNCTION ---
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

      // Firestore එකේ අදාළ Collection එක පරීක්ෂා කිරීම
      String collection = isDriver ? 'drivers' : 'admins';
      var doc = await FirebaseFirestore.instance.collection(collection).doc(userCredential.user!.uid).get();

      if (doc.exists) {
        if (!mounted) return;
        _navigateToDashboard();
      } else {
        await FirebaseAuth.instance.signOut();
        _showError("ඔබ තෝරාගත් අංශයේ (Account Type) මෙම ගිණුම නොමැත.");
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getAuthErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => isDriver ? const DriverDashboard() : const AdminDashboard()),
          (route) => false,
    );
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return "මෙම ඊමේල් ලිපිනයට අදාළ ගිණුමක් නොමැත.";
      case 'wrong-password': return "මුද්‍රිත රහස් පදය (Password) වැරදියි.";
      case 'invalid-email': return "ඊමේල් ලිපිනය නිවැරදි නැත.";
      default: return "Login අසාර්ථකයි. කරුණාකර නැවත උත්සාහ කරන්න.";
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.local_parking_rounded, color: Color(0xFF2B65A3), size: 80),
              const Text("Smart Parking", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Color(0xFF2B65A3))),
              const SizedBox(height: 40),
              // Role Selection Tabs
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
                      TextSpan(text: "Register Now", style: TextStyle(color: const Color(0xFF2B65A3), fontWeight: FontWeight.bold)),
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
              border: Border(bottom: BorderSide(color: isSelected ? const Color(0xFF2B65A3) : Colors.transparent, width: 3))
          ),
          child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF2B65A3) : Colors.grey, fontSize: 16))),
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
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("සියලු විස්තර පුරවන්න.")));
      return;
    }

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
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DriverDashboard()), (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("දෝෂයකි: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Registration"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            buildModernField("Full Name", Icons.person, _nameController, TextInputType.name),
            buildModernField("Email", Icons.email, _emailController, TextInputType.emailAddress),
            buildModernField("Password", Icons.lock, _passwordController, TextInputType.text, isPass: true),
            const SizedBox(height: 30),
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
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("සියලු විස්තර පුරවන්න.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Firestore එකේ 'admins' collection එකට දත්ත යැවීම
      await FirebaseFirestore.instance.collection('admins').doc(user.user!.uid).set({
        'uid': user.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // වැදගත්: මෙතන AdminDashboard() එකටම යනවාද බලන්න
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
              (route) => false
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Registration"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            buildModernField("Full Name", Icons.person, _nameController, TextInputType.name),
            buildModernField("Email", Icons.email, _emailController, TextInputType.emailAddress),
            buildModernField("Password", Icons.lock, _passwordController, TextInputType.text, isPass: true),
            const SizedBox(height: 30),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.blue.withOpacity(0.05),
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
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}