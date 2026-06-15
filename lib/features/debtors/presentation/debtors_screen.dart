import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/customers_provider.dart';

class DebtorsScreen extends ConsumerWidget {
  const DebtorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtorsAsync = ref.watch(debtorsFutureProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debtors')),
      body: debtorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (debtors) {
          if (debtors.isEmpty) {
            return const Center(
              child: Text('No outstanding debts.', style: AppTextStyles.bodySmall),
            );
          }

          final total = debtors.fold<double>(0, (sum, c) => sum + c.balance);
          final over30 = debtors.where((c) => _daysSince(c.updatedAt) > 30).length;
          final over60 = debtors.where((c) => _daysSince(c.updatedAt) > 60).length;

          return Column(
            children: [
              _SummaryBanner(total: total, over30: over30, over60: over60, count: debtors.length),
              Expanded(
                child: ListView.builder(
                  itemCount: debtors.length,
                  itemBuilder: (_, i) => _DebtorTile(customer: debtors[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static int _daysSince(DateTime dt) =>
      DateTime.now().difference(dt).inDays;
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.total,
    required this.count,
    required this.over30,
    required this.over60,
  });

  final double total;
  final int count;
  final int over30;
  final int over60;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.error.withAlpha(15),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Outstanding', style: AppTextStyles.bodySmall),
                Text(CurrencyUtils.format(total),
                    style: AppTextStyles.headlineMedium.copyWith(color: AppColors.error)),
                Text('$count debtor${count == 1 ? '' : 's'}', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AgingChip(label: '30+ days', count: over30, color: AppColors.warning),
              const SizedBox(height: 6),
              _AgingChip(label: '60+ days', count: over60, color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgingChip extends StatelessWidget {
  const _AgingChip({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count  $label',
        style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DebtorTile extends StatelessWidget {
  const _DebtorTile({required this.customer});

  final Customer customer;

  Color _agingColor(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days > 60) return AppColors.error;
    if (days > 30) return AppColors.warning;
    return AppColors.success;
  }

  String _agingLabel(DateTime dt) {
    final days = DateTime.now().difference(dt).inDays;
    if (days > 60) return '60+ days';
    if (days > 30) return '30+ days';
    return 'Current';
  }

  @override
  Widget build(BuildContext context) {
    final color = _agingColor(customer.updatedAt);
    final label = _agingLabel(customer.updatedAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(30),
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(customer.name, style: AppTextStyles.labelLarge),
      subtitle: Text(
        [
          if (customer.phone != null) customer.phone!,
          label,
        ].join(' · '),
        style: AppTextStyles.bodySmall,
      ),
      trailing: Text(
        CurrencyUtils.format(customer.balance),
        style: AppTextStyles.labelLarge.copyWith(color: color),
      ),
    );
  }
}
