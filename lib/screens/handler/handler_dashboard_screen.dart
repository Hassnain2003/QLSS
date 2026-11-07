import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import '../public/queue_display_screen.dart';

class HandlerDashboardScreen extends StatefulWidget {
  final AppUser? initialUser;

  const HandlerDashboardScreen({
    super.key,
    this.initialUser,
  });

  @override
  State<HandlerDashboardScreen> createState() => _HandlerDashboardScreenState();
}

class _HandlerDashboardScreenState extends State<HandlerDashboardScreen> {
  AppUser? _currentUser;
  String? _serviceId;
  bool _isLoading = true;
  String? _errorMessage;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      _initialized = true;
      final user = widget.initialUser;
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
        _findServiceForHandler(user);
        return;
      }
      _initializeDashboard();
    });
  }

  Future<void> _initializeDashboard() async {
    try {
      // Get current authenticated user
      final deps = QueueLessDependencies.of(context);
      final authService = deps.authService;
      
      final user = await authService
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 10), onTimeout: () => null);

      if (!mounted) return;

      if (user == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      if (user.role != UserRole.handler) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      setState(() {
        _currentUser = user;
      });

      await _findServiceForHandler(user);
    } catch (e) {
      print('Error initializing dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize dashboard: $e';
        });
      }
    }
  }

  Future<void> _findServiceForHandler(AppUser user) async {
    try {
      final canonicalServiceId = _getServiceIdForRole(user);
      if (canonicalServiceId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No service is configured for your role';
        });
        return;
      }

      if (mounted) {
        setState(() {
          _serviceId = canonicalServiceId;
          _isLoading = false;
        });
        print('Selected service ID: $canonicalServiceId');
      }
    } catch (e) {
      print('Error finding service: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to find service for your role: $e';
        });
      }
    }
  }

  String? _getServiceIdForRole(AppUser user) {
    final handlerRole = user.handlerRole?.toLowerCase() ?? '';
    final canteen = user.canteen?.toLowerCase() ?? '';

    switch (handlerRole) {
      case 'student advisor':
        return 'advisor_office';
      case 'hod coordinator':
        return 'hod_meeting';
      case 'accounts office':
        return 'accounts_office';
      case 'canteen staff':
        switch (canteen) {
          case 'crispino':
            return 'canteen_crispino';
          case 'deans':
            return 'canteen_deans';
          case 'student café':
            return 'canteen_bites_beans';
          case 'nescafe':
            return 'canteen_quetta';
          default:
            return 'canteen_crispino';
        }
      default:
        return null;
    }
  }

  String _getServiceNameForRole(AppUser user) {
    final handlerRole = user.handlerRole?.toLowerCase() ?? '';
    final canteen = user.canteen?.toLowerCase() ?? '';

    // Map handler roles to service names
    switch (handlerRole) {
      case 'student advisor':
        return 'Advisor Office';
      case 'hod coordinator':
        return 'HOD Meeting';
      case 'accounts office':
        return 'Accounts Office';
      case 'canteen staff':
        // Use canteen-specific mapping
        switch (canteen) {
          case 'crispino':
            return 'Crispino';
          case 'deans':
            return 'Deans Canteen';
          case 'student café':
            return 'Bites and Beans';
          case 'nescafe':
            return 'Quetta';
          default:
            return 'Crispino'; // Default fallback
        }
      default:
        return 'Advisor Office'; // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Handler Dashboard'),
          backgroundColor: AppColors.primaryBlue,
        ),
        backgroundColor: AppColors.backgroundLight,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              SizedBox(height: 16),
              Text(
                'Loading your dashboard...',
                style: TextStyle(fontSize: 16, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Handler Dashboard'),
          backgroundColor: AppColors.primaryBlue,
        ),
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading dashboard',
                style: AppTextStyles.heading2.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeDashboard();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final deps = QueueLessDependencies.of(context);
                  await deps.authService.logout();
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return HandlerDashboardContent(
      currentUser: _currentUser!,
      serviceId: _serviceId!,
      serviceName: _getServiceNameForRole(_currentUser!),
    );
  }
}

class HandlerDashboardContent extends StatefulWidget {
  final AppUser currentUser;
  final String serviceId;
  final String serviceName;

