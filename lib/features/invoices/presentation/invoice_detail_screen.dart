import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/invoices_provider.dart';
import 'invoice_pdf.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(invoiceDetailProvider(invoiceId));
    final authState = ref.watch(currentAuthStateProvider);
    final role = authState is Authenticated ? authState.user.role : 'cashier';
    final cashierName = authState is Authenticated ? authState.user.name : '';
    final canReturn = role == 'admin' || role == 'developer' || role == 'manager';
    final isAdmin = role == 'admin' || role == 'developer';

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(
          data: (d) => Text(d.invoice.invoiceNo),
          orElse: () => const Text('Invoice'),
        ),
        actions: [
          detailAsync.maybeWhen(
            data: (d) => IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export PDF',
              onPressed: () => _exportPdf(context, d, cashierName),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (d) => _DetailBody(
          detail: d,
          isAdmin: isAdmin,
          canReturn: canReturn,
          cashierName: cashierName,
          onVoid: () => _confirmVoid(context, ref, d.invoice),
          onProcessReturn: () => _openReturnSheet(context, ref, d),
        ),
      ),
    );
  }

  Future<void> _exportPdf(
      BuildContext context, InvoiceDetail detail, String cashierName) async {
    final doc = await InvoicePdf.build(
      invoice: detail.invoice,
      items: detail.items,
      customer: detail.customer,
      cashierName: cashierName,
    );
    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  Future<void> _confirmVoid(
      BuildContext context, WidgetRef ref, Invoice invoice) async {
    if (invoice.status == 'void') return;

    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Void Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will void ${invoice.invoiceNo}. Stock will NOT be auto-restored.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(dialogCtx, true);
            },
            child:
                const Text('Void', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await ref
        .read(invoiceActionsProvider)
        .voidInvoice(invoiceId: invoice.id, reason: reasonCtrl.text.trim());
    ref.invalidate(invoiceDetailProvider(invoice.id));
    ref.invalidate(invoicesListProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice voided')),
      );
    }
  }

  Future<void> _openReturnSheet(
      BuildContext context, WidgetRef ref, InvoiceDetail detail) async {
    final processed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProcessReturnSheet(detail: detail),
    );
    if (processed == true) {
      ref.invalidate(invoiceReturnsProvider(detail.invoice.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return processed and stock restored')),
        );
      }
    }
  }
}

