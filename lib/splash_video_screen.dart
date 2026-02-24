import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'auth_wrapper.dart'; // AuthWrapper එක මෙතනට Import කරන්න

class SplashVideoScreen extends StatefulWidget {
  const SplashVideoScreen({super.key});

  @override
  State<SplashVideoScreen> createState() => _SplashVideoScreenState();
}

class _SplashVideoScreenState extends State<SplashVideoScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/videos/parking_bg.mp4")
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.play();
        _controller.setVolume(0);
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_controller.value.isInitialized)
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

          // Overlay using withValues to avoid precision loss
          Container(color: Colors.black.withValues(alpha: 0.4)),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("SMART PARKING",
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 10),
                const Text("Precision Parking at Your Fingertips", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                  child: ElevatedButton(
                    onPressed: () {
                      // මෙන්න මෙතන තමයි වෙනස කළේ: LoginScreen වෙනුවට AuthWrapper එකට යනවා
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthWrapper())
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B65A3),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 10,
                    ),
                    child: const Text("GET STARTED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}