import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authStateProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    ref.listen(authStateProvider, (_, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        ),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryDark,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'BMS',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'BMS',
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Business Management System',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textInputAction: TextInputAction.next,
                            autofocus: true,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: authAsync.isLoading ? null : _submit,
                            child: authAsync.isLoading
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '© 2026 BMS. All rights reserved.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textDisabled,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
