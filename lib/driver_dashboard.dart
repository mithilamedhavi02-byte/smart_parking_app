import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';

import 'driver_profile_page.dart';
import 'driver_booking_screen.dart';
import 'my_app_icon.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});
  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String _searchCity = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("FIND PARKING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const MyAppIcon(iconData: Icons.person_pin, color: Colors.white, size: 32),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverProfilePage())),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg2.webp'), fit: BoxFit.cover))),
          Container(color: Colors.black.withOpacity(0.75)),
          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                _buildActiveBookingStatus(), // ✅ මේක තමයි පාලනය කරන්නේ
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  child: Align(alignment: Alignment.centerLeft, child: Text("AVAILABLE PARKING HUBS", style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w900))),
                ),
                Expanded(child: _buildParkingList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBookingStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings')
          .where('driverId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'parked'])
          .snapshots(),
      builder: (context, snapshot) {
        // ✅ දත්ත නැත්නම් හෝ ලොග් වුණ ගමන් මුකුත්ම පෙන්වන්නේ නැහැ
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        var bookingDoc = snapshot.data!.docs.first;
        var data = bookingDoc.data() as Map<String, dynamic>;
        String status = data['status'] ?? "";
        String bookingId = bookingDoc.id;

        if (status == 'pending') {
          DateTime expiry = (data['expiryTime'] as Timestamp).toDate();

          // 🛑 දැනටමත් විනාඩි 15 ඉවර නම් Database එකෙන් මකලා දාන්න, පෙන්වන්න එපා
          if (DateTime.now().isAfter(expiry)) {
            FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
            return const SizedBox.shrink();
          }

          return _buildStatusCard(
            title: "RESERVATION EXPIRES IN",
            child: LiveCountdownTimer(expiryTime: expiry, bookingId: bookingId),
            icon: Icons.hourglass_top_rounded, color: Colors.orangeAccent, bookingId: bookingId,
          );
        } else if (status == 'parked') {
          // ✅ වාහනය Park කරාම පෙන්වන Timer එක
          Timestamp? checkIn = data['checkInTime'] as Timestamp?;
          return _buildStatusCard(
            title: "PARKED AT: ${data['parkingName']}",
            child: LiveElapsedTimer(startTime: checkIn?.toDate() ?? DateTime.now()),
            icon: Icons.local_parking_rounded, color: Colors.greenAccent, bookingId: bookingId, isParked: true,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatusCard({required String title, required Widget child, required IconData icon, required Color color, required String bookingId, bool isParked = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: MyAppIcon(iconData: icon, color: color, size: 22)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)), const SizedBox(height: 4), child])),

          // ✅ Cancel Button එක පේන්නේ Pending වෙලාවේ විතරයි
          if (!isParked)
            IconButton(
                onPressed: () => FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete(),
                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 26)
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _searchCity = v.toLowerCase()),
              decoration: const InputDecoration(hintText: "Search city...", hintStyle: TextStyle(color: Colors.white38), prefixIcon: Icon(Icons.search, color: Colors.blueAccent), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParkingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('parkings').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snap.data!.docs.where((doc) {
          var d = doc.data() as Map<String, dynamic>;
          return _searchCity.isEmpty || d['parkingName'].toString().toLowerCase().contains(_searchCity);
        }).toList();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            var d = docs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: const Icon(Icons.local_parking, color: Colors.blueAccent),
                title: Text(d['parkingName'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(d['address'] ?? "", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DriverBookingScreen(parkingData: d, parkingId: docs[i].id))),
              ),
            );
          },
        );
      },
    );
  }
}

// 🕒 Countdown Timer - කාලය ඉවර වුණ ගමන් Delete වෙනවා
class LiveCountdownTimer extends StatefulWidget {
  final DateTime expiryTime;
  final String bookingId;
  const LiveCountdownTimer({super.key, required this.expiryTime, required this.bookingId});
  @override
  State<LiveCountdownTimer> createState() => _LiveCountdownTimerState();
}

class _LiveCountdownTimerState extends State<LiveCountdownTimer> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() { super.initState(); _startTimer(); }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      int diff = widget.expiryTime.difference(DateTime.now()).inSeconds;
      if (diff <= 0) {
        t.cancel();
        // 🗑️ විනාඩි 15 ඉවර වුණ ගමන් Database එකෙන් අයින් කරනවා
        FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).delete();
      } else {
        if (mounted) setState(() => _remaining = diff);
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    String m = (_remaining ~/ 60).toString().padLeft(2, '0');
    String s = (_remaining % 60).toString().padLeft(2, '0');
    return Text("$m:$s MINS", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24));
  }
}

class LiveElapsedTimer extends StatefulWidget {
  final DateTime startTime;
  const LiveElapsedTimer({super.key, required this.startTime});
  @override
  State<LiveElapsedTimer> createState() => _LiveElapsedTimerState();
}

class _LiveElapsedTimerState extends State<LiveElapsedTimer> {
  Timer? _timer;
  Duration _dur = Duration.zero;
  @override
  void initState() { super.initState(); _timer = Timer.periodic(const Duration(seconds: 1), (t) { if (mounted) setState(() => _dur = DateTime.now().difference(widget.startTime)); }); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    String h = _dur.inHours.toString().padLeft(2, '0');
    String m = (_dur.inMinutes % 60).toString().padLeft(2, '0');
    String s = (_dur.inSeconds % 60).toString().padLeft(2, '0');
    return Text("${h}h ${m}m ${s}s", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24));
  }
}