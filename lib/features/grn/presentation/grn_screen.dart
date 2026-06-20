import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/grn_provider.dart';
import 'package:bms/providers/inventory_provider.dart';
import 'package:bms/providers/suppliers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    _tabs = TabController(length: 3, vsync: this);
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
        title: Text(context.l10n.grnTitle),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: context.l10n.newGrn),
            Tab(text: context.l10n.grnHistory),
            Tab(text: context.l10n.purchaseOrders),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewGrnTab(),
          _GrnHistoryTab(),
          _PoTab(),
        ],
      ),
    );
  }
}

// ---- New GRN Tab ----

class _NewGrnTab extends ConsumerWidget {
  const _NewGrnTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(grnProvider);

    return Column(
      children: [
        _SupplierCard(selected: state.supplier),
        if (state.supplier != null) _PoLinkRow(state: state),
        const Divider(height: 1),
        Expanded(
          child: state.supplier == null
              ? Center(
                  child: Text(context.l10n.selectSupplierToStart, style: AppTextStyles.bodySmall))
              : _ItemsSection(items: state.items),
        ),
        const Divider(height: 1),
        if (state.supplier != null && state.items.isNotEmpty) _GrnFooter(state: state),
      ],
    );
  }
}

class _PoLinkRow extends ConsumerWidget {
  const _PoLinkRow({required this.state});
  final GrnState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplierId = state.supplier!.id;
    final poAsync = ref.watch(poBySupplierProvider(supplierId));

