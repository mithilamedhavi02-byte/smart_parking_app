import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'driver_booking_screen.dart';
import 'active_booking_status_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),

          // Active Booking Section
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('driverId', isEqualTo: uid)
                  .where('status', isEqualTo: 'confirmed')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  var activeBooking = snapshot.data!.docs.first;
                  return _buildActiveBookingCard(context, activeBooking);
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text("Parking Spots Near You",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('parkings').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }

              if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox());

              var filteredDocs = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                String name = (data['parkingName'] ?? "").toString().toLowerCase();
                String address = (data['address'] ?? "").toString().toLowerCase();
                return name.contains(_searchQuery.toLowerCase()) || address.contains(_searchQuery.toLowerCase());
              }).toList();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return _buildParkingCard(context, data, doc.id); // doc.id එක මෙතනින් යවනවා
                    },
                    childCount: filteredDocs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hello Driver,", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text("Where to Park?", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withAlpha(50),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(hintText: "Search by Area", border: InputBorder.none, icon: Icon(Icons.search)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingCard(BuildContext context, Map<String, dynamic> parking, String docId) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverBookingScreen(
            parkingData: parking,
            parkingId: docId, // නිවැරදිව required parameter එක මෙතන දෙනවා
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Container(height: 120, decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(20)), image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1506521781263-d8422e82f27a?q=80&w=1000'), fit: BoxFit.cover))),
            ListTile(
              title: Text(parking['parkingName'] ?? "Parking", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(parking['address'] ?? "Address"),
              trailing: Text("LKR ${parking['pricing']?['firstHour'] ?? '0'}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBookingCard(BuildContext context, QueryDocumentSnapshot booking) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.orange.shade500]), borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.timer, color: Colors.white, size: 35),
        title: const Text("Active Booking!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text("Tap to view timer", style: TextStyle(color: Colors.white70)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveBookingStatusScreen(bookingId: booking.id))),
      ),
    );
  }
}