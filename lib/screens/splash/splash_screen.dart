import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../handler/handler_dashboard_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription? _subscription;
  Timer? _initTimer;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _initTimer?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _init() {
    _initTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _initTimer = null;
      _listenToAuth();
    });

    // Add timeout as fallback
    _fallbackTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      _fallbackTimer = null;
      _subscription?.cancel();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  void _listenToAuth() {
    final deps = QueueLessDependencies.of(context);
    final AuthService authService = deps.authService;
    _subscription = authService.authStateChanges().listen((user) {
      if (!mounted) return;
      _subscription?.cancel();
      _subscription = null;

      if (user == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        if (user.role == UserRole.student) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HandlerDashboardScreen(initialUser: user)),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QueueLess',
              style: AppTextStyles.heading1.copyWith(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Appointment Manager',
              style: AppTextStyles.body.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
