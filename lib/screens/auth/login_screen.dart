import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../student/student_dashboard_screen.dart';
import '../handler/handler_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final deps = QueueLessDependencies.of(context);
    final AuthService authService = deps.authService;

    try {
      final user = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
      );
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _error = 'Login failed';
        });
        return;
      }

      if (user.role == UserRole.student) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HandlerDashboardScreen(initialUser: user)),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
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
    final scheme = Theme.of(context).colorScheme;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.9), width: 1.4),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
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
                  height: 220,
                  width: 220,
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
                  height: 260,
                  width: 260,
                  margin: const EdgeInsets.only(bottom: 8, left: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentGreen.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'QueueLess',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Smart Appointment Manager for Bahria University',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textDark.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(alpha: 0.55),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Welcome back', style: AppTextStyles.heading2),
                                const SizedBox(height: 4),
                                Text(
                                  'Sign in to continue',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textDark.withValues(alpha: 0.60),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Account type',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SegmentedButton<UserRole>(
                                  segments: const [
                                    ButtonSegment(
                                      value: UserRole.student,
                                      label: Text('Student'),
                                      icon: Icon(Icons.school_outlined),
                                    ),
                                    ButtonSegment(
                                      value: UserRole.handler,
                                      label: Text('Handler'),
                                      icon: Icon(Icons.badge_outlined),
                                    ),
                                  ],
                                  selected: <UserRole>{_selectedRole},
                                  onSelectionChanged: _isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _selectedRole = value.first;
                                          });
                                        },
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.resolveWith(
                                      (states) => states.contains(WidgetState.selected)
                                          ? AppColors.primaryBlue.withValues(alpha: 0.10)
                                          : Colors.transparent,
                                    ),
                                    foregroundColor: WidgetStateProperty.resolveWith(
                                      (states) => states.contains(WidgetState.selected)
                                          ? AppColors.primaryBlue
                                          : AppColors.textDark,
                                    ),
                                    side: WidgetStatePropertyAll(
                                      BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
                                    ),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.next,
                                  enabled: !_isLoading,
                                  onChanged: (_) {
                                    if (_error != null) {
                                      setState(() {
                                        _error = null;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.mail_outline),
                                    filled: true,
                                    fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                    border: inputBorder,
                                    enabledBorder: inputBorder,
                                    focusedBorder: focusedBorder,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _login(),
                                  enabled: !_isLoading,
                                  onChanged: (_) {
                                    if (_error != null) {
                                      setState(() {
                                        _error = null;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                    border: inputBorder,
                                    enabledBorder: inputBorder,
                                    focusedBorder: focusedBorder,
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _error == null
                                      ? const SizedBox(height: 0)
                                      : Padding(
                                          padding: const EdgeInsets.only(top: 10),
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.errorRed.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.errorRed.withValues(alpha: 0.22),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.error_outline, color: AppColors.errorRed, size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _error!,
                                                    style: AppTextStyles.body.copyWith(
                                                      color: AppColors.errorRed,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  label: 'Login',
                                  onPressed: _login,
                                  isLoading: _isLoading,
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account?",
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textDark.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => const RegisterScreen(),
                                                ),
                                              );
                                            },
                                      child: const Text('Create account'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
