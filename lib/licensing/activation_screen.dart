import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/licensing/license_provider.dart';
import 'package:bms/licensing/license_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _controller = TextEditingController();
  String? _serverError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(licenseProvider.notifier).activate(_controller.text);
    } on LicenseException catch (e) {
      setState(() => _serverError = e.message);
    } catch (e) {
      // Log the actual exception for debugging
      debugPrint('License activation error: $e');
      setState(() => _serverError = 'Could not connect to the licensing server');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(licenseProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                            constraints: const BoxConstraints(maxWidth: 400),
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
                                              'Enter your license key to activate BMS',
                                              style:
                                                  AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 36),
                                      TextFormField(
                                        controller: _controller,
                                        enabled: !isLoading,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        inputFormatters: [
                                          _LicenseKeyFormatter()
                                        ],
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          letterSpacing: 1.5,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'License key',
                                          hintText: 'BMS-XXXX-XXXX-XXXX-XXXX',
                                          prefixIcon: Icon(Icons.vpn_key_outlined),
                                        ),
                                        onFieldSubmitted: (_) => _submit(),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'License key is required';
                                          }
                                          return null;
                                        },
                                      ),
                                      if (_serverError != null) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          _serverError!,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(color: AppColors.error),
                                        ),
                                      ],
                                      const SizedBox(height: 32),
                                      ElevatedButton(
                                        onPressed: isLoading ? null : _submit,
                                        child: isLoading
                                            ? const SizedBox.square(
                                                dimension: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white),
                                              )
                                            : const Text('Activate'),
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

class _LicenseKeyFormatter extends TextInputFormatter {
  // Formats as BMS-XXXX-XXXX-XXXX-XXXX (19 alphanum chars + 4 dashes).
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final clean = newValue.text
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final limited = clean.length > 19 ? clean.substring(0, 19) : clean;

    final buf = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 3 || i == 7 || i == 11 || i == 15) buf.write('-');
      buf.write(limited[i]);
    }

    final result = buf.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
