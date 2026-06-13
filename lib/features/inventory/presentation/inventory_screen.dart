import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm({Product? product, double? currentQty}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProductFormSheet(product: product, currentQty: currentQty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final stockAsync = ref.watch(stockStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (products) {
                final stockMap = stockAsync.whenData((list) {
                  return {for (final s in list) s.productId: s};
                }).asData?.value ?? {};

                final filtered = _query.isEmpty
                    ? products
                    : products.where((p) {
                        return p.name.toLowerCase().contains(_query) ||
                            (p.brand?.toLowerCase().contains(_query) ?? false) ||
                            (p.barcode?.toLowerCase().contains(_query) ?? false);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found.', style: AppTextStyles.bodySmall));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    final stock = stockMap[p.id];
                    final qty = stock?.qty ?? 0.0;
                    final isLow = qty <= p.reorderLevel;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(p.name, style: AppTextStyles.labelLarge),
                      subtitle: Text(
                        [
                          if (p.brand != null) p.brand!,
                          if (p.barcode != null) p.barcode!,
                        ].join(' · '),
                        style: AppTextStyles.bodySmall,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(CurrencyUtils.format(p.sellPrice), style: AppTextStyles.titleMedium),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLow ? AppColors.warningLight : AppColors.successLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Qty: ${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isLow ? AppColors.warning : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _openForm(product: p, currentQty: qty),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductFormSheet extends ConsumerStatefulWidget {
  const _ProductFormSheet({this.product, this.currentQty});

  final Product? product;
  final double? currentQty;

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _barcode;
  late final TextEditingController _costPrice;
  late final TextEditingController _sellPrice;
  late final TextEditingController _reorderLevel;
  late final TextEditingController _stockQty;
  String _unitType = 'pcs';
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _costPrice = TextEditingController(text: p != null ? p.costPrice.toStringAsFixed(2) : '');
    _sellPrice = TextEditingController(text: p != null ? p.sellPrice.toStringAsFixed(2) : '');
    _reorderLevel = TextEditingController(text: p != null ? p.reorderLevel.toString() : '10');
    _stockQty = TextEditingController(
        text: widget.currentQty != null ? widget.currentQty!.toStringAsFixed(0) : '0');
    _unitType = p?.unitType ?? 'pcs';
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _barcode.dispose();
    _costPrice.dispose();
    _sellPrice.dispose();
    _reorderLevel.dispose();
    _stockQty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final actions = ref.read(inventoryActionsProvider);
      final authState = ref.read(currentAuthStateProvider);
      final userId = authState is Authenticated ? authState.user.id : 'system';

      await actions.saveProduct(
        existingId: widget.product?.id,
        name: _name.text.trim(),
        unitType: _unitType,
        costPrice: double.parse(_costPrice.text),
        sellPrice: double.parse(_sellPrice.text),
        barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        reorderLevel: int.tryParse(_reorderLevel.text) ?? 10,
      );

      // For edits only: if qty changed, call adjustStock
      if (_isEdit && widget.product != null) {
        final newQty = double.tryParse(_stockQty.text) ?? 0;
        if (newQty != (widget.currentQty ?? 0)) {
          await actions.adjustStock(
            productId: widget.product!.id,
            newQty: newQty,
            userId: userId,
            reason: 'manual adjustment',
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Product updated.' : 'Product added.')),
      );
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
            Text(_isEdit ? 'Edit Product' : 'New Product', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Product Name *', isDense: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brand,
                    decoration: const InputDecoration(labelText: 'Brand', isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _barcode,
                    decoration: const InputDecoration(labelText: 'Barcode', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unitType,
                    decoration: const InputDecoration(labelText: 'Unit Type *', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'pcs', child: Text('Pieces')),
                      DropdownMenuItem(value: 'kg', child: Text('Kg')),
                      DropdownMenuItem(value: 'g', child: Text('Grams')),
                      DropdownMenuItem(value: 'l', child: Text('Litres')),
                      DropdownMenuItem(value: 'ml', child: Text('Ml')),
                      DropdownMenuItem(value: 'box', child: Text('Box')),
                    ],
                    onChanged: (v) => setState(() => _unitType = v ?? 'pcs'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _reorderLevel,
                    decoration: const InputDecoration(labelText: 'Reorder Level', isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costPrice,
                    decoration: const InputDecoration(labelText: 'Cost Price *', prefixText: 'Rs. ', isDense: true),
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
                  child: TextFormField(
                    controller: _sellPrice,
                    decoration: const InputDecoration(labelText: 'Sell Price *', prefixText: 'Rs. ', isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockQty,
                decoration: const InputDecoration(labelText: 'Stock Qty', isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Update Product' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
