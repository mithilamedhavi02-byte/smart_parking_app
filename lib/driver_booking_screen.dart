import 'package:flutter/material.dart';
import 'dart:ui';
import 'vehicle_entry_page.dart';
import 'my_app_icon.dart';

class DriverBookingScreen extends StatelessWidget {
  final Map<String, dynamic> parkingData;
  final String parkingId;

  const DriverBookingScreen({super.key, required this.parkingData, required this.parkingId});

  @override
  Widget build(BuildContext context) {
    final rates = parkingData['rates'] as Map<String, dynamic>? ?? {};
    final facilities = parkingData['facilities'] as List<dynamic>? ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(parkingData['parkingName']?.toUpperCase() ?? "DETAILS",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const MyAppIcon(iconData: Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/bg2.webp'), fit: BoxFit.cover),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.8)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(parkingData['parkingName'] ?? "Unnamed",
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const MyAppIcon(iconData: Icons.location_on_rounded, color: Colors.blueAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(parkingData['address'] ?? "Address not provided",
                                style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const _SectionTitle(title: "FACILITIES AVAILABLE"),
                const SizedBox(height: 12),
                _buildGlassCard(
                  child: facilities.isEmpty
                      ? const Text("Standard Parking Facilities", style: TextStyle(color: Colors.white38))
                      : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: facilities.map((f) => _buildFacilityChip(f.toString())).toList()
                  ),
                ),
                const SizedBox(height: 25),
                const _SectionTitle(title: "PRICING (LKR)"),
                const SizedBox(height: 12),
                _buildGlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPriceItem("First Hour", "${rates['firstHour'] ?? 0}"),
                      Container(width: 1, height: 40, color: Colors.white10),
                      _buildPriceItem("Extra Hour", "${rates['extraHour'] ?? 0}"),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 10,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => _handleBooking(context, rates),
                        child: const Text("BOOK NOW", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleBooking(BuildContext context, Map<String, dynamic> rates) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleEntryPage(
          parkingId: parkingId,
          parkingName: parkingData['parkingName'] ?? "Parking Hub",
          rates: rates,
          parkingData: parkingData, // 👈 මෙම පේළිය අනිවාර්යයි
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildFacilityChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPriceItem(String label, String price) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("Rs.$price", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 20)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
      ],
    );
  }
}