import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  // Controllers කලින්ම initialize කරනවා LateInitializationError මඟහරින්න
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
    // Basic Info
    _name.text = widget.currentData['parkingName']?.toString() ?? "";
    _address.text = widget.currentData['address']?.toString() ?? "";

    // Pricing (Null check එකක් දාලා ආරක්ෂිතව අගයන් ගන්නවා)
    final prices = widget.currentData['prices'] as Map<String, dynamic>? ?? {};
    _rateFirst.text = (prices['firstHour'] ?? '0').toString();
    _rateExtra.text = (prices['extraHour'] ?? '0').toString();
    _rateFullDay.text = (prices['fullDay'] ?? '0').toString();

    // Capacity (Vehicle Grid)
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
        const SnackBar(content: Text("Parking Details Updated! ✨"), backgroundColor: Colors.blue),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
        title: const Text("Edit Parking Info", style: TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: updateParking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("UPDATE PARKING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods (ඔයාගේ Add Page එකේ UI එකමයි) ---

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