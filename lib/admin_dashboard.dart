import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

// Pages
import 'active_vehicles_page.dart';
import 'admin_manage_bookings.dart';
import 'admin_add_parking.dart';
import 'admin_profile_page.dart';
import 'settings_page.dart';
import 'my_app_icon.dart';
import 'admin_edit_parking.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final String? adminUid = FirebaseAuth.instance.currentUser?.uid;

  void _showDailyRevenue(double totalAmount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: const Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),
              const Text("Daily Revenue", style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 15),
              Text(
                "LKR ${totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Color(0xFF00E5FF)),
              ),
              const Text("Total Earnings Today", style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 35),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("CLOSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF020617), // Deepest Navy
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddParking())),
        backgroundColor: const Color(0xFF00E5FF),
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF0F172A), size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: Stack(
        children: [
          // 1. Animated Radial Background Effect
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.5),
                radius: 1.2,
                colors: [
                  Color(0xFF1E293B),
                  Color(0xFF020617),
                ],
              ),
            ),
          ),

          // 2. Corner Glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('parkings')
                .where('adminId', isEqualTo: adminUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

              var parkingDoc = snapshot.data!.docs.first;
              var parkingId = parkingDoc.id;
              var pData = parkingDoc.data() as Map<String, dynamic>;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('parkingId', isEqualTo: parkingId)
                    .snapshots(),
                builder: (context, bookingSnap) {
                  double dailyRevenue = 0.0;
                  int currentlyParked = 0;
                  int pendingBookings = 0;
                  int exitedToday = 0;
                  DateTime now = DateTime.now();
                  DateTime startOfToday = DateTime(now.year, now.month, now.day);

                  if (bookingSnap.hasData) {
                    for (var doc in bookingSnap.data!.docs) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      if (data['status'] == 'completed' && data['totalBill'] != null) {
                        Timestamp? outTS = data['checkOutTime'] as Timestamp?;
                        if (outTS != null && outTS.toDate().isAfter(startOfToday)) {
                          dailyRevenue += (data['totalBill']).toDouble();
                          exitedToday++;
                        }
                      }
                      if (data['status'] == 'parked') currentlyParked++;
                      if (data['status'] == 'pending') pendingBookings++;
                    }
                  }

                  return Scaffold(
                    backgroundColor: Colors.transparent,
                    bottomNavigationBar: _buildBottomBar(dailyRevenue),
                    body: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildHeader(pData, parkingId),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOccupancyCard(currentlyParked, pData),
                                _buildDetailedOccupancy(pData, bookingSnap.data!.docs),
                                const SizedBox(height: 35),
                                _buildSectionTitle("Quick Actions"),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    _buildActionCard("Arrivals", Icons.login_rounded, Colors.orangeAccent, const AdminManageBookings()),
                                    const SizedBox(width: 10),
                                    _buildActionCard("Manual", Icons.edit_note_rounded, Colors.greenAccent, AdminManualEntry(parkingId: parkingId, parkingData: pData)),
                                    const SizedBox(width: 10),
                                    _buildActionCard("Live View", Icons.remove_red_eye_rounded, const Color(0xFF00E5FF), ActiveVehiclesPage(parkingId: parkingId, fullData: pData)),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                _buildSectionTitle("Today's Analytics"),
                                const SizedBox(height: 18),
                                _buildStatusGrid(currentlyParked, pendingBookings, dailyRevenue, exitedToday),
                                const SizedBox(height: 120),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }



// --- Header with Glassmorphism ---
  Widget _buildHeader(Map<String, dynamic> data, String pId) {
    final String parkingName = (data['parkingName'] ?? "PARKING HUB").toUpperCase();

    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF020617),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminEditParking(parkingId: pId, currentData: data))),
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfilePage())),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: TweenAnimationBuilder<int>(
          duration: const Duration(milliseconds: 1500),
          tween: IntTween(begin: 0, end: parkingName.length),
          builder: (context, value, child) {
            return Text(
              parkingName.substring(0, value),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2.5,
                color: Colors.white,
                fontFamily: 'Orbitron', // Professional Cyber/Tech look එකක් සඳහා (නැතිනම් 'Inter' හෝ 'Montserrat' භාවිතා කරන්න)
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.blueAccent,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            );
          },
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/parking_header.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1E293B))
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.2), const Color(0xFF020617)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }





  Widget _buildOccupancyCard(int current, Map<String, dynamic> data) {
    int total = int.tryParse(data['totalSlots']?.toString() ?? '1') ?? 1;
    double percent = (current / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Overall Occupancy", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${(percent * 100).toInt()}%", style: TextStyle(color: percent > 0.8 ? Colors.redAccent : const Color(0xFF00E5FF), fontWeight: FontWeight.w900, fontSize: 22)),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.white10,
              color: percent > 0.8 ? Colors.redAccent : const Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(height: 15),
          Text("$current Total Slots Occupied out of $total", style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }







  Widget _buildDetailedOccupancy(Map<String, dynamic> data, List<QueryDocumentSnapshot> bookings) {
    final Map<String, dynamic> slotsMap = data['totalSlotsMap'] ?? data['capacity'] ?? {};

    if (slotsMap.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Slots Breakdown", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 15),
          ...slotsMap.entries.map((entry) {
            String type = entry.key.toString();
            int total = int.tryParse(entry.value.toString()) ?? 0;

            // --- මෙන්න මෙතනදී තමයි වැදගත්ම දේ වෙන්නේ ---
            // දැනට ලැබී ඇති සියලුම bookings වලින් 'parked' තත්වයේ තියෙන,
            // මෙම වාහන වර්ගයට (type) අදාළ වාහන ගණන ගණනය කරනවා:
            int occupied = bookings.where((doc) {
              Map<String, dynamic> d = doc.data() as Map<String, dynamic>;
              return d['status'] == 'parked' && d['vehicleType'] == type;
            }).length;

            double progress = total > 0 ? (occupied / total).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(type, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      Text("$occupied / $total Full",
                          style: TextStyle(
                              color: progress > 0.8 ? Colors.orangeAccent : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      color: progress > 0.9 ? Colors.redAccent : (progress > 0.7 ? Colors.orangeAccent : const Color(0xFF00E5FF)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }







  Widget _buildActionCard(String t, IconData i, Color c, Widget p) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.withOpacity(0.15), c.withOpacity(0.02)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: c.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, color: c, size: 28)),
              const SizedBox(height: 8),
              Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusGrid(int current, int pending, double revenue, int completed) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard("PARKED", "$current", Icons.directions_car_filled_rounded, const Color(0xFF00E5FF)),
            const SizedBox(width: 15),
            _buildStatCard("PENDING", "$pending", Icons.hourglass_empty_rounded, Colors.orangeAccent),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildStatCard("DAILY REVENUE", "Rs. ${revenue.toInt()}", Icons.account_balance_wallet_rounded, Colors.greenAccent),
            const SizedBox(width: 15),
            _buildStatCard("EXITED TODAY", "$completed", Icons.check_circle_rounded, Colors.purpleAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String val, IconData iconData, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: col.withOpacity(0.2), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(iconData, color: col, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(val, style: TextStyle(color: col, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double revenue) {
    return BottomAppBar(
      color: const Color(0xFF0F172A).withOpacity(0.9),
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.grid_view_rounded, color: Color(0xFF00E5FF), size: 26), onPressed: () {}),
          IconButton(icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white54, size: 26), onPressed: () => _showDailyRevenue(revenue)),
          const SizedBox(width: 50),
          IconButton(icon: const Icon(Icons.history_rounded, color: Colors.white54, size: 26), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageBookings()))),
          IconButton(icon: const Icon(Icons.settings_rounded, color: Colors.white54, size: 26), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Row(
    children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(10))),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    ],
  );

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_business_rounded, size: 100, color: Colors.white10),
          const SizedBox(height: 25),
          const Text("No Parking Lot Registered", style: TextStyle(color: Colors.white38, fontSize: 18)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddParking())),
            child: const Text("Create Parking Now", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

// AdminManualEntry logic stays same but with updated UI colors
class AdminManualEntry extends StatefulWidget {
  final String parkingId;
  final Map<String, dynamic> parkingData;
  const AdminManualEntry({super.key, required this.parkingId, required this.parkingData});
  @override State<AdminManualEntry> createState() => _AdminManualEntryState();
}
class _AdminManualEntryState extends State<AdminManualEntry> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleController = TextEditingController();
  String? _selectedType;
  bool _isLoading = false;
  List<String> _availableVehicleTypes = [];

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> slotsMap = widget.parkingData['totalSlotsMap'] ?? widget.parkingData['capacity'] ?? {};
    _availableVehicleTypes = slotsMap.keys.where((type) => (int.tryParse(slotsMap[type].toString()) ?? 0) > 0).toList();
    if (_availableVehicleTypes.isNotEmpty) _selectedType = _availableVehicleTypes.first;
  }










  void _submitManualEntry() async {
    if (_formKey.currentState!.validate() && _selectedType != null) {
      setState(() => _isLoading = true);

      try {
        // 1. දැනට මෙම වාහන වර්ගයට (e.g. Car, Bike) අදාළව දැනට පාර්ක් කර ඇති ප්‍රමාණය බලන්න
        final snapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('parkingId', isEqualTo: widget.parkingId)
            .where('vehicleType', isEqualTo: _selectedType)
            .where('status', isEqualTo: 'parked')
            .get();

        int currentlyOccupied = snapshot.docs.length;

        // 2. අදාළ වර්ගයට වෙන් කර ඇති මුළු slots ප්‍රමාණය ලබා ගන්න
        Map<String, dynamic> slotsMap = widget.parkingData['totalSlotsMap'] ?? widget.parkingData['capacity'] ?? {};
        int totalAllowed = int.tryParse(slotsMap[_selectedType].toString()) ?? 0;

        // 3. ඉඩ තිබේදැයි පරීක්ෂා කරන්න
        if (currentlyOccupied >= totalAllowed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("NO SLOTS AVAILABLE FOR $_selectedType!"),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() => _isLoading = false);
          return; // මෙතනින් නවත්වන්න, Save කරන්න එපා
        }

        // 4. ඉඩ තිබේ නම් පමණක් save කරන්න
        await FirebaseFirestore.instance.collection('bookings').add({
          'parkingId': widget.parkingId,
          'vehicleNumber': _vehicleController.text.trim().toUpperCase(),
          'vehicleType': _selectedType,
          'status': 'parked',
          'checkInTime': Timestamp.now(),
          'type': 'manual',
          'parkingName': widget.parkingData['parkingName']
        });

        if (mounted) Navigator.pop(context);

      } catch (e) {
        debugPrint(e.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error processing entry"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }









  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("MANUAL ENTRY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg1.webp'), fit: BoxFit.cover))),
          Container(color: const Color(0xFF020617).withOpacity(0.85)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white10)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _vehicleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(labelText: "Vehicle Number", labelStyle: const TextStyle(color: Colors.white38), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF)))),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 30),
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(labelText: "Vehicle Type", labelStyle: const TextStyle(color: Colors.white38)),
                            items: _availableVehicleTypes.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                            onChanged: (v) => setState(() => _selectedType = v),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _isLoading ? null : _submitManualEntry, child: _isLoading ? const CircularProgressIndicator() : const Text("CONFIRM & PARK", style: TextStyle(fontWeight: FontWeight.bold)))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}