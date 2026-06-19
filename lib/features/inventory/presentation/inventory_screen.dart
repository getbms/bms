import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/inventory_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(inventoryLowStockFilterProvider)) {
        setState(() => _lowStockOnly = true);
        ref.read(inventoryLowStockFilterProvider.notifier).reset();
      }
    });
  }

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
        title: Text(context.l10n.inventoryTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.l10n.searchProducts,
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
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(context.l10n.lowStockOnly),
                selected: _lowStockOnly,
                onSelected: (v) => setState(() => _lowStockOnly = v),
              ),
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

                final filtered = products.where((p) {
                  if (_query.isNotEmpty) {
                    final match = p.name.toLowerCase().contains(_query) ||
                        (p.brand?.toLowerCase().contains(_query) ?? false) ||
                        (p.barcode?.toLowerCase().contains(_query) ?? false);
                    if (!match) return false;
                  }
                  if (_lowStockOnly) {
                    final qty = stockMap[p.id]?.qty ?? 0.0;
                    if (qty > p.reorderLevel) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text(context.l10n.noProductsFound, style: AppTextStyles.bodySmall));
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
        tooltip: context.l10n.addProduct,
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
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? context.l10n.productUpdated : context.l10n.productAdded)),
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
            Text(_isEdit ? context.l10n.editProduct : context.l10n.addProduct, style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: context.l10n.productName),
              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.required : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brand,
                    decoration: InputDecoration(labelText: context.l10n.brand),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _barcode,
                    decoration: InputDecoration(labelText: context.l10n.barcode),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unitType,
                    decoration: InputDecoration(labelText: context.l10n.unitType),
                    items: [
                      DropdownMenuItem(value: 'pcs', child: Text(context.l10n.unitPieces)),
                      DropdownMenuItem(value: 'kg', child: Text(context.l10n.unitKg)),
                      DropdownMenuItem(value: 'g', child: Text(context.l10n.unitGrams)),
                      DropdownMenuItem(value: 'l', child: Text(context.l10n.unitLitres)),
                      DropdownMenuItem(value: 'ml', child: Text(context.l10n.unitMl)),
                      DropdownMenuItem(value: 'box', child: Text(context.l10n.unitBox)),
                    ],
                    onChanged: (v) => setState(() => _unitType = v ?? 'pcs'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _reorderLevel,
                    decoration: InputDecoration(labelText: context.l10n.reorderLevel),
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
                    decoration: InputDecoration(labelText: context.l10n.costPrice, prefixText: context.l10n.currencyPrefix),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return context.l10n.required;
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellPrice,
                    decoration: InputDecoration(labelText: context.l10n.sellPrice, prefixText: context.l10n.currencyPrefix),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return context.l10n.required;
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
                decoration: InputDecoration(labelText: context.l10n.stockQty),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? context.l10n.updateProduct : context.l10n.addProduct),
            ),
          ],
        ),
      ),
    );
  }
}
