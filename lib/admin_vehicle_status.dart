import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminVehicleStatusScreen extends StatelessWidget {
  const AdminVehicleStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? adminId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Vehicle Capacity Status", style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_spots')
            .where('adminId', isEqualTo: adminId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          int cars = 0, bikes = 0, vans = 0, wheels = 0, buses = 0, trucks = 0, bicycles = 0;

          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            var cap = data['capacity'] as Map<String, dynamic>? ?? {};
            cars += (cap['cars'] as int? ?? 0);
            bikes += (cap['bikes'] as int? ?? 0);
            vans += (cap['vans'] as int? ?? 0);
            wheels += (cap['threeWheels'] as int? ?? 0);
            buses += (cap['buses'] as int? ?? 0);
            trucks += (cap['lorries'] as int? ?? 0);
            bicycles += (cap['bicycles'] as int? ?? 0);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatusCard("Cars", cars, Icons.directions_car, Colors.blue),
                _buildStatusCard("Bikes", bikes, Icons.motorcycle, Colors.orange),
                _buildStatusCard("Vans", vans, Icons.airport_shuttle, Colors.green),
                _buildStatusCard("3-Wheels", wheels, Icons.electric_rickshaw, Colors.amber),
                _buildStatusCard("Buses", buses, Icons.directions_bus, Colors.red),
                _buildStatusCard("Lorries", trucks, Icons.local_shipping, Colors.purple),
                _buildStatusCard("Bicycles", bicycles, Icons.pedal_bike, Colors.teal),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 20),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text("$count", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(width: 5),
          const Text("Spots", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}