import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import 'my_app_icon.dart';
import 'vehicle_entry_page.dart';

class AdminQRScanner extends StatefulWidget {
  const AdminQRScanner({super.key});

  @override
  State<AdminQRScanner> createState() => _AdminQRScannerState();
}

class _AdminQRScannerState extends State<AdminQRScanner> {
  bool isPermissionGranted = false;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      isPermissionGranted = status.isGranted;
    });
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  // --- QR එක ස්කෑන් වුණාම සිදුවන ප්‍රධාන ලොජික් එක ---
  void _handleScannedData(String scannedBookingId) async {
    setState(() => isScanning = false);

    // Loading Indicator එකක් පෙන්වීම
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );

    try {
      // Bookings collection එකෙන් අදාළ ලේඛනය ලබා ගැනීම
      var doc = await FirebaseFirestore.instance.collection('bookings').doc(scannedBookingId).get();

      if (!mounted) return;
      Navigator.pop(context); // Loading indicator එක ඉවත් කිරීම

      if (doc.exists) {
        var data = doc.data()!;

        // දැනටමත් පාවිච්චි කර ඇත්නම් හෝ cancel කර ඇත්නම් පරීක්ෂා කිරීම
        if (data['status'] != 'pending') {
          _showError("This booking is already ${data['status']}.");
          return;
        }

        // ✅ නිවැරදි කළ කොටස: VehicleEntryPage එකට අවශ්‍ය සියලුම දත්ත ලබා දීම
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleEntryPage(
              parkingId: data['parkingId'],
              parkingName: data['parkingName'],
              rates: data['rates'] ?? {},
              parkingData: data, // 👈 මෙන්න මේ Argument එක තමයි අඩු වෙලා තිබුණේ
            ),
          ),
        );
      } else {
        _showError("Invalid QR Code. Booking not found.");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Connection Error. Please try again.");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // තත්පර 2කින් පස්සේ නැවත ස්කෑන් කිරීමට ඉඩ දීම
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => isScanning = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("SCAN BOOKING QR",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
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
          if (isPermissionGranted)
            MobileScanner(
              onDetect: (capture) {
                if (!isScanning) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _handleScannedData(barcode.rawValue!);
                    break;
                  }
                }
              },
            )
          else
            _buildPermissionRequest(),

          if (isPermissionGranted) _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(color: Colors.black),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30)
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                _buildCorner(top: 0, left: 0, angle: 0),
                _buildCorner(top: 0, right: 0, angle: 1.57),
                _buildCorner(bottom: 0, left: 0, angle: 4.71),
                _buildCorner(bottom: 0, right: 0, angle: 3.14),
              ],
            ),
          ),
        ),
        const Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Text("Place the QR code inside the frame",
                style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5)),
          ),
        )
      ],
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right, required double angle}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.blueAccent, width: 6),
              left: BorderSide(color: Colors.blueAccent, width: 6),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(15)),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MyAppIcon(iconData: Icons.camera_enhance_rounded, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 25),
            const Text("Camera Access Needed",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("To scan parking tickets, we need your camera permission.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _checkPermission,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: const Text("ALLOW CAMERA", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}