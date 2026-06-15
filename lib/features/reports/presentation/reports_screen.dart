import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/cheques_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/inventory_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySalesAsync = ref.watch(todaySalesTotalProvider);
    final upcomingChequesAsync = ref.watch(chequesUpcomingProvider);
    final lowStockAsync = ref.watch(lowStockStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(todaySalesTotalProvider);
              ref.invalidate(chequesUpcomingProvider);
              ref.invalidate(lowStockStreamProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaySalesTotalProvider);
          ref.invalidate(chequesUpcomingProvider);
          ref.invalidate(lowStockStreamProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text("Today's Summary — ${BmsDateUtils.formatDate(DateTime.now())}", style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            // Today's sales card
            todaySalesAsync.when(
              loading: () => const _SummaryCardShimmer(label: "Today's Sales"),
              error: (e, _) => _ErrorCard(label: "Today's Sales", error: e.toString()),
              data: (total) => _SummaryCard(
                label: "Today's Sales",
                value: CurrencyUtils.format(total),
                icon: Icons.receipt_long_outlined,
                color: AppColors.success,
                subtitle: 'Total invoiced today',
              ),
            ),
            const SizedBox(height: 16),
            // Low stock card
            lowStockAsync.when(
              loading: () => const _SummaryCardShimmer(label: 'Low Stock Items'),
              error: (e, _) => _ErrorCard(label: 'Low Stock Items', error: e.toString()),
              data: (items) => _SummaryCard(
                label: 'Low Stock Items',
                value: '${items.length}',
                icon: Icons.warning_amber_outlined,
                color: items.isEmpty ? AppColors.success : AppColors.warning,
                subtitle: items.isEmpty ? 'All items are adequately stocked' : 'Items at or below reorder level',
              ),
            ),
            const SizedBox(height: 16),
            // Upcoming cheques card
            upcomingChequesAsync.when(
              loading: () => const _SummaryCardShimmer(label: 'Cheques Due (7 days)'),
              error: (e, _) => _ErrorCard(label: 'Cheques Due (7 days)', error: e.toString()),
              data: (cheques) {
                final total = cheques.fold<double>(0, (s, c) => s + c.amount);
                return _SummaryCard(
                  label: 'Cheques Due (7 days)',
                  value: '${cheques.length}',
                  icon: Icons.calendar_today_outlined,
                  color: cheques.isEmpty ? AppColors.success : AppColors.primary,
                  subtitle: cheques.isEmpty ? 'No cheques due soon' : 'Total: ${CurrencyUtils.format(total)}',
                );
              },
            ),
            const SizedBox(height: 32),
            // Upcoming cheques list
            upcomingChequesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (cheques) {
                if (cheques.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upcoming Cheques', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    ...cheques.map((c) => _ChequeRow(cheque: c)),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Low stock list
            lowStockAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Low Stock Items', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    ...items.map((s) => _StockRow(stock: s)),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Charts and detailed reports (P&L, stock valuation, aging) will be available in Phase 4.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySmall),
                  Text(value, style: AppTextStyles.titleLarge.copyWith(color: color)),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCardShimmer extends StatelessWidget {
  const _SummaryCardShimmer({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                const SizedBox(height: 6),
                const SizedBox(
                  width: 80,
                  height: 20,
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.label, required this.error});
  final String label;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.errorLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$label: $error', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
      ),
    );
  }
}

class _ChequeRow extends StatelessWidget {
  const _ChequeRow({required this.cheque});
  final Cheque cheque;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(
          cheque.type == 'received' ? Icons.arrow_downward : Icons.arrow_upward,
          color: cheque.type == 'received' ? AppColors.success : AppColors.error,
          size: 20,
        ),
        title: Text(cheque.partyName, style: AppTextStyles.labelLarge),
        subtitle: Text(
          'Due: ${BmsDateUtils.formatDate(cheque.dueDate)}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Text(CurrencyUtils.format(cheque.amount), style: AppTextStyles.titleMedium),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.stock});
  final StockLevel stock;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.inventory_2_outlined, color: AppColors.warning, size: 20),
        title: Text(stock.productId, style: AppTextStyles.labelLarge),
        trailing: Text(
          'Qty: ${stock.qty.toStringAsFixed(0)}',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.warning),
        ),
      ),
    );
  }
}
