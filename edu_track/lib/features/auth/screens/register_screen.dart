import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String _selectedRole = 'student';
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final List<Map<String, dynamic>> _roles = [
    {'value': 'student', 'label': 'Student', 'icon': Icons.person_outline},
    {'value': 'teacher', 'label': 'Teacher', 'icon': Icons.school_outlined},
    {'value': 'parent', 'label': 'Parent', 'icon': Icons.family_restroom},
    {'value': 'admin', 'label': 'Admin', 'icon': Icons.admin_panel_settings_outlined},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthBloc>().add(AuthRegisterRequested(
          fullName: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
          role: _selectedRole,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (ctx, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Join SPM',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in your details to create an account',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Role Selector
                  const Text('I am a…',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: _roles.map((r) {
                      final isSelected = _selectedRole == r['value'];
                      final color = AppColors.roleColor(r['value'] as String);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = r['value'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected ? color : AppColors.border,
                                  width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              children: [
                                Icon(r['icon'] as IconData,
                                    color: isSelected
                                        ? color
                                        : AppColors.textHint,
                                    size: 22),
                                const SizedBox(height: 4),
                                Text(r['label'] as String,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? color
                                            : AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  SPMTextField(
                    label: 'Full Name',
                    hint: 'John Doe',
                    controller: _nameCtrl,
                    validator: (v) =>
                        Validators.required(v, 'Full name'),
                    prefix: const Icon(Icons.person_outline,
                        color: AppColors.textHint),
                  ),
                  const SizedBox(height: 16),
                  SPMTextField(
                    label: 'Email Address',
                    hint: 'you@school.edu',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    prefix: const Icon(Icons.mail_outline,
                        color: AppColors.textHint),
                  ),
                  const SizedBox(height: 16),
                  SPMTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    validator: Validators.password,
                    prefix: const Icon(Icons.lock_outline,
                        color: AppColors.textHint),
                    suffix: IconButton(
                      icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textHint),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SPMTextField(
                    label: 'Confirm Password',
                    hint: '••••••••',
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    validator: (v) =>
                        Validators.confirmPassword(v, _passCtrl.text),
                    prefix: const Icon(Icons.lock_outline,
                        color: AppColors.textHint),
                    suffix: IconButton(
                      icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textHint),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: state is AuthLoading ? null : _submit,
                    child: state is AuthLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ))
                        : const Text('Create Account'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                          style: TextStyle(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
