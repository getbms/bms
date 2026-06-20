import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/features/invoices/presentation/invoice_detail_screen.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/invoices_provider.dart';
import 'package:bms/shared/widgets/bms_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.invoicesTitle)),
      body: const Column(
        children: [
          _FilterBar(),
          _SummaryBar(),
          Expanded(child: _InvoiceList()),
        ],
      ),
    );
  }
}


class _FilterBar extends ConsumerStatefulWidget {
  const _FilterBar();

  @override
  ConsumerState<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<_FilterBar> {
  final _searchCtrl = TextEditingController();

  List<(String?, String)> _statuses(BuildContext context) => [
    (null, context.l10n.filterAll),
    ('paid', context.l10n.filterPaid),
    ('partial', context.l10n.filterPartial),
    ('open', context.l10n.filterOpen),
    ('void', context.l10n.filterVoid),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(invoiceFilterProvider);

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BmsFilterRow(
            start: filter.dateRange.start,
            end: filter.dateRange.end,
            onDatePick: (range) => ref
                .read(invoiceFilterProvider.notifier)
                .update(ref.read(invoiceFilterProvider).copyWith(dateRange: range)),
            searchController: _searchCtrl,
            onSearch: (v) => ref
                .read(invoiceFilterProvider.notifier)
                .update(ref.read(invoiceFilterProvider).copyWith(query: v)),
            searchHint: context.l10n.searchInvoice,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses(context).map((s) {
                  final (value, label) = s;
                  final selected = filter.status == value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => ref
                          .read(invoiceFilterProvider.notifier)
                          .update(filter.copyWith(status: value)),
                      selectedColor: AppColors.primary.withAlpha(20),
                      checkmarkColor: AppColors.primary,
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: selected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                      backgroundColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _SummaryBar extends ConsumerWidget {
  const _SummaryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(invoiceSummaryProvider);

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryItem(label: context.l10n.summaryInvoices, value: summary.count.toString()),
          _divider(),
          _SummaryItem(label: context.l10n.summaryTotalSales, value: CurrencyUtils.format(summary.total)),
          _divider(),
          _SummaryItem(label: context.l10n.summaryCollected, value: CurrencyUtils.format(summary.collected)),
          _divider(),
          _SummaryItem(
            label: context.l10n.summaryOutstanding,
            value: CurrencyUtils.format(summary.total - summary.collected),
            highlight: summary.total - summary.collected > 0,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 28, color: Colors.white24,
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.warningLight : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}


class _InvoiceList extends ConsumerWidget {
  const _InvoiceList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(invoicesListProvider);

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Text(context.l10n.noInvoicesFound, style: AppTextStyles.bodySmall),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: rows.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (_, i) => _InvoiceTile(row: rows[i]),
        );
      },
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.row});
  final InvoiceRow row;

  static final _dateFmt = DateFormat('dd MMM  HH:mm');

  @override
  Widget build(BuildContext context) {
    final inv = row.invoice;
    final isVoid = inv.status == 'void';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _statusColor(inv.status).withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _statusIcon(inv.status),
          color: _statusColor(inv.status),
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(inv.invoiceNo,
              style: AppTextStyles.labelLarge.copyWith(
                decoration: isVoid ? TextDecoration.lineThrough : null,
                color: isVoid ? AppColors.textSecondary : null,
              )),
          const SizedBox(width: 8),
          _StatusBadge(status: inv.status),
        ],
      ),
      subtitle: Text(
        [
          row.customerName ?? context.l10n.walkIn,
          _dateFmt.format(inv.createdAt),
          _paymentLabel(inv.paymentType),
        ].join('  ·  '),
        style: AppTextStyles.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyUtils.format(inv.total),
            style: AppTextStyles.labelLarge.copyWith(
              color: isVoid ? AppColors.textSecondary : AppColors.primary,
              decoration: isVoid ? TextDecoration.lineThrough : null,
            ),
          ),
          if (inv.total - inv.paidAmount > 0 && !isVoid)
            Text(
              'Due ${CurrencyUtils.format(inv.total - inv.paidAmount)}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => InvoiceDetailScreen(invoiceId: inv.id)),
      ),
    );
  }

  static Color _statusColor(String status) => switch (status) {
        'paid' => AppColors.success,
        'partial' => AppColors.warning,
        'void' => AppColors.error,
        'open' => AppColors.info,
        _ => AppColors.textSecondary,
      };

  static IconData _statusIcon(String status) => switch (status) {
        'paid' => Icons.check_circle_outline,
        'partial' => Icons.hourglass_bottom_outlined,
        'void' => Icons.block_outlined,
        'open' => Icons.pending_outlined,
        _ => Icons.receipt_outlined,
      };

  static String _paymentLabel(String type) => switch (type) {
        'cash' => 'Cash',
        'card' => 'Card',
        'cheque' => 'Cheque',
        'credit' => 'Credit',
        'mixed' => 'Mixed',
        _ => type,
      };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paid' => AppColors.success,
      'partial' => AppColors.warning,
      'void' => AppColors.error,
      'open' => AppColors.info,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}