    return poAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (pos) {
        final openPos = pos.where((p) => p.status == 'draft' || p.status == 'sent').toList();
        if (openPos.isEmpty) return const SizedBox.shrink();

        final linked = state.linkedPoId;
        final linkedPo = linked != null
            ? openPos.where((p) => p.id == linked).firstOrNull
            : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  linkedPo != null ? context.l10n.linkedPo(linkedPo.poNumber) : context.l10n.linkToPo,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: linkedPo != null ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _showPoPicker(context, ref, openPos),
                child: Text(linkedPo != null ? context.l10n.change : 'Select',
                    style: const TextStyle(fontSize: 12)),
              ),
              if (linkedPo != null)
                GestureDetector(
                  onTap: () => ref.read(grnProvider.notifier).setLinkedPO(null),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPoPicker(BuildContext context, WidgetRef ref, List<PurchaseOrder> pos) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.selectPurchaseOrder, style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            ...pos.map((po) => ListTile(
                  dense: true,
                  title: Text(po.poNumber, style: AppTextStyles.labelLarge),
                  subtitle: Text(
                    '${CurrencyUtils.format(po.total)}  •  ${po.status.toUpperCase()}',
                    style: AppTextStyles.bodySmall,
                  ),
                  onTap: () {
                    ref.read(grnProvider.notifier).setLinkedPO(po.id);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
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
        selected?.name ?? context.l10n.selectSupplier,
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
  ConsumerState<_SupplierPickerSheet> createState() => _SupplierPickerSheetState();
}

class _SupplierPickerSheetState extends ConsumerState<_SupplierPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.selectSupplier, style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: context.l10n.search,
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
              Text('${context.l10n.items} (${items.length})', style: AppTextStyles.labelLarge),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.l10n.addItem),
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
              ? Center(
                  child: Text(context.l10n.addItemsHint,
                      style: AppTextStyles.bodySmall))
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
  ConsumerState<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.addProduct, style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: context.l10n.searchProduct,
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
                      .where((p) =>
                          p.name.toLowerCase().contains(_q) ||
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
                      subtitle: Text('Cost: ${CurrencyUtils.format(p.costPrice)}',
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
    _priceCtrl = TextEditingController(text: widget.item.costPrice.toStringAsFixed(2));
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
                decoration: InputDecoration(
                    labelText: context.l10n.qty, contentPadding: const EdgeInsets.all(6)),
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
                decoration: InputDecoration(
                    labelText: context.l10n.cost, contentPadding: const EdgeInsets.all(6)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (v) => notifier.updateItem(pid,
                    costPrice: double.tryParse(v) ?? widget.item.costPrice),
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

class _GrnFooter extends ConsumerStatefulWidget {
  const _GrnFooter({required this.state});
  final GrnState state;

  @override
  ConsumerState<_GrnFooter> createState() => _GrnFooterState();
}

class _GrnFooterState extends ConsumerState<_GrnFooter> {
  final _invoiceNoCtrl = TextEditingController();
  final _invoiceAmtCtrl = TextEditingController();

  @override
  void dispose() {
    _invoiceNoCtrl.dispose();
    _invoiceAmtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = ref.read(grnProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _invoiceNoCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.supplierInvoiceNo,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (v) => notifier.setSupplierInvoice(
                    invoiceNo: v.isEmpty ? null : v,
                    amount: state.supplierInvoiceAmount,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _invoiceAmtCtrl,
                  decoration: InputDecoration(
                    labelText: context.l10n.supplierInvoiceAmt,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  onChanged: (v) => notifier.setSupplierInvoice(
                    invoiceNo: state.supplierInvoiceNo,
                    amount: double.tryParse(v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.total, style: AppTextStyles.titleMedium),
              Text(CurrencyUtils.format(state.total),
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          if (state.supplierInvoiceAmount != null &&
              (state.supplierInvoiceAmount! - state.total).abs() > 0.01)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n.discrepancy(CurrencyUtils.format((state.total - state.supplierInvoiceAmount!).abs())),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
              ),
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
                              content: Text(context.l10n.grnConfirmed(grnNo)),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    },
              child: state.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(context.l10n.confirmGrn,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed:
                state.isSubmitting ? null : () => ref.read(grnProvider.notifier).reset(),
            child: Text(context.l10n.clear, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ---- GRN History Tab ----

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
          return Center(child: Text(context.l10n.noGrnsYet, style: AppTextStyles.bodySmall));
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
      leading: const CircleAvatar(
        backgroundColor: AppColors.surfaceVariant,
        child: Icon(Icons.move_to_inbox_rounded, size: 18, color: AppColors.primary),
      ),
      title: Text(purchase.grnNumber ?? purchase.id, style: AppTextStyles.labelLarge),
      subtitle: Text(
        '${d.day}/${d.month}/${d.year}  •  ${purchase.supplierId}'
        '${purchase.supplierInvoiceNo != null ? '  •  Inv: ${purchase.supplierInvoiceNo}' : ''}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Text(
        CurrencyUtils.format(purchase.total),
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ---- Purchase Orders Tab ----

class _PoTab extends ConsumerWidget {
  const _PoTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(poListProvider);

    return Scaffold(
      body: posAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pos) {
          if (pos.isEmpty) {
            return Center(
              child: Text(context.l10n.noPurchaseOrdersYet, style: AppTextStyles.bodySmall));
          }
          return ListView.builder(
            itemCount: pos.length,
            itemBuilder: (_, i) => _PoRow(
              po: pos[i],
              onTap: () => _showPoDetail(context, ref, pos[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePo(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newPo),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreatePo(BuildContext context, WidgetRef ref) {
    ref.read(poProvider.notifier).reset();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreatePoSheet(),
    );
  }

  void _showPoDetail(BuildContext context, WidgetRef ref, PurchaseOrder po) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PoDetailSheet(po: po),
    );
  }
}

Color _poStatusColor(String status) {
  switch (status) {
    case 'draft':
      return AppColors.textSecondary;
    case 'sent':
      return AppColors.warning;
    case 'partially_received':
      return Colors.orange;
    case 'received':
      return AppColors.success;
    case 'cancelled':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

String _poStatusLabel(String status) {
  switch (status) {
    case 'draft':
      return 'Draft';
    case 'sent':
      return 'Sent';
    case 'partially_received':
      return 'Partial';
    case 'received':
      return 'Received';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}

class _PoRow extends StatelessWidget {
  const _PoRow({required this.po, required this.onTap});
  final PurchaseOrder po;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = po.createdAt;
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.surfaceVariant,
        child: Icon(Icons.description_rounded, size: 18, color: AppColors.primary),
      ),
      title: Text(po.poNumber, style: AppTextStyles.labelLarge),
      subtitle: Text(
        '${d.day}/${d.month}/${d.year}  •  ${CurrencyUtils.format(po.total)}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _poStatusColor(po.status).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _poStatusLabel(po.status),
          style: AppTextStyles.bodySmall.copyWith(
            color: _poStatusColor(po.status),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _PoDetailSheet extends ConsumerWidget {
  const _PoDetailSheet({required this.po});
  final PurchaseOrder po;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(poItemsProvider(po.id));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(po.poNumber, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Created ${po.createdAt.day}/${po.createdAt.month}/${po.createdAt.year}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _poStatusColor(po.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _poStatusLabel(po.status),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _poStatusColor(po.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (po.notes != null) ...[
            const SizedBox(height: 8),
            Text(po.notes!, style: AppTextStyles.bodySmall),
          ],
          const SizedBox(height: 16),
          Text(context.l10n.items, style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (items) => Column(
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(item.productId, style: AppTextStyles.bodySmall),
                            ),
                            Text(
                              '${item.orderedQty.toStringAsFixed(item.orderedQty % 1 == 0 ? 0 : 2)} x ${CurrencyUtils.format(item.costPrice)}',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyUtils.format(item.orderedQty * item.costPrice),
                              style: AppTextStyles.labelLarge,
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.total, style: AppTextStyles.titleMedium),
              Text(CurrencyUtils.format(po.total),
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatePoSheet extends ConsumerStatefulWidget {
  const _CreatePoSheet();

  @override
  ConsumerState<_CreatePoSheet> createState() => _CreatePoSheetState();
}

class _CreatePoSheetState extends ConsumerState<_CreatePoSheet> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(poProvider);
    final notifier = ref.read(poProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(context.l10n.newPurchaseOrder, style: AppTextStyles.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_shipping_rounded, color: AppColors.primary),
            title: Text(
              state.supplier?.name ?? context.l10n.selectSupplier,
              style: state.supplier != null
                  ? AppTextStyles.labelLarge
                  : AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickSupplier(context, notifier),
          ),
          const Divider(height: 8),
          if (state.supplier != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text('${context.l10n.items} (${state.items.length})', style: AppTextStyles.labelLarge),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(context.l10n.add),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _pickProduct(context, notifier),
                  ),
                ],
              ),
            ),
            ...state.items.map((item) => _PoItemRow(
                  key: ValueKey(item.product.id),
                  item: item,
                  notifier: notifier,
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: context.l10n.notesOptional),
              onChanged: (v) => notifier.setNotes(v.isEmpty ? null : v),
            ),
            const SizedBox(height: 12),
            if (state.items.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.total, style: AppTextStyles.titleMedium),
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
                onPressed: (state.canSubmit && !state.isSubmitting)
                    ? () async {
                        try {
                          final poNo = await notifier.submit();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.poCreated(poNo ?? '')),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error),
                          );
                        }
                      }
                    : null,
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(context.l10n.createPurchaseOrder,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _pickSupplier(BuildContext context, PoNotifier notifier) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SupplierPickerSheet(
        onPick: (s) {
          notifier.setSupplier(s);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _pickProduct(BuildContext context, PoNotifier notifier) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductPickerSheet(
        onPick: (p) {
          notifier.addItem(p);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _PoItemRow extends ConsumerStatefulWidget {
  const _PoItemRow({super.key, required this.item, required this.notifier});
  final PoCartItem item;
  final PoNotifier notifier;

  @override
  ConsumerState<_PoItemRow> createState() => _PoItemRowState();
}

class _PoItemRowState extends ConsumerState<_PoItemRow> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
        text: widget.item.orderedQty
            .toStringAsFixed(widget.item.orderedQty % 1 == 0 ? 0 : 1));
    _priceCtrl = TextEditingController(text: widget.item.costPrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pid = widget.item.product.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(widget.item.product.name, style: AppTextStyles.labelLarge)),
            SizedBox(
              width: 64,
              child: TextField(
                controller: _qtyCtrl,
                decoration: InputDecoration(
                    labelText: context.l10n.qty, contentPadding: const EdgeInsets.all(6)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (v) => widget.notifier
                    .updateItem(pid, orderedQty: double.tryParse(v) ?? widget.item.orderedQty),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: TextField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                    labelText: context.l10n.cost, contentPadding: const EdgeInsets.all(6)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                onChanged: (v) => widget.notifier.updateItem(pid,
                    costPrice: double.tryParse(v) ?? widget.item.costPrice),
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
              onPressed: () => widget.notifier.removeItem(pid),
            ),
          ],
        ),
      ),
    );
  }
}
