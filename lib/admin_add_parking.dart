import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminAddParking extends StatefulWidget {
  const AdminAddParking({super.key});
  @override
  State<AdminAddParking> createState() => _AdminAddParkingState();
}

class _AdminAddParkingState extends State<AdminAddParking> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _rateFirst = TextEditingController();
  final _rateExtra = TextEditingController();
  final _rateFullDay = TextEditingController();

  bool _isLoading = false;

  final Map<String, TextEditingController> _vehicleControllers = {
    'Car': TextEditingController(text: '0'),
    'Bike': TextEditingController(text: '0'),
    'Van': TextEditingController(text: '0'),
    'Bus': TextEditingController(text: '0'),
    'Lorry': TextEditingController(text: '0'),
    'Tuk-Tuk': TextEditingController(text: '0'),
  };

  void saveParking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      const String autoParkingImage = 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?q=80&w=1000&auto=format&fit=crop';

      Map<String, int> capacities = {};
      _vehicleControllers.forEach((key, controller) {
        int val = int.tryParse(controller.text) ?? 0;
        if (val > 0) capacities[key] = val;
      });

      await FirebaseFirestore.instance.collection('parkings').add({
        'adminId': uid,
        'parkingName': _name.text.trim(),
        'address': _address.text.trim(),
        'capacity': capacities,
        'currentFree': capacities,
        'location': const GeoPoint(6.9271, 79.8612),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Parking Registered Successfully! ✨"), backgroundColor: Colors.green),
      );

    } catch (e) {
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Register Parking", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader("Basic Information"),
            _buildCard([
              _buildTextField(_name, "Parking Space Name", Icons.business),
              const SizedBox(height: 15),
              _buildTextField(_address, "Full Address", Icons.location_on, maxLines: 2),
            ]),
            _buildSectionHeader("Total Capacity (Slots)"),
            _buildCard([_buildVehicleGrid()]),
            _buildSectionHeader("Pricing Structure (LKR)"),
            _buildCard([
              Row(
                children: [
                  Expanded(child: _buildTextField(_rateFirst, "1st Hour", Icons.timer, isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_rateExtra, "Add. Hour", Icons.more_time, isNum: true)),
                ],
              ),
              const SizedBox(height: 15),
              _buildTextField(_rateFullDay, "Full Day Rate", Icons.calendar_today, isNum: true),
            ]),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: saveParking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("REGISTER PARKING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 15),
    child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
  );

  Widget _buildCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
    ),
    child: Column(children: children),
  );

  Widget _buildTextField(TextEditingController ctrl, String lbl, IconData icon, {bool isNum = false, int maxLines = 1}) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    validator: (v) => v!.isEmpty ? "Field Required" : null,
    decoration: InputDecoration(
      labelText: lbl,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );

  Widget _buildVehicleGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.0, crossAxisSpacing: 8, mainAxisSpacing: 8),
    itemCount: _vehicleControllers.length,
    itemBuilder: (context, index) {
      String type = _vehicleControllers.keys.elementAt(index);
      return TextFormField(
        controller: _vehicleControllers[type],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: type,
          labelStyle: const TextStyle(fontSize: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.zero,
        ),
      );
    },
  );
}