import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
// වැදගත්: ඔයා MyAppIcon හදපු file එක මෙතනට import කරන්න
import 'my_app_icon.dart';

class ActiveBookingStatusScreen extends StatelessWidget {
  final String bookingId;
  const ActiveBookingStatusScreen({super.key, required this.bookingId});

  final Color primaryBlue = const Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("BOOKING STATUS",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
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
                image: NetworkImage('https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&q=80&w=1000'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.75)),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Booking not found", style: TextStyle(color: Colors.white)));
              }

              var data = snapshot.data!.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';

              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusIcon(status),
                              const SizedBox(height: 25),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const Divider(color: Colors.white24, height: 40),
                              _buildDetailRow("Parking", data['parkingName'] ?? "N/A"),
                              _buildDetailRow("Vehicle No", data['vehicleNumber'] ?? "N/A"),
                              _buildDetailRow("Type", data['vehicleType'] ?? "N/A"),
                              const SizedBox(height: 30),
                              _buildStatusMessage(status),
                              if (status == 'completed' || status == 'rejected')
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: primaryBlue,
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("BACK TO HOME", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color color;

    if (status == 'pending') {
      iconData = Icons.hourglass_top_rounded;
      color = Colors.orangeAccent;
    } else if (status == 'parked') {
      iconData = Icons.check_circle_rounded;
      color = Colors.greenAccent;
    } else if (status == 'rejected') {
      iconData = Icons.cancel_rounded;
      color = Colors.redAccent;
    } else {
      iconData = Icons.info_rounded;
      color = Colors.blueAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      // මෙතන MyAppIcon එක පාවිච්චි කරනවා නම් (ඔයාට අලුත් විදිහට හදාගන්න ඕන නිසා)
      child: MyAppIcon(iconData: iconData, size: 80, color: color),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'pending') return Colors.orangeAccent;
    if (status == 'parked') return Colors.greenAccent;
    if (status == 'rejected') return Colors.redAccent;
    return Colors.white;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(String status) {
    String msg = "";
    IconData iconData = Icons.info_outline;
    Color color = Colors.white70;

    if (status == 'pending') {
      msg = "Waiting for Admin approval. Please wait...";
      iconData = Icons.access_time;
    } else if (status == 'parked') {
      msg = "Your parking is active. Enjoy your stay!";
      iconData = Icons.verified_user;
      color = Colors.greenAccent;
    } else if (status == 'completed') {
      msg = "Booking completed. Thank you!";
      iconData = Icons.history;
    } else if (status == 'rejected') {
      msg = "Sorry, your request was declined.";
      iconData = Icons.error_outline;
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // මෙතනත් MyAppIcon එක පාවිච්චි කරමු
          MyAppIcon(iconData: iconData, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}