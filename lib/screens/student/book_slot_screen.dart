import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/appointment.dart';
import '../../models/service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import 'student_queue_status_screen.dart';

class BookSlotScreen extends StatefulWidget {
  final Service service;

  const BookSlotScreen({super.key, required this.service});

  @override
  State<BookSlotScreen> createState() => _BookSlotScreenState();
}

class _BookSlotScreenState extends State<BookSlotScreen> {
  final DateTime _selectedDate = DateTime.now();
  DateTime? _selectedSlot;
  bool _isLoading = false;
  String? _error;

  List<DateTime> _generateSlots() {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      9,
      30,
    );
    final end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      15,
      30,
    );
    final slots = <DateTime>[];
    var current = start;
    while (!current.isAfter(end)) {
      slots.add(current);
      current = current.add(const Duration(minutes: 30));
    }
    return slots;
  }

  Future<void> _book() async {
    if (_selectedSlot == null) {
      setState(() {
        _error = 'Please select a slot';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final deps = QueueLessDependencies.of(context);
    final auth = deps.authService;
    final queueService = deps.queueService;
    final user = auth.currentUser!;
    final scheduled = _selectedSlot!;

    try {
      final appt = await queueService.bookAppointment(
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userEnrollment: user.enrollment,
        service: widget.service,
        scheduledTime: scheduled,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentQueueStatusScreen(appointmentId: appt.id),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to book: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    final slots = _generateSlots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Book - ${widget.service.name}'),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<List<Appointment>>(
            stream: queueService.watchServiceQueue(widget.service.id),
            builder: (context, snapshot) {
              final appointments = snapshot.data ?? [];
              final busySlots = <String>{};
              for (final a in appointments) {
                if (a.scheduledTime.year == _selectedDate.year &&
                    a.scheduledTime.month == _selectedDate.month &&
                    a.scheduledTime.day == _selectedDate.day) {
                  busySlots.add('${a.scheduledTime.hour}:${a.scheduledTime.minute}');
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select a time slot', style: AppTextStyles.heading2),
                  const SizedBox(height: 8),
                  Text(
                    'Today • 9:30 AM to 3:30 PM',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.8,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final key = '${slot.hour}:${slot.minute}';
                        final isBusy = busySlots.contains(key);
                        final isSelected = _selectedSlot != null &&
                            _selectedSlot!.hour == slot.hour &&
                            _selectedSlot!.minute == slot.minute;

                        return GestureDetector(
                          onTap: _isLoading || isBusy
                              ? null
                              : () {
                                  setState(() {
                                    _selectedSlot = slot;
                                  });
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isBusy
                                  ? AppColors.errorRed.withValues(alpha: 0.1)
                                  : isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isBusy
                                    ? AppColors.errorRed
                                    : isSelected
                                        ? AppColors.primaryBlue
                                        : Colors.grey.shade200,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  TimeOfDay(
                                    hour: slot.hour,
                                    minute: slot.minute,
                                  ).format(context),
                                  style: AppTextStyles.body.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isBusy ? 'Busy' : 'Available',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    color: isBusy
                                        ? AppColors.errorRed
                                        : isSelected
                                            ? Colors.white
                                            : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.errorRed),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    PrimaryButton(
                      label: 'Confirm Booking',
                      onPressed: _book,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
