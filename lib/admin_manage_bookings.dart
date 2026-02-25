import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminManageBookings extends StatefulWidget {
  const AdminManageBookings({super.key});

  @override
  State<AdminManageBookings> createState() => _AdminManageBookingsState();
}

class _AdminManageBookingsState extends State<AdminManageBookings> {
  final String? currentAdminUid = FirebaseAuth.instance.currentUser?.uid;

  // --- Confirm Logic: මෙය තමයි බොත්තම එබූ විට ක්‍රියාත්මක වන්නේ ---
  Future<void> _confirmArrival(String bookingId, String parkingId, String vehicleType) async {
    // 1. Loading Dialog එකක් පෙන්වමු
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      final parkingRef = FirebaseFirestore.instance.collection('parkings').doc(parkingId);

      // 2. Transaction එකක් හරහා දත්ත ආරක්ෂිතව update කරමු
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot parkingSnap = await transaction.get(parkingRef);

        if (!parkingSnap.exists) {
          throw Exception("Parking place not found!");
        }

        Map<String, dynamic> currentFree = Map<String, dynamic>.from(parkingSnap['currentFree'] ?? {});

        // Slot එකක් තිබේදැයි බලමු
        if (currentFree.containsKey(vehicleType) && (currentFree[vehicleType] ?? 0) > 0) {
          currentFree[vehicleType] -= 1; // එකක් අඩු කරයි

          // --- මෙතන තමයි වැදගත්ම වෙනස කළේ ---
          transaction.update(bookingRef, {
            'status': 'parked',
            'checkInTime': FieldValue.serverTimestamp(), // කාලය ගණනය කිරීමට මෙය අත්‍යවශ්‍යයි
          });

          // Parking එකේ slots ප්‍රමාණය update කරයි
          transaction.update(parkingRef, {'currentFree': currentFree});
        } else {
          throw Exception("No free slots available for $vehicleType");
        }
      });

      if (mounted) {
        Navigator.pop(context); // Loading එක අයින් කරන්න
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Arrival Confirmed!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading එක අයින් කරන්න
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
      debugPrint("Confirm Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ARRIVAL REQUESTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parkings')
            .where('adminId', isEqualTo: currentAdminUid)
            .snapshots(),
        builder: (context, parkSnap) {
          if (parkSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (!parkSnap.hasData || parkSnap.data!.docs.isEmpty) {
            return const Center(child: Text("No Parking Registered for this Admin"));
          }

          String myParkingId = parkSnap.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('parkingId', isEqualTo: myParkingId)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, bookingSnap) {
              if (bookingSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              if (!bookingSnap.hasData || bookingSnap.data!.docs.isEmpty) {
                return const Center(child: Text("No new requests. Waiting for arrivals..."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: bookingSnap.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = bookingSnap.data!.docs[index];
                  var data = doc.data() as Map<String, dynamic>;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.directions_car, color: Colors.orange.shade800),
                        ),
                        title: Text(
                          data['vehicleNumber'] ?? "UNKNOWN",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text("Vehicle: ${data['vehicleType']}"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _confirmArrival(doc.id, myParkingId, data['vehicleType']),
                          child: const Text("CONFIRM"),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}