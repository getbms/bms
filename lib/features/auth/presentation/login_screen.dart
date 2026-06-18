import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        ),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // LayoutBuilder + IntrinsicHeight keeps the card vertically centred
        // on desktop while SingleChildScrollView prevents keyboard overflow
        // on mobile/short screens.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 32),
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 400),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: Column(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/images/bms_logo.svg',
                                              height: 72,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Business Management System',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color:
                                                    AppColors.textSecondary,
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
                                          prefixIcon:
                                              Icon(Icons.person_outline),
                                        ),
                                        textInputAction:
                                            TextInputAction.next,
                                        autofocus: true,
                                        validator: (v) =>
                                            (v == null ||
                                                    v.trim().isEmpty)
                                                ? 'Required'
                                                : null,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon:
                                              const Icon(Icons.lock_outline),
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility),
                                            onPressed: () => setState(() =>
                                                _obscurePassword =
                                                    !_obscurePassword),
                                          ),
                                        ),
                                        textInputAction:
                                            TextInputAction.done,
                                        onFieldSubmitted: (_) => _submit(),
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                                ? 'Required'
                                                : null,
                                      ),
                                      const SizedBox(height: 32),
                                      ElevatedButton(
                                        onPressed: authAsync.isLoading
                                            ? null
                                            : _submit,
                                        child: authAsync.isLoading
                                            ? const SizedBox.square(
                                                dimension: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white),
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
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        '© ${DateTime.now().year} BMS. All rights reserved.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
