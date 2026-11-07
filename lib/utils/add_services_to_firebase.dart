import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/firebase_config.dart';

class AddServicesToFirebase {
  static Future<void> addServices() async {
    await FirebaseConfig.initializeFirebase();
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
        'description': 'Fast food and snacks',
        'location': 'Food Court',
        'minutesPerPerson': 4,
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Muncheez',
        'description': 'Fast food and snacks',
        'location': 'Food Court',
        'minutesPerPerson': 4,
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Quetta',
        'description': 'Tea and snacks',
        'location': 'Food Court',
        'minutesPerPerson': 2,
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Bites and Beans',
        'description': 'Coffee and snacks',
        'location': 'Food Court',
        'minutesPerPerson': 5,
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Accounts Office',
        'description': 'Fee and accounts related queries',
        'location': 'Admin Block',
        'minutesPerPerson': 10,
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'HOD Meeting',
        'description': 'Meetings with Head of Department',
        'location': 'Department Office',
        'minutesPerPerson': 20,
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Rector Meeting',
        'description': 'Meetings with Rector',
        'location': 'Rector Office',
        'minutesPerPerson': 25,
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    print('Adding services to Firebase...');

    for (final service in services) {
      try {
        final name = service['name'] as String;
        final existing = await firestore
            .collection('services')
            .where('name', isEqualTo: name)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          print('Skipped (already exists): $name');
          continue;
        }

        await firestore.collection('services').add(service);
        print('Added: $name');
      } catch (e) {
        print('Error adding ${service['name']}: $e');
      }
    }

    print('Services added successfully!');
  }
}
