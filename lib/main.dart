import 'package:flutter/material.dart';
import 'screens/main_app/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_app/map_screen.dart';
import 'screens/main_app/profile_screen.dart';
import 'screens/main_app/booking_confirmation_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Parking Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Primary Colors
        primaryColor: const Color(0xFF1E88E5), // Blue
        primaryColorDark: const Color(0xFF1565C0),
        primaryColorLight: const Color(0xFF64B5F6),
        
        // Secondary Colors
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: const Color(0xFF43A047), // Green
        ),
        
        // App Bar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
          ),
        ),
        
        // Card Theme
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        
        // Text Theme
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF64B5F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D47A1),
        ),
      ),
      themeMode: ThemeMode.light,
      
      // Routes
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder(
          future: AuthService().checkLoginStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            return snapshot.data == true 
                ? const HomeScreen() 
                : const LoginScreen();
          },
        ),
        '/home': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(),
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/booking-confirmation': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return BookingConfirmationScreen(
            parkingName: args['parkingName'],
            bookingId: args['bookingId'],
          );
        },
      },
      
      // 404 Error Screen
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Page not found',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The requested page does not exist.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Splash Screen Widget
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_parking,
                size: 60,
                color: Color(0xFF1E88E5),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // App Name
            const Text(
              'Smart Parking Finder',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Tagline
            const Text(
              'Find. Book. Park. Easy.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Loading Indicator
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            
            const SizedBox(height: 20),
            
            // Loading Text
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Auth Service (for main.dart)
class AuthService {
  Future<bool> checkLoginStatus() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    // For demo, always return false (show login screen)
    // Change to true to skip login
    return false;
  }
}