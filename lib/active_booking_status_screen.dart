import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActiveBookingStatusScreen extends StatelessWidget {
  final String bookingId;
  const ActiveBookingStatusScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking Status")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String status = data['status'];

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusIcon(status),
                const SizedBox(height: 20),
                Text(status.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Parking: ${data['parkingName']}"),
                Text("Vehicle: ${data['vehicleNumber']}"),
                const SizedBox(height: 30),
                if (status == 'parked')
                  const Text("Enjoy your stay! Ticket active.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                if (status == 'completed')
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("BACK TO HOME"),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'pending') return const Icon(Icons.hourglass_empty, size: 80, color: Colors.orange);
    if (status == 'parked') return const Icon(Icons.check_circle, size: 80, color: Colors.green);
    return const Icon(Icons.info, size: 80, color: Colors.grey);
  }
}