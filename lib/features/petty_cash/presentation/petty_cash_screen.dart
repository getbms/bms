import 'dart:io';

import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/core/utils/date_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/petty_cash_provider.dart';
import 'package:bms/shared/widgets/bms_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class PettyCashScreen extends ConsumerWidget {
  const PettyCashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(pettyCashDateRangeProvider);
    final entriesAsync = ref.watch(pettyCashEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pettyCashTitle)),
      body: Column(
        children: [
          BmsDateBar(
            start: range.from,
            end: range.to,
            onPick: (r) => ref.read(pettyCashDateRangeProvider.notifier).set(r.start, r.end),
          ),
          entriesAsync.when(
            loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Expanded(child: Center(child: Text('Error: $e'))),
            data: (entries) {
              final totalIn = entries
                  .where((e) => e.type == 'in')
                  .fold<double>(0, (s, e) => s + e.amount);
              final totalOut = entries
                  .where((e) => e.type == 'out')
                  .fold<double>(0, (s, e) => s + e.amount);

              return Expanded(
                child: Column(
                  children: [
                    _FloatCard(totalIn: totalIn, totalOut: totalOut),
                    Expanded(
                      child: entries.isEmpty
                          ? Center(
                              child: Text(context.l10n.noEntriesFound,
                                  style: AppTextStyles.bodySmall),
                            )
                          : ListView.builder(
                              itemCount: entries.length,
                              itemBuilder: (_, i) => _EntryRow(entry: entries[i]),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const _AddEntrySheet(),
        ),
        tooltip: context.l10n.addEntry,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FloatCard extends StatelessWidget {
  const _FloatCard({required this.totalIn, required this.totalOut});
  final double totalIn;
  final double totalOut;

  @override
  Widget build(BuildContext context) {
    final net = totalIn - totalOut;
    return Container(
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Stat(label: context.l10n.inLabel, amount: totalIn, color: AppColors.success),
          const SizedBox(width: 16),
          _Stat(label: context.l10n.outLabel, amount: totalOut, color: AppColors.error),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(context.l10n.balance, style: AppTextStyles.bodySmall),
              Text(
                CurrencyUtils.format(net),
                style: AppTextStyles.titleMedium.copyWith(
                  color: net >= 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.amount, required this.color});
  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(CurrencyUtils.format(amount),
            style: AppTextStyles.labelLarge.copyWith(color: color)),
      ],
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry});
  final PettyCashEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOut = entry.type == 'out';
    final actions = ref.read(pettyCashActionsProvider);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isOut ? AppColors.errorLight : AppColors.successLight,
        child: Icon(
          isOut ? Icons.arrow_upward : Icons.arrow_downward,
          color: isOut ? AppColors.error : AppColors.success,
          size: 20,
        ),
      ),
      title: Text(entry.description, style: AppTextStyles.labelLarge),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            children: [
              _Chip(label: entry.category),
              Text(BmsDateUtils.formatDate(entry.createdAt), style: AppTextStyles.bodySmall),
              if (entry.receiptPhotoPath != null)
                GestureDetector(
                  onTap: () => _viewPhoto(context, entry.receiptPhotoPath!),
                  child: const _Chip(
                    label: 'Receipt',
                    color: AppColors.primary,
                    textColor: Colors.white,
                  ),
                ),
            ],
          ),
          if (entry.approvalNotes != null && entry.approvalNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Reason: ${entry.approvalNotes}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyUtils.format(entry.amount),
            style: AppTextStyles.titleMedium.copyWith(
              color: isOut ? AppColors.error : AppColors.success,
            ),
          ),
          const SizedBox(height: 4),
          _StatusBadge(status: entry.status),
        ],
      ),
      onTap: entry.status == 'pending'
          ? () => _showApprovalSheet(context, actions, entry.id)
          : null,
    );
  }

  void _viewPhoto(BuildContext context, String path) {
    final file = File(path);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.existsSync())
              Image.file(file)
            else
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.receiptNotFound),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  void _showApprovalSheet(
    BuildContext context,
    PettyCashActions actions,
    String id,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.approveOrReject, style: AppTextStyles.titleMedium),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
              title: Text(context.l10n.approve),
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  await actions.approve(id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: AppColors.error),
              title: Text(context.l10n.reject),
              onTap: () {
                Navigator.of(ctx).pop();
                _showRejectNotesSheet(context, actions, id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectNotesSheet(
    BuildContext context,
    PettyCashActions actions,
    String id,
  ) {
    final notesCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.rejectionReason, style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                hintText: context.l10n.rejectionReasonHint,
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
                notesCtrl.dispose();
                try {
                  await actions.reject(id, notes: notes);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: Text(context.l10n.confirmReject),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _color => switch (status) {
        'approved' => AppColors.success,
        'rejected' => AppColors.error,
        _ => AppColors.warning,
      };

  Color get _bg => switch (status) {
        'approved' => AppColors.successLight,
        'rejected' => AppColors.errorLight,
        _ => AppColors.warningLight,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color: _color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color, this.textColor});
  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(color: textColor),
      ),
    );
  }
}

class _AddEntrySheet extends ConsumerStatefulWidget {
  const _AddEntrySheet();

  @override
  ConsumerState<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends ConsumerState<_AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  String _type = 'out';
  String _category = 'Other';
  String? _photoPath;
  bool _saving = false;

  static const _categories = [
    'Food', 'Travel', 'Office', 'Maintenance', 'Utilities', 'Salary', 'Other'
  ];

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile != null) setState(() => _photoPath = xFile.path);
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (xFile != null) setState(() => _photoPath = xFile.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(pettyCashActionsProvider).addEntry(
            description: _description.text.trim(),
            amount: double.parse(_amount.text),
            type: _type,
            category: _category,
            receiptPhotoPath: _photoPath,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.entryAdded)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.addPettyCashEntry, style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: InputDecoration(labelText: context.l10n.description),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? context.l10n.required : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amount,
                    decoration: InputDecoration(
                        labelText: context.l10n.amountRequired, prefixText: context.l10n.currencyPrefix),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return context.l10n.required;
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration:
                        InputDecoration(labelText: context.l10n.entryType),
                    items: [
                      DropdownMenuItem(value: 'out', child: Text(context.l10n.typeOut)),
                      DropdownMenuItem(value: 'in', child: Text(context.l10n.typeIn)),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration:
                  InputDecoration(labelText: context.l10n.category),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Other'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(context.l10n.receipt, style: AppTextStyles.bodySmall),
                const SizedBox(width: 8),
                if (_photoPath != null) ...[
                  GestureDetector(
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => Dialog(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.file(File(_photoPath!)),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(_photoPath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => _photoPath = null),
                    child: Text(context.l10n.removeReceipt),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(context.l10n.gallery),
                    style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    onPressed: _pickPhoto,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: Text(context.l10n.camera),
                    style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    onPressed: _takePhoto,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.l10n.addEntry),
            ),
          ],
        ),
      ),
    );
  }
}
