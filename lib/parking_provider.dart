import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // බුකින් එකක් ක්‍රියාත්මක කිරීම සහ Firestore එකට යැවීම
  Future<void> createBooking(String spotId, String vehicleType, String userId, double rate) async {
    try {
      final String bookingId = "BK-${DateTime.now().millisecondsSinceEpoch}";

      await _db.collection('bookings').doc(bookingId).set({
        'bookingId': bookingId,
        'userId': userId,
        'spotId': spotId,
        'vehicleType': vehicleType,
        'status': 'pending', // මුලින්ම pending status එක
        'rate': rate,
        'startTime': FieldValue.serverTimestamp(),
      });

      debugPrint("Booking Created: $bookingId");

      // විනාඩි 10ක Auto-Cancel Timer එක
      Timer(const Duration(minutes: 10), () => _handleAutoCancel(bookingId));

    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // ඇඩ්මින් confirm කළේ නැත්නම් විනාඩි 10න් පසු cancel කිරීම
  Future<void> _handleAutoCancel(String bookingId) async {
    var doc = await _db.collection('bookings').doc(bookingId).get();

    if (doc.exists && doc.data()?['status'] == 'pending') {
      await _db.collection('bookings').doc(bookingId).update({'status': 'cancelled'});
      debugPrint("Booking $bookingId auto-cancelled due to delay.");
      notifyListeners();
    }
  }

  // බිල් එක ගණනය කිරීමේ Logic එක ($inline$ LaTeX භාවිතා කර ඇත)
  // Bill = $Hours \times Rate$
  double calculateBill(DateTime start, DateTime end, double rate) {
    final double hours = end.difference(start).inMinutes / 60;
    if (hours < 0.1) return rate * 0.1; // අවම ගාස්තුවක් ලෙස විනාඩි කිහිපයකටත් අය කිරීම
    return hours * rate;
  }
}