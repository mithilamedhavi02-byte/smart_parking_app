import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
// පහත import එක ඔයාගේ project එකේ folder structure එක අනුව නිවැරදි දැයි බලන්න
import 'my_app_icon.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  bool _isLogin = true;
  String _role = 'driver';
  bool _isLoading = false;

  void _toggleView() => setState(() {
    _isLogin = !_isLogin;
    _email.clear();
    _password.clear();
    _name.clear();
    _phone.clear();
  });

  void _msg(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(15),
        )
    );
  }

// --- Asgardeo Login Function Updated with Your Real Credentials ---
  Future<void> _handleAsgardeoSignIn() async {
    // ඔයාගේ Asgardeo Console එකෙන් ගත්තු නිවැරදි දත්ත මෙන්න
    const String clientId = 'wyFL14yl8Nf_VNVnedaDe0r5MQUa';
    const String orgName = 'org78shy';
    const String redirectUrl = 'wso2.asgardeo.io.sample://login-callback';
    const String discoveryUrl = 'https://api.asgardeo.io/t/$orgName/oauth2/token/.well-known/openid-configuration';

    final FlutterAppAuth appAuth = const FlutterAppAuth();

    setState(() => _isLoading = true);
    try {
      final AuthorizationTokenResponse? result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl: discoveryUrl,
          scopes: ['openid', 'profile', 'email'],
        ),
      );

      if (result != null && result.accessToken != null) {
        debugPrint("Access Token: ${result.accessToken}");
        if (!mounted) return;
        _msg("Asgardeo Login Successful!", Colors.greenAccent);

        // සාර්ථක වූ පසු Driver Dashboard එකට යොමු කෙරේ
        Navigator.pushReplacementNamed(context, '/driver-dashboard');
      }
    } catch (e) {
      debugPrint("Asgardeo Error: $e");
      _msg("Asgardeo Login Failed! Please try again.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final emailTxt = _email.text.trim();
    final passTxt = _password.text.trim();

    if (emailTxt.isEmpty || passTxt.isEmpty) {
      _msg("Please enter email and password", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailTxt, password: passTxt);

        String col = (_role == 'admin') ? 'admins' : 'drivers';
        var doc = await FirebaseFirestore.instance.collection(col).doc(cred.user!.uid).get();

        if (doc.exists) {
          if (!mounted) return;
          if (_role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/driver-dashboard');
          }
        } else {
          await FirebaseAuth.instance.signOut();
          _msg("Access Denied: Not registered as ${_role.toUpperCase()}", Colors.orangeAccent);
        }
      } else {
        if (_name.text.isEmpty || _phone.text.isEmpty) {
          _msg("All fields are required", Colors.redAccent);
          setState(() => _isLoading = false);
          return;
        }

        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailTxt, password: passTxt);

        String col = (_role == 'admin') ? 'admins' : 'drivers';
        await FirebaseFirestore.instance.collection(col).doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': _name.text.trim(),
          'email': emailTxt,
          'phone': _phone.text.trim(),
          'role': _role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _msg("Account created! Please login.", Colors.greenAccent);
        _toggleView();
      }
    } on FirebaseAuthException catch (e) {
      _msg(e.message ?? "Authentication failed", Colors.redAccent);
    } catch (e) {
      _msg("Something went wrong.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image (Ensure assets/bg.jpg exists)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/bg.jpg'), fit: BoxFit.cover),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.9)],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_parking_rounded, size: 70, color: Colors.white),
                        const SizedBox(height: 10),
                        const Text("PARK-PRO", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
                        const SizedBox(height: 30),
                        _buildRoleSelector(),
                        const SizedBox(height: 25),
                        if (!_isLogin) ...[
                          _input(_name, "Full Name", Icons.person_rounded),
                          const SizedBox(height: 15),
                          _input(_phone, "Phone Number", Icons.phone_android_rounded),
                          const SizedBox(height: 15),
                        ],
                        _input(_email, "Email Address", Icons.email_outlined),
                        const SizedBox(height: 15),
                        _input(_password, "Password", Icons.lock_outline_rounded, hide: true),
                        const SizedBox(height: 35),
                        _isLoading
                            ? const CircularProgressIndicator(color: Colors.blueAccent)
                            : Column(
                          children: [
                            _btn(), // Firebase Sign In
                            if (_isLogin) ...[
                              const SizedBox(height: 15),
                              _asgardeoBtn(), // Asgardeo Sign In
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: _toggleView,
                          child: RichText(
                            text: TextSpan(
                              text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: _isLogin ? "REGISTER" : "LOGIN",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        _roleBtn('driver', "Driver", Icons.directions_car_rounded),
        const SizedBox(width: 15),
        _roleBtn('admin', "Admin", Icons.admin_panel_settings_rounded),
      ],
    );
  }

  Widget _roleBtn(String r, String label, IconData icon) {
    bool sel = _role == r;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? Colors.blueAccent : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: sel ? Colors.white70 : Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String l, IconData i, {bool hide = false}) {
    return TextField(
      controller: c,
      obscureText: hide,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(i, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
    );
  }

  Widget _btn() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        onPressed: _submit,
        child: Text(_isLogin ? "SIGN IN" : "CREATE ACCOUNT", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _asgardeoBtn() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.orangeAccent, width: 2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _handleAsgardeoSignIn,
        icon: const Icon(Icons.security, color: Colors.orangeAccent),
        label: const Text("SIGN IN WITH ASGARDEO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }
}