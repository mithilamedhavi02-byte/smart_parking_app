import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminSetup extends StatefulWidget {
  const AdminSetup({super.key});

  @override
  State<AdminSetup> createState() => _AdminSetupState();
}

class _AdminSetupState extends State<AdminSetup> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _car = TextEditingController();
  final _bike = TextEditingController();

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('parking_lots').doc(uid).set({
      'adminId': uid,
      'parkingName': _name.text,
      'city': _city.text.trim().toLowerCase(),
      'capacity': {'car': int.parse(_car.text), 'bike': int.parse(_bike.text)},
      'occupied': {'car': 0, 'bike': 0},
    });
    await FirebaseFirestore.instance.collection('admins').doc(uid).update({'parking_setup': true});
    Navigator.pushReplacementNamed(context, '/admin-dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Your Parking")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Parking Name")),
          TextField(controller: _city, decoration: const InputDecoration(labelText: "City")),
          TextField(controller: _car, decoration: const InputDecoration(labelText: "Car Capacity"), keyboardType: TextInputType.number),
          TextField(controller: _bike, decoration: const InputDecoration(labelText: "Bike Capacity"), keyboardType: TextInputType.number),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: _save, child: const Text("Complete Setup"))
        ]),
      ),
    );
  }
}