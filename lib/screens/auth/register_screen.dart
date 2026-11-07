import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../student/student_dashboard_screen.dart';
import '../handler/handler_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  UserRole _selectedRole = UserRole.student;

  // Common
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Student specific
  final _departmentController = TextEditingController();
  final _enrollmentController = TextEditingController();

  // Handler specific
  String _handlerRole = 'Student Advisor';
  String _canteen = 'Crispino';
  final _securityCodeController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _enrollmentController.dispose();
    _securityCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final deps = QueueLessDependencies.of(context);
    final AuthService authService = deps.authService;

    try {
      if (_selectedRole == UserRole.handler) {
        if (_securityCodeController.text.trim() != 'accessgranted') {
          setState(() {
            _error = 'Invalid security code';
          });
          return;
        }
      }

      final user = await authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        handlerRole: _selectedRole == UserRole.handler ? _handlerRole : null,
        canteen: _selectedRole == UserRole.handler && _handlerRole == 'Canteen Staff' ? _canteen : null,
      );

      if (!mounted) return;
      if (user == null) {
        setState(() {
          _error = 'Registration failed';
        });
        return;
      }

      if (user.role == UserRole.student) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HandlerDashboardScreen(initialUser: user)),
          (route) => false,
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
    final isStudent = _selectedRole == UserRole.student;

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
                alignment: Alignment.topLeft,
                child: Container(
                  height: 210,
                  width: 210,
                  margin: const EdgeInsets.only(top: 8, left: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  height: 250,
                  width: 250,
                  margin: const EdgeInsets.only(bottom: 8, right: 8),
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
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _isLoading ? null : () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            Expanded(
                              child: Text(
                                'Create account',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                                  controller: _nameController,
                                  autofillHints: const [AutofillHints.name],
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
                                    labelText: 'Full name',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    filled: true,
                                    fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                    border: inputBorder,
                                    enabledBorder: inputBorder,
                                    focusedBorder: focusedBorder,
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                                  autofillHints: const [AutofillHints.newPassword],
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
                                    labelText: 'Create password',
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
                                const SizedBox(height: 16),
                                if (isStudent) ...[
                                  TextField(
                                    controller: _departmentController,
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
                                      labelText: 'Department',
                                      prefixIcon: const Icon(Icons.apartment_outlined),
                                      filled: true,
                                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                      border: inputBorder,
                                      enabledBorder: inputBorder,
                                      focusedBorder: focusedBorder,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _enrollmentController,
                                    textInputAction: TextInputAction.done,
                                    enabled: !_isLoading,
                                    onChanged: (_) {
                                      if (_error != null) {
                                        setState(() {
                                          _error = null;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Enrollment number',
                                      prefixIcon: const Icon(Icons.confirmation_number_outlined),
                                      filled: true,
                                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                      border: inputBorder,
                                      enabledBorder: inputBorder,
                                      focusedBorder: focusedBorder,
                                    ),
                                  ),
                                ] else ...[
                                  DropdownButtonFormField<String>(
                                    initialValue: _handlerRole,
                                    decoration: InputDecoration(
                                      labelText: 'Handler role',
                                      prefixIcon: const Icon(Icons.work_outline),
                                      filled: true,
                                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                      border: inputBorder,
                                      enabledBorder: inputBorder,
                                      focusedBorder: focusedBorder,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Student Advisor',
                                        child: Text('Student Advisor'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'HOD Coordinator',
                                        child: Text('HOD Coordinator'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Accounts Office',
                                        child: Text('Accounts Office'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Canteen Staff',
                                        child: Text('Canteen Staff'),
                                      ),
                                    ],
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            if (value == null) return;
                                            setState(() {
                                              _handlerRole = value;
                                              _error = null;
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 12),
                                  if (_handlerRole == 'Canteen Staff') ...[
                                    DropdownButtonFormField<String>(
                                      initialValue: _canteen,
                                      decoration: InputDecoration(
                                        labelText: 'Canteen',
                                        prefixIcon: const Icon(Icons.storefront_outlined),
                                        filled: true,
                                        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                        border: inputBorder,
                                        enabledBorder: inputBorder,
                                        focusedBorder: focusedBorder,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Crispino',
                                          child: Text('Crispino'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Deans',
                                          child: Text('Deans'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Student Café',
                                          child: Text('Student Café'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Nescafe',
                                          child: Text('Nescafe'),
                                        ),
                                      ],
                                      onChanged: _isLoading
                                          ? null
                                          : (value) {
                                              if (value == null) return;
                                              setState(() {
                                                _canteen = value;
                                                _error = null;
                                              });
                                            },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  TextField(
                                    controller: _securityCodeController,
                                    obscureText: true,
                                    autofillHints: const [AutofillHints.password],
                                    textInputAction: TextInputAction.done,
                                    enabled: !_isLoading,
                                    onChanged: (_) {
                                      if (_error != null) {
                                        setState(() {
                                          _error = null;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Handler security code',
                                      prefixIcon: const Icon(Icons.verified_user_outlined),
                                      filled: true,
                                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                      border: inputBorder,
                                      enabledBorder: inputBorder,
                                      focusedBorder: focusedBorder,
                                    ),
                                  ),
                                ],
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _error == null
                                      ? const SizedBox(height: 0)
                                      : Padding(
                                          padding: const EdgeInsets.only(top: 12),
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
                                  label: 'Create Account',
                                  onPressed: _register,
                                  isLoading: _isLoading,
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textDark.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _isLoading ? null : () => Navigator.of(context).maybePop(),
                                      child: const Text('Login'),
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
