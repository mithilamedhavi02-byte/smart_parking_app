import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'my_app_icon.dart';

class VehicleEntryPage extends StatefulWidget {
  final String parkingId;
  final String parkingName;
  final Map<String, dynamic> rates;
  final Map<String, dynamic> parkingData;

  const VehicleEntryPage({
    super.key,
    required this.parkingId,
    required this.parkingName,
    required this.rates,
    required this.parkingData,
  });

  @override
  State<VehicleEntryPage> createState() => _VehicleEntryPageState();
}

class _VehicleEntryPageState extends State<VehicleEntryPage> {
  final _numController = TextEditingController();
  List<String> _vehicleTypes = [];
  String? _selectedType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  void _loadVehicleTypes() {
    // ✅ FIX: ඔයාගේ DB එකේ තියෙන්නේ 'capacity' කියන field එක නිසා ඒක මුලින්ම ගන්නවා
    Map<String, dynamic> slots = widget.parkingData['capacity'] ??
        widget.parkingData['totalSlotsMap'] ?? {};

    setState(() {
      _vehicleTypes = slots.keys.toList();
      if (_vehicleTypes.isNotEmpty) {
        _selectedType = _vehicleTypes[0];
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_numController.text.isEmpty) {
      _showSnackBar("Please enter vehicle number");
      return;
    }

    if (_selectedType == null) {
      _showSnackBar("No vehicle types available");
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. දැනට එම වාහන වර්ගයෙන් වෙන් කර ඇති (Pending) සහ නවතා ඇති (Parked) ගණන බැලීම
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('parkingId', isEqualTo: widget.parkingId)
          .where('vehicleType', isEqualTo: _selectedType)
          .where('status', whereIn: ['pending', 'parked'])
          .get();

      int occupiedCount = snapshot.docs.length;

      // ✅ 2. FIX: Admin ලබා දී ඇති 'capacity' එකෙන් අදාළ වාහන වර්ගයට ඇති ඉඩ ප්‍රමාණය ගැනීම
      Map<String, dynamic> slotsMap = widget.parkingData['capacity'] ??
          widget.parkingData['totalSlotsMap'] ?? {};

      // String එකක් විදිහට හෝ Int එකක් විදිහට තිබුණත් හරියටම ගණන ගන්නවා
      int totalCapacity = int.tryParse(slotsMap[_selectedType].toString()) ?? 0;

      // DEBUG PRINT: Logic එක වැඩද කියලා බලන්න Console එක බලන්න
      print("Type: $_selectedType | Total: $totalCapacity | Occupied: $occupiedCount");

      // 3. ඉඩ තිබේදැයි පරීක්ෂා කිරීම
      if (occupiedCount >= totalCapacity) {
        if (mounted) {
          _showErrorDialog(
              "No Slots Available",
              "Sorry, all $_selectedType slots are full at ${widget.parkingName}. Please try another vehicle type or location."
          );
        }
        setState(() => _loading = false);
        return;
      }

      // 4. ඉඩ තිබේ නම් පමණක් Booking එක සිදු කිරීම
      final user = FirebaseAuth.instance.currentUser;
      final expiry = DateTime.now().add(const Duration(minutes: 15));

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking Confirmed!"), backgroundColor: Colors.green),
        );
        // මුල් Screen එකටම යනවා
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("VEHICLE ENTRY",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const MyAppIcon(iconData: Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/bg2.webp'), fit: BoxFit.cover),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.8)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ENTER VEHICLE NUMBER",
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 15),
                  _buildGlassInput(
                    child: TextField(
                      controller: _numController,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: "Ex: WP ABC-1234",
                        hintStyle: TextStyle(color: Colors.white24),
                        prefixIcon: Icon(Icons.directions_car, color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text("SELECT VEHICLE TYPE",
                      style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 15),
                  _buildGlassInput(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        dropdownColor: const Color(0xFF1E293B),
                        isExpanded: true,
                        hint: const Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Text("Select Type", style: TextStyle(color: Colors.white24)),
                        ),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: Text(type.toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedType = v),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        elevation: 8,
                        shadowColor: Colors.blueAccent.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("CONFIRM RESERVATION",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}