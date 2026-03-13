import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

// Import screens
import 'auth_wrapper.dart';
import 'login_screen.dart';
import 'admin_setup.dart';
import 'admin_dashboard.dart';
import 'driver_dashboard.dart';
import 'my_app_icon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ParkProApp());
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
          // Background Video
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

          // Gradient Overlay
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

                    // --- Colorful Animated PARK-PRO ---
                    TweenAnimationBuilder<int>(
                      duration: const Duration(milliseconds: 2000),
                      tween: IntTween(begin: 0, end: "PARK-PRO".length),
                      builder: (context, value, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF00E5FF), // Cyan
                              Color(0xFF3B82F6), // Blue
                              Color(0xFFA855F7), // Purple
                            ],
                          ).createShader(bounds),
                          child: Text(
                            "PARK-PRO".substring(0, value),
                            style: TextStyle(
                              color: Colors.white, // Shader එක නිසා මෙය Gradient එකක් ලෙස පෙනේ
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              shadows: [
                                Shadow(
                                  blurRadius: 20,
                                  color: const Color(0xFF00E5FF).withOpacity(0.5),
                                  offset: const Offset(0, 0),
                                ),
                                Shadow(
                                  blurRadius: 40,
                                  color: const Color(0xFFA855F7).withOpacity(0.3),
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const Text(
                      "SMART PARKING REDEFINED",
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold
                      ),
                    ),

                    const Spacer(flex: 4),

                    // Premium Animated Button
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

// --- 🔥 Animated Neon Button Widget ---
class AnimatedPremiumButton extends StatefulWidget {
  final VoidCallback onTap;
  const AnimatedPremiumButton({super.key, required this.onTap});

  @override
  State<AnimatedPremiumButton> createState() => _AnimatedPremiumButtonState();
}

class _AnimatedPremiumButtonState extends State<AnimatedPremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
                colors: const [
                  Color(0xFF000000),
                  Color(0xFF0D47A1),
                  Color(0xFF00E5FF), // Neon Glow
                  Color(0xFF4A148C),
                  Color(0xFF000000),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),


                ),
                const Expanded(
                  child: Center(
                    child: Text("GET STARTED",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
        );
      },
    );
  }
}