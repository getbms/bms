import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/providers/grn_provider.dart';
import 'package:bms/providers/inventory_provider.dart';
import 'package:bms/providers/suppliers_provider.dart';

class GrnScreen extends ConsumerStatefulWidget {
  const GrnScreen({super.key});

  @override
  ConsumerState<GrnScreen> createState() => _GrnScreenState();
}

class _GrnScreenState extends ConsumerState<GrnScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GRN - Goods Receipt'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'New GRN'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewGrnTab(),
          _GrnHistoryTab(),
        ],
      ),
    );
  }
}


class _NewGrnTab extends ConsumerWidget {
  const _NewGrnTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(grnProvider);

    return Column(
      children: [
        // Step 1: Supplier selector
        _SupplierCard(selected: state.supplier),
        const Divider(height: 1),

        // Step 2: Items
        Expanded(
          child: state.supplier == null
              ? const Center(
                  child: Text(
                    'Select a supplier to start',
                    style: AppTextStyles.bodySmall,
                  ),
                )
              : _ItemsSection(items: state.items),
        ),
        const Divider(height: 1),

        // Footer total + confirm
        if (state.supplier != null && state.items.isNotEmpty)
          _GrnFooter(state: state),
      ],
    );
  }
}

class _SupplierCard extends ConsumerWidget {
  const _SupplierCard({required this.selected});
  final Supplier? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.local_shipping_rounded, color: AppColors.primary),
      title: Text(
        selected?.name ?? 'Select Supplier',
        style: selected != null
            ? AppTextStyles.labelLarge
            : AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showSupplierPicker(context, ref),
    );
  }

  void _showSupplierPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SupplierPickerSheet(
        onPick: (s) {
          ref.read(grnProvider.notifier).setSupplier(s);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _SupplierPickerSheet extends ConsumerStatefulWidget {
  const _SupplierPickerSheet({required this.onPick});
  final void Function(Supplier) onPick;

  @override
  ConsumerState<_SupplierPickerSheet> createState() =>
      _SupplierPickerSheetState();
}

class _SupplierPickerSheetState extends ConsumerState<_SupplierPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select Supplier', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Search...',
                          ),
            onChanged: (v) => setState(() => _q = v.toLowerCase()),
          ),
          const SizedBox(height: 8),
          suppliersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (suppliers) {
              final filtered = _q.isEmpty
                  ? suppliers
                  : suppliers.where((s) => s.name.toLowerCase().contains(_q)).toList();
              return SizedBox(
                height: 260,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(filtered[i].name, style: AppTextStyles.labelLarge),
                    subtitle: Text(filtered[i].phone ?? '', style: AppTextStyles.bodySmall),
                    onTap: () => widget.onPick(filtered[i]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ItemsSection extends ConsumerWidget {
  const _ItemsSection({required this.items});
  final List<GrnCartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text('Items (${items.length})', style: AppTextStyles.labelLarge),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _showProductPicker(context, ref),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text('Add items from your product catalog', style: AppTextStyles.bodySmall))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _GrnItemRow(
                    key: ValueKey(items[i].product.id),
                    item: items[i],
                  ),
                ),
        ),
      ],
    );
  }

  void _showProductPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductPickerSheet(
        onPick: (p) {
          ref.read(grnProvider.notifier).addItem(p);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet({required this.onPick});
  final void Function(Product) onPick;

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add Product', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Search product...',
                          ),
            onChanged: (v) => setState(() => _q = v.toLowerCase()),
          ),
          const SizedBox(height: 8),
          productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (products) {
              final active = products.where((p) => p.isActive).toList();
              final filtered = _q.isEmpty
                  ? active.take(15).toList()
                  : active
                      .where((p) => p.name.toLowerCase().contains(_q) ||
                          (p.barcode?.toLowerCase().contains(_q) ?? false))
                      .take(15)
                      .toList();
              return SizedBox(
                height: 280,
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return ListTile(
                      dense: true,
                      title: Text(p.name, style: AppTextStyles.labelLarge),
                      subtitle: Text(
                          'Cost: ${CurrencyUtils.format(p.costPrice)}',
                          style: AppTextStyles.bodySmall),
                      trailing: const Icon(Icons.add_circle_outline, size: 20),
                      onTap: () => widget.onPick(p),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GrnItemRow extends ConsumerStatefulWidget {
  const _GrnItemRow({super.key, required this.item});
  final GrnCartItem item;

  @override
  ConsumerState<_GrnItemRow> createState() => _GrnItemRowState();
}

class _GrnItemRowState extends ConsumerState<_GrnItemRow> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
        text: widget.item.qty.toStringAsFixed(widget.item.qty % 1 == 0 ? 0 : 1));
    _priceCtrl = TextEditingController(
        text: widget.item.costPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(grnProvider.notifier);
    final pid = widget.item.product.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(widget.item.product.name, style: AppTextStyles.labelLarge),
            ),
            SizedBox(
              width: 64,
              child: TextField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(
                    labelText: 'Qty', contentPadding: EdgeInsets.all(6)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (v) =>
                    notifier.updateItem(pid, qty: double.tryParse(v) ?? widget.item.qty),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: TextField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                    labelText: 'Cost', contentPadding: EdgeInsets.all(6)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (v) =>
                    notifier.updateItem(pid, costPrice: double.tryParse(v) ?? widget.item.costPrice),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text(
                CurrencyUtils.format(widget.item.lineTotal),
                textAlign: TextAlign.end,
                style: AppTextStyles.labelLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => notifier.removeItem(pid),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrnFooter extends ConsumerWidget {
  const _GrnFooter({required this.state});
  final GrnState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: AppTextStyles.titleMedium),
              Text(CurrencyUtils.format(state.total),
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      try {
                        final grnNo = await ref.read(grnProvider.notifier).confirm();
                        if (!context.mounted) return;
                        if (grnNo != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('GRN $grnNo confirmed - stock updated'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    },
              child: state.isSubmitting
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm GRN & Stock In',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: state.isSubmitting ? null : () => ref.read(grnProvider.notifier).reset(),
            child: const Text('Clear', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}


class _GrnHistoryTab extends ConsumerWidget {
  const _GrnHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grnAsync = ref.watch(grnListProvider);

    return grnAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (grns) {
        if (grns.isEmpty) {
          return const Center(
            child: Text('No GRNs yet.', style: AppTextStyles.bodySmall),
          );
        }
        return ListView.builder(
          itemCount: grns.length,
          itemBuilder: (_, i) => _GrnHistoryRow(purchase: grns[i]),
        );
      },
    );
  }
}

class _GrnHistoryRow extends StatelessWidget {
  const _GrnHistoryRow({required this.purchase});
  final Purchase purchase;

  @override
  Widget build(BuildContext context) {
    final d = purchase.createdAt;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceVariant,
        child: const Icon(Icons.move_to_inbox_rounded, size: 18, color: AppColors.primary),
      ),
      title: Text(purchase.grnNumber ?? purchase.id, style: AppTextStyles.labelLarge),
      subtitle: Text(
        '${d.day}/${d.month}/${d.year}  •  ${purchase.supplierId}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Text(
        CurrencyUtils.format(purchase.total),
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
      ),
    );
  }
}
