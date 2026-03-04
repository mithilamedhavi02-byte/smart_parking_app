import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'my_app_icon.dart'; // අමතක නොකර MyAppIcon එක import කරගන්න

class BookingBillScreen extends StatelessWidget {
  final String bookingId;
  const BookingBillScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Background Blur & Gradient
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.85)),

          // 2. Main Content
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Bill not found", style: TextStyle(color: Colors.white)));
              }

              var data = snapshot.data!.data() as Map<String, dynamic>;
              double billAmount = (data['totalBill'] ?? 0).toDouble();

              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        // Success Icon with Glow
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.greenAccent.withValues(alpha: 0.1),
                            boxShadow: [
                              BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 5)
                            ],
                          ),
                          child: const MyAppIcon(iconData: Icons.check_circle_rounded, color: Colors.greenAccent, size: 80),
                        ),
                        const SizedBox(height: 25),
                        const Text("PAYMENT CONFIRMED",
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 10),
                        const Text("Transaction successful and space released.",
                            style: TextStyle(color: Colors.white38, fontSize: 13)),

                        const SizedBox(height: 40),

                        // Digital Receipt Card
                        _buildReceiptCard(data, billAmount, context),

                        const SizedBox(height: 40),

                        // Back Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 10,
                            ),
                            child: const Text("DONE & BACK TO DASHBOARD",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
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

  Widget _buildReceiptCard(Map<String, dynamic> data, double amount, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Text("LKR ${amount.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
              const Text("TOTAL AMOUNT PAID", style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),

              const SizedBox(height: 30),
              const Divider(color: Colors.white10, thickness: 1),
              const SizedBox(height: 20),

              _buildInfoRow("Vehicle Number", data['vehicleNumber'] ?? "N/A"),
              _buildInfoRow("Vehicle Type", data['vehicleType'] ?? "N/A"),
              _buildInfoRow("Status", "COMPLETED"),
              _buildInfoRow("Reference ID", bookingId.substring(0, 8).toUpperCase()),

              const SizedBox(height: 20),
              const Divider(color: Colors.white10, thickness: 1),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MyAppIcon(iconData: Icons.history_edu_rounded, color: Colors.white24, size: 18),
                  const SizedBox(width: 8),
                  Text("Digital Receipt Generated Successfully",
                      style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}