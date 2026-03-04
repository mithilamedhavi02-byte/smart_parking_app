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

  // ආදායම පෙන්වන Bottom Sheet එක
  void _showDailyRevenue(double totalAmount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.95),
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
                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.greenAccent),
              ),
              const Text("Total Earnings Today", style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 35),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    side: const BorderSide(color: Colors.blueAccent),
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
      backgroundColor: const Color(0xFF0F172A),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddParking())),
        backgroundColor: Colors.blueAccent,
        elevation: 12,
        child: const MyAppIcon(iconData: Icons.add_location_alt_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parkings')
            .where('adminId', isEqualTo: adminUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
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

              // අද දවසේ ආරම්භක කාලය (00:00:00)
              DateTime now = DateTime.now();
              DateTime startOfToday = DateTime(now.year, now.month, now.day);

              if (bookingSnap.hasData) {
                for (var doc in bookingSnap.data!.docs) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                  // දවසේ ආදායම (completed සහ checkOutTime එක අද දවසට අයිති නම්)
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
                            _buildDetailedOccupancy(pData),
                            const SizedBox(height: 35),
                            _buildSectionTitle("Quick Actions"),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                _buildActionCard("Arrivals", Icons.login_rounded, Colors.orangeAccent, const AdminManageBookings()),
                                const SizedBox(width: 10),
                                _buildActionCard(
                                    "Manual",
                                    Icons.edit_note_rounded,
                                    Colors.greenAccent,
                                    AdminManualEntry(parkingId: parkingId, parkingData: pData)
                                ),
                                const SizedBox(width: 10),
                                _buildActionCard("Live View", Icons.remove_red_eye_rounded, Colors.cyanAccent, ActiveVehiclesPage(parkingId: parkingId, fullData: pData)),
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
    );
  }

  // --- Utility Widgets ---

  Widget _buildActionCard(String t, IconData i, Color c, Widget p) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
          borderRadius: BorderRadius.circular(25),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [c.withOpacity(0.25), c.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: c.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: c.withOpacity(0.2), shape: BoxShape.circle),
                  child: MyAppIcon(iconData: i, color: c, size: 28),
                ),
                const SizedBox(height: 8),
                Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedOccupancy(Map<String, dynamic> data) {
    // Firestore එකේ තියෙන data වලට අනුව field names හරියටම ගන්න
    final Map<String, dynamic> slotsMap = data['totalSlotsMap'] ?? data['capacity'] ?? {};
    final Map<String, dynamic> currentFree = data['currentFree'] ?? {};

    // slotsMap එක හිස් නම් මේ widget එක පෙන්වන්නේ නැහැ
    if (slotsMap.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Slots Breakdown",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 15),

          // මෙතන කලින් තිබුණ 'totalSlots' වෙනුවට 'slotsMap' කියලා නිවැරදි කළා
          ...slotsMap.entries.map((entry) {
            String type = entry.key.toString();
            int total = int.tryParse(entry.value.toString()) ?? 0;

            // ඉතිරි ඉඩ ප්‍රමාණය (currentFree) නැත්නම් මුළු ප්‍රමාණයම free කියලා ගන්නවා
            int free = int.tryParse(currentFree[type]?.toString() ?? entry.value.toString()) ?? total;

            int occupied = total - free;
            if (occupied < 0) occupied = 0; // ඍණ අගයන් වැළැක්වීමට

            double progress = total > 0 ? (occupied / total).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(type, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      Text(
                          "$occupied / $total Full",
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
                      // පිරීගෙන එනකොට පාට වෙනස් වෙනවා
                      color: progress > 0.9
                          ? Colors.redAccent
                          : (progress > 0.7 ? Colors.orangeAccent : Colors.blueAccent),
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

  Widget _buildHeader(Map<String, dynamic> data, String pId) {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0F172A),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminEditParking(parkingId: pId, currentData: data)),
          ),
        ),
        // Logout වෙනුවට Profile Button එක
        IconButton(
          icon: const MyAppIcon(iconData: Icons.account_circle_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfilePage())),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          (data['parkingName'] ?? "PARKING HUB").toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2.0, color: Colors.white),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/parking_header.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.blueGrey)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), const Color(0xFF0F172A).withOpacity(0.95)],
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Overall Occupancy", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${(percent * 100).toInt()}%", style: TextStyle(color: percent > 0.8 ? Colors.redAccent : Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 22)),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.white10,
              color: percent > 0.8 ? Colors.redAccent : Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 15),
          Text("$current Total Slots Occupied out of $total", style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusGrid(int current, int pending, double revenue, int completed) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard("PARKED", "$current", Icons.directions_car_filled_rounded, Colors.blueAccent),
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: col.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: MyAppIcon(iconData: iconData, color: col, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
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
      color: const Color(0xFF1E293B),
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const MyAppIcon(iconData: Icons.grid_view_rounded, color: Colors.blueAccent, size: 28), onPressed: () {}),
          IconButton(icon: const MyAppIcon(iconData: Icons.account_balance_wallet_rounded, color: Colors.white54), onPressed: () => _showDailyRevenue(revenue)),
          const SizedBox(width: 45),
          IconButton(icon: const MyAppIcon(iconData: Icons.history_rounded, color: Colors.white54), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageBookings()))),
          IconButton(icon: const MyAppIcon(iconData: Icons.settings_rounded, color: Colors.white54), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Row(
    children: [
      Container(width: 5, height: 20, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(10))),
      const SizedBox(width: 12),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    ],
  );

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MyAppIcon(iconData: Icons.add_business_rounded, size: 100, color: Colors.white10),
          const SizedBox(height: 25),
          const Text("No Parking Lot Registered", style: TextStyle(color: Colors.white38, fontSize: 18)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddParking())),
            child: const Text("Create Parking Now"),
          )
        ],
      ),
    );
  }
}

