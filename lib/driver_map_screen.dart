import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverBookingScreen extends StatefulWidget {
  final Map<String, dynamic> parkingData;

  const DriverBookingScreen({super.key, required this.parkingData});

  @override
  State<DriverBookingScreen> createState() => _DriverBookingScreenState();
}

class _DriverBookingScreenState extends State<DriverBookingScreen> {
  final _vehicleNoController = TextEditingController();
  bool _termsAccepted = false;
  bool _isLoading = false;

  String _selectedType = "Car";

  @override
  void initState() {
    super.initState();
    print("RECEIVED DATA: ${widget.parkingData}");
  }

  void _confirmBooking() async {
    if (_vehicleNoController.text.isEmpty) {
      _showSnackBar("Enter vehicle number", Colors.red);
      return;
    }

    String parkingId = widget.parkingData['parkingId'] ?? "";

    if (parkingId.isEmpty) {
      _showSnackBar("Parking not selected", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      DocumentReference parkingRef =
      FirebaseFirestore.instance.collection('parkings').doc(parkingId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(parkingRef);

        if (!snapshot.exists) {
          throw "Parking not found";
        }

        Map<String, dynamic> data =
        snapshot.data() as Map<String, dynamic>;

        Map<String, dynamic> free =
        Map<String, dynamic>.from(data['currentFree'] ?? {});

        int available = free[_selectedType] ?? 0;

        if (available <= 0) {
          throw "No slots available";
        }

        free[_selectedType] = available - 1;

        transaction.update(parkingRef, {"currentFree": free});

        final bookingRef =
        FirebaseFirestore.instance.collection('bookings').doc();

        transaction.set(bookingRef, {
          "driverId": user?.uid,
          "parkingId": parkingId,
          "parkingName": data['parkingName'],
          "vehicleNumber":
          _vehicleNoController.text.trim().toUpperCase(),
          "vehicleType": _selectedType,
          "status": "confirmed",
          "bookingTime": FieldValue.serverTimestamp(),
        });
      });

      _showSnackBar("Booking Successful", Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    }

    setState(() => _isLoading = false);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Booking")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(widget.parkingData['parkingName'] ?? ""),
            const SizedBox(height: 20),
            TextField(
              controller: _vehicleNoController,
              decoration: const InputDecoration(
                  labelText: "Vehicle Number",
                  border: OutlineInputBorder()),
            ),
            CheckboxListTile(
              value: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v!),
              title: const Text("Accept terms"),
            ),
            ElevatedButton(
              onPressed: _termsAccepted ? _confirmBooking : null,
              child: const Text("CONFIRM BOOKING"),
            )
          ],
        ),
      ),
    );
  }
}