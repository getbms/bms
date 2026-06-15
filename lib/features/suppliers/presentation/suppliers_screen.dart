import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/suppliers_provider.dart';

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
        title: const Text('Suppliers'),
      ),
      body: suppliersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return const Center(
              child: Text('No suppliers yet. Add one with the button above.', style: AppTextStyles.bodySmall),
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
        tooltip: 'Add Supplier',
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

class _SupplierDetailSheet extends StatelessWidget {
  const _SupplierDetailSheet({required this.supplier});
  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    if (supplier.phone != null) Text(supplier.phone!, style: AppTextStyles.bodySmall),
                    if (supplier.address != null) Text(supplier.address!, style: AppTextStyles.bodySmall),
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
                Text('Amount Payable', style: AppTextStyles.bodyMedium),
                Text(
                  CurrencyUtils.format(supplier.balance),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: supplier.balance > 0 ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.payment),
            label: const Text('Record Payment'),
            onPressed: () {
              Navigator.of(context).pop();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => _SupplierPaymentSheet(supplierId: supplier.id, supplierName: supplier.name),
              );
            },
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier added.')));
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
            const Text('Add Supplier', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Supplier Name *', isDense: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone', isDense: true),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address', isDense: true),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paymentTerms,
              decoration: const InputDecoration(labelText: 'Payment Terms (e.g. Net 30)', isDense: true),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add Supplier'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded.')));
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
            Text('Record Payment - ${widget.supplierName}', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Amount *', prefixText: 'Rs. ', isDense: true),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Payment Method', isDense: true),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              ],
              onChanged: (v) => setState(() => _method = v ?? 'cash'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes', isDense: true),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
