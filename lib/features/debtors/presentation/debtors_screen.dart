import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/providers/customers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DebtorsScreen extends ConsumerWidget {
  const DebtorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtorsAsync = ref.watch(debtorsFutureProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debtors')),
      body: debtorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (debtors) {
          if (debtors.isEmpty) {
            return const Center(
              child: Text('No outstanding debts.', style: AppTextStyles.bodySmall),
            );
          }

          final total = debtors.fold<double>(0, (sum, c) => sum + c.balance);
          final over30 = debtors.where((c) => _daysSince(c.updatedAt) > 30).length;
          final over60 = debtors.where((c) => _daysSince(c.updatedAt) > 60).length;

          return Column(
            children: [
              _SummaryBanner(total: total, over30: over30, over60: over60, count: debtors.length),
              Expanded(
                child: ListView.builder(
                  itemCount: debtors.length,
                  itemBuilder: (_, i) => _DebtorTile(customer: debtors[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static int _daysSince(DateTime dt) => DateTime.now().difference(dt).inDays;
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.total,
    required this.count,
    required this.over30,
    required this.over60,
  });

  final double total;
  final int count;
  final int over30;
  final int over60;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.error.withAlpha(15),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Outstanding', style: AppTextStyles.bodySmall),
                Text(CurrencyUtils.format(total),
                    style: AppTextStyles.headlineMedium.copyWith(color: AppColors.error)),
                Text('$count debtor${count == 1 ? '' : 's'}', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AgingChip(label: '30+ days', count: over30, color: AppColors.warning),
              const SizedBox(height: 6),
              _AgingChip(label: '60+ days', count: over60, color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgingChip extends StatelessWidget {
  const _AgingChip({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count  $label',
        style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DebtorTile extends StatelessWidget {
  const _DebtorTile({required this.customer});

  final Customer customer;

  Color _agingColor(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days > 60) return AppColors.error;
    if (days > 30) return AppColors.warning;
    return AppColors.success;
  }

  String _agingLabel(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days > 60) return '60+ days';
    if (days > 30) return '30+ days';
    return 'Current';
  }

  @override
  Widget build(BuildContext context) {
    final color = _agingColor(customer.updatedAt);
    final label = _agingLabel(customer.updatedAt);

    return ListTile(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _DebtorDetailSheet(customer: customer),
      ),
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(30),
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(customer.name, style: AppTextStyles.labelLarge),
      subtitle: Text(
        [if (customer.phone != null) customer.phone!, label].join(' · '),
        style: AppTextStyles.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CurrencyUtils.format(customer.balance),
            style: AppTextStyles.labelLarge.copyWith(color: color),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textDisabled),
        ],
      ),
    );
  }
}

// ── Detail + Payment Sheet ──────────────────────────────────────────────────

class _DebtorDetailSheet extends ConsumerWidget {
  const _DebtorDetailSheet({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(customerPaymentHistoryProvider(customer.id));
    final color = customer.balance > 0 ? AppColors.error : AppColors.success;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          // drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withAlpha(20),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: AppTextStyles.titleLarge),
                    if (customer.phone != null)
                      Text(customer.phone!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Balance card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Outstanding Balance', style: AppTextStyles.bodySmall),
                    Text(
                      CurrencyUtils.format(customer.balance),
                      style: AppTextStyles.headlineMedium.copyWith(color: color),
                    ),
                  ],
                ),
                if (customer.creditLimit > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Credit Limit', style: AppTextStyles.bodySmall),
                      Text(
                        CurrencyUtils.format(customer.creditLimit),
                        style: AppTextStyles.labelLarge,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Record Payment button
          ElevatedButton.icon(
            icon: const Icon(Icons.payment_rounded),
            label: const Text('Record Payment'),
            onPressed: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => _RecordPaymentSheet(
                  customerId: customer.id,
                  customerName: customer.name,
                  outstanding: customer.balance,
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Payment History
          const Text('Payment History', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (payments) => payments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No payments recorded yet.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  )
                : Column(
                    children: payments
                        .map((p) => _PaymentHistoryRow(payment: p))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.south_west_rounded, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.method.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary, letterSpacing: 0.5),
                ),
                if (payment.notes != null)
                  Text(payment.notes!, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyUtils.format(payment.amount),
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
              Text(
                DateFormat('dd MMM yyyy').format(payment.createdAt),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Record Payment Sheet ────────────────────────────────────────────────────

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  const _RecordPaymentSheet({
    required this.customerId,
    required this.customerName,
    required this.outstanding,
  });

  final String customerId;
  final String customerName;
  final double outstanding;

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _method = 'cash';
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(customerActionsProvider).recordPayment(
            customerId: widget.customerId,
            amount: double.parse(_amount.text),
            method: _method,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
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
            const Text('Record Payment', style: AppTextStyles.titleLarge),
            Text(widget.customerName,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            if (widget.outstanding > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Outstanding', style: AppTextStyles.bodySmall),
                    Text(CurrencyUtils.format(widget.outstanding),
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.error)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Amount *', prefixText: 'Rs. '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              ],
              onChanged: (v) => setState(() => _method = v ?? 'cash'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
