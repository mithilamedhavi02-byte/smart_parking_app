import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingBillScreen extends StatelessWidget {
  final String bookingId;
  const BookingBillScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D100E),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 100),
                const Text("Payment Confirmed", style: TextStyle(color: Colors.white, fontSize: 24)),
                const SizedBox(height: 20),
                Text("Total: LKR ${data['totalBill']}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("BACK TO DASHBOARD"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}