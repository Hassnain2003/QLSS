import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  final services = [
    {
      'name': 'Advisor Office',
      'description': 'Course advising and academic guidance',
      'location': 'Main Block',
      'minutesPerPerson': 15,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Deans Canteen',
      'description': 'Food and beverages',
      'location': 'Central Courtyard',
      'minutesPerPerson': 3,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Crispino',
      'description': 'Food and beverages',
      'location': 'Building A',
      'minutesPerPerson': 5,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Bites and Beans',
      'description': 'Coffee and snacks',
      'location': 'Student Center',
      'minutesPerPerson': 5,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Quetta',
      'description': 'Food and beverages',
      'location': 'Building B',
      'minutesPerPerson': 5,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Accounts Office',
      'description': 'Fee payments and accounts queries',
      'location': 'Admin Block',
      'minutesPerPerson': 10,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'HOD Meeting',
      'description': 'Department head meetings',
      'location': 'Department Office',
      'minutesPerPerson': 20,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  ];

  print('Adding services to Firestore...');

  for (final service in services) {
    try {
      await firestore.collection('services').add(service);
      print('Added: ${service['name']}');
    } catch (e) {
      print('Error adding ${service['name']}: $e');
    }
  }

  print('Services added successfully!');
}
