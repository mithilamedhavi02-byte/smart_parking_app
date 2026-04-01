import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

// Asgardeo සඳහා ඔයාගේ pubspec එකේ ඇති package එක
import 'package:flutter_appauth/flutter_appauth.dart';

// Import screens
import 'auth_wrapper.dart';
import 'login_screen.dart';
import 'admin_setup.dart';
import 'admin_dashboard.dart';
import 'driver_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase Initialize කිරීම
  await Firebase.initializeApp();

  runApp(const ParkProApp());
}

// Asgardeo Configuration එක මේ විදිහට වෙනම තබා ගැනීම පහසුයි
class AsgardeoConfig {
  static const String clientId = "wyFL14yl8Nf_VNVnedaDe0r5MQUa"; // ඔයාගේ Client ID එක
  static const String redirectUri = "wso2.asgardeo.io.sample://login-callback"; //
  static const String organizationName = "org78shy"; //
  static const String discoveryUrl = "https://api.asgardeo.io/t/org78shy/oauth2/token/.well-known/openid-configuration";
}

class ParkProApp extends StatelessWidget {
  const ParkProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Park-Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashVideoScreen(),
        '/auth': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/admin-setup': (context) => const AdminSetup(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/driver-dashboard': (context) => const DriverDashboard(),
      },
    );
  }
}

class SplashVideoScreen extends StatefulWidget {
  const SplashVideoScreen({super.key});
  @override
  State<SplashVideoScreen> createState() => _SplashVideoScreenState();
}

class _SplashVideoScreenState extends State<SplashVideoScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset("assets/videos/parking_bg.mp4")
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
        if (mounted) {
          setState(() => _isVideoReady = true);
          _animController.forward();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideoReady) return const Scaffold(backgroundColor: Color(0xFF020617));

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  const Color(0xFF020617).withOpacity(0.9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    TweenAnimationBuilder<int>(
                      duration: const Duration(milliseconds: 2000),
                      tween: IntTween(begin: 0, end: "PARK-PRO".length),
                      builder: (context, value, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF3B82F6), Color(0xFFA855F7)],
                          ).createShader(bounds),
                          child: Text(
                            "PARK-PRO".substring(0, value),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                            ),
                          ),
                        );
                      },
                    ),
                    const Text(
                      "SMART PARKING REDEFINED",
                      style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(flex: 4),
                    AnimatedPremiumButton(
                      onTap: () => Navigator.pushReplacementNamed(context, '/auth'),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "v1.0.2 • SECURE CLOUD-SYNC ENABLED",
                      style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedPremiumButton extends StatefulWidget {
  final VoidCallback onTap;
  const AnimatedPremiumButton({super.key, required this.onTap});

  @override
  State<AnimatedPremiumButton> createState() => _AnimatedPremiumButtonState();
}

class _AnimatedPremiumButtonState extends State<AnimatedPremiumButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment(_controller.value * 2 - 1, -1),
                end: Alignment(_controller.value * 2, 1),
                colors: const [Color(0xFF000000), Color(0xFF0D47A1), Color(0xFF00E5FF), Color(0xFF4A148C), Color(0xFF000000)],
              ),
              boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 20, spreadRadius: -5)],
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: const Center(
              child: Text("GET STARTED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
            ),
          ),
        );
      },
    );
  }
}