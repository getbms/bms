import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/petty_cash_provider.dart';

class PettyCashScreen extends ConsumerWidget {
  const PettyCashScreen({super.key});

  void _openAddEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddEntrySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(pettyCashDateRangeProvider);
    final entriesAsync = ref.watch(pettyCashEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petty Cash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Entry',
            onPressed: () => _openAddEntry(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _DateRangeBar(range: range),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No entries for this period.', style: AppTextStyles.bodySmall),
                  );
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _EntryRow(entry: entries[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEntry(context),
        tooltip: 'Add Entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DateRangeBar extends ConsumerWidget {
  const _DateRangeBar({required this.range});
  final ({DateTime from, DateTime to}) range;

  Future<void> _pick(BuildContext context, WidgetRef ref, bool isFrom) async {
    final initial = isFrom ? range.from : range.to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    ref.read(pettyCashDateRangeProvider.notifier).set(
          isFrom ? picked : range.from,
          isFrom ? range.to : picked,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('From:', style: AppTextStyles.bodySmall),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _pick(context, ref, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(BmsDateUtils.formatDate(range.from), style: AppTextStyles.labelLarge),
            ),
          ),
          const SizedBox(width: 12),
          const Text('To:', style: AppTextStyles.bodySmall),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _pick(context, ref, false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(BmsDateUtils.formatDate(range.to), style: AppTextStyles.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry});
  final PettyCashEntry entry;

  Color _statusColor(String status) => switch (status) {
        'approved' => AppColors.success,
        'rejected' => AppColors.error,
        _ => AppColors.warning,
      };

  Color _statusBg(String status) => switch (status) {
        'approved' => AppColors.successLight,
        'rejected' => AppColors.errorLight,
        _ => AppColors.warningLight,
      };

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
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(entry.category, style: AppTextStyles.bodySmall),
          ),
          const SizedBox(width: 8),
          Text(BmsDateUtils.formatDate(entry.createdAt), style: AppTextStyles.bodySmall),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusBg(entry.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.status.toUpperCase(),
              style: AppTextStyles.bodySmall.copyWith(
                color: _statusColor(entry.status),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      onTap: entry.status == 'pending'
          ? () => showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                        title: const Text('Approve'),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          try {
                            await actions.approve(entry.id);
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
                        title: const Text('Reject'),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          try {
                            await actions.reject(entry.id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )
          : null,
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
  final _categoryController = TextEditingController();
  String _type = 'out';
  bool _saving = false;

  static const _categories = ['Food', 'Travel', 'Office', 'Maintenance', 'Other'];

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(pettyCashActionsProvider).addEntry(
            description: _description.text.trim(),
            amount: double.parse(_amount.text),
            type: _type,
            category: _categoryController.text.trim().isEmpty ? 'Other' : _categoryController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry added.')));
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
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Petty Cash Entry', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description *', isDense: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amount,
                    decoration: const InputDecoration(labelText: 'Amount *', prefixText: 'Rs. ', isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Type *', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'out', child: Text('Out (Expense)')),
                      DropdownMenuItem(value: 'in', child: Text('In (Income)')),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              optionsBuilder: (v) => _categories.where(
                (c) => c.toLowerCase().contains(v.text.toLowerCase()),
              ),
              onSelected: (v) => _categoryController.text = v,
              fieldViewBuilder: (_, controller, focusNode, onFieldSubmitted) {
                _categoryController.text = controller.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Category *', isDense: true),
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
