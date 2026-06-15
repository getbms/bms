import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../shared/widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${BmsDateUtils.formatDate(DateTime.now())}'),
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardStatsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GridView.extent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(
                    label: "Today's Sales",
                    value: CurrencyUtils.format(s.todaySales),
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.success,
                    onTap: () => context.go(AppRoutes.pos),
                  ),
                  StatCard(
                    label: 'Low Stock Items',
                    value: '${s.lowStockCount}',
                    icon: Icons.warning_amber_outlined,
                    color: AppColors.warning,
                    onTap: () => context.go(AppRoutes.inventory),
                  ),
                  StatCard(
                    label: 'Cheques Due (7 days)',
                    value: '${s.chequesThisWeek}',
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.primary,
                    onTap: () => context.go(AppRoutes.cheques),
                  ),
                  StatCard(
                    label: 'Total Receivables',
                    value: CurrencyUtils.format(s.totalDebtors),
                    icon: Icons.people_outline,
                    color: AppColors.error,
                    onTap: () => context.go(AppRoutes.customers),
                  ),
                ],
              ),
              if (s.recentInvoices.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text('Recent Invoices', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                ...s.recentInvoices.map((inv) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.receipt_outlined,
                            color: AppColors.primary),
                        title: Text(inv.invoiceNo,
                            style: AppTextStyles.labelLarge),
                        subtitle: Text(
                            BmsDateUtils.formatDateTime(inv.createdAt),
                            style: AppTextStyles.bodySmall),
                        trailing: Text(
                          CurrencyUtils.format(inv.total),
                          style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.success),
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
