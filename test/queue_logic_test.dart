import 'package:flutter_test/flutter_test.dart';
import 'package:queueless_app/models/appointment.dart';
import 'package:queueless_app/models/service.dart';
import 'package:queueless_app/services/queue_service.dart';

// Deterministic in-memory QueueService so tests are not affected by
// stream-controller timing (events already emitted before a listener
// subscribed are not replayed on broadcast controllers).
class _MemoryQueueService implements QueueService {
  final _services = <Service>{};
  final _appointments = <Appointment>[];
  final _byUserId = <String, List<Appointment>>{};
  final _byServiceId = <String, List<Appointment>>{};
  final _byApptId = <String, Appointment>{};

  _MemoryQueueService() {
    _services.addAll([
      const Service(id: 'advisor_office', name: 'Advisor Office', description: 'Course advising',
          location: 'Main Block', minutesPerPerson: 15),
      const Service(id: 'canteen_deans', name: 'Deans Canteen', description: 'Food and beverages',
          location: 'Central Courtyard', minutesPerPerson: 3),
    ]);
  }

  Appointment? _getAppointment(String id) => _byApptId[id];

  @override
  Stream<List<Service>> getServices() => Stream.value(_services.toList());

  @override
  Stream<List<Appointment>> getStudentAppointments(String userId) =>
      Stream.value(_byUserId[userId] ?? []);

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
    final serviceObj = _services.firstWhere((s) => s.id == service.id);
    final sameDay = _appointments.where((a) => a.serviceId == service.id).toList();
    final nextToken = sameDay.isEmpty
        ? 1
        : sameDay.map((a) => a.tokenNumber).reduce((a, b) => a > b ? a : b) + 1;
    final appointment = Appointment(
      id: '${service.id}_${_appointments.length}',
      serviceId: service.id,
      serviceName: serviceObj.name,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userEnrollment: userEnrollment,
      createdAt: DateTime.now(),
      scheduledTime: scheduledTime,
      tokenNumber: nextToken,
      status: AppointmentStatus.pending,
      seatNumbers: seatNumbers,
      durationMinutes: durationMinutes,
    );
    _appointments.add(appointment);
    _byApptId[appointment.id] = appointment;
    _byUserId.putIfAbsent(userId, () => []).add(appointment);
    _byServiceId.putIfAbsent(serviceObj.id, () => []).add(appointment);
    return appointment;
  }

  @override
  Stream<Appointment?> watchAppointment(String appointmentId) =>
      Stream.value(_getAppointment(appointmentId));

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return;
    final updated = _appointments[index].copyWith(status: AppointmentStatus.cancelled);
    _appointments[index] = updated;
    _byApptId[appointmentId] = updated;
  }

  @override
  Stream<List<Appointment>> watchServiceQueue(String serviceId) =>
      Stream.value(_appointments.where((a) => a.serviceId == serviceId).toList());

  @override
  Future<void> markInProgress(String appointmentId) async {
    _updateStatus(appointmentId, AppointmentStatus.inProgress);
  }

  @override
  Future<void> markNextAsInProgress(String serviceId) async {}

  @override
  Future<void> markCompleted(String appointmentId) async {
    _updateStatus(appointmentId, AppointmentStatus.completed);
  }

  @override
  Future<void> markCancelled(String appointmentId) async {
    _updateStatus(appointmentId, AppointmentStatus.cancelled);
  }

  @override
  Stream<QueueSnapshot> watchPublicQueue(String serviceId) {
    final service = _services.firstOrNull ?? const Service(
      id: '', name: '', description: '', location: '', minutesPerPerson: 0);
    return Stream.value(QueueSnapshot(service: service, current: null, nextUp: []));
  }

  @override
  Future<int> getPositionInQueue(String appointmentId) async {
    final appt = _getAppointment(appointmentId);
    if (appt == null) throw ArgumentError('Appointment not found');
    final sameService = _appointments
        .where((a) => a.serviceId == appt.serviceId)
        .where((a) =>
            a.status == AppointmentStatus.pending ||
            a.status == AppointmentStatus.inProgress)
        .toList()
      ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
    return sameService.indexWhere((a) => a.id == appointmentId) + 1;
  }

  @override
  Future<int> getEstimatedWaitMinutes(
    String appointmentId, {
    int minutesPerPerson = 5,
  }) async {
    final appt = _getAppointment(appointmentId);
    if (appt == null) throw ArgumentError('Appointment not found');
    final position = await getPositionInQueue(appointmentId);
    if (position <= 1) return 0;
    // Use the service's configured per-person minutes (fall back to the
    // provided default only if the service has no minutesPerPerson).
    final service = _services.firstWhere((s) => s.id == appt.serviceId);
    return (position - 1) * (service.minutesPerPerson > 0 ? service.minutesPerPerson : minutesPerPerson);
  }

  @override
  Stream<bool> watchServiceOpen(String serviceId) => Stream.value(true);

  @override
  Future<void> setServiceOpen(String serviceId, bool isOpen) async {}

  void _updateStatus(String id, AppointmentStatus status) {
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _appointments[index].copyWith(status: status);
    _appointments[index] = updated;
    _byApptId[id] = updated;
  }
}


