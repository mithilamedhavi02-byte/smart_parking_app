import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'my_app_icon.dart';

class ActiveVehiclesPage extends StatefulWidget {
  final String parkingId;
  final Map<String, dynamic> fullData;

  const ActiveVehiclesPage({
    super.key,
    required this.parkingId,
    required this.fullData,
  });

  @override
  State<ActiveVehiclesPage> createState() => _ActiveVehiclesPageState();
}

class _ActiveVehiclesPageState extends State<ActiveVehiclesPage> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  String _searchQuery = ""; // 👈 Search query එක save කරගන්න variable එක

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("LIVE PARKED VEHICLES",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Background Image UI
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/bg1.webp'),
                  fit: BoxFit.cover
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.85)),

          // 2. Data Content
          SafeArea(
            child: Column(
              children: [
                // --- Search Bar Section ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toUpperCase(); // 👈 Type කරන අකුරු uppercase කරලා query එක update කරනවා
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Search Vehicle Number...",
                        hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),

                // --- Live Stream List ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('parkingId', isEqualTo: widget.parkingId)
                        .where('status', isEqualTo: 'parked')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                      }

                      // දත්ත filter කිරීම
                      var filteredDocs = snapshot.data?.docs.where((doc) {
                        var vNumber = (doc.data() as Map<String, dynamic>)['vehicleNumber']?.toString().toUpperCase() ?? "";
                        return vNumber.contains(_searchQuery); // 👈 මෙතනින් තමයි search එකට අදාළ වාහන විතරක් පෙන්නන්නේ
                      }).toList() ?? [];

                      if (filteredDocs.isEmpty) {
                        return _buildEmptyState(_searchQuery.isEmpty ? "No Active Vehicles" : "No Match Found");
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          var doc = filteredDocs[index];
                          var data = doc.data() as Map<String, dynamic>;

                          DateTime checkIn = (data['checkInTime'] as Timestamp?)?.toDate() ??
                              (data['entryTime'] as Timestamp?)?.toDate() ??
                              DateTime.now();

                          String vType = data['vehicleType'] ?? "Car";
                          return _buildVehicleCard(context, doc.id, data, checkIn, vType);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- පහත Methods කලින් තිබූ ආකාරයටම පවතී (අවශ්‍ය තැන්වල widget.parkingId ආදේශ කර ඇත) ---

  Widget _buildVehicleCard(BuildContext context, String bId, Map<String, dynamic> data, DateTime checkIn, String vType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                  child: MyAppIcon(iconData: _getIcon(vType), color: Colors.blueAccent, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['vehicleNumber'] ?? "UNKNOWN",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.5)),
                      const SizedBox(height: 3),
                      Text("$vType • Since ${checkIn.hour}:${checkIn.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                  ),
                  onPressed: () => _showCheckoutConfirm(context, bId, data, checkIn),
                  child: const Text("OUT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckoutConfirm(BuildContext context, String bId, Map<String, dynamic> data, DateTime checkIn) {
    DateTime now = DateTime.now();
    Duration diff = now.difference(checkIn);
    int hours = diff.inHours;
    if (diff.inMinutes % 60 > 0) hours++;
    if (hours == 0) hours = 1;

    int firstHour = int.tryParse(widget.fullData['rates']?['firstHour']?.toString() ?? '100') ?? 100;
    int extraHour = int.tryParse(widget.fullData['rates']?['extraHour']?.toString() ?? '80') ?? 80;
    int totalBill = firstHour + ((hours - 1) * extraHour);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: Colors.white10)),
          title: const Text("Confirm Checkout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow("Vehicle No", data['vehicleNumber']),
              _infoRow("Check-in", "${checkIn.hour}:${checkIn.minute.toString().padLeft(2, '0')}"),
              _infoRow("Duration", "$hours Hour(s)"),
              const Divider(color: Colors.white10, height: 30),
              _infoRow("TOTAL PAYABLE", "LKR $totalBill.00", isGold: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                String vType = data['vehicleType'] ?? 'Car';
                await FirebaseFirestore.instance.collection('bookings').doc(bId).update({
                  'status': 'completed',
                  'checkOutTime': FieldValue.serverTimestamp(),
                  'totalBill': totalBill,
                  'stayDuration': "$hours Hr(s)",
                });
                await FirebaseFirestore.instance.collection('parkings').doc(widget.parkingId).update({
                  'currentFree.$vType': FieldValue.increment(1),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  _showReceiptDialog(context, data, totalBill, hours);
                }
              },
              child: const Text("Confirm Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ---Receipt UI, Icon helper and row widgets ---
  void _showReceiptDialog(BuildContext context, Map<String, dynamic> data, int bill, int hours) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MyAppIcon(iconData: Icons.check_circle_rounded, color: Colors.green, size: 70),
              const SizedBox(height: 10),
              const Text("PAYMENT SUCCESS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
              const Text("ParkPro Official Receipt", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)),
              const SizedBox(height: 25),
              _receiptRow("Vehicle Number", data['vehicleNumber'] ?? "N/A"),
              _receiptRow("Stay Duration", "$hours Hour(s)"),
              _receiptRow("Payment Method", "Cash"),
              const Divider(height: 35, thickness: 1, color: Colors.black12),
              _receiptRow("TOTAL AMOUNT", "LKR $bill.00", isBold: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const MyAppIcon(iconData: Icons.print_rounded, size: 18, color: Colors.white),
                  label: const Text("PRINT RECEIPT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MyAppIcon(iconData: Icons.local_parking_rounded, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 15),
          Text(msg, style: const TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'car': return Icons.directions_car_filled_rounded;
      case 'bike': return Icons.motorcycle_rounded;
      case 'van': return Icons.airport_shuttle_rounded;
      case 'bus': return Icons.directions_bus_rounded;
      case 'tuk-tuk': return Icons.electric_rickshaw_rounded;
      default: return Icons.local_parking_rounded;
    }
  }

  Widget _infoRow(String label, String? val, {bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(val ?? "N/A", style: TextStyle(color: isGold ? Colors.orangeAccent : Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black45, fontSize: 13)),
          Text(value, style: TextStyle(color: Colors.black87, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, fontSize: isBold ? 18 : 13)),
        ],
      ),
    );
  }
}