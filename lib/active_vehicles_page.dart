import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActiveVehiclesPage extends StatelessWidget {
  final String parkingId;
  final Map<String, dynamic> fullData;

  const ActiveVehiclesPage({
    super.key,
    required this.parkingId,
    required this.fullData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Currently Parked"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('parkingId', isEqualTo: parkingId)
            .where('status', isEqualTo: 'parked')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_filled_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No vehicles parked right now.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              DateTime checkIn = (data['checkInTime'] as Timestamp).toDate();
              String vType = data['vehicleType'] ?? "Vehicle";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(_getIcon(vType), color: const Color(0xFF0D47A1)),
                  ),
                  title: Text(data['vehicleNumber'] ?? "N/A",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text("Type: $vType\nIn: ${checkIn.hour}:${checkIn.minute.toString().padLeft(2, '0')}"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showCheckoutConfirm(context, doc.id, data, checkIn),
                    child: const Text("CHECKOUT", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'car': return Icons.directions_car;
      case 'bus': return Icons.directions_bus;
      case 'bike': return Icons.directions_bike;
      case 'van': return Icons.airport_shuttle;
      case 'tuk-tuk': return Icons.electric_rickshaw;
      default: return Icons.local_parking;
    }
  }

  // --- පියවර 1: Checkout එක තහවුරු කිරීමේ Dialog එක ---
  void _showCheckoutConfirm(BuildContext context, String bId, Map<String, dynamic> data, DateTime checkIn) {
    DateTime now = DateTime.now();
    Duration diff = now.difference(checkIn);
    int hours = (diff.inMinutes / 60).ceil();
    if (hours == 0) hours = 1;

    // Rates ගණනය කිරීම
    int firstHour = int.tryParse(fullData['rates']?['firstHour']?.toString() ?? '100') ?? 100;
    int extraHour = int.tryParse(fullData['rates']?['extraHour']?.toString() ?? '80') ?? 80;
    int totalBill = firstHour + ((hours - 1) * extraHour);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Checkout"),
        content: Text("Vehicle: ${data['vehicleNumber']}\nDuration: $hours Hr(s)\nTotal Bill: LKR $totalBill.00"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String vType = data['vehicleType'] ?? 'Car';

              // 1. Update Booking Status
              await FirebaseFirestore.instance.collection('bookings').doc(bId).update({
                'status': 'completed',
                'checkOutTime': FieldValue.serverTimestamp(),
                'totalBill': totalBill,
                'stayDuration': "$hours Hr(s)",
              });

              // 2. Increment Free Slots
              await FirebaseFirestore.instance.collection('parkings').doc(parkingId).update({
                'currentFree.$vType': FieldValue.increment(1),
              });

              if (context.mounted) {
                Navigator.pop(context); // Confirm dialog එක වහනවා
                _showReceiptDialog(context, data, totalBill, hours); // බිල් එක පෙන්වනවා
              }
            },
            child: const Text("Confirm & Pay"),
          ),
        ],
      ),
    );
  }

  // --- පියවර 2: අවසාන බිල් පත (Receipt Dialog) ---
  void _showReceiptDialog(BuildContext context, Map<String, dynamic> data, int bill, int hours) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 10),
            const Text("PAYMENT SUCCESS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            const SizedBox(height: 5),
            Text(fullData['parkingName'] ?? "Parking Receipt", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 30, thickness: 1),

            _receiptRow("Vehicle No", data['vehicleNumber'] ?? "N/A"),
            _receiptRow("Vehicle Type", data['vehicleType'] ?? "N/A"),
            _receiptRow("Duration", "$hours Hr(s)"),
            _receiptRow("Date", DateTime.now().toString().split(' ')[0]),

            const Divider(height: 30, thickness: 1),
            _receiptRow("TOTAL BILL", "LKR $bill.00", isBold: true),
            const SizedBox(height: 25),

            // Print බොත්තම (දැනට UI එක පමණයි)
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () {
                  // මෙතනට Thermal Printer කෝඩ් එක දාන්න පුළුවන්
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Printing Receipt...")));
                },
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text("PRINT BILL", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("DONE", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: isBold ? 18 : 14, color: isBold ? Colors.blue.shade900 : Colors.black87)),
        ],
      ),
    );
  }
}