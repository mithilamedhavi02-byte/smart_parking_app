import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_add_parking.dart';

// =============================================================
// 1. MAIN DASHBOARD - ව්‍යාපාරික විශ්ලේෂණ සහිතව
// =============================================================
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout_rounded))
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('parkings').where('adminId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Parking Registered. Please add one in settings."));
          }

          var doc = snapshot.data!.docs.first;
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String pId = doc.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("INCOME ANALYTICS", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 1.2)),
                const SizedBox(height: 15),
                _buildAdvancedStats(pId),

                const SizedBox(height: 35),
                const Text("MANAGEMENT", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 1.2)),
                const SizedBox(height: 15),

                _largeMenuButton(
                    context,
                    "MANAGE VEHICLES",
                    "View, Search & Check-out vehicles",
                    Icons.manage_search_rounded,
                    Colors.blue.shade800,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminVehicleSummary(parkingData: data, parkingId: pId)))
                ),

                const SizedBox(height: 15),
                _largeMenuButton(
                    context,
                    "PARKING SETTINGS",
                    "Update slots, prices & location",
                    Icons.settings_suggest_rounded,
                    Colors.blueGrey,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddParking()))
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedStats(String pId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings')
          .where('parkingId', isEqualTo: pId)
          .where('status', isEqualTo: 'completed').snapshots(),
      builder: (context, snapshot) {
        double todayIncome = 0;
        double weeklyIncome = 0;
        double monthlyIncome = 0;

        DateTime now = DateTime.now();
        DateTime todayStart = DateTime(now.year, now.month, now.day);
        DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
        DateTime monthStart = DateTime(now.year, now.month, 1);

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> bData = doc.data() as Map<String, dynamic>;
            double bill = (bData['totalBill'] ?? 0).toDouble();
            DateTime checkoutDate = (bData['checkOutTime'] as Timestamp).toDate();

            if (checkoutDate.isAfter(todayStart)) todayIncome += bill;
            if (checkoutDate.isAfter(weekStart)) weeklyIncome += bill;
            if (checkoutDate.isAfter(monthStart)) monthlyIncome += bill;
          }
        }

        return Column(
          children: [
            _revenueCard("Today's Revenue", "LKR ${todayIncome.toStringAsFixed(0)}", Icons.payments_rounded, Colors.green.shade700),
            const SizedBox(height: 15),
            Row(
              children: [
                _smallStatCard("This Week", "LKR ${weeklyIncome.toStringAsFixed(0)}", Icons.calendar_view_week, Colors.blue),
                const SizedBox(width: 15),
                _smallStatCard("This Month", "LKR ${monthlyIncome.toStringAsFixed(0)}", Icons.analytics, Colors.orange),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _revenueCard(String title, String val, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withAlpha(200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withAlpha(80), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(val, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _smallStatCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 5),
          Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _largeMenuButton(BuildContext context, String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withAlpha(30), radius: 25, child: Icon(icon, color: color)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 2. VEHICLE SUMMARY PAGE
// =============================================================
class AdminVehicleSummary extends StatelessWidget {
  final Map<String, dynamic> parkingData;
  final String parkingId;
  const AdminVehicleSummary({super.key, required this.parkingData, required this.parkingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(title: const Text("Select Vehicle Type"), backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: parkingData['capacity'].keys.map<Widget>((type) {
          return _buildCategoryCard(context, type, parkingData['capacity'][type], parkingData['currentFree'][type]);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String type, dynamic total, dynamic free) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminVehicleList(parkingId: parkingId, vehicleType: type, fullParkingData: parkingData))),
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        subtitle: Text("Free Slots: $free / $total", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// =============================================================
// 3. VEHICLE LIST PAGE (Search + Filter + Checkout)
// =============================================================
class AdminVehicleList extends StatefulWidget {
  final String parkingId;
  final String vehicleType;
  final Map<String, dynamic> fullParkingData;
  const AdminVehicleList({super.key, required this.parkingId, required this.vehicleType, required this.fullParkingData});

  @override
  State<AdminVehicleList> createState() => _AdminVehicleListState();
}

class _AdminVehicleListState extends State<AdminVehicleList> {
  String selectedFilter = 'all';
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  void _showCheckoutDialog(BuildContext context, DocumentSnapshot doc) {
    var bData = doc.data() as Map<String, dynamic>;
    Timestamp checkIn = bData['checkInTime'] ?? Timestamp.now();
    DateTime now = DateTime.now();
    Duration diff = now.difference(checkIn.toDate());
    int hours = diff.inHours + (diff.inMinutes % 60 > 0 ? 1 : 0);
    double bill = hours * 100.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Check-out Receipt"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(bData['vehicleNumber'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Duration: $hours Hour(s)"),
            const Divider(),
            Text("LKR ${bill.toStringAsFixed(0)}", style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await doc.reference.update({'status': 'completed', 'checkOutTime': now, 'totalBill': bill});
              Map<String, dynamic> currentFree = Map.from(widget.fullParkingData['currentFree']);
              currentFree[widget.vehicleType] = (currentFree[widget.vehicleType] ?? 0) + 1;
              await FirebaseFirestore.instance.collection('parkings').doc(widget.parkingId).update({'currentFree': currentFree});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Release Vehicle"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: Text("${widget.vehicleType} Status"), backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => searchQuery = val.toUpperCase()),
              decoration: InputDecoration(
                hintText: "Search Vehicle Number...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // FILTERS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(children: [
              _filterBtn("PENDING", 'pending', Colors.orange),
              const SizedBox(width: 10),
              _filterBtn("IN PARK", 'parked', Colors.red),
              const SizedBox(width: 10),
              _filterBtn("ALL", 'all', Colors.blueGrey),
            ]),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings')
                  .where('parkingId', isEqualTo: widget.parkingId)
                  .where('vehicleType', isEqualTo: widget.vehicleType)
                  .where('status', whereIn: ['confirmed', 'parked']).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool matchesFilter = (selectedFilter == 'all') ||
                      (selectedFilter == 'parked' && data['status'] == 'parked') ||
                      (selectedFilter == 'pending' && data['status'] == 'confirmed');
                  bool matchesSearch = data['vehicleNumber'].toString().contains(searchQuery);
                  return matchesFilter && matchesSearch;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    bool isParked = doc['status'] == 'parked';
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        onTap: () => isParked ? _showCheckoutDialog(context, doc) : null,
                        leading: Icon(Icons.directions_car, color: isParked ? Colors.red : Colors.orange),
                        title: Text(doc['vehicleNumber'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(isParked ? "Parked (Tap to Release)" : "Pending Arrival"),
                        trailing: Icon(isParked ? Icons.logout : Icons.hourglass_top, size: 18),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBtn(String label, String filter, Color color) {
    bool isSel = selectedFilter == filter;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSel ? color : color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(label, style: TextStyle(color: isSel ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 11))),
        ),
      ),
    );
  }
}