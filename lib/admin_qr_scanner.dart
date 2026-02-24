import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class AdminQRScanner extends StatefulWidget {
  const AdminQRScanner({super.key});

  @override
  State<AdminQRScanner> createState() => _AdminQRScannerState();
}

class _AdminQRScannerState extends State<AdminQRScanner> {
  bool isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    // පේජ් එක ලෝඩ් වෙද්දීම අවසර ඉල්ලමු
    _checkPermission();
  }

  // අවසර ඉල්ලන ෆන්ෂන් එක
  Future<void> _checkPermission() async {
    // කැමරාවට අවසර ඉල්ලීම
    final status = await Permission.camera.request();

    setState(() {
      isPermissionGranted = status.isGranted;
    });

    // පර්මිෂන් එක ලැබුණේ නැත්නම් කෙලින්ම සෙටින්ග්ස් වලට යවන එක හොඳයි
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR"),
        backgroundColor: Colors.blue.shade900,
      ),
      // පර්මිෂන් එක තියෙනවා නම් ස්කෑනරය පෙන්වනවා, නැත්නම් බටන් එක පෙන්වනවා
      body: isPermissionGranted
          ? MobileScanner(
        onDetect: (capture) {
          // මෙතන ස්කෑන් කිරීමෙන් පසු දත්ත Firestore එකට යැවීමේ ලොජික් එක දාන්න
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            debugPrint('Barcode found! ${barcode.rawValue}');
          }
        },
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Camera permission is required!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              // මෙන්න මෙතන බටන් එක ක්ලික් කළාම ආයේ පර්මිෂන් චෙක් කරනවා
              onPressed: () => _checkPermission(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("Grant Permission"),
            ),
          ],
        ),
      ),
    );
  }
}