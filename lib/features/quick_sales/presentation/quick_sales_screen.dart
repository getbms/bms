import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/providers/inventory_provider.dart';
import 'package:bms/providers/quick_sale_provider.dart';
import 'package:bms/shared/widgets/bms_filter_bar.dart';

class QuickSalesScreen extends ConsumerWidget {
  const QuickSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(quickSaleDateRangeProvider);
    final salesAsync = ref.watch(quickSalesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Sales'),
      ),
      body: Column(
        children: [
          BmsDateBar(
            start: range.from,
            end: range.to,
            onPick: (r) => ref.read(quickSaleDateRangeProvider.notifier).set(r.start, r.end),
          ),
          salesAsync.when(
            loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Expanded(child: Center(child: Text('Error: $e'))),
            data: (sales) {
              if (sales.isEmpty) {
                return const Expanded(
                  child: Center(
                    child: Text('No quick sales for this period.', style: AppTextStyles.bodySmall),
                  ),
                );
              }
              final total = sales.fold<double>(0, (s, e) => s + e.qty * e.price);
              return Expanded(
                child: Column(
                  children: [
                    _SummaryBar(count: sales.length, total: total),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sales.length,
                        itemBuilder: (_, i) => _SaleRow(sale: sales[i]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSaleSheet(context),
        icon: const Icon(Icons.flash_on_rounded),
        label: const Text('Quick Sale'),
      ),
    );
  }

  void _showSaleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _QuickSaleSheet(),
    );
  }
}


class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.count, required this.total});
  final int count;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryLight.withAlpha(30),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count sales', style: AppTextStyles.labelLarge),
              const Text('for period', style: AppTextStyles.bodySmall),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyUtils.format(total),
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.success)),
              const Text('total revenue', style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.sale});
  final NoInvoiceSale sale;

  @override
  Widget build(BuildContext context) {
    final qty = sale.qty % 1 == 0
        ? sale.qty.toStringAsFixed(0)
        : sale.qty.toStringAsFixed(1);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceVariant,
        child: const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.primary),
      ),
      title: Text(sale.productName, style: AppTextStyles.labelLarge),
      subtitle: Text(
        '$qty × ${CurrencyUtils.format(sale.price)}  •  ${sale.createdAt.day}/${sale.createdAt.month}/${sale.createdAt.year}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Text(
        CurrencyUtils.format(sale.qty * sale.price),
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.success),
      ),
    );
  }
}

class _QuickSaleSheet extends ConsumerStatefulWidget {
  const _QuickSaleSheet();

  @override
  ConsumerState<_QuickSaleSheet> createState() => _QuickSaleSheetState();
}

class _QuickSaleSheetState extends ConsumerState<_QuickSaleSheet> {
  Product? _selected;
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _search = '';
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final product = _selected;
    if (product == null) return;
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity and price must be greater than zero'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(quickSaleActionsProvider).sell(
            product: product,
            qty: qty,
            price: price,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quick sale recorded: ${product.name} × $qty'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final stockAsync = ref.watch(stockStreamProvider);
    final stockMap = stockAsync.whenData((list) => {for (final s in list) s.productId: s}).asData?.value ?? {};

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Quick Sale', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),

            if (_selected == null) ...[
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Search product...',
                                  ),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
              ),
              const SizedBox(height: 8),
              productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (products) {
                  final filtered = _search.isEmpty
                      ? products.where((p) => p.isActive).take(10).toList()
                      : products
                          .where((p) =>
                              p.isActive &&
                              (p.name.toLowerCase().contains(_search) ||
                                  (p.barcode?.toLowerCase().contains(_search) ?? false)))
                          .take(10)
                          .toList();
                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        final qty = stockMap[p.id]?.qty ?? 0.0;
                        return ListTile(
                          dense: true,
                          title: Text(p.name, style: AppTextStyles.labelLarge),
                          subtitle: Text('Stock: ${qty.toStringAsFixed(0)}  •  ${CurrencyUtils.format(p.sellPrice)}',
                              style: AppTextStyles.bodySmall),
                          onTap: () {
                            setState(() {
                              _selected = p;
                              _priceCtrl.text = p.sellPrice.toStringAsFixed(2);
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selected!.name, style: AppTextStyles.labelLarge),
                        Text('Selected product', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selected = null;
                      _search = '';
                    }),
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      decoration: const InputDecoration(labelText: 'Qty'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                      decoration: const InputDecoration(labelText: 'Price', prefixText: 'Rs. '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Record Sale', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
