import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/appointment.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class StudentQueueStatusScreen extends StatelessWidget {
  final String appointmentId;

  const StudentQueueStatusScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue Status'),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<Appointment?>(
          stream: queueService.watchAppointment(appointmentId),
          builder: (context, snapshot) {
            final appt = snapshot.data;
            if (appt == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appt.serviceName, style: AppTextStyles.heading2),
                  if (appt.seatNumbers != null && appt.seatNumbers!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Seats: ${appt.seatNumbers!.join(', ')}${appt.durationMinutes != null ? ' • ${appt.durationMinutes} min' : ''}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Token #${appt.tokenNumber}',
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: 16),
                  _PositionAndEta(appointment: appt),
                  const SizedBox(height: 24),
                  Text(
                    'Status: ${appt.status.name}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (appt.status == AppointmentStatus.pending)
                    PrimaryButton(
                      label: 'Cancel Appointment',
                      filled: false,
                      onPressed: () async {
                        await queueService.cancelAppointment(appt.id);
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PositionAndEta extends StatelessWidget {
  final Appointment appointment;

  const _PositionAndEta({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;

    return FutureBuilder<List<int>>(
      future: Future.wait([
        queueService.getPositionInQueue(appointment.id),
        queueService.getEstimatedWaitMinutes(appointment.id),
      ]),
      builder: (context, snapshot) {
        final position = snapshot.data != null ? snapshot.data![0] : 0;
        final etaMinutes = snapshot.data != null ? snapshot.data![1] : 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your position in queue', style: AppTextStyles.body),
              const SizedBox(height: 4),
              Text(
                position <= 0 ? '--' : '#$position',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text('Estimated wait time', style: AppTextStyles.body),
              const SizedBox(height: 4),
              Text(
                etaMinutes <= 0
                    ? 'Almost your turn'
                    : '$etaMinutes minutes',
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }
}