// ── Detail Body ──────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.detail,
    required this.isAdmin,
    required this.canReturn,
    required this.cashierName,
    required this.onVoid,
    required this.onProcessReturn,
  });

  final InvoiceDetail detail;
  final bool isAdmin;
  final bool canReturn;
  final String cashierName;
  final VoidCallback onVoid;
  final VoidCallback onProcessReturn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = detail.invoice;
    final items = detail.items;
    final customer = detail.customer;
    final isVoided = inv.status == 'void';
    final returnsAsync = ref.watch(invoiceReturnsProvider(inv.id));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Status banner
        if (isVoided)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.block_outlined, color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VOIDED',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.error)),
                      if (inv.voidReason != null)
                        Text(inv.voidReason!, style: AppTextStyles.bodySmall),
                      if (inv.voidApprovedBy != null)
                        Text('By: ${inv.voidApprovedBy}',
                            style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (isVoided) const SizedBox(height: 16),

        // Header card
        _Card(
          child: Column(
            children: [
              _InfoRow(label: 'Invoice No', value: inv.invoiceNo),
              _InfoRow(
                  label: 'Date',
                  value: '${inv.createdAt.day.toString().padLeft(2, '0')} '
                      '${_monthName(inv.createdAt.month)} ${inv.createdAt.year}  '
                      '${inv.createdAt.hour.toString().padLeft(2, '0')}:'
                      '${inv.createdAt.minute.toString().padLeft(2, '0')}'),
              _InfoRow(label: 'Customer', value: customer?.name ?? 'Walk-in'),
              if (customer?.phone != null)
                _InfoRow(label: 'Phone', value: customer!.phone!),
              _InfoRow(label: 'Payment', value: _paymentLabel(inv.paymentType)),
              _InfoRow(
                label: 'Status',
                valueWidget: _StatusChip(status: inv.status),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Items table
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items', style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FixedColumnWidth(50),
                  2: FixedColumnWidth(90),
                  3: FixedColumnWidth(90),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppColors.border))),
                    children: [
                      _TableHeader('Item'),
                      _TableHeader('Qty', align: TextAlign.center),
                      _TableHeader('Price', align: TextAlign.right),
                      _TableHeader('Amount', align: TextAlign.right),
                    ],
                  ),
                  for (final item in items)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: AppTextStyles.bodyMedium),
                              if (item.discountPercent > 0)
                                Text(
                                  '${item.discountPercent.toStringAsFixed(0)}% off',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.error),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            item.qty % 1 == 0
                                ? item.qty.toInt().toString()
                                : item.qty.toStringAsFixed(2),
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            CurrencyUtils.format(item.unitPrice),
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            CurrencyUtils.format(item.subtotal),
                            style: AppTextStyles.labelLarge,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Totals card
        _Card(
          child: Column(
            children: [
              _TotalRow(label: 'Subtotal', value: inv.subtotal),
              if (inv.discountAmount > 0)
                _TotalRow(
                    label: 'Discount',
                    value: -inv.discountAmount,
                    color: AppColors.error),
              const Divider(height: 20),
              _TotalRow(
                  label: 'Total',
                  value: inv.total,
                  style: AppTextStyles.titleMedium,
                  color: AppColors.primary),
              const SizedBox(height: 8),
              _TotalRow(label: 'Amount Received', value: inv.paidAmount),
              if (inv.total - inv.paidAmount > 0)
                _TotalRow(
                  label: 'Balance Due',
                  value: inv.total - inv.paidAmount,
                  color: AppColors.error,
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Actions
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Export PDF'),
              onPressed: () async {
                final doc = await InvoicePdf.build(
                  invoice: inv,
                  items: items,
                  customer: customer,
                  cashierName: cashierName,
                );
                await Printing.layoutPdf(onLayout: (_) => doc.save());
              },
            ),
            if (canReturn && !isVoided && items.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning),
                icon: const Icon(Icons.assignment_return_outlined,
                    color: Colors.white),
                label: const Text('Process Return',
                    style: TextStyle(color: Colors.white)),
                onPressed: onProcessReturn,
              ),
            if (isAdmin && !isVoided)
              ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                icon: const Icon(Icons.block_outlined, color: Colors.white),
                label: const Text('Void Invoice',
                    style: TextStyle(color: Colors.white)),
                onPressed: onVoid,
              ),
          ],
        ),

        // Return history
        returnsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (returns) {
            if (returns.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 28),
              child: _ReturnHistory(returns: returns),
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  static String _paymentLabel(String type) => switch (type) {
        'cash' => 'Cash',
        'card' => 'Card',
        'cheque' => 'Cheque',
        'credit' => 'Credit',
        'mixed' => 'Mixed',
        _ => type,
      };

  static String _monthName(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
}

// ── Return History ───────────────────────────────────────────────────────────

class _ReturnHistory extends StatelessWidget {
  const _ReturnHistory({required this.returns});
  final List<SalesReturn> returns;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_return_outlined,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Text('Returns (${returns.length})',
                  style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          for (final ret in returns) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ret.returnNo, style: AppTextStyles.labelLarge),
                      Text(
                        _typeLabel(ret.type),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      if (ret.reason != null)
                        Text(ret.reason!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(CurrencyUtils.format(ret.totalAmount),
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.warning)),
                    Text(
                      '${ret.createdAt.day.toString().padLeft(2, '0')}/'
                      '${ret.createdAt.month.toString().padLeft(2, '0')}/'
                      '${ret.createdAt.year}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _typeLabel(String type) => switch (type) {
        'refund' => 'Refund',
        'credit' => 'Credit Note',
        'exchange' => 'Exchange',
        _ => type,
      };
}

// ── Process Return Sheet ─────────────────────────────────────────────────────

class _ProcessReturnSheet extends ConsumerStatefulWidget {
  const _ProcessReturnSheet({required this.detail});
  final InvoiceDetail detail;

  @override
  ConsumerState<_ProcessReturnSheet> createState() =>
      _ProcessReturnSheetState();
}

class _ProcessReturnSheetState extends ConsumerState<_ProcessReturnSheet> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _qtyControllers;
  String _type = 'refund';
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _qtyControllers = widget.detail.items
        .map((_) => TextEditingController(text: '0'))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _qtyControllers) {
      c.dispose();
    }
    _reasonCtrl.dispose();
    super.dispose();
  }

  double get _totalReturnAmount {
    double total = 0;
    for (int i = 0; i < widget.detail.items.length; i++) {
      final qty = double.tryParse(_qtyControllers[i].text.trim()) ?? 0;
      if (qty > 0) total += widget.detail.items[i].unitPrice * qty;
    }
    return total;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final returnItems = <({InvoiceItem item, double qty})>[];
    for (int i = 0; i < widget.detail.items.length; i++) {
      final qty = double.tryParse(_qtyControllers[i].text.trim()) ?? 0;
      if (qty > 0) returnItems.add((item: widget.detail.items[i], qty: qty));
    }

    if (returnItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a return quantity for at least one item')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final authState = ref.read(currentAuthStateProvider);
      final userId =
          authState is Authenticated ? authState.user.id : 'unknown';
      final userName =
          authState is Authenticated ? authState.user.name : 'unknown';

      final returnsDao = ref.read(returnsDaoProvider);
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      const uuid = Uuid();

      final returnId = uuid.v7();
      final returnNo = await returnsDao.nextReturnNumber();
      final totalAmount = returnItems.fold(
          0.0, (s, e) => s + e.item.unitPrice * e.qty);

      final entry = SalesReturnsCompanion(
        id: Value(returnId),
        invoiceId: Value(widget.detail.invoice.id),
        returnNo: Value(returnNo),
        type: Value(_type),
        totalAmount: Value(totalAmount),
        reason: Value(
            _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim()),
        userId: Value(userId),
      );

      final items = returnItems
          .map((e) => ReturnItemsCompanion(
                id: Value(uuid.v7()),
                returnId: Value(returnId),
                productId: Value(e.item.productId),
                productName: Value(e.item.productName),
                qty: Value(e.qty),
                unitPrice: Value(e.item.unitPrice),
                subtotal: Value(e.item.unitPrice * e.qty),
              ))
          .toList();

      await returnsDao.insertReturnWithItems(entry, items);

      for (final e in returnItems) {
        await inventoryRepo.adjustStock(
          productId: e.item.productId,
          delta: e.qty,
          reason: 'Sales return $returnNo',
          userId: userId,
          userName: userName,
          refId: returnId,
          refType: 'sales_return',
          movementType: 'return_in',
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.detail.items;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Form(
          key: _form,
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_return_outlined,
                        color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Process Return - ${widget.detail.invoice.invoiceNo}',
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Items section
                    Text('Select Items to Return',
                        style: AppTextStyles.labelLarge),
                    const SizedBox(height: 12),

                    for (int i = 0; i < items.length; i++)
                      _ReturnItemRow(
                        item: items[i],
                        controller: _qtyControllers[i],
                        onChanged: () => setState(() {}),
                      ),

                    const SizedBox(height: 20),

                    // Return type
                    Text('Return Type', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    _ReturnTypeSelector(
                      value: _type,
                      onChanged: (v) => setState(() => _type = v),
                    ),

                    const SizedBox(height: 20),

                    // Reason
                    Text('Reason', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Optional reason for return...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Return Total',
                              style: AppTextStyles.titleMedium),
                          Text(
                            CurrencyUtils.format(_totalReturnAmount),
                            style: AppTextStyles.titleMedium
                                .copyWith(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom actions
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning),
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Confirm Return',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Return Item Row ──────────────────────────────────────────────────────────

class _ReturnItemRow extends StatelessWidget {
  const _ReturnItemRow({
    required this.item,
    required this.controller,
    required this.onChanged,
  });

  final InvoiceItem item;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final maxQty = item.qty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.bodyMedium),
                Text(
                  'Sold: ${item.qty % 1 == 0 ? item.qty.toInt() : item.qty.toStringAsFixed(2)}  @  ${CurrencyUtils.format(item.unitPrice)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _QtyStepper(
            controller: controller,
            max: maxQty,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Qty Stepper ──────────────────────────────────────────────────────────────

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.controller,
    required this.max,
    required this.onChanged,
  });

  final TextEditingController controller;
  final double max;
  final VoidCallback onChanged;

  void _decrement() {
    final current = double.tryParse(controller.text) ?? 0;
    if (current <= 0) return;
    final next = (current - 1).clamp(0.0, max);
    controller.text = next == next.toInt() ? next.toInt().toString() : next.toStringAsFixed(2);
    onChanged();
  }

  void _increment() {
    final current = double.tryParse(controller.text) ?? 0;
    if (current >= max) return;
    final next = (current + 1).clamp(0.0, max);
    controller.text = next == next.toInt() ? next.toInt().toString() : next.toStringAsFixed(2);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _decrement,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.remove, size: 16),
          ),
        ),
        SizedBox(
          width: 52,
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onChanged(),
            validator: (v) {
              final qty = double.tryParse(v ?? '');
              if (qty == null) return '*';
              if (qty < 0) return '*';
              if (qty > max) return '>max';
              return null;
            },
          ),
        ),
        InkWell(
          onTap: _increment,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.add, size: 16),
          ),
        ),
      ],
    );
  }
}

