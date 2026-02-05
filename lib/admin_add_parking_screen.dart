import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_parking_details_screen.dart';

class AdminAddParkingScreen extends StatefulWidget {
  const AdminAddParkingScreen({super.key});

  @override
  State<AdminAddParkingScreen> createState() => _AdminAddParkingScreenState();
}

class _AdminAddParkingScreenState extends State<AdminAddParkingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _firstHourRate = TextEditingController();
  final TextEditingController _additionalHourRate = TextEditingController();

  final Map<String, TextEditingController> _capacityControllers = {
    'Cars': TextEditingController(),
    'Motorbikes': TextEditingController(),
    'Three-Wheelers': TextEditingController(),
    'Vans': TextEditingController(),
    'SUVs / Jeeps': TextEditingController(),
    'Buses': TextEditingController(),
    'Lorries (Light)': TextEditingController(),
    'Heavy Vehicles': TextEditingController(),
    'Bicycles': TextEditingController(),
    'Electric Vehicles': TextEditingController(),
  };

  final Map<String, bool> _facilities = {
    'CCTV': false, 'EV Charging': false, 'Security': false, '24/7 Open': false,
  };

  bool _isLoading = false;

  Future<void> _saveParking() async {
    // දත්ත පිරවීම නිවැරදිදැයි පරීක්ෂා කිරීම
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      DocumentReference docRef = FirebaseFirestore.instance.collection('parkings').doc();

      // වාහන ධාරිතාවය Map එකක් ලෙස සකස් කිරීම
      Map<String, dynamic> vehicleStats = {};
      _capacityControllers.forEach((key, ctrl) {
        int cap = int.tryParse(ctrl.text) ?? 0;
        if (cap > 0) {
          vehicleStats[key] = {
            'total': cap,
            'free': cap,
            'booked': 0,
            'pending': 0,
          };
        }
      });

      // පින්තූර නැතිව දත්ත Firestore වෙත සුරැකීම
      await docRef.set({
        'adminId': user?.uid,
        'parkingName': _nameController.text,
        'address': _addressController.text,
        'pricing': {
          'firstHour': double.tryParse(_firstHourRate.text) ?? 0.0,
          'additionalHour': double.tryParse(_additionalHourRate.text) ?? 0.0,
        },
        'vehicleStats': vehicleStats,
        'facilities': _facilities.entries.where((e) => e.value).map((e) => e.key).toList(),
        'imageUrls': [], // හිස් ලැයිස්තුවක් ලෙස තබමු
        'createdAt': FieldValue.serverTimestamp(),
      });

      // සාර්ථක වූ පසු Details Screen එකට Navigate වීම
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminParkingDetailsScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Save Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D100E),
      appBar: AppBar(
        title: const Text("Setup New Parking", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8DE15D)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section("General Info"),
              _input(_nameController, "Parking Name"),
              const SizedBox(height: 10),
              _input(_addressController, "Address"),

              const SizedBox(height: 30),
              _section("Hourly Pricing (LKR)"),
              Row(
                children: [
                  Expanded(child: _input(_firstHourRate, "1st Hour Rate", isNum: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _input(_additionalHourRate, "Additional Rate", isNum: true)),
                ],
              ),

              const SizedBox(height: 30),
              _section("Vehicles (Enter Total Slots)"),
              ..._capacityControllers.entries.map((e) => _vehicleRow(e.key, e.value)),

              const SizedBox(height: 30),
              _section("Facilities"),
              _buildFacilities(),

              const SizedBox(height: 40),
              _submitButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI උදව්කරු කොටස් ---
  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(color: Color(0xFF8DE15D), fontWeight: FontWeight.bold)),
  );

  Widget _input(TextEditingController ctrl, String hint, {bool isNum = false}) => TextFormField(
    controller: ctrl,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white12),
      filled: true,
      fillColor: const Color(0xFF1A1F1C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    validator: (v) => v!.isEmpty ? "Required" : null,
  );

  Widget _vehicleRow(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
        SizedBox(width: 80, child: _input(ctrl, "0", isNum: true)),
      ],
    ),
  );

  Widget _buildFacilities() => Container(
    decoration: BoxDecoration(color: const Color(0xFF1A1F1C), borderRadius: BorderRadius.circular(15)),
    child: Column(
      children: _facilities.keys
          .map((k) => CheckboxListTile(
        title: Text(k, style: const TextStyle(color: Colors.white, fontSize: 14)),
        value: _facilities[k],
        activeColor: const Color(0xFF8DE15D),
        onChanged: (v) => setState(() => _facilities[k] = v!),
      ))
          .toList(),
    ),
  );

  Widget _submitButton() => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: _saveParking,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8DE15D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: const Text("SAVE PARKING", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    ),
  );
}