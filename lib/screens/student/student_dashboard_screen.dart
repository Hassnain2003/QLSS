import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../main.dart';
import '../../models/appointment.dart';
import '../../models/service.dart';
import '../../services/auth_service.dart';
import '../../services/queue_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import 'simple_booking_categories_screen.dart';
import 'student_cafe_booking_screen.dart';
import '../auth/login_screen.dart';
import 'student_queue_status_screen.dart';
import 'book_slot_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final deps = QueueLessDependencies.of(context);
    final AuthService authService = deps.authService;
    final QueueService queueService = deps.queueService;
    final user = authService.currentUser!;
    final scheme = Theme.of(context).colorScheme;

    final services = const [
      Service(
        id: 'advisor_office',
        name: 'Meet Advisor',
        description: 'Discuss courses, academic issues, and get guidance.',
        location: 'Advisor Office',
        minutesPerPerson: 15,
      ),
      Service(
        id: 'hod_meeting',
        name: 'Meeting with HOD',
        description: 'Book time with your Head of Department for approvals.',
        location: 'Department Office',
        minutesPerPerson: 20,
      ),
      Service(
        id: 'accounts_office',
        name: 'Accounts Office',
        description: 'Resolve fee, challan, and accounts related matters.',
        location: 'Accounts Office',
        minutesPerPerson: 10,
      ),
      Service(
        id: 'canteen_deans',
        name: 'Café Slot Booking',
        description: 'Book seats at Deans, Crispino, Student Café or Nescafe.',
        location: 'Campus Cafés',
        minutesPerPerson: 5,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.14),
                    Colors.white,
                    AppColors.accentGreen.withValues(alpha: 0.10),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                height: 240,
                width: 240,
                margin: const EdgeInsets.only(top: 8, right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                height: 280,
                width: 280,
                margin: const EdgeInsets.only(bottom: 8, left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGreen.withValues(alpha: 0.08),
                ),
              ),
            ),
            StreamBuilder<List<Appointment>>(
              stream: queueService.getStudentAppointments(user.id),
              builder: (context, snapshot) {
                final appts = snapshot.data ?? const <Appointment>[];
                final active = appts
                    .where(
                      (a) => a.status == AppointmentStatus.pending || a.status == AppointmentStatus.inProgress,
                    )
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final history = appts
                    .where(
                      (a) => a.status == AppointmentStatus.completed || a.status == AppointmentStatus.cancelled,
                    )
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                final topActive = active.isEmpty ? null : active.first;
                final timeFormat = DateFormat('EEE, dd MMM • hh:mm a');

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 28,
                                    width: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.event_available, size: 16, color: AppColors.primaryBlue),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'QueueLess',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryBlue,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            IconButton.filledTonal(
                              onPressed: () async {
                                await authService.logout();
                                if (!context.mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.logout_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${_firstName(user.name)}',
                              style: AppTextStyles.heading1.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Book and track your appointments in one place.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textDark.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                        child: _QuickActions(
                          hasActive: topActive != null,
                          onBook: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SimpleBookingCategoriesScreen()),
                            );
                          },
                          onCafe: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const StudentCafeBookingScreen()),
                            );
                          },
                          onActive: topActive == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => StudentQueueStatusScreen(appointmentId: topActive.id),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ),
                    if (topActive != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                          child: _ActiveBookingCard(
                            appointment: topActive,
                            timeFormat: timeFormat,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StudentQueueStatusScreen(appointmentId: topActive.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                        child: Row(
                          children: [
                            Text('Services', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800)),
                            const Spacer(),
                            Text(
                              'Explore',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final service = services[index];
                            final icon = switch (service.id) {
                              'advisor_office' => Icons.school_outlined,
                              'hod_meeting' => Icons.groups_2_outlined,
                              'accounts_office' => Icons.account_balance_outlined,
                              _ => Icons.restaurant_outlined,
                            };
                            return _ServiceCard(
                              service: service,
                              icon: icon,
                              onTap: () {
                                if (service.id == 'canteen_deans') {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const StudentCafeBookingScreen()),
                                  );
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => BookSlotScreen(service: service)),
                                );
                              },
                            );
                          },
                          childCount: services.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.05,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                        child: Text(
                          'Your appointments',
                          style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (active.isEmpty && history.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 36,
                                  width: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.inbox_outlined, color: AppColors.primaryBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No bookings yet. Tap “Book appointment” to get started.',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textDark.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (active.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                          child: Text(
                            'Active',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    if (active.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        sliver: SliverList.separated(
                          itemBuilder: (context, index) {
                            final a = active[index];
                            return _AppointmentTile(
                              appointment: a,
                              timeText: timeFormat.format(a.scheduledTime),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => StudentQueueStatusScreen(appointmentId: a.id),
                                  ),
                                );
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: active.length,
                        ),
                      ),
                    if (history.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                          child: Text(
                            'History',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    if (history.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                        sliver: SliverList.separated(
                          itemBuilder: (context, index) {
                            final a = history[index];
                            return _AppointmentTile(
                              appointment: a,
                              timeText: timeFormat.format(a.scheduledTime),
                              onTap: null,
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: history.length,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: PrimaryButton(
            label: 'Book appointment',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SimpleBookingCategoriesScreen()),
              );
            },
          ),
        ),
      ),
    );
  }

  String _firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.first;
  }
}

