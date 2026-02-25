import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Pages
import 'admin_manage_bookings.dart'; // My Bookings saathi vaparu shakto

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;

  // Pages chi List
  final List<Widget> _pages = [
    const DriverHomeScreen(),
    const DriverSearchScreen(),
    const Center(child: Text("My Bookings Page")), // Tumhi tumche Bookings page ithe add kara
    const DriverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// --- 1. HOME SCREEN ---
class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildHeader("Ready to Park?"),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Nearby Parking Hubs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildParkingList(null), // Home var sarva parking distil
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return SliverAppBar(
      expandedHeight: 180, pinned: true, backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          Image.network('https://images.unsplash.com/photo-1545179605-1296651e9d43?q=80&w=2070&auto=format&fit=crop', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.4)),
          Positioned(bottom: 30, left: 20, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }
}

// --- 2. SEARCH SCREEN (With City Search) ---
class DriverSearchScreen extends StatefulWidget {
  const DriverSearchScreen({super.key});

  @override
  State<DriverSearchScreen> createState() => _DriverSearchScreenState();
}

class _DriverSearchScreenState extends State<DriverSearchScreen> {
  String searchCity = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
          child: TextField(
            onChanged: (val) => setState(() => searchCity = val.toLowerCase()),
            decoration: const InputDecoration(hintText: "Search by City...", border: InputBorder.none, icon: Icon(Icons.search)),
          ),
        ),
      ),
      body: searchCity.isEmpty
          ? const Center(child: Text("Enter city name to find parking"))
          : _buildParkingList(searchCity),
    );
  }
}

// --- 3. PROFILE SCREEN (Like Admin Profile) ---
class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 40, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 50, color: Colors.white)),
                const SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.email?.split('@')[0].toUpperCase() ?? "DRIVER", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("Premium Member", style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _profileMenu("My Wallet", Icons.account_balance_wallet, Colors.green, () {}),
          _profileMenu("Booking History", Icons.history, Colors.blue, () {}),
          _profileMenu("Support", Icons.help_outline, Colors.orange, () {}),
          const Divider(),
          _profileMenu("Logout", Icons.logout, Colors.red, () async {
            await FirebaseAuth.instance.signOut();
          }),
        ],
      ),
    );
  }

  Widget _profileMenu(String title, IconData icon, Color color, VoidCallback tap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: tap,
    );
  }
}

// --- COMMON PARKING LIST LOGIC ---
Widget _buildParkingList(String? cityQuery) {
  Query query = FirebaseFirestore.instance.collection('parkings');

  // Jar city search kela asel tar
  if (cityQuery != null && cityQuery.isNotEmpty) {
    query = query.where('city', isEqualTo: cityQuery);
  }

  return StreamBuilder<QuerySnapshot>(
    stream: query.snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No parking found in this city."));

      return ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          var pData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
          return _ParkingCard(pData: pData);
        },
      );
    },
  );
}

class _ParkingCard extends StatelessWidget {
  final Map<String, dynamic> pData;
  const _ParkingCard({required this.pData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          const Icon(Icons.local_parking, color: Colors.blueAccent, size: 40),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pData['parkingName'] ?? "Parking", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(pData['city'] ?? "Location", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          Text("LKR ${pData['pricePerHour']}/hr", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}