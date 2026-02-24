import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ActiveBookingStatusScreen extends StatelessWidget {
  final String bookingId;

  const ActiveBookingStatusScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Status"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Booking not found."));
          }

          var bookingData = snapshot.data!.data() as Map<String, dynamic>;
          String status = bookingData['status'] ?? 'pending';
          String qrData = bookingData['qrCode'] ?? bookingId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: status == 'confirmed' ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: status == 'confirmed' ? Colors.green.shade900 : Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Scan this QR at the Entrance",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow("Parking", bookingData['parkingName'] ?? 'N/A'),
                        const Divider(),
                        _buildDetailRow("Vehicle No", bookingData['vehicleNumber'] ?? 'N/A'),
                        const Divider(),
                        _buildDetailRow("Vehicle Type", bookingData['vehicleType'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancelBooking(context, bookingId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("CANCEL BOOKING"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // මෙතන 'mounted' check එක දාලා තියෙන්නේ context error එක අයින් කරන්න
  void _cancelBooking(BuildContext context, String id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking?"),
        content: const Text("Are you sure you want to cancel this booking?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NO")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("YES")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('bookings').doc(id).delete();
      if (!context.mounted) return; // context error එක මෙතනින් fix වෙනවා
      Navigator.pop(context);
    }
  }
}