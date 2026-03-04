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
          seedColor: const Color(0xFF3B82F6), // Modern Blue
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // වඩාත් නවීන Look එකක් සඳහා
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

    // 1. Animation Setup (Logic එක එහෙම්මමයි, ඇනිමේෂන් එක විතරක් smooth කළා)
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
          setState(() {
            _isVideoReady = true;
          });
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
    // වීඩියෝ එක ලෑස්ති නැතිනම් කළු screen එකක් පෙන්වන්න (අර රතු error එක එන්නේ නැහැ)
    if (!_isVideoReady) {
      return const Scaffold(backgroundColor: Color(0xFF020617));
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Video
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

          // 2. Dark Gradient Overlay (UI එක පැහැදිලිව පෙනීමට)
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

          // 3. Animated UI Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // Logo with Glow Effect
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: const MyAppIcon(iconData: Icons.local_parking_rounded, color: Colors.blueAccent, size: 90),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "PARK-PRO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),

                    const Text(
                      "SMART PARKING REDEFINED",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Modern Glassmorphism Container for the Button
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: _buildEnhancedButton(context),
                        ),
                      ),
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

  Widget _buildEnhancedButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushReplacementNamed(context, '/auth'), // ✅ Logic එක කලින් වගේමයි
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "GET STARTED",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}