  const HandlerDashboardContent({
    super.key,
    required this.currentUser,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<HandlerDashboardContent> createState() => _HandlerDashboardContentState();
}

class _HandlerDashboardContentState extends State<HandlerDashboardContent> {
  final Set<String> _busyAppointmentIds = <String>{};
  bool _isCallingNext = false;
  bool _isLoggingOut = false;

  bool get _isCanteenService => widget.serviceId.startsWith('canteen_');

  void _setBusy(String appointmentId, bool busy) {
    setState(() {
      if (busy) {
        _busyAppointmentIds.add(appointmentId);
      } else {
        _busyAppointmentIds.remove(appointmentId);
      }
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
    });
    try {
      final deps = QueueLessDependencies.of(context);
      await deps.authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _markCompleted(String appointmentId) async {
    if (_busyAppointmentIds.contains(appointmentId)) return;
    _setBusy(appointmentId, true);
    try {
      final deps = QueueLessDependencies.of(context);
      await deps.queueService.markCompleted(appointmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment completed'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        _setBusy(appointmentId, false);
      }
    }
  }

  Future<void> _markCancelled(String appointmentId) async {
    if (_busyAppointmentIds.contains(appointmentId)) return;
    _setBusy(appointmentId, true);
    try {
      final deps = QueueLessDependencies.of(context);
      await deps.queueService.markCancelled(appointmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        _setBusy(appointmentId, false);
      }
    }
  }

  Future<void> _accept(String appointmentId) async {
    if (_busyAppointmentIds.contains(appointmentId)) return;
    _setBusy(appointmentId, true);
    try {
      final deps = QueueLessDependencies.of(context);
      await deps.queueService.markInProgress(appointmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        _setBusy(appointmentId, false);
      }
    }
  }

  Future<void> _reject(String appointmentId) async {
    if (_busyAppointmentIds.contains(appointmentId)) return;
    _setBusy(appointmentId, true);
    try {
      final deps = QueueLessDependencies.of(context);
      await deps.queueService.markCancelled(appointmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        _setBusy(appointmentId, false);
      }
    }
  }

  Future<void> _callNext() async {
    if (_isCallingNext) return;
    setState(() {
      _isCallingNext = true;
    });
    try {
      final deps = QueueLessDependencies.of(context);
      await deps.queueService.markNextAsInProgress(widget.serviceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Next person called'), backgroundColor: AppColors.primaryBlue),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCallingNext = false;
        });
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'H';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    final scheme = Theme.of(context).colorScheme;

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
              stream: queueService.watchServiceQueue(widget.serviceId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 56, color: Colors.red),
                            const SizedBox(height: 10),
                            Text(
                              'Error loading queue',
                              style: AppTextStyles.heading2.copyWith(color: Colors.red, fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: AppTextStyles.body.copyWith(color: AppColors.textDark.withValues(alpha: 0.65)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryBlue),
                  );
                }

                final queue = snapshot.data ?? const <Appointment>[];
                final current = queue.where((a) => a.status == AppointmentStatus.inProgress).toList();
                final pending = queue.where((a) => a.status == AppointmentStatus.pending).toList()
                  ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
                final completed = queue.where((a) => a.status == AppointmentStatus.completed).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final Appointment? nowServing = current.isEmpty ? null : current.first;

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
                                    child: const Icon(Icons.badge_outlined, size: 16, color: AppColors.primaryBlue),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.serviceName,
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
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => QueueDisplayScreen(serviceId: widget.serviceId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.tv_rounded),
                              tooltip: 'View Public Display',
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              onPressed: _isLoggingOut ? null : _logout,
                              icon: const Icon(Icons.logout_rounded),
                              tooltip: 'Logout',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.14),
                                child: Text(
                                  _initials(widget.currentUser.name),
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.currentUser.name,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${widget.currentUser.handlerRole ?? "Handler"} • ${widget.currentUser.email}',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textDark.withValues(alpha: 0.60),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusPill(
                                text: 'Accepting',
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Current Service Status
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                        child: Row(
                          children: [
                            Text('Now Serving', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800)),
                            const Spacer(),
                            Text(
                              'Waiting: ${pending.length}',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textDark.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Current Serving Card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
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
                          child: nowServing == null
                              ? Column(
                                  children: [
                                    const SizedBox(height: 6),
                                    Icon(Icons.people_outline, size: 44, color: AppColors.textDark.withValues(alpha: 0.40)),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No one in progress',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textDark.withValues(alpha: 0.62),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isCanteenService
                                          ? 'Accept a booking below to start serving.'
                                          : 'Call next from the queue to start serving.',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textDark.withValues(alpha: 0.55),
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            '#${nowServing.tokenNumber}',
                                            style: AppTextStyles.heading1.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nowServing.userName,
                                                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
                                              ),
                                              const SizedBox(height: 4),
                                              if (nowServing.seatNumbers != null && nowServing.seatNumbers!.isNotEmpty)
                                                Text(
                                                  'Seats: ${nowServing.seatNumbers!.join(', ')}${nowServing.durationMinutes != null ? ' • ${nowServing.durationMinutes} min' : ''}',
                                                  style: AppTextStyles.body.copyWith(
                                                    color: AppColors.textDark.withValues(alpha: 0.60),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              if (nowServing.userEnrollment != null)
                                                Text(
                                                  'Enrollment: ${nowServing.userEnrollment}',
                                                  style: AppTextStyles.body.copyWith(
                                                    color: AppColors.textDark.withValues(alpha: 0.60),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        _StatusPill(text: 'In progress', color: AppColors.accentGreen),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: _busyAppointmentIds.contains(nowServing.id)
                                                ? null
                                                : () => _markCompleted(nowServing.id),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                            child: _busyAppointmentIds.contains(nowServing.id)
                                                ? const SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                  )
                                                : const Text('Complete'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: _busyAppointmentIds.contains(nowServing.id)
                                                ? null
                                                : () => _markCancelled(nowServing.id),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                            child: _busyAppointmentIds.contains(nowServing.id)
                                                ? const SizedBox(
                                                    height: 18,
                                                    width: 18,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                  )
                                                : const Text('Cancel'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    if (!_isCanteenService && pending.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                          child: PrimaryButton(
                            label: nowServing == null ? 'Start First Person' : 'Call Next Person',
                            onPressed: _callNext,
                            isLoading: _isCallingNext,
                            enabled: !_isCallingNext,
                          ),
                        ),
                      ),

                    // Waiting Queue
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                        child: Text(
                          'Waiting Queue (${pending.length})',
                          style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),

                    if (pending.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.check_circle_outline, color: Colors.green),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No one waiting right now.',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textDark.withValues(alpha: 0.70),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                        sliver: SliverList.separated(
                          itemBuilder: (context, index) {
                            final appointment = pending[index];
                            final busy = _busyAppointmentIds.contains(appointment.id);
                            final seatLine = (appointment.seatNumbers != null && appointment.seatNumbers!.isNotEmpty)
                                ? 'Seats: ${appointment.seatNumbers!.join(', ')}${appointment.durationMinutes != null ? ' • ${appointment.durationMinutes} min' : ''}'
                                : null;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '#${appointment.tokenNumber}',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appointment.userName,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (seatLine != null)
                                          Text(
                                            seatLine,
                                            style: AppTextStyles.body.copyWith(
                                              color: AppColors.textDark.withValues(alpha: 0.60),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (appointment.userEnrollment != null)
                                          Text(
                                            appointment.userEnrollment!,
                                            style: AppTextStyles.body.copyWith(
                                              color: AppColors.textDark.withValues(alpha: 0.60),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Waiting ${index + 1}',
                                          style: AppTextStyles.body.copyWith(
                                            color: AppColors.textDark.withValues(alpha: 0.50),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!_isCanteenService)
                                    _StatusPill(text: 'Queue', color: AppColors.primaryBlue)
                                  else
                                    Column(
                                      children: [
                                        FilledButton(
                                          onPressed: busy ? null : () => _accept(appointment.id),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                          child: busy
                                              ? const SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Text('Accept'),
                                        ),
                                        const SizedBox(height: 8),
                                        FilledButton(
                                          onPressed: busy ? null : () => _reject(appointment.id),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                          child: busy
                                              ? const SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Text('Reject'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: pending.length,
                        ),
                      ),

                    // Recently Completed
                    if (completed.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                          child: Text(
                            'Recently Completed (${completed.length})',
                            style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                        sliver: SliverList.separated(
                          itemBuilder: (context, index) {
                            final appointment = completed[index];
                            final seatLine = (appointment.seatNumbers != null && appointment.seatNumbers!.isNotEmpty)
                                ? 'Seats: ${appointment.seatNumbers!.join(', ')}${appointment.durationMinutes != null ? ' • ${appointment.durationMinutes} min' : ''}'
                                : null;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '#${appointment.tokenNumber}',
                                        style: AppTextStyles.body.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appointment.userName,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (seatLine != null)
                                          Text(
                                            seatLine,
                                            style: AppTextStyles.body.copyWith(
                                              color: AppColors.textDark.withValues(alpha: 0.60),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (appointment.userEnrollment != null)
                                          Text(
                                            appointment.userEnrollment!,
                                            style: AppTextStyles.body.copyWith(
                                              color: AppColors.textDark.withValues(alpha: 0.60),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Completed',
                                          style: AppTextStyles.body.copyWith(
                                            color: Colors.green,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _StatusPill(text: 'Completed', color: Colors.green),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: completed.length,
                        ),
                      ),
                    ],
                  ],
                );
              },
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
