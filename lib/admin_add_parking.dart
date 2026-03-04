import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'my_app_icon.dart';

class AdminAddParking extends StatefulWidget {
  const AdminAddParking({super.key});
  @override
  State<AdminAddParking> createState() => _AdminAddParkingState();
}

class _AdminAddParkingState extends State<AdminAddParking> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();

  // ✅ Phone Number එක සඳහා අලුත් Controller එක
  final _phone = TextEditingController();

  final _rateFirst = TextEditingController();
  final _rateExtra = TextEditingController();
  final _rateFullDay = TextEditingController();

  final _heightLimit = TextEditingController(text: "No Limit");
  final _operatingHours = TextEditingController(text: "24/7");

  bool _isLoading = false;

  final Map<String, TextEditingController> _vehicleControllers = {
    'Bicycle': TextEditingController(text: '0'),
    'Motorcycle': TextEditingController(text: '0'),
    'Three-Wheeler': TextEditingController(text: '0'),
    'Car': TextEditingController(text: '0'),
    'Van': TextEditingController(text: '0'),
    'Bus': TextEditingController(text: '0'),
    'Truck': TextEditingController(text: '0'),
  };

  final Map<String, bool> _facilities = {
    'CCTV 24/7': false,
    'EV Charging Point': false,
    'Security Guard': false,
    'Indoor (Covered)': false,
    'Disabled Access (♿)': false,
    'Car Wash Service': false,
  };

  Future<void> saveParking() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      Map<String, int> capacities = {};
      int totalSlots = 0;

      _vehicleControllers.forEach((key, controller) {
        int val = int.tryParse(controller.text) ?? 0;
        if (val > 0) {
          capacities[key] = val;
          totalSlots += val;
        }
      });

      List<String> selectedFacilities = [];
      _facilities.forEach((key, value) { if (value) selectedFacilities.add(key); });

      // ✅ Firestore එකට 'phone' field එක ඇතුළත් කිරීම
      await FirebaseFirestore.instance.collection('parkings').add({
        'adminId': uid,
        'parkingName': _name.text.trim(),
        'address': _address.text.trim(),
        'phone': _phone.text.trim(), // අලුතින් එක් කළ කොටස
        'capacity': capacities,
        'currentFree': capacities,
        'totalSlots': totalSlots,
        'facilities': selectedFacilities,
        'heightLimit': _heightLimit.text.trim(),
        'operatingHours': _operatingHours.text.trim(),
        'location': const GeoPoint(6.9271, 79.8612),
        'rates': {
          'firstHour': double.tryParse(_rateFirst.text) ?? 0.0,
          'extraHour': double.tryParse(_rateExtra.text) ?? 0.0,
          'fullDay': double.tryParse(_rateFullDay.text) ?? 0.0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Parking Hub Registered! 🚀"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("REGISTER PARKING HUB", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity, width: double.infinity,
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg1.webp'), fit: BoxFit.cover)),
          ),
          Container(color: Colors.black.withValues(alpha:0.75)),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSection("Basic Details", Icons.business, [
                    _buildTextField(_name, "Parking Name", Icons.drive_file_rename_outline),
                    const SizedBox(height: 12),

                    // ✅ Phone Number Field එක එකතු කළා
                    _buildTextField(_phone, "Contact Number", Icons.phone_android, isNum: true),
                    const SizedBox(height: 12),

                    _buildTextField(_address, "Address", Icons.map_outlined, maxLines: 2),
                  ]),

                  const SizedBox(height: 15),
                  _buildSection("Slot Capacities (One by One)", Icons.directions_car,
                      _vehicleControllers.keys.map((type) => _buildVehicleRow(type)).toList()
                  ),

                  const SizedBox(height: 15),
                  _buildSection("Facilities", Icons.star_border, [
                    _buildFacilitiesWrap(),
                  ]),

                  const SizedBox(height: 15),
                  _buildSection("Advanced info", Icons.shutter_speed, [
                    _buildTextField(_heightLimit, "Height Limit (m)", Icons.height),
                    const SizedBox(height: 12),
                    _buildTextField(_operatingHours, "Operating Hours", Icons.timer),
                  ]),

                  const SizedBox(height: 15),
                  _buildSection("Pricing (LKR)", Icons.money, [
                    _buildTextField(_rateFirst, "First Hour Rate", Icons.looks_one_outlined, isNum: true),
                    const SizedBox(height: 12),
                    _buildTextField(_rateExtra, "Extra Hour Rate", Icons.add_circle_outline, isNum: true),
                    const SizedBox(height: 12),
                    _buildTextField(_rateFullDay, "Full Day Rate", Icons.calendar_month, isNum: true),
                  ]),

                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData iconData, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.07),
            border: Border.all(color: Colors.white.withValues(alpha:0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                MyAppIcon(iconData: iconData, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ]),
              const Divider(color: Colors.white10, height: 25),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String lbl, IconData iconData, {bool isNum = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      validator: (v) => v!.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: lbl, labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: MyAppIcon(iconData: iconData, color: Colors.blueAccent.withValues(alpha:0.7), size: 18),
        ),
        filled: true, fillColor: Colors.white.withValues(alpha:0.03),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
      ),
    );
  }

  Widget _buildVehicleRow(String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(type, style: const TextStyle(color: Colors.white70, fontSize: 14))),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 45,
              child: TextFormField(
                controller: _vehicleControllers[type],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white.withValues(alpha:0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesWrap() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _facilities.keys.map((String key) {
        bool isSelected = _facilities[key]!;
        return InkWell(
          onTap: () {
            setState(() {
              _facilities[key] = !isSelected;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blueAccent.withValues(alpha:0.6)
                  : Colors.white.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.white24,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyAppIcon(
                  iconData: isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: saveParking,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: const Text("REGISTER HUB", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}