import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'my_app_icon.dart'; // අමතක නොකර import කරගන්න

class EditParkingPage extends StatefulWidget {
  final String parkingId;
  final Map<String, dynamic> currentData;

  const EditParkingPage({super.key, required this.parkingId, required this.currentData});

  @override
  State<EditParkingPage> createState() => _EditParkingPageState();
}

class _EditParkingPageState extends State<EditParkingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _name = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _rateFirst = TextEditingController();
  final TextEditingController _rateExtra = TextEditingController();
  final TextEditingController _rateFullDay = TextEditingController();

  final Map<String, TextEditingController> _vehicleControllers = {
    'Car': TextEditingController(text: '0'),
    'Bike': TextEditingController(text: '0'),
    'Van': TextEditingController(text: '0'),
    'Bus': TextEditingController(text: '0'),
    'Lorry': TextEditingController(text: '0'),
    'Tuk-Tuk': TextEditingController(text: '0'),
  };

  @override
  void initState() {
    super.initState();
    _fillExistingData();
  }

  void _fillExistingData() {
    _name.text = widget.currentData['parkingName']?.toString() ?? "";
    _address.text = widget.currentData['address']?.toString() ?? "";

    final prices = widget.currentData['prices'] as Map<String, dynamic>? ?? {};
    _rateFirst.text = (prices['firstHour'] ?? '0').toString();
    _rateExtra.text = (prices['extraHour'] ?? '0').toString();
    _rateFullDay.text = (prices['fullDay'] ?? '0').toString();

    final capacities = widget.currentData['capacity'] as Map<String, dynamic>? ?? {};
    _vehicleControllers.forEach((key, controller) {
      if (capacities.containsKey(key)) {
        controller.text = capacities[key].toString();
      }
    });
  }

  void updateParking() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Map<String, int> capacities = {};
      _vehicleControllers.forEach((key, controller) {
        capacities[key] = int.tryParse(controller.text) ?? 0;
      });

      await FirebaseFirestore.instance.collection('parkings').doc(widget.parkingId).update({
        'parkingName': _name.text.trim(),
        'address': _address.text.trim(),
        'capacity': capacities,
        'prices': {
          'firstHour': double.tryParse(_rateFirst.text) ?? 0.0,
          'extraHour': double.tryParse(_rateExtra.text) ?? 0.0,
          'fullDay': double.tryParse(_rateFullDay.text) ?? 0.0,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Parking Details Updated Successfully! ✨"), backgroundColor: Colors.blueAccent),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("EDIT PARKING", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const MyAppIcon(iconData: Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Image with Blur
          Container(
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg1.webp'), fit: BoxFit.cover)),
          ),
          Container(color: Colors.black.withValues(alpha: 0.8)),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionHeader("BASIC INFORMATION"),
                  _buildGlassCard([
                    _buildTextField(_name, "Parking Space Name", Icons.business_rounded),
                    const SizedBox(height: 15),
                    _buildTextField(_address, "Full Address", Icons.location_on_rounded, maxLines: 2),
                  ]),

                  _buildSectionHeader("TOTAL CAPACITY (SLOTS)"),
                  _buildGlassCard([_buildVehicleGrid()]),

                  _buildSectionHeader("PRICING STRUCTURE (LKR)"),
                  _buildGlassCard([
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_rateFirst, "1st Hour", Icons.timer_rounded, isNum: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildTextField(_rateExtra, "Add. Hour", Icons.more_time_rounded, isNum: true)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(_rateFullDay, "Full Day Rate", Icons.calendar_today_rounded, isNum: true),
                  ]),

                  const SizedBox(height: 30),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: updateParking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 10,
                      ),
                      child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 15, left: 5),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1)),
  );

  Widget _buildGlassCard(List<Widget> children) => ClipRRect(
    borderRadius: BorderRadius.circular(25),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(children: children),
      ),
    ),
  );

  Widget _buildTextField(TextEditingController ctrl, String lbl, IconData icon, {bool isNum = false, int maxLines = 1}) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    keyboardType: isNum ? TextInputType.number : TextInputType.text,
    validator: (v) => v!.isEmpty ? "Required" : null,
    decoration: InputDecoration(
      labelText: lbl,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      prefixIcon: MyAppIcon(iconData: icon, color: Colors.blueAccent, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent, width: 1)),
    ),
  );

  Widget _buildVehicleGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.6, crossAxisSpacing: 10, mainAxisSpacing: 10),
    itemCount: _vehicleControllers.length,
    itemBuilder: (context, index) {
      String type = _vehicleControllers.keys.elementAt(index);
      return TextFormField(
        controller: _vehicleControllers[type],
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: type,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      );
    },
  );
}