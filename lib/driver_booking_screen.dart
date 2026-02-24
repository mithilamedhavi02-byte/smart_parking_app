import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverBookingScreen extends StatefulWidget {
  final Map<String, dynamic> parkingData;
  final String parkingId;

  const DriverBookingScreen({
    super.key,
    required this.parkingData,
    required this.parkingId,
  });

  @override
  State<DriverBookingScreen> createState() => _DriverBookingScreenState();
}

class _DriverBookingScreenState extends State<DriverBookingScreen> {
  final _vehicleNoController = TextEditingController();

  String _selectedType = 'Car';
  bool _isLoading = false;
  bool _termsAccepted = false;

  final List<String> _vehicleTypes = [
    'Car',
    'Bike',
    'Van',
    'Bus',
    'Lorry',
    'Tuk-Tuk',
    'Electric Car'
  ];

  void _confirmBooking() async {
    if (_vehicleNoController.text.trim().isEmpty) {
      _showSnackBar("Please enter vehicle number", Colors.red);
      return;
    }

    if (!_termsAccepted) {
      _showSnackBar("Please accept terms", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      /// ✅ GET ID FROM CONSTRUCTOR (FINAL FIX)
      String parkingDocId = widget.parkingId;

      DocumentReference parkingRef = FirebaseFirestore.instance
          .collection('parkings')
          .doc(parkingDocId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final parkingSnapshot = await transaction.get(parkingRef);

        if (!parkingSnapshot.exists) {
          throw "Parking not found";
        }

        Map<String, dynamic> pData =
        parkingSnapshot.data() as Map<String, dynamic>;

        Map<String, dynamic> currentFree =
        Map<String, dynamic>.from(pData['currentFree'] ?? {});

        int available = (currentFree[_selectedType] ?? 0);

        if (available <= 0) {
          throw "No slots available for $_selectedType";
        }

        /// reduce slot
        currentFree[_selectedType] = available - 1;

        transaction.update(parkingRef, {
          'currentFree': currentFree,
        });

        /// create booking
        DocumentReference bookingRef =
        FirebaseFirestore.instance.collection('bookings').doc();

        transaction.set(bookingRef, {
          'driverId': user?.uid,
          'parkingId': parkingDocId,
          'parkingName': pData['parkingName'],
          'vehicleNumber':
          _vehicleNoController.text.trim().toUpperCase(),
          'vehicleType': _selectedType,
          'status': 'confirmed',
          'bookingTime': FieldValue.serverTimestamp(),
        });
      });

      _showSnackBar("Booking Successful!", Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    }

    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFree =
    widget.parkingData['currentFree'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Booking"),
        foregroundColor: Colors.blue.shade900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// parking name
            Text(
              widget.parkingData['parkingName'] ?? "Parking",
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// vehicle number
            TextField(
              controller: _vehicleNoController,
              decoration: const InputDecoration(
                labelText: "Vehicle Number",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),

            const SizedBox(height: 20),

            /// vehicle type dropdown
            DropdownButtonFormField(
              value: _selectedType,
              items: _vehicleTypes
                  .map((type) => DropdownMenuItem(
                value: type,
                child: Text(
                  "$type  (Free: ${currentFree?[type] ?? 0})",
                ),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedType = value.toString());
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Vehicle Type",
              ),
            ),

            const SizedBox(height: 20),

            /// terms
            CheckboxListTile(
              value: _termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v!),
              title: const Text("I agree to terms and conditions"),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 20),

            /// button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: _confirmBooking,
              child: const Text(
                "CONFIRM & GET QR",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}