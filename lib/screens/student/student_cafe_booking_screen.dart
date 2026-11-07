import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/service.dart';
import '../../services/auth_service.dart';
import '../../services/queue_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import 'student_queue_status_screen.dart';

class StudentCafeBookingScreen extends StatefulWidget {
  const StudentCafeBookingScreen({super.key});

  @override
  State<StudentCafeBookingScreen> createState() => _StudentCafeBookingScreenState();
}

class _StudentCafeBookingScreenState extends State<StudentCafeBookingScreen> {
  static const int _capacityPerCafe = 20;

  // Simple in-memory state for current session
  static final Map<String, Set<int>> _occupiedSeatsByCafe = {
    'deans': <int>{},
    'crispino': <int>{},
    'student_cafe': <int>{},
    'quetta': <int>{},
    'nescafe': <int>{},
  };

  String? _selectedCafeId;
  String? _selectedCafeName;
  final Set<int> _selectedSeats = {};
  int _durationMinutes = 60; // default 1 hour
  String? _error;
  bool _isSubmitting = false;

  Set<int> get _occupiedSeats {
    if (_selectedCafeId == null) return {};
    return _occupiedSeatsByCafe[_selectedCafeId] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final cafes = [
      ('deans', 'Deans'),
      ('crispino', 'Crispino'),
      ('student_cafe', 'Student Café'),
      ('quetta', 'Quetta Café'),
      ('nescafe', 'Nescafe'),
    ];

    final occupiedCount = _occupiedSeats.length;
    final availableCount = _capacityPerCafe - occupiedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Café Slot Booking'),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a café', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cafes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final (id, name) = cafes[index];
                    final selected = _selectedCafeId == id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCafeId = id;
                          _selectedCafeName = name;
                          _selectedSeats.clear();
                          _error = null;
                        });
                      },
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryBlue
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.body.copyWith(
                                color:
                                    selected ? Colors.white : AppColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to select',
                              style: AppTextStyles.body.copyWith(
                                color: selected
                                    ? Colors.white70
                                    : AppColors.textLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedCafeId != null) ...[
                Text(
                  '$_selectedCafeName seating',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Occupied: $occupiedCount',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.errorRed,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Available: $availableCount',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.accentGreen,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Select seats', style: AppTextStyles.body),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (int i = 1; i <= _capacityPerCafe; i++)
                      _buildSeatChip(i),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Duration (max 2 hours)', style: AppTextStyles.body),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _durationMinutes,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 30,
                      child: Text('30 minutes'),
                    ),
                    DropdownMenuItem(
                      value: 60,
                      child: Text('1 hour'),
                    ),
                    DropdownMenuItem(
                      value: 90,
                      child: Text('1 hour 30 minutes'),
                    ),
                    DropdownMenuItem(
                      value: 120,
                      child: Text('2 hours (max)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _durationMinutes = value;
                    });
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.errorRed),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Confirm Booking',
                onPressed: _onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatChip(int seatNumber) {
    final occupied = _occupiedSeats.contains(seatNumber);
    final selected = _selectedSeats.contains(seatNumber);

    return GestureDetector(
      onTap: occupied
          ? null
          : () {
              setState(() {
                if (selected) {
                  _selectedSeats.remove(seatNumber);
                } else {
                  _selectedSeats.add(seatNumber);
                }
                _error = null;
              });
            },
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: occupied
              ? AppColors.errorRed.withValues(alpha: 0.1)
              : selected
                  ? AppColors.primaryBlue
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: occupied
                ? AppColors.errorRed
                : selected
                    ? AppColors.primaryBlue
                    : Colors.grey.shade300,
          ),
        ),
        child: Text(
          seatNumber.toString(),
          style: AppTextStyles.body.copyWith(
            fontSize: 11,
            color: occupied
                ? AppColors.errorRed
                : selected
                    ? Colors.white
                    : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    if (_selectedCafeId == null) {
      setState(() {
        _error = 'Please select a café first';
      });
      return;
    }

    if (_selectedSeats.isEmpty) {
      setState(() {
        _error = 'Please select at least one seat';
      });
      return;
    }

    if (_durationMinutes > 120) {
      setState(() {
        _error = 'Maximum booking duration is 2 hours';
      });
      return;
    }

    _submitBooking();
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final deps = QueueLessDependencies.of(context);
      final AuthService auth = deps.authService;
      final QueueService queueService = deps.queueService;
      final user = auth.currentUser;

      if (user == null) {
        setState(() {
          _error = 'Please login again';
        });
        return;
      }

      final cafeId = _selectedCafeId!;
      final service = _serviceForCafe(cafeId);
      if (service == null) {
        setState(() {
          _error = 'Unsupported café selection';
        });
        return;
      }

      final seats = _selectedSeats.toList()..sort();

      final appt = await queueService.bookAppointment(
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userEnrollment: user.enrollment,
        service: service,
        scheduledTime: DateTime.now(),
        seatNumbers: seats,
        durationMinutes: _durationMinutes,
      );

      final occupied = _occupiedSeatsByCafe[_selectedCafeId]!;
      occupied.addAll(_selectedSeats);

      if (!mounted) return;
      setState(() {
        _selectedSeats.clear();
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentQueueStatusScreen(appointmentId: appt.id),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to book seats: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Service? _serviceForCafe(String cafeId) {
    switch (cafeId) {
      case 'deans':
        return const Service(
          id: 'canteen_deans',
          name: 'Deans Canteen',
          description: 'Food and beverages',
          location: 'Central Courtyard',
          minutesPerPerson: 5,
        );
      case 'crispino':
        return const Service(
          id: 'canteen_crispino',
          name: 'Crispino',
          description: 'Food and beverages',
          location: 'Building A',
          minutesPerPerson: 5,
        );
      case 'student_cafe':
        return const Service(
          id: 'canteen_bites_beans',
          name: 'Bites and Beans',
          description: 'Coffee and snacks',
          location: 'Student Center',
          minutesPerPerson: 5,
        );
      case 'quetta':
      case 'nescafe':
        return const Service(
          id: 'canteen_quetta',
          name: 'Quetta',
          description: 'Food and beverages',
          location: 'Building B',
          minutesPerPerson: 5,
        );
      default:
        return null;
    }
  }
}
