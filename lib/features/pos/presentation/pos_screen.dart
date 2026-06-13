import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/customers_provider.dart';
import '../../../data/database/daos/inventory_dao.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/pos_provider.dart';

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
    // Barcode scan: try exact barcode match first, then name
    final products = ref.read(productsStreamProvider).asData?.value ?? [];
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final byBarcode = products.where((p) => p.barcode == trimmed).toList();
    if (byBarcode.isNotEmpty) {
      ref.read(posProvider.notifier).addItem(byBarcode.first);
      _searchController.clear();
      setState(() => _searchQuery = '');
      return;
    }

    // Fall through: filter the grid by name
    setState(() => _searchQuery = trimmed.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS / Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Cart',
            onPressed: () => ref.read(posProvider.notifier).clearCart(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left panel: product search + grid
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
                            hintText: 'Scan barcode or search...',
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
                            isDense: true,
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
          // Right panel: cart
          SizedBox(
            width: 380,
            child: const _CartPanel(),
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
                (p.brand?.toLowerCase().contains(searchQuery) ?? false)).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No products found.', style: AppTextStyles.bodySmall));
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outOfStock = stockQty <= 0;

    return InkWell(
      onTap: outOfStock ? null : () => ref.read(posProvider.notifier).addItem(product),
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
              Text(
                CurrencyUtils.format(product.sellPrice),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 2),
              Text(
                outOfStock ? 'Out of stock' : 'Qty: ${stockQty.toStringAsFixed(0)}',
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

  void _openCustomerSearch() {
    showDialog(
      context: context,
      builder: (_) => const _CustomerSearchDialog(),
    );
  }

  Future<void> _checkout() async {
    final notifier = ref.read(posProvider.notifier);
    try {
      final invoiceNo = await notifier.checkout();
      if (!mounted) return;
      if (invoiceNo != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice $invoiceNo completed!'),
            backgroundColor: AppColors.success,
          ),
        );
        _tenderedController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posProvider);
    final notifier = ref.read(posProvider.notifier);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surfaceVariant,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cart', style: AppTextStyles.titleMedium),
              Text('${state.items.length} item(s)', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        // Cart items
        Expanded(
          child: state.isEmpty
              ? const Center(child: Text('Cart is empty', style: AppTextStyles.bodySmall))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.items.length,
                  itemBuilder: (_, i) {
                    final item = state.items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: AppTextStyles.labelLarge),
                                  Text(CurrencyUtils.format(item.unitPrice), style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => notifier.updateQty(item.product.id, item.qty - 1),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 1),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.labelLarge,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => notifier.updateQty(item.product.id, item.qty + 1),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
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
                    );
                  },
                ),
        ),
        // Bottom panel
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: AppTextStyles.bodyMedium),
                  Text(CurrencyUtils.format(state.subtotal), style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                  Text(CurrencyUtils.format(state.total), style: AppTextStyles.posAmount.copyWith(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 12),
              // Customer
              OutlinedButton.icon(
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(state.customer?.name ?? 'Set Customer (optional)'),
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
                    child: const Text('Remove Customer'),
                  ),
                ),
              const SizedBox(height: 12),
              // Payment method
              Row(
                children: [
                  _PayMethodBtn(
                    label: 'Cash',
                    color: AppColors.paymentCash,
                    selected: state.paymentMethod == 'cash',
                    onTap: () => notifier.setPaymentMethod('cash'),
                  ),
                  const SizedBox(width: 8),
                  _PayMethodBtn(
                    label: 'Card',
                    color: AppColors.paymentCard,
                    selected: state.paymentMethod == 'card',
                    onTap: () => notifier.setPaymentMethod('card'),
                  ),
                  const SizedBox(width: 8),
                  _PayMethodBtn(
                    label: 'Credit',
                    color: AppColors.paymentCredit,
                    selected: state.paymentMethod == 'credit',
                    onTap: () => notifier.setPaymentMethod('credit'),
                  ),
                ],
              ),
              // Cash tendered + change
              if (state.paymentMethod == 'cash') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _tenderedController,
                  decoration: const InputDecoration(
                    labelText: 'Amount Received',
                    prefixText: 'Rs. ',
                    isDense: true,
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
                      const Text('Change', style: AppTextStyles.bodyMedium),
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
                          'Checkout',
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
                decoration: const InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
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

// ─── Camera scan button ───────────────────────────────────────────────────────

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
        label: const Text('Scan'),
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

// ─── Barcode scan dialog ──────────────────────────────────────────────────────

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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Scan Barcode', style: AppTextStyles.titleMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scanner viewport
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                    // Scan window overlay
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
                    // Corner accents
                    ..._buildCorners(),
                    // Processing indicator
                    if (_processing)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    // Error banner
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
    const offset = (220 - size * 2) / 2;

    Widget corner(double top, double left, bool flipH, bool flipV) => Positioned(
          top: top,
          left: left,
          child: Transform.scale(
            scaleX: flipH ? -1 : 1,
            scaleY: flipV ? -1 : 1,
            child: SizedBox(
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
      corner(cy - thickness, cx - thickness, false, false),
      corner(cy - thickness, cx + 220 - size + thickness, true, false),
      corner(cy + 220 - size + thickness, cx - thickness, false, true),
      corner(cy + 220 - size + thickness, cx + 220 - size + thickness, true, true),
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
