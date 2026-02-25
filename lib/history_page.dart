import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  final String parkingId;
  const HistoryPage({super.key, required this.parkingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History"), backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings')
            .where('parkingId', isEqualTo: parkingId)
            .where('status', isEqualTo: 'completed').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              var data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['vehicleNumber']),
                subtitle: Text(DateFormat('yyyy-MM-dd').format((data['checkOutTime'] as Timestamp).toDate())),
                trailing: Text("LKR ${data['totalBill']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              );
            },
          );
        },
      ),
    );
  }
}