// --- Manual Entry Page (Dynamic Dropdown) ---
class AdminManualEntry extends StatefulWidget {
  final String parkingId;
  final Map<String, dynamic> parkingData;

  const AdminManualEntry({super.key, required this.parkingId, required this.parkingData});

  @override
  State<AdminManualEntry> createState() => _AdminManualEntryState();
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
    _availableVehicleTypes = slotsMap.keys.where((type) {
      int count = int.tryParse(slotsMap[type].toString()) ?? 0;
      return count > 0;
    }).toList();

    if (_availableVehicleTypes.isNotEmpty) {
      _selectedType = _availableVehicleTypes.first;
    }
  }

  void _submitManualEntry() async {
    if (_formKey.currentState!.validate() && _selectedType != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('bookings').add({
          'parkingId': widget.parkingId,
          'vehicleNumber': _vehicleController.text.trim().toUpperCase(),
          'vehicleType': _selectedType,
          'status': 'parked',
          'checkInTime': Timestamp.now(),
          'type': 'manual',
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vehicle Added Successfully!"), backgroundColor: Colors.greenAccent),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("MANUAL ENTRY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          Container(decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg1.webp'), fit: BoxFit.cover))),
          Container(color: Colors.black.withOpacity(0.7)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _vehicleController,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: InputDecoration(
                                prefixIcon: const Padding(padding: EdgeInsets.all(12.0), child: MyAppIcon(iconData: Icons.directions_car_filled, color: Colors.blueAccent)),
                                labelText: "Vehicle Number",
                                labelStyle: const TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
                              ),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                            const SizedBox(height: 30),
                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Vehicle Type",
                                labelStyle: const TextStyle(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
                              ),
                              items: _availableVehicleTypes.map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(color: Colors.white)))).toList(),
                              onChanged: (v) => setState(() => _selectedType = v),
                              validator: (v) => v == null ? "Select Type" : null,
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity, height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                                onPressed: _isLoading ? null : _submitManualEntry,
                                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRM & PARK", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
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