import 'package:flutter/material.dart';

// Imports with Aliases
import 'admin_add_parking_screen.dart' as add_screen;
import 'admin_parking_details_screen.dart' as details_screen;
import 'admin_vehicle_status.dart' as status_screen;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 1; // Default ලෙස Parkings Tab එක පෙන්වයි

  // Screen List එක
  final List<Widget> _screens = [
    const DashboardHomeContent(),
    const details_screen.AdminParkingDetailsScreen(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D100E),
      body: IndexedStack( // Tab මාරු කිරීමේදී State එක ආරක්ෂා කිරීමට IndexedStack භාවිතා කෙරේ
        index: _selectedIndex,
        children: _screens,
      ),
      // Parking Details tab එකේදී පමණක් Edit Button එක පෙන්වයි
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
        onPressed: () {
          // NAVIGATION FIX: මෙතැනින් නිවැරදිව Add/Edit Screen එකට යයි
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const add_screen.AdminAddParkingScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF8DE15D),
        child: const Icon(Icons.edit, color: Colors.black, size: 28),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0D100E),
        selectedItemColor: const Color(0xFF8DE15D),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.local_parking), label: "Parkings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// --- Home Content (Grid Menu) ---
class DashboardHomeContent extends StatelessWidget {
  const DashboardHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _buildMenuCard(
            context,
            "Edit Parking",
            Icons.edit_location_alt,
            const add_screen.AdminAddParkingScreen(),
          ),
          _buildMenuCard(
            context,
            "Status",
            Icons.bar_chart,
            const status_screen.AdminVehicleStatusScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1A1F1C), borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF8DE15D)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Profile Settings", style: TextStyle(color: Colors.white)));
}