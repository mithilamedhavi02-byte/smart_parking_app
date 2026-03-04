import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'my_app_icon.dart';

class VehicleEntryPage extends StatefulWidget {
  final String parkingId;
  final String parkingName;
  final Map<String, dynamic> rates;

  const VehicleEntryPage({super.key, required this.parkingId, required this.parkingName, required this.rates});

  @override
  State<VehicleEntryPage> createState() => _VehicleEntryPageState();
}

class _VehicleEntryPageState extends State<VehicleEntryPage> {
  final _numController = TextEditingController();

  // ✅ නිවැරදි වාහන වර්ග ලැයිස්තුව
  final List<String> _vehicleTypes = ["Car", "Bus", "Van", "Bike", "Three-Wheel"];
  String? _selectedType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = _vehicleTypes[0]; // පලමු අගය Default ලෙස තබමු
  }

  Future<void> _confirmBooking() async {
    if (_numController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter vehicle number")));
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();
      final expiry = now.add(const Duration(minutes: 15)); // විනාඩි 15 කින් පසු ඉකුත් වේ

      await FirebaseFirestore.instance.collection('bookings').add({
        'parkingId': widget.parkingId,
        'parkingName': widget.parkingName,
        'driverId': user?.uid,
        'vehicleNumber': _numController.text.toUpperCase(),
        'vehicleType': _selectedType,
        'status': 'pending',
        'expiryTime': Timestamp.fromDate(expiry),
        'createdAt': FieldValue.serverTimestamp(),
        'rates': widget.rates,
      });

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text("VEHICLE ENTRY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), centerTitle: true, backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg2.webp'), fit: BoxFit.cover))),
          Container(color: Colors.black.withOpacity(0.8)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ENTER DETAILS", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildGlassInput(
                    child: TextField(
                      controller: _numController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "Ex: WP ABC-1234", hintStyle: TextStyle(color: Colors.white24), prefixIcon: Icon(Icons.directions_car, color: Colors.blueAccent), border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text("VEHICLE TYPE", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildGlassInput(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        dropdownColor: const Color(0xFF1E293B),
                        isExpanded: true,
                        items: _vehicleTypes.map((type) => DropdownMenuItem(value: type, child: Padding(padding: const EdgeInsets.only(left: 15), child: Text(type.toUpperCase(), style: const TextStyle(color: Colors.white))))).toList(),
                        onChanged: (v) => setState(() => _selectedType = v),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: _loading ? null : _confirmBooking, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRM RESERVATION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput({required Widget child}) {
    return Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.1))), child: child);
  }
}