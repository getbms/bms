import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../features/auth/domain/auth_state.dart';
import '../../../providers/auth_provider.dart';
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
          cashierName: cashierName,
          onVoid: () => _confirmVoid(context, ref, d.invoice),
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
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.isAdmin,
    required this.cashierName,
    required this.onVoid,
  });

  final InvoiceDetail detail;
  final bool isAdmin;
  final String cashierName;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context) {
    final inv = detail.invoice;
    final items = detail.items;
    final customer = detail.customer;
    final isVoided = inv.status == 'void';

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
                      Text('VOIDED', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                      if (inv.voidReason != null)
                        Text(inv.voidReason!, style: AppTextStyles.bodySmall),
                      if (inv.voidApprovedBy != null)
                        Text('By: ${inv.voidApprovedBy}', style: AppTextStyles.bodySmall),
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
                  value:
                      '${inv.createdAt.day.toString().padLeft(2, '0')} '
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
                        border: Border(bottom: BorderSide(color: AppColors.border))),
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
                              Text(item.productName, style: AppTextStyles.bodyMedium),
                              if (item.discountPercent > 0)
                                Text(
                                  '${item.discountPercent.toStringAsFixed(0)}% off',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error),
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
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
            ),
            if (isAdmin && !isVoided) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  icon: const Icon(Icons.block_outlined, color: Colors.white),
                  label: const Text('Void Invoice',
                      style: TextStyle(color: Colors.white)),
                  onPressed: onVoid,
                ),
              ),
            ],
          ],
        ),
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
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

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
              child:
                  Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
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
                    AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            Text(
              value < 0
                  ? '- ${CurrencyUtils.format(-value)}'
                  : CurrencyUtils.format(value),
              style: (style ?? AppTextStyles.bodyMedium)
                  .copyWith(color: color),
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
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: AppTextStyles.bodySmall.copyWith(
              color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
