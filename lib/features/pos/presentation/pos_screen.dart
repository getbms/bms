import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/daos/inventory_dao.dart';
import 'package:bms/features/pos/presentation/receipt_pdf.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/customers_provider.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:bms/providers/inventory_provider.dart';
import 'package:bms/providers/pos_provider.dart';
import 'package:bms/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSubmitSearch(String value) {
    final products = ref.read(productsStreamProvider).asData?.value ?? [];
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    // Exact barcode match → add to cart immediately and clear
    final byBarcode = products.where((p) => p.barcode == trimmed).toList();
    if (byBarcode.isNotEmpty) {
      ref.read(posProvider.notifier).addItem(byBarcode.first);
      _searchController.clear();
      setState(() => _searchQuery = '');
      return;
    }

    // Single name/barcode partial match → add directly
    final active = products.where((p) => p.isActive).toList();
    final q = trimmed.toLowerCase();
    final matched = active.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.brand?.toLowerCase().contains(q) ?? false) ||
        (p.barcode?.toLowerCase().contains(q) ?? false)).toList();
    if (matched.length == 1) {
      ref.read(posProvider.notifier).addItem(matched.first);
      _searchController.clear();
      setState(() => _searchQuery = '');
      return;
    }

    // Multiple matches: show filtered grid
    setState(() => _searchQuery = q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.posTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: context.l10n.clearCart,
            onPressed: () => ref.read(posProvider.notifier).clearCart(),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: context.l10n.scanOrSearch,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                                                      ),
                          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                          onSubmitted: _onSubmitSearch,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ScanButton(onProductFound: (product) {
                        ref.read(posProvider.notifier).addItem(product);
                      }),
                    ],
                  ),
                ),
                Expanded(child: _ProductGrid(searchQuery: _searchQuery)),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          const SizedBox(
            width: 380,
            child: _CartPanel(),
          ),
        ],
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({required this.searchQuery});
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final stockAsync = ref.watch(stockStreamProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        final stockMap = stockAsync.whenData((list) => {for (final s in list) s.productId: s}).asData?.value ?? {};
        final active = products.where((p) => p.isActive).toList();
        final filtered = searchQuery.isEmpty
            ? active
            : active.where((p) =>
                p.name.toLowerCase().contains(searchQuery) ||
                (p.brand?.toLowerCase().contains(searchQuery) ?? false) ||
                (p.barcode?.toLowerCase().contains(searchQuery) ?? false)).toList();

        if (filtered.isEmpty) {
          return Center(child: Text(context.l10n.noProductsFound, style: AppTextStyles.bodySmall));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final p = filtered[i];
            final qty = stockMap[p.id]?.qty ?? 0.0;
            return _ProductCard(product: p, stockQty: qty);
          },
        );
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product, required this.stockQty});
  final Product product;
  final double stockQty;

  void _add(BuildContext context, WidgetRef ref) {
    if (_isDecimalUnit(product.unitType)) {
      _showQtyDialog(context, ref);
    } else {
      ref.read(posProvider.notifier).addItem(product);
    }
  }

  void _showQtyDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            labelText: context.l10n.quantity,
            suffixText: product.unitType.toUpperCase(),
            hintText: '0.5',
          ),
          onSubmitted: (_) {
            final qty = double.tryParse(ctrl.text.trim()) ?? 0;
            if (qty > 0) {
              ref.read(posProvider.notifier).addItem(product, qty: qty);
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(ctrl.text.trim()) ?? 0;
              if (qty > 0) {
                ref.read(posProvider.notifier).addItem(product, qty: qty);
              }
              Navigator.pop(ctx);
            },
            child: Text(context.l10n.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outOfStock = stockQty <= 0;
    final decimal = _isDecimalUnit(product.unitType);

    return InkWell(
      onTap: outOfStock ? null : () => _add(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: outOfStock ? AppColors.surfaceVariant : AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: outOfStock ? AppColors.border : AppColors.primary,
                    child: Text(
                      product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: outOfStock ? AppColors.textSecondary : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                style: AppTextStyles.labelLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    CurrencyUtils.format(product.sellPrice),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                  ),
                  if (decimal) ...[
                    const SizedBox(width: 4),
                    Text(
                      '/${product.unitType}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                outOfStock
                    ? context.l10n.outOfStock
                    : '${context.l10n.stock} ${_formatQty(stockQty)} ${product.unitType}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: outOfStock ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends ConsumerStatefulWidget {
  const _CartPanel();

  @override
  ConsumerState<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<_CartPanel> {
  final _tenderedController = TextEditingController();

  @override
  void dispose() {
    _tenderedController.dispose();
    super.dispose();
  }

  void _editQty(CartItem item, PosNotifier notifier) {
    final ctrl = TextEditingController(text: _formatQty(item.qty));
    final decimal = _isDecimalUnit(item.product.unitType);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.product.name),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: context.l10n.quantity,
            suffixText: item.product.unitType.toUpperCase(),
          ),
          onSubmitted: (_) {
            final qty = double.tryParse(ctrl.text.trim()) ?? 0;
            if (qty > 0) notifier.updateQty(item.product.id, qty);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(ctrl.text.trim()) ?? 0;
              if (qty > 0) notifier.updateQty(item.product.id, qty);
              Navigator.pop(ctx);
            },
            child: Text(context.l10n.set),
          ),
        ],
      ),
    );
  }

  void _openCustomerSearch() {
    showDialog(
      context: context,
      builder: (_) => const _CustomerSearchDialog(),
    );
  }

  void _showLineDiscountSheet(CartItem item) {
    final controller = TextEditingController(
      text: item.discountPct > 0 ? item.discountPct.toStringAsFixed(0) : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.lineDiscount(item.product.name), style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: const InputDecoration(
                labelText: 'Discount %',
                suffixText: '%',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(posProvider.notifier).setLineDiscount(item.product.id, 0);
                    Navigator.pop(ctx);
                  },
                  child: Text(context.l10n.remove),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    final pct = double.tryParse(controller.text) ?? 0;
                    ref.read(posProvider.notifier).setLineDiscount(item.product.id, pct);
                    Navigator.pop(ctx);
                  },
                  child: Text(context.l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBillDiscountSheet() {
    final current = ref.read(posProvider).billDiscountPct;
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.billDiscount, style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: const InputDecoration(
                labelText: 'Discount %',
                suffixText: '%',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(posProvider.notifier).setBillDiscount(0);
                    Navigator.pop(ctx);
                  },
                  child: Text(context.l10n.remove),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    final pct = double.tryParse(controller.text) ?? 0;
                    ref.read(posProvider.notifier).setBillDiscount(pct);
                    Navigator.pop(ctx);
                  },
                  child: Text(context.l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    final notifier = ref.read(posProvider.notifier);
    final snapshot = ref.read(posProvider);
    try {
      final invoiceNo = await notifier.checkout();
      if (!mounted) return;
      if (invoiceNo != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.invoiceCompleted(invoiceNo)),
            backgroundColor: AppColors.success,
          ),
        );
        _tenderedController.clear();

        // Auto-print receipt on connected printer; fall back to print dialog
        final store = ref.read(storeInfoProvider);
        ReceiptPdf.printOrPreview(
          items: snapshot.items,
          invoiceNo: invoiceNo,
          paymentMethod: snapshot.paymentMethod,
          subtotal: snapshot.subtotal,
          discountAmount: snapshot.discountAmount,
          total: snapshot.total,
          amountTendered: snapshot.amountTendered,
          change: snapshot.change,
          customer: snapshot.customer,
          storeName: store.name,
          storeAddress: store.address,
          storePhone: store.phone,
        ).ignore();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.checkoutFailed(e.toString())), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surfaceVariant,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.cart, style: AppTextStyles.titleMedium),
              Text('${state.items.length} ${context.l10n.cartItems}', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: state.isEmpty
              ? Center(child: Text(context.l10n.cartEmpty, style: AppTextStyles.bodySmall))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.items.length,
                  itemBuilder: (_, i) {
                    final item = state.items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onLongPress: () => _showLineDiscountSheet(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: AppTextStyles.labelLarge),
                                    if (item.discountPct > 0)
                                      Text(
                                        '${item.discountPct.toStringAsFixed(0)}% off  ${CurrencyUtils.format(item.unitPrice)}',
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                                      )
                                    else
                                      Text(
                                        '${CurrencyUtils.format(item.unitPrice)} / ${item.product.unitType}',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      final step = _stepFor(item.product.unitType);
                                      final next = double.parse(
                                          (item.qty - step).toStringAsFixed(4));
                                      notifier.updateQty(item.product.id, next);
                                    },
                                  ),
                                  GestureDetector(
                                    onTap: () => _editQty(item, notifier),
                                    child: Container(
                                      constraints: const BoxConstraints(minWidth: 44),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.border),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _formatQty(item.qty),
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.labelLarge,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      final step = _stepFor(item.product.unitType);
                                      final next = double.parse(
                                          (item.qty + step).toStringAsFixed(4));
                                      notifier.updateQty(item.product.id, next);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 72,
                                child: Text(
                                  CurrencyUtils.format(item.lineTotal),
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.labelLarge,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => notifier.removeItem(item.product.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.subtotal, style: AppTextStyles.bodyMedium),
                  Text(CurrencyUtils.format(state.subtotal), style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showBillDiscountSheet(),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          state.billDiscountPct > 0
                              ? 'Discount (${state.billDiscountPct.toStringAsFixed(0)}%)'
                              : context.l10n.addDiscount,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (state.discountAmount > 0)
                    Text(
                      '- ${CurrencyUtils.format(state.discountAmount)}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.total, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                  Text(CurrencyUtils.format(state.total), style: AppTextStyles.posAmount.copyWith(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(state.customer?.name ?? context.l10n.setCustomer),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: _openCustomerSearch,
              ),
              if (state.customer != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => notifier.setCustomer(null),
                    child: Text(context.l10n.removeCustomer),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PayMethodBtn(
                    label: context.l10n.paymentMethodCash,
                    color: AppColors.paymentCash,
                    selected: state.paymentMethod == 'cash',
                    onTap: () => notifier.setPaymentMethod('cash'),
                  ),
                  const SizedBox(width: 8),
                  _PayMethodBtn(
                    label: context.l10n.paymentMethodCard,
                    color: AppColors.paymentCard,
                    selected: state.paymentMethod == 'card',
                    onTap: () => notifier.setPaymentMethod('card'),
                  ),
                  const SizedBox(width: 8),
                  _PayMethodBtn(
                    label: context.l10n.paymentMethodCredit,
                    color: AppColors.paymentCredit,
                    selected: state.paymentMethod == 'credit',
                    onTap: () => notifier.setPaymentMethod('credit'),
                  ),
                ],
              ),
              if (state.paymentMethod == 'cash') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _tenderedController,
                  decoration: InputDecoration(
                    labelText: context.l10n.amountReceived,
                    prefixText: 'Rs. ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  onChanged: (v) {
                    final amount = double.tryParse(v) ?? 0;
                    notifier.setAmountTendered(amount);
                  },
                ),
                if (state.amountTendered > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.l10n.change, style: AppTextStyles.bodyMedium),
                      Text(
                        CurrencyUtils.format(state.change > 0 ? state.change : 0),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: state.change >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isEmpty ? AppColors.border : AppColors.success,
                  ),
                  onPressed: (state.isEmpty || state.isSubmitting) ? null : _checkout,
                  child: state.isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          context.l10n.checkout,
                          style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PayMethodBtn extends StatelessWidget {
  const _PayMethodBtn({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 40,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selected ? color : AppColors.surfaceVariant,
            foregroundColor: selected ? Colors.white : AppColors.textSecondary,
            padding: EdgeInsets.zero,
            elevation: selected ? 2 : 0,
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }
}

class _CustomerSearchDialog extends ConsumerStatefulWidget {
  const _CustomerSearchDialog();

  @override
  ConsumerState<_CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends ConsumerState<_CustomerSearchDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);

    return Dialog(
      child: SizedBox(
        width: 360,
        height: 480,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.l10n.searchCustomers,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (customers) {
                  final filtered = _query.isEmpty
                      ? customers
                      : customers.where((c) =>
                          c.name.toLowerCase().contains(_query) ||
                          (c.phone?.toLowerCase().contains(_query) ?? false)).toList();
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(c.name, style: AppTextStyles.labelLarge),
                        subtitle: c.phone != null ? Text(c.phone!) : null,
                        onTap: () {
                          ref.read(posProvider.notifier).setCustomer(c);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isDecimalUnit(String unitType) =>
    const {'kg', 'g', 'l', 'ml'}.contains(unitType.toLowerCase());

double _stepFor(String unitType) {
  switch (unitType.toLowerCase()) {
    case 'kg':
    case 'l':
      return 0.25;
    case 'g':
    case 'ml':
      return 50;
    default:
      return 1;
  }
}

String _formatQty(double qty) {
  // Trim trailing zeros: 1.500 → "1.5", 1.000 → "1", 0.250 → "0.25"
  return qty.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
}

class _ScanButton extends ConsumerWidget {
  const _ScanButton({required this.onProductFound});

  final void Function(Product product) onProductFound;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.qr_code_scanner, size: 20),
        label: Text(context.l10n.scan),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _BarcodeScanDialog(
            inventoryDao: ref.read(inventoryDaoProvider),
            onProductFound: onProductFound,
          ),
        ),
      ),
    );
  }
}

class _BarcodeScanDialog extends StatefulWidget {
  const _BarcodeScanDialog({
    required this.inventoryDao,
    required this.onProductFound,
  });

  final InventoryDao inventoryDao;
  final void Function(Product product) onProductFound;

  @override
  State<_BarcodeScanDialog> createState() => _BarcodeScanDialogState();
}

class _BarcodeScanDialogState extends State<_BarcodeScanDialog> {
  final _controller = MobileScannerController();
  bool _processing = false;
  String? _lastError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _processing = true);

    final product = await widget.inventoryDao.findByBarcode(raw);

    if (!mounted) return;

    if (product != null) {
      Navigator.of(context).pop();
      widget.onProductFound(product);
    } else {
      setState(() {
        _lastError = 'No product found for barcode: $raw';
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        height: 440,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(context.l10n.scanBarcode, style: AppTextStyles.titleMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 2.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ..._buildCorners(),
                    if (_processing)
                      const ColoredBox(
                        color: Colors.black45,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    if (_lastError != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            _lastError!,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 3.5;
    const color = AppColors.primary;
    Widget corner(double top, double left, {required bool flipH, required bool flipV}) => Positioned(
          top: top,
          left: left,
          child: Transform.scale(
            scaleX: flipH ? -1 : 1,
            scaleY: flipV ? -1 : 1,
            child: const SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _CornerPainter(color: color, thickness: thickness),
              ),
            ),
          ),
        );

    // Center the 220x220 box in a 380x400 viewport (approx)
    const cx = (380 - 220) / 2;
    const cy = (400 - 220) / 2;

    return [
      corner(cy - thickness, cx - thickness, flipH: false, flipV: false),
      corner(cy - thickness, cx + 220 - size + thickness, flipH: true, flipV: false),
      corner(cy + 220 - size + thickness, cx - thickness, flipH: false, flipV: true),
      corner(cy + 220 - size + thickness, cx + 220 - size + thickness, flipH: true, flipV: true),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.color, required this.thickness});

  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
