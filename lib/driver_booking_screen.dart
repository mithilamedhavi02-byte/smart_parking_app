import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverBookingScreen extends StatefulWidget {
  final Map<String, dynamic> parkingData;
  final String parkingId;

  const DriverBookingScreen({super.key, required this.parkingData, required this.parkingId});

  @override
  State<DriverBookingScreen> createState() => _DriverBookingScreenState();
}

class _DriverBookingScreenState extends State<DriverBookingScreen> {
  final _vehicleNoController = TextEditingController();
  String _selectedType = 'Car';
  bool _isLoading = false;

  void _confirmBooking() async {
    String vehicleNo = _vehicleNoController.text.trim().toUpperCase();

    if (vehicleNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter vehicle number"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      DateTime now = DateTime.now();

      // අලුත් Booking Record එකක් සාදයි
      await FirebaseFirestore.instance.collection('bookings').add({
        'driverId': user?.uid,
        'parkingId': widget.parkingId,
        'parkingName': widget.parkingData['parkingName'],
        'vehicleNumber': vehicleNo,
        'vehicleType': _selectedType,
        'status': 'pending', // Admin ට පෙනීමට 'pending' විය යුතුය
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking Request Sent!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Parking Slot"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.parkingData['parkingName'] ?? "Parking Space",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(widget.parkingData['address'] ?? "", style: const TextStyle(color: Colors.grey)),
            const Divider(height: 40),

            const Text("Vehicle Details", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            TextField(
              controller: _vehicleNoController,
              decoration: InputDecoration(
                labelText: "Vehicle Number (e.g. CAB-1234)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.directions_car),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: "Vehicle Type",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Car', 'Bike', 'Van', 'Bus', 'Lorry', 'Tuk-Tuk']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("SEND REQUEST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}