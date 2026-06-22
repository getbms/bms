import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/eula_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _eulaText = '''
END-USER LICENSE AGREEMENT (EULA)
Business Management System (BMS)

IMPORTANT - READ CAREFULLY BEFORE USING THIS SOFTWARE

This End-User License Agreement ("Agreement") is a legal contract between you ("Licensee") and the BMS software provider ("Licensor"). By clicking "Accept & Continue" you agree to be bound by the terms of this Agreement. If you do not agree, click "Decline" to exit.

1. GRANT OF LICENSE
Licensor grants you a non-exclusive, non-transferable license to install and use one copy of BMS on devices associated with your license key, solely for your internal business operations.

2. RESTRICTIONS
You may not:
(a) copy, modify, or distribute the software without prior written consent;
(b) reverse engineer, decompile, or disassemble the software;
(c) sublicense, rent, lease, or lend the software to any third party;
(d) remove or alter any proprietary notices, labels, or marks.

3. OWNERSHIP
The software and all copies thereof are proprietary to Licensor and title thereto remains with Licensor. All rights in the software not specifically granted in this Agreement are reserved.

4. LICENSE KEY
The software requires activation with a valid license key. You must not share, transfer, or disclose your license key to unauthorized parties.

5. DATA AND PRIVACY
You retain full ownership of all business data entered into the software. The software connects to Licensor's licensing servers solely for the purpose of license validation. No personally identifiable business data is transmitted to Licensor without your explicit consent.

6. DISCLAIMER OF WARRANTIES
THE SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.

7. LIMITATION OF LIABILITY
IN NO EVENT SHALL LICENSOR BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES, HOWEVER CAUSED, INCLUDING LOSS OF PROFITS, BUSINESS INTERRUPTION, OR LOSS OF DATA, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

8. TERM AND TERMINATION
This Agreement is effective until terminated. Your rights under this Agreement will terminate automatically if you breach any term. Upon termination, you must cease all use of the software and destroy all copies.

9. GOVERNING LAW
This Agreement shall be governed by the laws of the jurisdiction in which Licensor is incorporated, without regard to conflict of law provisions.

10. ENTIRE AGREEMENT
This Agreement constitutes the entire agreement between the parties with respect to the software and supersedes all prior understandings and agreements.

By accepting this Agreement you confirm that you have read, understood, and agree to all the terms and conditions stated above.
''';

class EulaScreen extends ConsumerStatefulWidget {
  const EulaScreen({super.key});

  @override
  ConsumerState<EulaScreen> createState() => _EulaScreenState();
}

class _EulaScreenState extends ConsumerState<EulaScreen> {
  final _scrollController = ScrollController();
  bool _scrolledToBottom = false;
  bool _agreed = false;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrolledToBottom) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 40) {
      setState(() => _scrolledToBottom = true);
    }
  }

  Future<void> _accept() async {
    if (!_agreed || _accepting) return;
    setState(() => _accepting = true);
    await ref.read(eulaProvider.notifier).accept();
    // Router will redirect automatically once eulaProvider emits true.
  }

  Future<void> _decline() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.eulaDeclineTitle),
        content: Text(context.l10n.eulaDeclineMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              SystemNavigator.pop();
            },
            child: Text(context.l10n.eulaDeclineConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Expanded(child: _TermsCard(controller: _scrollController)),
                    const SizedBox(height: 16),
                    _ScrollHint(scrolledToBottom: _scrolledToBottom),
                    const SizedBox(height: 12),
                    _AgreementCheckbox(
                      enabled: _scrolledToBottom,
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    const SizedBox(height: 20),
                    _ActionButtons(
                      canAccept: _agreed && !_accepting,
                      accepting: _accepting,
                      onAccept: _accept,
                      onDecline: _decline,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business_center,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('BMS', style: AppTextStyles.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.eulaTitle,
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.eulaSubtitle,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({required this.controller});
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Scrollbar(
          controller: controller,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            child: Text(
              _eulaText,
              style: AppTextStyles.bodySmall.copyWith(
                height: 1.7,
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint({required this.scrolledToBottom});
  final bool scrolledToBottom;

  @override
  Widget build(BuildContext context) {
    if (scrolledToBottom) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 6),
          Text(
            context.l10n.eulaScrollComplete,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.keyboard_arrow_down,
            color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          context.l10n.eulaScrollHint,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _AgreementCheckbox extends StatelessWidget {
  const _AgreementCheckbox({
    required this.enabled,
    required this.value,
    required this.onChanged,
  });
  final bool enabled;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  context.l10n.eulaCheckboxLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.canAccept,
    required this.accepting,
    required this.onAccept,
    required this.onDecline,
  });
  final bool canAccept;
  final bool accepting;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(context.l10n.eulaDecline),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: canAccept ? onAccept : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: accepting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(context.l10n.eulaAccept),
          ),
        ),
      ],
    );
  }
}
