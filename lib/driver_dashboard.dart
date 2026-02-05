import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  // Screen මාරු කිරීම සඳහා ලැයිස්තුව
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),         // අලුත් Home Dashboard
      const MapViewScreen(),      // Search (සිතියම සමඟ)
      const HistoryScreen(),      // බුකින් ඉතිහාසය
      const ProfileScreen(),      // පරිශීලක තොරතුරු
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingConfirmationScreen())),
        backgroundColor: const Color(0xFF00E676),
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_filled, "Home", 0),
              _navItem(Icons.search, "Search", 1),
              const SizedBox(width: 40),
              _navItem(Icons.history, "History", 2),
              _navItem(Icons.person_outline, "Profile", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF2B65A3) : Colors.grey),
          Text(label, style: TextStyle(
              color: isSelected ? const Color(0xFF2B65A3) : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )),
        ],
      ),
    );
  }
}

// --- 1. HOME SCREEN (Dashboard Style) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Good Day, 👋", style: TextStyle(color: Colors.grey)),
                    Text(user?.email?.split('@')[0].toUpperCase() ?? "Driver",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png')),
              ],
            ),
          ),
          const SizedBox(height: 25),
          // Status Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2B65A3), Color(0xFF1E4C7A)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ready to Park?", style: TextStyle(color: Colors.white70)),
                    Text("12 Available Spots Near You", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(Icons.directions_car, color: Colors.white, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          _buildQuickAction(Icons.local_parking, "Find Parking", "Find the best spots in town"),
          _buildQuickAction(Icons.account_balance_wallet, "Wallet", "Top up your balance for easy pay"),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2B65A3), size: 30),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12))])
        ],
      ),
    );
  }
}


// --- 2. SEARCH SCREEN (MAP VIEW - Image 1 Style) ---
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  bool _showSummary = false; // සෙවුමකින් පසු විස්තර පෙන්වීමට

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. සැබෑ සිතියමේ පෙනුම (Map Style Layer)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF0F1210)),
            child: Opacity(
              opacity: 0.4,
              child: Image.network(
                'https://images.squarespace-cdn.com/content/v1/54ff63f0e4b022989c184e13/1559869680327-1K0K59K13R1R1K0K59K1/Dark+Map+Style.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Search Bar සහ Filters
          Positioned(
            top: 50, left: 20, right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2623),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                  ),
                  child: TextField(
                    onSubmitted: (value) => setState(() => _showSummary = true), // Enter කළ විට summary එක පෙන්වයි
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Where do you want to park?",
                      hintStyle: TextStyle(color: Colors.grey),
                      icon: Icon(Icons.search, color: Color(0xFF00E676)),
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.tune, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(Icons.flash_on, "EV Charging", true),
                      _filterChip(Icons.currency_bitcoin, "Cheap", false),
                      _filterChip(Icons.security, "Covered", false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Map Markers (මිල ගණන්)
          if (!_showSummary) ...[
            _priceMarker(250, 100, "\$3.20", false),
            _priceMarker(320, 180, "\$4.50", true),
          ],

          // 4. Bottom Detail Card / Summary
          if (_showSummary)
            Positioned(
              bottom: 90, left: 15, right: 15,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B16),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Central Plaza Garage", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("123 Market St • 0.4 mi", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("\$4.50", style: TextStyle(color: Color(0xFF00E676), fontSize: 22, fontWeight: FontWeight.bold)),
                            const Text("per hour", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Amenities
                    Row(
                      children: [
                        _amenityIcon(Icons.electric_car, "EV Charging"),
                        const SizedBox(width: 10),
                        _amenityIcon(Icons.videocam, "CCTV"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Reserve Spot", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(IconData icon, String text, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00E676) : const Color(0xFF1E2623),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [Icon(icon, size: 16, color: isActive ? Colors.black : Colors.white), const SizedBox(width: 5), Text(text, style: TextStyle(color: isActive ? Colors.black : Colors.white, fontSize: 12))]),
    );
  }

  Widget _priceMarker(double top, double left, String price, bool isSelected) {
    return Positioned(
      top: top, left: left,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E676) : const Color(0xFF1E2623),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(price, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _amenityIcon(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [Icon(icon, size: 14, color: const Color(0xFF00E676)), const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11))]),
    );
  }
}

// --- 3. HISTORY SCREEN (Real-time from Firestore) ---
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parking History"), elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No history found"));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: Text(data['parkingName'] ?? "Parking Spot"),
                subtitle: Text(data['date'] ?? "N/A"),
                trailing: Text("Rs.${data['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              );
            },
          );
        },
      ),
    );
  }
}

// --- 4. PROFILE SCREEN (User Details) ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Center(child: CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'))),
          const SizedBox(height: 15),
          Text(user?.email ?? "Email Not Found", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Professional Driver", style: TextStyle(color: Colors.grey)),
          const Divider(height: 40, indent: 20, endIndent: 20),
          _profileItem(Icons.person, "User ID", user?.uid ?? "Unknown"),
          _profileItem(Icons.email, "Email Address", user?.email ?? "Unknown"),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _profileItem(IconData icon, String title, String value) {
    return ListTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)));
  }
}

// Booking Confirmation UI (Image 3 Style)
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking Confirmation")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const Text("Confirmed!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Image.network('https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=ParkingID_123', height: 150),
            const SizedBox(height: 20),
            const Text("Scan this QR at the entrance"),
          ],
        ),
      ),
    );
  }
}