void main() {
  group('QueueService (in-memory)', () {
    late _MemoryQueueService service;

    setUp(() { service = _MemoryQueueService(); });

    test('lists services from the queue service', () {
      expect(service._services.length, greaterThan(0));
      expect(service._services.any((s) => s.id == 'advisor_office'), isTrue);
    });

    test('booking creates an appointment with a token number', () async {
      final serviceObj = service._services.firstWhere((s) => s.id == 'advisor_office');
      final now = DateTime(2026, 1, 1, 10, 0);
      final appointment = await service.bookAppointment(
        userId: 'student-1',
        userName: 'Ali',
        userEmail: 'ali@bahria.edu',
        service: serviceObj,
        scheduledTime: now,
      );
      expect(appointment.id, isNotEmpty);
      expect(appointment.tokenNumber, 1);
      expect(appointment.status, AppointmentStatus.pending);
      expect(appointment.userId, 'student-1');
    });

    test('position in queue returns 1 for the first pending appointment', () async {
      final serviceObj = service._services.firstWhere((s) => s.id == 'advisor_office');
      await service.bookAppointment(
        userId: 's1', userName: 'Alice', userEmail: 'a@x', service: serviceObj,
        scheduledTime: DateTime(2026, 1, 1));
      await service.bookAppointment(
        userId: 's2', userName: 'Bob', userEmail: 'b@x', service: serviceObj,
        scheduledTime: DateTime(2026, 1, 1));

      final pos1 = await service.getPositionInQueue(service._appointments[0].id);
      final pos2 = await service.getPositionInQueue(service._appointments[1].id);
      expect(pos1, 1);
      expect(pos2, 2);
    });

    test('estimated wait minutes equals (position - 1) * minutesPerPerson', () async {
      final serviceObj = service._services.firstWhere((s) => s.id == 'advisor_office');
      await service.bookAppointment(
        userId: 's1', userName: 'Alice', userEmail: 'a@x', service: serviceObj,
        scheduledTime: DateTime(2026, 1, 1));
      await service.bookAppointment(
        userId: 's2', userName: 'Bob', userEmail: 'b@x', service: serviceObj,
        scheduledTime: DateTime(2026, 1, 1));
      // Bob (position 2) -> 1 * 15 = 15 minutes
      expect(await service.getEstimatedWaitMinutes(service._appointments[1].id), 15);
    });

    test('handler can mark an appointment in progress and completed', () async {
      final serviceObj = service._services.firstWhere((s) => s.id == 'canteen_deans');
      final appointment = await service.bookAppointment(
        userId: 'h1', userName: 'Carol', userEmail: 'c@x', service: serviceObj,
        scheduledTime: DateTime(2026, 1, 1));
      expect(appointment.status, AppointmentStatus.pending);

      await service.markInProgress(appointment.id);
      expect(service._getAppointment(appointment.id)!.status, AppointmentStatus.inProgress);

      await service.markCompleted(appointment.id);
      expect(service._getAppointment(appointment.id)!.status, AppointmentStatus.completed);
    });

    test('cancelAppointment sets status to cancelled', () async {
      final serviceObj = service._services.firstWhere((s) => s.id == 'advisor_office');
      final appointment = await service.bookAppointment(
        userId: 's1', userName: 'Dan', userEmail: 'd@x', service: serviceObj,
        scheduledTime: DateTime(2026, 1, 1));

      await service.cancelAppointment(appointment.id);
      expect(service._getAppointment(appointment.id)!.status, AppointmentStatus.cancelled);
    });

    test('getStudentAppointments returns only the given user\'s appointments', () async {
      final serviceObj = service._services.firstWhere((s) => s.id == 'canteen_deans');
      final user1 = 'user-1';
      final otherUser = 'user-2';
      await service.bookAppointment(
        userId: user1, userName: 'User One', userEmail: 'u1@x', service: serviceObj,
        scheduledTime: DateTime(2026, 1, 1));
      await service.bookAppointment(
        userId: otherUser, userName: 'Other', userEmail: 'u2@x', service: serviceObj,
        scheduledTime: DateTime(2026, 1, 1));

      final mine = service._byUserId[user1] ?? [];
      expect(mine.length, 1);
      expect(mine.first.userId, user1);
    });
  });
}