// ── Return Type Selector ─────────────────────────────────────────────────────

class _ReturnTypeSelector extends StatelessWidget {
  const _ReturnTypeSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const _types = [
    ('refund', 'Refund', Icons.payments_outlined),
    ('credit', 'Credit Note', Icons.note_outlined),
    ('exchange', 'Exchange', Icons.swap_horiz_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _types.map((t) {
        final selected = value == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(t.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.warning : AppColors.border,
                  width: selected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(t.$3,
                      color: selected
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      size: 20),
                  const SizedBox(height: 4),
                  Text(
                    t.$2,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared UI Widgets ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueWidget});
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            valueWidget ?? Text(value ?? '', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.color,
    this.style,
  });
  final String label;
  final double value;
  final Color? color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: style ??
                    AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
            Text(
              value < 0
                  ? '- ${CurrencyUtils.format(-value)}'
                  : CurrencyUtils.format(value),
              style: (style ?? AppTextStyles.bodyMedium).copyWith(color: color),
            ),
          ],
        ),
      );
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text, {this.align = TextAlign.left});
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: align),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'paid' => (AppColors.successLight, AppColors.success),
      'partial' => (AppColors.warningLight, AppColors.warning),
      'void' => (AppColors.errorLight, AppColors.error),
      'open' => (const Color(0xFFE3F2FD), AppColors.info),
      _ => (AppColors.surfaceVariant, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
              color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
