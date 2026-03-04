import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
// අමතක නොකර MyAppIcon එක import කරගන්න
import 'my_app_icon.dart';

class AdminManageBookings extends StatefulWidget {
  const AdminManageBookings({super.key});

  @override
  State<AdminManageBookings> createState() => _AdminManageBookingsState();
}

class _AdminManageBookingsState extends State<AdminManageBookings> {
  final String? currentAdminUid = FirebaseAuth.instance.currentUser?.uid;

  // Arrival එක Confirm කරන Logic එක
  Future<void> _confirmArrival(String bookingId, String parkingId, String vehicleType) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );

    try {
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      final parkingRef = FirebaseFirestore.instance.collection('parkings').doc(parkingId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot parkingSnap = await transaction.get(parkingRef);
        if (!parkingSnap.exists) throw Exception("Parking not found!");

        Map<String, dynamic> currentFree = Map<String, dynamic>.from(parkingSnap['currentFree'] ?? {});

        // වාහන වර්ගය අනුව slot එකක් අඩු කරනවා
        // Case sensitivity අවුල් නොවෙන්න මෙතන safe කලා
        String vType = vehicleType;

        if (currentFree.containsKey(vType) && (currentFree[vType] ?? 0) > 0) {
          currentFree[vType] -= 1;
          transaction.update(bookingRef, {
            'status': 'parked',
            'checkInTime': FieldValue.serverTimestamp(),
          });
          transaction.update(parkingRef, {'currentFree': currentFree});
        } else {
          throw Exception("No slots available for $vType");
        }
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Arrival Confirmed! 🚗"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("ARRIVAL REQUESTS",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.8)),

          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parkings')
                  .where('adminId', isEqualTo: currentAdminUid)
                  .snapshots(),
              builder: (context, parkSnap) {
                if (parkSnap.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator(color: Colors.white));

                if (!parkSnap.hasData || parkSnap.data!.docs.isEmpty)
                  return _buildEmptyState("No Parking Registered for you");

                String myParkingId = parkSnap.data!.docs.first.id;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('parkingId', isEqualTo: myParkingId)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, bookingSnap) {
                    if (bookingSnap.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator(color: Colors.white));

                    if (!bookingSnap.hasData || bookingSnap.data!.docs.isEmpty)
                      return _buildEmptyState("No new requests.\nWaiting for arrivals...");

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: bookingSnap.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = bookingSnap.data!.docs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        return _buildRequestCard(doc.id, myParkingId, data);
                      },
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

  Widget _buildRequestCard(String bId, String pId, Map<String, dynamic> data) {
    // වාහන වර්ගය Null ද කියලා check කරලා default අගයක් ගන්නවා (Fix for Null Error)
    String vType = data['vehicleType'] ?? 'Car';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                  child: MyAppIcon(iconData: _getIcon(vType), color: Colors.orangeAccent, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['vehicleNumber'] ?? "UNKNOWN",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("Type: $vType",
                          style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _confirmArrival(bId, pId, vType),
                  child: const Text("CONFIRM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MyAppIcon(iconData: Icons.hourglass_empty_rounded, size: 80, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 15),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'car': return Icons.directions_car_filled_rounded;
      case 'bike': return Icons.motorcycle_rounded;
      case 'bus': return Icons.directions_bus_filled_rounded;
      case 'van': return Icons.airport_shuttle_rounded;
      case 'tuk-tuk': return Icons.electric_rickshaw_rounded;
      default: return Icons.local_parking_rounded;
    }
  }
}