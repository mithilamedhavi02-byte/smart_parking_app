import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_add_parking_screen.dart' as add_screen;

class AdminParkingDetailsScreen extends StatefulWidget {
  const AdminParkingDetailsScreen({super.key});

  @override
  State<AdminParkingDetailsScreen> createState() => _AdminParkingDetailsScreenState();
}

class _AdminParkingDetailsScreenState extends State<AdminParkingDetailsScreen> {
  String? _selectedParkingId;
  List<Map<String, dynamic>> _parkingList = [];
  final String? adminUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadParkings();
  }

  Future<void> _loadParkings() async {
    if (adminUid == null) return;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('parkings')
          .where('adminId', isEqualTo: adminUid)
          .get();

      if (mounted) {
        setState(() {
          _parkingList = querySnapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['parkingName'] ?? 'Unnamed Parking',
          }).toList();

          if (_parkingList.isNotEmpty && _selectedParkingId == null) {
            _selectedParkingId = _parkingList[0]['id'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading parkings: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D100E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 25),
              _buildParkingSelector(),
              const SizedBox(height: 25),
              const Text("Vehicle Status",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              if (_selectedParkingId != null)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('parkings')
                      .doc(_selectedParkingId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF8DE15D)));
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Text("No data found", style: TextStyle(color: Colors.white));
                    }

                    var data = snapshot.data!.data() as Map<String, dynamic>;
                    var vehicleStats = data['vehicleStats'] as Map<String, dynamic>? ?? {};

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: vehicleStats.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: _buildTypeCard(
                              entry.key,
                              entry.value,
                              _getIconForType(entry.key),
                              _getColorForType(entry.key),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Admin Panel", style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text("Parking Manager", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const add_screen.AdminAddParkingScreen())),
          icon: const Icon(Icons.edit, color: Color(0xFF8DE15D)),
          style: IconButton.styleFrom(backgroundColor: Colors.white10),
        ),
      ],
    );
  }

  Widget _buildTypeCard(String title, Map<String, dynamic> stats, IconData icon, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text("Total: ${stats['total']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("Free", stats['free']?.toString() ?? '0', Colors.green),
              _statItem("Booked", stats['booked']?.toString() ?? '0', Colors.blue),
              _statItem("Pending", stats['pending']?.toString() ?? '0', Colors.orange),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _getIconForType(String type) {
    if (type.contains('Car')) return Icons.directions_car;
    if (type.contains('Bike')) return Icons.motorcycle;
    if (type.contains('Van')) return Icons.airport_shuttle;
    if (type.contains('Three')) return Icons.electric_rickshaw;
    if (type.contains('Bus')) return Icons.bus_alert;
    if (type.contains('Lorr')) return Icons.local_shipping;
    return Icons.local_parking;
  }

  Color _getColorForType(String type) {
    if (type.contains('Car')) return Colors.blue;
    if (type.contains('Bike')) return Colors.orange;
    if (type.contains('Bus')) return Colors.red;
    return Colors.green;
  }

  Widget _buildParkingSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: const Color(0xFF1A1F1C), borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedParkingId,
          dropdownColor: const Color(0xFF1A1F1C),
          isExpanded: true,
          onChanged: (v) => setState(() => _selectedParkingId = v),
          items: _parkingList.map((p) => DropdownMenuItem(value: p['id'] as String, child: Text(p['name'], style: const TextStyle(color: Colors.white)))).toList(),
        ),
      ),
    );
  }
}