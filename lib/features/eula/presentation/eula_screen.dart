import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/providers/eula_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

// The EULA is a legal document and must always be displayed in English,
// regardless of the user's selected application language.
const _eulaText = '''
END-USER LICENSE AGREEMENT (EULA)
Business Management System (BMS)

IMPORTANT - READ CAREFULLY BEFORE USING THIS SOFTWARE

This End-User License Agreement ("Agreement") is a legally binding contract between you, either an individual or a single legal entity ("Licensee"), and the BMS software provider ("Licensor"). By clicking "Accept & Continue" or by installing, copying, or otherwise using the Software, you acknowledge that you have read this Agreement, understand it, and agree to be bound by its terms and conditions. If you do not agree, click "Decline" and the application will close.


1. DEFINITIONS

"Software" means the Business Management System (BMS) application, including all files, modules, updates, upgrades, and associated documentation provided by Licensor.

"License Key" means the unique alphanumeric code issued by Licensor that activates and validates your license to use the Software.

"Device" means a single physical computer or workstation on which the Software is installed and activated.

"User Data" means all business records, transactions, customer information, inventory data, and any other data you enter into or generate using the Software.


2. GRANT OF LICENSE

Subject to the terms of this Agreement and payment of applicable license fees, Licensor grants you a limited, non-exclusive, non-transferable, non-sublicensable license to:

(a) Install and use one activated instance of the Software on the number of Devices permitted by your purchased license tier (Free, Pro, or Enterprise);

(b) Make one (1) archival copy of the Software solely for backup purposes, provided that such copy includes all copyright and proprietary notices.

This license is granted solely for your internal business operations. No rights are granted except as expressly stated herein.


3. LICENSE TIERS AND FEATURES

The Software is offered in the following tiers, each activating a defined set of features:

- Free Tier: Point-of-sale, inventory management, and customer records.
- Pro Tier: All Free features plus reports, goods received notes, cheques, petty cash, and debtor management.
- Enterprise Tier: All Pro features plus user management, API access, and multi-branch support.

Feature access is enforced at runtime via your License Key. Attempting to access features outside your licensed tier is prohibited.


4. RESTRICTIONS

You may NOT, and may not permit any third party to:

(a) Copy, reproduce, distribute, publish, or sublicense the Software or any portion thereof without prior written consent from Licensor;

(b) Modify, adapt, translate, reverse engineer, decompile, disassemble, or create derivative works based on the Software;

(c) Rent, lease, lend, sell, resell, or transfer the Software or any License Key to any third party;

(d) Remove, alter, or obscure any copyright, trademark, patent, or other proprietary notices embedded in the Software;

(e) Use the Software to develop a competing product or service;

(f) Circumvent, disable, or otherwise interfere with the license enforcement mechanisms, activation servers, or security features of the Software;

(g) Share, publish, or disclose your License Key to any unauthorized person;

(h) Use the Software in any manner that violates applicable local, national, or international laws or regulations.


5. INTELLECTUAL PROPERTY AND OWNERSHIP

The Software, including but not limited to its source code, object code, interfaces, design, architecture, algorithms, and documentation, is and shall remain the exclusive intellectual property of Licensor. This Agreement does not convey to you any ownership interest in the Software, but only a limited right of use as expressly set forth herein.

All trademarks, service marks, trade names, and logos associated with BMS are the property of Licensor. Nothing in this Agreement grants you the right to use any such marks.


6. LICENSE KEY AND ACTIVATION

6.1 The Software requires online activation using a valid License Key issued by Licensor. You must keep your License Key confidential and must not share it.

6.2 The Software may contact Licensor's licensing servers periodically to validate your License Key. An internet connection may be required for initial activation and periodic revalidation.

6.3 A grace period of seven (7) days is provided for offline use after the last successful validation. After the grace period expires, the Software will require revalidation before permitting access.

6.4 Licensor reserves the right to revoke a License Key if it detects fraudulent use, key sharing, or any breach of this Agreement.


7. USER DATA AND PRIVACY

7.1 You retain full ownership of all User Data. Licensor makes no claim to your business data.

7.2 The Software stores User Data locally on your device using a SQLite database. Data is stored unencrypted at the database level. Optional MySQL sync is available for multi-device deployments and operates entirely within your own infrastructure.

7.3 The Software communicates with Licensor's servers solely for the purpose of license key activation and validation. No User Data, business records, customer information, or personally identifiable information is transmitted to Licensor.

7.4 Licensor will handle any personal data it collects (such as device identifiers for license enforcement) in accordance with applicable data protection laws.


8. UPDATES AND SUPPORT

8.1 Licensor may, at its sole discretion, provide updates, patches, or new versions of the Software. Such updates may be subject to additional terms.

8.2 Support is provided according to the support plan associated with your license tier. Licensor is not obligated to provide support under this Agreement unless a separate support agreement exists.

8.3 Licensor reserves the right to discontinue the Software or any feature at any time with reasonable notice.


9. DISCLAIMER OF WARRANTIES

THE SOFTWARE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTY OF ANY KIND. TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, LICENSOR EXPRESSLY DISCLAIMS ALL WARRANTIES, WHETHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, INCLUDING WITHOUT LIMITATION:

- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE;
- WARRANTIES OF NON-INFRINGEMENT OF THIRD-PARTY RIGHTS;
- WARRANTIES THAT THE SOFTWARE WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE;
- WARRANTIES REGARDING THE ACCURACY OR COMPLETENESS OF THE SOFTWARE OR ITS OUTPUTS.

YOU ASSUME THE ENTIRE RISK ARISING OUT OF YOUR USE OF THE SOFTWARE AND ANY OUTPUT PRODUCED THEREBY.


10. LIMITATION OF LIABILITY

10.1 TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL LICENSOR, ITS DIRECTORS, EMPLOYEES, AGENTS, OR SUPPLIERS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO:

- LOSS OF PROFITS, REVENUE, OR BUSINESS;
- LOSS OF DATA OR BUSINESS INTERRUPTION;
- COST OF SUBSTITUTE GOODS OR SERVICES;

EVEN IF LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

10.2 IN NO EVENT SHALL LICENSOR'S TOTAL CUMULATIVE LIABILITY ARISING OUT OF OR RELATED TO THIS AGREEMENT EXCEED THE GREATER OF (A) THE AMOUNT YOU PAID FOR THE SOFTWARE LICENSE IN THE TWELVE (12) MONTHS PRECEDING THE CLAIM, OR (B) ONE HUNDRED US DOLLARS (USD 100).


11. INDEMNIFICATION

You agree to indemnify, defend, and hold harmless Licensor and its officers, directors, employees, and agents from and against any claims, liabilities, damages, losses, costs, and expenses (including reasonable legal fees) arising out of or related to: (a) your use of the Software in violation of this Agreement; (b) your violation of any applicable law or regulation; or (c) infringement of any third-party rights caused by your use of the Software.


12. TERM AND TERMINATION

12.1 This Agreement is effective upon your acceptance and shall continue until terminated.

12.2 This Agreement terminates automatically and without notice if you breach any term herein.

12.3 Upon termination, you must immediately cease all use of the Software and destroy all copies in your possession or control, including backup copies.

12.4 Sections 5 (Intellectual Property), 7 (User Data), 9 (Disclaimer of Warranties), 10 (Limitation of Liability), 11 (Indemnification), and 13 (Governing Law) shall survive termination.


13. GOVERNING LAW AND DISPUTE RESOLUTION

This Agreement shall be governed by and construed in accordance with the laws of the jurisdiction in which Licensor is incorporated, without regard to its conflict of law provisions. Any dispute arising from this Agreement that cannot be resolved by good-faith negotiation shall be subject to the exclusive jurisdiction of the courts of that jurisdiction.


14. SEVERABILITY

If any provision of this Agreement is found to be invalid, illegal, or unenforceable, that provision shall be modified to the minimum extent necessary to make it enforceable, and the remaining provisions shall continue in full force and effect.


15. ENTIRE AGREEMENT

This Agreement constitutes the entire agreement between you and Licensor with respect to the Software and supersedes all prior or contemporaneous understandings, agreements, negotiations, representations, and warranties, whether written or oral, relating to the Software.


BY CLICKING "ACCEPT & CONTINUE" YOU CONFIRM THAT YOU HAVE READ, UNDERSTOOD, AND AGREE TO ALL THE TERMS AND CONDITIONS OF THIS END-USER LICENSE AGREEMENT.
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
  }

  Future<void> _decline() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Agreement'),
        content: const Text(
          'You must accept the License Agreement to use BMS. '
          'The application will close if you decline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              SystemNavigator.pop();
            },
            child: const Text('Close App'),
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
            const _Header(),
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LogoBadge(),
              SizedBox(width: 12),
              Text('BMS', style: AppTextStyles.titleLarge),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'License & Terms of Use',
            style: AppTextStyles.headlineMedium,
          ),
          SizedBox(height: 4),
          Text(
            'Please read and accept the End-User License Agreement before continuing.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: SvgPicture.asset('assets/images/bms_logo.svg'),
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
      return const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 16),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'You have read the full agreement',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      );
    }
    return const Row(
      children: [
        Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 16),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Scroll to the bottom to enable acceptance',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
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
                  'I have read and agree to the End-User License Agreement and Terms of Use',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
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
            child: const Text('Decline'),
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
                : const Text('Accept & Continue'),
          ),
        ),
      ],
    );
  }
}
