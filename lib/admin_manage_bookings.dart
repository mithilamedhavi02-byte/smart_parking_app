import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminManageBookings extends StatefulWidget {
  const AdminManageBookings({super.key});

  @override
  State<AdminManageBookings> createState() => _AdminManageBookingsState();
}

class _AdminManageBookingsState extends State<AdminManageBookings> {

  // 1. විනාඩි 15 ඉක්මවා ගිය බුකින්ස් පරීක්ෂා කර Auto-Cancel කරන ලොජික් එක
  void _checkAutoCancel(List<QueryDocumentSnapshot> docs) {
    DateTime now = DateTime.now();

    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      // Status එක pending නම් පමණක් පරීක්ෂා කරයි
      if (data['status'] == 'pending' && data['timestamp'] != null) {
        DateTime bookingTime = (data['timestamp'] as Timestamp).toDate();

        // දැන් වේලාව සහ බුකින් වේලාව අතර වෙනස විනාඩි 15 ට වඩා වැඩිද?
        if (now.difference(bookingTime).inMinutes >= 15) {
          FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({
            'status': 'expired',
          });
        }
      }
    }
  }

  // 2. බුකින් එකක් Confirm කරන විට Slot එකක් අඩු කිරීම (Transaction ලොජික් එක)
  Future<void> _confirmBooking(String bookingId, String parkingId, String vehicleType) async {
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
    final parkingRef = FirebaseFirestore.instance.collection('parkings').doc(parkingId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot parkingSnap = await transaction.get(parkingRef);

        if (!parkingSnap.exists) return;

        Map<String, dynamic> currentFree = Map<String, dynamic>.from(parkingSnap['currentFree']);

        // අදාළ වාහන වර්ගයට ඉඩ තිබේදැයි බැලීම
        if (currentFree.containsKey(vehicleType) && currentFree[vehicleType] > 0) {
          currentFree[vehicleType] -= 1; // ඉතිරි ඉඩ ප්‍රමාණයෙන් එකක් අඩු කරයි

          transaction.update(bookingRef, {'status': 'confirmed'});
          transaction.update(parkingRef, {'currentFree': currentFree});
        } else {
          // ඉඩ නැතිනම් Error එකක් පෙන්වීමට SnackBar එකක් පාවිච්චි කළ හැක
          throw "No available slots for $vehicleType";
        }
      });

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Booking Confirmed & Slot Updated!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Manage Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // දත්ත ලැබුණු පසු Expired ඒවා තිබේදැයි පරීක්ෂා කරයි
          _checkAutoCancel(snapshot.data!.docs);

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No booking requests available."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var booking = snapshot.data!.docs[index];
              var data = booking.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';
              DateTime bookingTime = (data['timestamp'] as Timestamp).toDate();

              int minutesPassed = DateTime.now().difference(bookingTime).inMinutes;
              int timeLeft = 15 - minutesPassed;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                          child: Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                        ),
                        title: Text(
                          "Vehicle: ${data['vehicleType']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("Status: ${status.toUpperCase()}", style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.w600)),
                            Text("Booked at: ${bookingTime.toString().substring(11, 16)}"),
                          ],
                        ),
                        trailing: (status == 'pending' && timeLeft > 0)
                            ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Text("${timeLeft}m left", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        )
                            : null,
                      ),

                      if (status == 'pending') ...[
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => FirebaseFirestore.instance.collection('bookings').doc(booking.id).update({'status': 'cancelled'}),
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              label: const Text("Reject", style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _confirmBooking(booking.id, data['parkingId'], data['vehicleType']),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              icon: const Icon(Icons.check_circle),
                              label: const Text("Confirm Arrival"),
                            ),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'cancelled':
      case 'expired': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.verified;
      case 'cancelled':
      case 'expired': return Icons.error;
      default: return Icons.hourglass_top;
    }
  }
}