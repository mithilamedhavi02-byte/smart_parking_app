import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key}); // Key warning එක fix කළා

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Firestore එකේ තියෙන සියලුම බුකින් Real-time ලබා ගැනීම
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading data"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No active bookings at the moment."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';
              String id = docs[index].id;

              return _buildBookingCard(context, id, data, status);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, String docId, Map<String, dynamic> data, String status) {
    Color statusColor = status == 'pending' ? Colors.orange : (status == 'parked' ? Colors.green : Colors.grey);
    String buttonText = status == 'pending' ? "Confirm Arrival" : "Checkout";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        title: Text("Vehicle: ${data['vehicleType'].toString().toUpperCase()}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text("Status: ${status.toUpperCase()}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
            Text("ID: $docId", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: status == 'pending' ? const Color(0xFF2B65A3) : Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          onPressed: () => _updateBookingStatus(docId, status),
          child: Text(buttonText),
        ),
      ),
    );
  }

  // බුකින් ස්ටේටස් එක වෙනස් කිරීමේ function එක
  Future<void> _updateBookingStatus(String id, String currentStatus) async {
    final db = FirebaseFirestore.instance.collection('bookings');
    if (currentStatus == 'pending') {
      await db.doc(id).update({'status': 'parked', 'arrivalTime': FieldValue.serverTimestamp()});
    } else if (currentStatus == 'parked') {
      await db.doc(id).update({'status': 'completed', 'exitTime': FieldValue.serverTimestamp()});
    }
  }
}