class _QuickActions extends StatelessWidget {
  final bool hasActive;
  final VoidCallback onBook;
  final VoidCallback onCafe;
  final VoidCallback? onActive;

  const _QuickActions({
    required this.hasActive,
    required this.onBook,
    required this.onCafe,
    required this.onActive,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ActionCard(
          title: 'Book',
          subtitle: 'New appointment',
          icon: Icons.add_task_outlined,
          color: AppColors.primaryBlue,
          onTap: onBook,
        ),
        _ActionCard(
          title: 'Café',
          subtitle: 'Seat booking',
          icon: Icons.restaurant_outlined,
          color: AppColors.accentGreen,
          onTap: onCafe,
        ),
        _ActionCard(
          title: 'Status',
          subtitle: hasActive ? 'View live queue' : 'No active booking',
          icon: Icons.track_changes_outlined,
          color: Colors.deepPurple,
          onTap: onActive,
          disabled: !hasActive,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveOnTap = disabled ? null : onTap;

    return InkWell(
      onTap: effectiveOnTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: (MediaQuery.of(context).size.width - 18 * 2 - 10) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: disabled ? 0.55 : 0.86),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: disabled ? 0.10 : 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: disabled ? AppColors.textLight : color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: disabled ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.body.copyWith(
                      color: disabled
                          ? AppColors.textLight
                          : AppColors.textDark.withValues(alpha: 0.62),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBookingCard extends StatelessWidget {
  final Appointment appointment;
  final DateFormat timeFormat;
  final VoidCallback onTap;

  const _ActiveBookingCard({
    required this.appointment,
    required this.timeFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = appointment.status == AppointmentStatus.inProgress
        ? AppColors.accentGreen
        : AppColors.primaryBlue;

    final seatLine = (appointment.seatNumbers != null && appointment.seatNumbers!.isNotEmpty)
        ? 'Seats: ${appointment.seatNumbers!.join(', ')}${appointment.durationMinutes != null ? ' • ${appointment.durationMinutes} min' : ''}'
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Active booking',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                _StatusPill(
                  text: appointment.status == AppointmentStatus.inProgress ? 'In progress' : 'Pending',
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              appointment.serviceName,
              style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Token #${appointment.tokenNumber} • ${timeFormat.format(appointment.scheduledTime)}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textDark.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (seatLine != null) ...[
              const SizedBox(height: 6),
              Text(
                seatLine,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textDark.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'View live status',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = service.id.startsWith('canteen_')
        ? AppColors.accentGreen
        : AppColors.primaryBlue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textDark.withValues(alpha: 0.35)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              service.name,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              service.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textDark.withValues(alpha: 0.58),
                fontSize: 12,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 14, color: AppColors.textDark.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    service.location,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textDark.withValues(alpha: 0.52),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final String timeText;
  final VoidCallback? onTap;

  const _AppointmentTile({
    required this.appointment,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = switch (appointment.status) {
      AppointmentStatus.pending => AppColors.primaryBlue,
      AppointmentStatus.inProgress => AppColors.accentGreen,
      AppointmentStatus.completed => Colors.green,
      AppointmentStatus.cancelled => AppColors.errorRed,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                appointment.serviceId.startsWith('canteen_')
                    ? Icons.restaurant_outlined
                    : Icons.event_note_outlined,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.serviceName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Token #${appointment.tokenNumber} • $timeText',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textDark.withValues(alpha: 0.60),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusPill(text: appointment.status.name, color: statusColor),
          ],
        ),
      ),
    );
  }
}
