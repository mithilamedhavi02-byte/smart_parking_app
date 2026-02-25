import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCheckoutPage extends StatelessWidget {
  const AdminCheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Currently Parked")),
      body: StreamBuilder<QuerySnapshot>(
        // දැනට පාර්ක් කර ඇති (status = parked) වාහන පමණක් පෙන්වයි
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('status', isEqualTo: 'parked')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var booking = snapshot.data!.docs[index];
              var data = booking.data() as Map<String, dynamic>;

              // පැමිණි වෙලාව (Check-in Time)
              DateTime checkIn = (data['checkInTime'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Vehicle: ${data['vehicleNumber']}"),
                  subtitle: Text("In: ${checkIn.hour}:${checkIn.minute}"),
                  trailing: ElevatedButton(
                    onPressed: () => _processCheckout(context, booking.id, data, checkIn),
                    child: const Text("Checkout"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // බිල් එක හැදීම සහ පිටවීම තහවුරු කිරීම
  void _processCheckout(BuildContext context, String bId, Map<String, dynamic> data, DateTime checkIn) async {
    DateTime now = DateTime.now();
    Duration duration = now.difference(checkIn);

    // පැය ගණන ගණනය කිරීම (අවම පැය 1ක් ලෙස ගනිමු)
    int hours = duration.inHours;
    if (duration.inMinutes % 60 > 0) hours++;
    if (hours == 0) hours = 1;

    // ගාස්තුව ගණනය කිරීම (උදාහරණයකට පැයට රු. 100 බැගින්)
    int ratePerHour = 100;
    int totalBill = hours * ratePerHour;

    // Checkout එක Confirm කරන්න Dialog එකක් පෙන්වමු
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Final Bill"),
        content: Text("Duration: $hours hour(s)\nTotal Amount: RS $totalBill"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // 1. Booking එක 'completed' කරන්න
              await FirebaseFirestore.instance.collection('bookings').doc(bId).update({
                'status': 'completed',
                'checkOutTime': FieldValue.serverTimestamp(),
                'totalBill': totalBill,
              });

              // 2. Parking slot එකක් ආපහු නිදහස් (Free) කරන්න
              String pId = data['parkingId'];
              String vType = data['vehicleType'];

              await FirebaseFirestore.instance.collection('parkings').doc(pId).update({
                'currentFree.$vType': FieldValue.increment(1),
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checkout Successful!")));
            },
            child: const Text("Complete & Release Slot"),
          ),
        ],
      ),
    );
  }
}