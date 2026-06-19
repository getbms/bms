import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/suppliers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  void _openAddSupplier(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddSupplierSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.suppliersTitle),
      ),
      body: suppliersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return Center(
              child: Text(context.l10n.noSuppliersYet, style: AppTextStyles.bodySmall),
            );
          }
          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, i) => _SupplierTile(supplier: suppliers[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSupplier(context),
        tooltip: context.l10n.addSupplier,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({required this.supplier});
  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    // balance = amount we owe the supplier (payable)
    final isOwed = supplier.balance > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryDark,
        child: Text(
          supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(supplier.name, style: AppTextStyles.labelLarge),
      subtitle: Text(
        [
          if (supplier.phone != null) supplier.phone!,
          if (supplier.address != null) supplier.address!,
        ].join(' · '),
        style: AppTextStyles.bodySmall,
      ),
      trailing: Text(
        CurrencyUtils.format(supplier.balance),
        style: AppTextStyles.titleMedium.copyWith(
          color: isOwed ? AppColors.error : AppColors.success,
        ),
      ),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _SupplierDetailSheet(supplier: supplier),
      ),
    );
  }
}

class _SupplierDetailSheet extends ConsumerWidget {
  const _SupplierDetailSheet({required this.supplier});
  final Supplier supplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(supplierPaymentHistoryProvider(supplier.id));
    final balanceColor = supplier.balance > 0 ? AppColors.error : AppColors.success;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
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
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryDark,
                child: Text(
                  supplier.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier.name, style: AppTextStyles.titleLarge),
                    if (supplier.phone != null)
                      Text(supplier.phone!, style: AppTextStyles.bodySmall),
                    if (supplier.address != null)
                      Text(supplier.address!, style: AppTextStyles.bodySmall),
                    if (supplier.paymentTerms != null)
                      Text('Terms: ${supplier.paymentTerms}', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: supplier.balance > 0 ? AppColors.errorLight : AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.amountPayable, style: AppTextStyles.bodyMedium),
                Text(
                  CurrencyUtils.format(supplier.balance),
                  style: AppTextStyles.titleMedium.copyWith(color: balanceColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.payment_rounded),
            label: Text(context.l10n.recordPayment),
            onPressed: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => _SupplierPaymentSheet(
                    supplierId: supplier.id, supplierName: supplier.name),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(context.l10n.paymentHistory, style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (payments) => payments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(context.l10n.noPayments,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  )
                : Column(
                    children: payments.map((p) => _SupplierPaymentRow(payment: p)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SupplierPaymentRow extends StatelessWidget {
  const _SupplierPaymentRow({required this.payment});

  final SupplierPayment payment;

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
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.north_east_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.method.toUpperCase(),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary, letterSpacing: 0.5),
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
                      .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
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

class _AddSupplierSheet extends ConsumerStatefulWidget {
  const _AddSupplierSheet();

  @override
  ConsumerState<_AddSupplierSheet> createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends ConsumerState<_AddSupplierSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _paymentTerms = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _paymentTerms.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(supplierActionsProvider).addSupplier(
            name: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            paymentTerms: _paymentTerms.text.trim().isEmpty ? null : _paymentTerms.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.supplierAdded)));
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
            Text(context.l10n.addSupplier, style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: context.l10n.supplierName),
              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(labelText: context.l10n.phone),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: InputDecoration(labelText: context.l10n.address),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paymentTerms,
              decoration: InputDecoration(labelText: context.l10n.paymentTerms),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.l10n.addSupplier),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierPaymentSheet extends ConsumerStatefulWidget {
  const _SupplierPaymentSheet({required this.supplierId, required this.supplierName});
  final String supplierId;
  final String supplierName;

  @override
  ConsumerState<_SupplierPaymentSheet> createState() => _SupplierPaymentSheetState();
}

class _SupplierPaymentSheetState extends ConsumerState<_SupplierPaymentSheet> {
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
      await ref.read(supplierActionsProvider).recordPayment(
            supplierId: widget.supplierId,
            amount: double.parse(_amount.text),
            method: _method,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.paymentRecorded)));
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
            Text(context.l10n.recordPaymentFor(widget.supplierName), style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              decoration: InputDecoration(labelText: context.l10n.amountRequired, prefixText: context.l10n.currencyPrefix),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return context.l10n.required;
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: InputDecoration(labelText: context.l10n.paymentMethod),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(context.l10n.paymentMethodCash)),
                DropdownMenuItem(value: 'bank', child: Text(context.l10n.paymentMethodBankTransfer)),
                DropdownMenuItem(value: 'cheque', child: Text(context.l10n.paymentMethodCheque)),
              ],
              onChanged: (v) => setState(() => _method = v ?? 'cash'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: context.l10n.notes),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.l10n.recordPayment),
            ),
          ],
        ),
      ),
    );
  }
}
