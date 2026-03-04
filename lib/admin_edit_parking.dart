import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'my_app_icon.dart';

class AdminEditParking extends StatefulWidget {
  final String parkingId;
  final Map<String, dynamic> currentData;

  const AdminEditParking({super.key, required this.parkingId, required this.currentData});

  @override
  State<AdminEditParking> createState() => _AdminEditParkingState();
}

class _AdminEditParkingState extends State<AdminEditParking> {
  final _formKey = GlobalKey<FormState>();

  // Basic Controllers
  late TextEditingController _name;
  late TextEditingController _address;
  late TextEditingController _heightLimit;
  late TextEditingController _operatingHours;

  // Pricing Controllers
  late TextEditingController _rateFirst;
  late TextEditingController _rateExtra;
  late TextEditingController _rateFullDay;

  bool _isLoading = false;

  // Vehicle Slots Controllers
  late Map<String, TextEditingController> _vehicleControllers;

  // Facilities
  late Map<String, bool> _facilities;

  @override
  void initState() {
    super.initState();

    // කලින් තිබුණු data වලින් Controllers පිරවීම
    _name = TextEditingController(text: widget.currentData['parkingName']);
    _address = TextEditingController(text: widget.currentData['address']);
    _heightLimit = TextEditingController(text: widget.currentData['heightLimit'] ?? "No Limit");
    _operatingHours = TextEditingController(text: widget.currentData['operatingHours'] ?? "24/7");

    var rates = widget.currentData['rates'] ?? {};
    _rateFirst = TextEditingController(text: rates['firstHour']?.toString() ?? '0');
    _rateExtra = TextEditingController(text: rates['extraHour']?.toString() ?? '0');
    _rateFullDay = TextEditingController(text: rates['fullDay']?.toString() ?? '0');

    // Slots පිරවීම (totalSlotsMap එකෙන් ගන්නවා)
    Map<String, dynamic> existingSlots = widget.currentData['totalSlotsMap'] ?? widget.currentData['capacity'] ?? {};
    _vehicleControllers = {
      'Bicycle': TextEditingController(text: (existingSlots['Bicycle'] ?? 0).toString()),
      'Motorcycle': TextEditingController(text: (existingSlots['Motorcycle'] ?? 0).toString()),
      'Three-Wheeler': TextEditingController(text: (existingSlots['Three-Wheeler'] ?? 0).toString()),
      'Car': TextEditingController(text: (existingSlots['Car'] ?? 0).toString()),
      'Van': TextEditingController(text: (existingSlots['Van'] ?? 0).toString()),
      'Bus': TextEditingController(text: (existingSlots['Bus'] ?? 0).toString()),
      'Truck': TextEditingController(text: (existingSlots['Truck'] ?? 0).toString()),
    };

    // Facilities පිරවීම
    List<dynamic> existingFacilities = widget.currentData['facilities'] ?? [];
    _facilities = {
      'CCTV 24/7': existingFacilities.contains('CCTV 24/7'),
      'EV Charging Point': existingFacilities.contains('EV Charging Point'),
      'Security Guard': existingFacilities.contains('Security Guard'),
      'Indoor (Covered)': existingFacilities.contains('Indoor (Covered)'),
      'Disabled Access (♿)': existingFacilities.contains('Disabled Access (♿)'),
      'Car Wash Service': existingFacilities.contains('Car Wash Service'),
    };
  }

  Future<void> updateParking() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Map<String, int> updatedCapacities = {};
      int totalSlots = 0;

      _vehicleControllers.forEach((key, controller) {
        int val = int.tryParse(controller.text) ?? 0;
        updatedCapacities[key] = val;
        totalSlots += val;
      });

      List<String> selectedFacilities = [];
      _facilities.forEach((key, value) { if (value) selectedFacilities.add(key); });

      await FirebaseFirestore.instance.collection('parkings').doc(widget.parkingId).update({
        'parkingName': _name.text.trim(),
        'address': _address.text.trim(),
        'totalSlotsMap': updatedCapacities, // Dashboard එකට ඕන නිසා
        'capacity': updatedCapacities,
        'totalSlots': totalSlots,
        'facilities': selectedFacilities,
        'heightLimit': _heightLimit.text.trim(),
        'operatingHours': _operatingHours.text.trim(),
        'rates': {
          'firstHour': double.tryParse(_rateFirst.text) ?? 0.0,
          'extraHour': double.tryParse(_rateExtra.text) ?? 0.0,
          'fullDay': double.tryParse(_rateFullDay.text) ?? 0.0,
        },
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Parking Details Updated! ✨"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
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
        title: const Text("EDIT PARKING HUB", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          Container(color: Colors.black.withOpacity(0.75)),

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
                    _buildTextField(_address, "Address", Icons.map_outlined, maxLines: 2),
                  ]),

                  const SizedBox(height: 15),
                  _buildSection("Slot Capacities", Icons.directions_car,
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

  // --- Helper Widgets (ඔයාගේ Register පේජ් එකේ තියෙන විදියටම) ---

  Widget _buildSection(String title, IconData iconData, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
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
          child: MyAppIcon(iconData: iconData, color: Colors.blueAccent.withOpacity(0.7), size: 18),
        ),
        filled: true, fillColor: Colors.white.withOpacity(0.03),
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
                  filled: true, fillColor: Colors.white.withOpacity(0.05),
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
          onTap: () => setState(() => _facilities[key] = !isSelected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent.withOpacity(0.6) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyAppIcon(iconData: isSelected ? Icons.check_circle : Icons.add_circle_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(key, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
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
        onPressed: updateParking,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}