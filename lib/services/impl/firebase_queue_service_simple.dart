import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/appointment.dart';
import '../../models/service.dart';
import '../queue_service.dart' as qs;

class SimpleFirebaseQueueService implements qs.QueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Service>> getServices() {
    return _firestore
        .collection('services')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Service(
                  id: _canonicalServiceIdFromName(doc['name'] as String, fallbackId: doc.id),
                  name: doc['name'] as String,
                  description: doc['description'] as String,
                  location: doc['location'] as String,
                  minutesPerPerson: doc['minutesPerPerson'] as int,
                ))
            .toList());
  }

  @override
  Future<void> markInProgress(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'inProgress',
      'updatedAt': Timestamp.now(),
    });
  }

  String _canonicalServiceIdFromName(String name, {required String fallbackId}) {
    final normalized = name.toLowerCase().trim();
    switch (normalized) {
      case 'advisor office':
        return 'advisor_office';
      case 'accounts office':
        return 'accounts_office';
      case 'hod meeting':
        return 'hod_meeting';
      case 'crispino':
        return 'canteen_crispino';
      case 'deans canteen':
        return 'canteen_deans';
      case 'bites and beans':
        return 'canteen_bites_beans';
      case 'quetta':
        return 'canteen_quetta';
      default:
        return fallbackId;
    }
  }

  String _serviceNameFromCanonicalId(String serviceId) {
    switch (serviceId) {
      case 'advisor_office':
        return 'Advisor Office';
      case 'accounts_office':
        return 'Accounts Office';
      case 'hod_meeting':
        return 'HOD Meeting';
      case 'canteen_crispino':
        return 'Crispino';
      case 'canteen_deans':
        return 'Deans Canteen';
      case 'canteen_bites_beans':
        return 'Bites and Beans';
      case 'canteen_quetta':
        return 'Quetta';
      default:
        return '';
    }
  }

  @override
  Stream<List<Appointment>> getStudentAppointments(String userId) {
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _documentToAppointment(doc))
            .toList());
  }

  @override
  Future<Appointment> bookAppointment({
    required String userId,
    required String userName,
    required String userEmail,
    String? userEnrollment,
    required Service service,
    required DateTime scheduledTime,
    List<int>? seatNumbers,
    int? durationMinutes,
  }) async {
    print('=== SIMPLE BOOKING START ===');
    print('User: $userName ($userEmail)');
    print('Service: ${service.name}');
    print('Time: $scheduledTime');

    try {
      // Simple token assignment
      final tokenNumber = DateTime.now().millisecondsSinceEpoch % 10000;
      print('Token: $tokenNumber');

      final appointmentData = {
        'serviceId': service.id,
        'serviceName': service.name,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'userEnrollment': userEnrollment,
        'createdAt': Timestamp.now(),
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'tokenNumber': tokenNumber,
        'status': 'pending',
        if (seatNumbers != null) 'seatNumbers': seatNumbers,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
      };

      print('Creating appointment...');
      final docRef = await _firestore.collection('appointments').add(appointmentData);
      print('Created: ${docRef.id}');

      final appointment = Appointment(
        id: docRef.id,
        serviceId: service.id,
        serviceName: service.name,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userEnrollment: userEnrollment,
        createdAt: DateTime.now(),
        scheduledTime: scheduledTime,
        tokenNumber: tokenNumber,
        status: AppointmentStatus.pending,
        seatNumbers: seatNumbers,
        durationMinutes: durationMinutes,
      );

      print('=== BOOKING SUCCESS ===');
      return appointment;
    } catch (e) {
      print('=== BOOKING FAILED ===');
      print('Error: $e');
      rethrow;
    }
  }

  @override
  Stream<Appointment?> watchAppointment(String appointmentId) {
    return _firestore
        .collection('appointments')
        .doc(appointmentId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? _documentToAppointment(snapshot) : null);
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).delete();
  }

  @override
  Stream<List<Appointment>> watchServiceQueue(String serviceId) {
    return _firestore
        .collection('appointments')
        .where('serviceId', isEqualTo: serviceId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => _documentToAppointment(doc))
              .toList();
          list.sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
          return list;
        });
  }

  @override
  Stream<bool> watchServiceOpen(String serviceId) {
    return Stream.value(true);
  }

  @override
  Future<void> setServiceOpen(String serviceId, bool isOpen) async {
    // No-op - services are always open
  }

  @override
  Future<void> markNextAsInProgress(String serviceId) async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('serviceId', isEqualTo: serviceId)
        .get();

    final pendingDocs = snapshot.docs
        .where((doc) => (doc.data())['status'] == 'pending')
        .toList();

    if (pendingDocs.isEmpty) return;

    pendingDocs.sort((a, b) {
      final aCreated = (a.data())['createdAt'] as Timestamp;
      final bCreated = (b.data())['createdAt'] as Timestamp;
      return aCreated.compareTo(bCreated);
    });

    await pendingDocs.first.reference.update({'status': 'inProgress'});
  }

  @override
  Future<int> getEstimatedWaitMinutes(
    String serviceId, {
    int minutesPerPerson = 5,
  }) async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('serviceId', isEqualTo: serviceId)
        .get();

    final pendingDocs = snapshot.docs
        .where((doc) => (doc.data())['status'] == 'pending')
        .toList();

    if (pendingDocs.isEmpty) return 0;

    pendingDocs.sort((a, b) {
      final aTime = (a.data())['scheduledTime'] as Timestamp;
      final bTime = (b.data())['scheduledTime'] as Timestamp;
      return aTime.compareTo(bTime);
    });
    
    final firstAppointment = pendingDocs.first;
    final now = DateTime.now();
    final scheduledTime = (firstAppointment['scheduledTime'] as Timestamp).toDate();
    final difference = scheduledTime.difference(now);
    
    return difference.inMinutes.clamp(0, 1440); // Max 24 hours
  }

  @override
  Future<int> getPositionInQueue(String appointmentId) async {
    // First get the appointment to find its serviceId
    final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
    if (!appointmentDoc.exists) return 0;
    
    final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
    final serviceId = appointmentData['serviceId'] as String;

    final snapshot = await _firestore
        .collection('appointments')
        .where('serviceId', isEqualTo: serviceId)
        .get();

    final pendingDocs = snapshot.docs
        .where((doc) => (doc.data())['status'] == 'pending')
        .toList();

    pendingDocs.sort((a, b) {
      final aCreated = (a.data())['createdAt'] as Timestamp;
      final bCreated = (b.data())['createdAt'] as Timestamp;
      return aCreated.compareTo(bCreated);
    });

    for (int i = 0; i < pendingDocs.length; i++) {
      if (pendingDocs[i].id == appointmentId) {
        return i + 1;
      }
    }
    
    return 0;
  }

  @override
  Future<void> markCancelled(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'cancelled',
      'cancelledAt': Timestamp.now(),
    });
  }

  @override
  Future<void> markCompleted(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': 'completed',
      'completedAt': Timestamp.now(),
    });
  }

  @override
  Stream<qs.QueueSnapshot> watchPublicQueue(String serviceId) {
    return _firestore
        .collection('appointments')
        .where('serviceId', isEqualTo: serviceId)
        .snapshots()
        .asyncMap((snapshot) async {
          final appointments = snapshot.docs
              .map((doc) => _documentToAppointment(doc))
              .where((a) => a.status == AppointmentStatus.pending || a.status == AppointmentStatus.inProgress)
              .toList()
            ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
          
          // Get the service details
          final serviceName = _serviceNameFromCanonicalId(serviceId);
          final serviceQuery = serviceName.isEmpty
              ? await _firestore.collection('services').limit(1).get()
              : await _firestore
                  .collection('services')
                  .where('name', isEqualTo: serviceName)
                  .limit(1)
                  .get();

          if (serviceQuery.docs.isEmpty) {
            throw StateError('Service not found');
          }

          final serviceData = serviceQuery.docs.first.data();
          final service = Service(
            id: serviceId,
            name: serviceData['name'] as String,
            description: serviceData['description'] as String,
            location: serviceData['location'] as String,
            minutesPerPerson: serviceData['minutesPerPerson'] as int,
          );

          Appointment? current;
          if (appointments.isNotEmpty) {
            current = appointments.firstWhere(
              (a) => a.status == AppointmentStatus.inProgress,
              orElse: () => appointments.first,
            );
          }

          final nextUp = current == null
              ? appointments.take(3).toList()
              : appointments
                  .where((a) => a.id != current!.id)
                  .take(3)
                  .toList();
          
          return qs.QueueSnapshot(
            service: service,
            current: current,
            nextUp: nextUp,
          );
        });
  }

  Appointment _documentToAppointment(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Appointment(
      id: doc.id,
      serviceId: data['serviceId'] as String,
      serviceName: data['serviceName'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userEmail: data['userEmail'] as String? ?? '',
      userEnrollment: data['userEnrollment'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      tokenNumber: data['tokenNumber'] as int,
      status: AppointmentStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      seatNumbers: (data['seatNumbers'] as List?)?.map((e) => (e as num).toInt()).toList(),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
    );
  }
}
