import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/data/database/daos/reports_dao.dart';
import 'package:bms/providers/reports_provider.dart';
import 'package:bms/shared/widgets/bms_filter_bar.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
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
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'P&L'),
            Tab(text: 'Stock Value'),
            Tab(text: 'Aging'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _PLTab(),
          _StockTab(),
          _AgingTab(),
        ],
      ),
    );
  }
}

// ─── P&L Tab ────────────────────────────────────────────────────────────────

class _PLTab extends ConsumerStatefulWidget {
  const _PLTab();

  @override
  ConsumerState<_PLTab> createState() => _PLTabState();
}

class _PLTabState extends ConsumerState<_PLTab> {
  late DateTimeRange _range;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dailySalesProvider(_range.start, _range.end));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: BmsDateRangeField(
            start: _range.start,
            end: _range.end,
            onPick: (r) => setState(() => _range = r),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (daily) {
              final revenue = daily.fold<double>(0, (s, d) => s + d.revenue);

              if (revenue == 0) {
                return Column(
                  children: [
                    Expanded(
                      child: _EmptyState(
                        icon: Icons.bar_chart_outlined,
                        iconColor: AppColors.primary,
                        title: 'No Sales Data',
                        subtitle:
                            'No transactions were recorded for this period.\nTry adjusting the date range.',
                      ),
                    ),
                  ],
                );
              }

              final cogs = daily.fold<double>(0, (s, d) => s + d.cogs);
              final grossProfit = revenue - cogs;
              final margin = revenue > 0 ? grossProfit / revenue * 100 : 0.0;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryGrid(
                    items: [
                      (
                        label: 'Revenue',
                        value: CurrencyUtils.format(revenue),
                        color: AppColors.success,
                        icon: Icons.trending_up,
                      ),
                      (
                        label: 'COGS',
                        value: CurrencyUtils.format(cogs),
                        color: AppColors.error,
                        icon: Icons.shopping_cart_outlined,
                      ),
                      (
                        label: 'Gross Profit',
                        value: CurrencyUtils.format(grossProfit),
                        color: grossProfit >= 0 ? AppColors.primary : AppColors.error,
                        icon: Icons.account_balance_outlined,
                      ),
                      (
                        label: 'Margin',
                        value: '${margin.toStringAsFixed(1)}%',
                        color: margin >= 20 ? AppColors.success : AppColors.warning,
                        icon: Icons.percent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Daily Revenue', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  _PLChart(daily: daily),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PLChart extends StatelessWidget {
  const _PLChart({required this.daily});
  final List<DailySales> daily;

  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final maxY = daily.map((d) => d.revenue).fold<double>(0, (a, b) => a > b ? a : b);

    // Show a label every N days depending on range length
    final labelStep = daily.length <= 10
        ? 1
        : daily.length <= 20
            ? 2
            : 5;

    final barGroups = daily.asMap().entries.map((e) {
      final d = e.value;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: d.revenue,
            color: d.revenue > 0 ? AppColors.primary : AppColors.border,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border.withValues(alpha: 0.6),
              strokeWidth: 0.8,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) {
                final d = daily[group.x];
                return BarTooltipItem(
                  '${d.date.day}/${d.date.month}\n${CurrencyUtils.format(rod.toY)}',
                  AppTextStyles.bodySmall.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (v, meta) {
                  if (v == 0 || v == meta.max) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(_compact(v), style: AppTextStyles.bodySmall),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= daily.length || idx % labelStep != 0) {
                    return const SizedBox.shrink();
                  }
                  final d = daily[idx].date;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${d.day}/${d.month}',
                      style: AppTextStyles.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stock Valuation Tab ─────────────────────────────────────────────────────

class _StockTab extends ConsumerWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stockValuationProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return _EmptyState(
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primary,
            title: 'No Stock on Hand',
            subtitle:
                'Products with stock will appear here once\nyou record a goods received note.',
          );
        }

        final totalValue = rows.fold<double>(0, (s, r) => s + r.value);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Column(
                children: [
                  _TotalValueCard(
                    totalValue: totalValue,
                    itemCount: rows.length,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text('Product',
                                style: AppTextStyles.bodySmall)),
                        SizedBox(
                          width: 48,
                          child: Text('Qty',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.end),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text('Value',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            }
            final row = rows[i - 1];
            return _StockValueRow(row: row, maxValue: totalValue);
          },
        );
      },
    );
  }
}

class _TotalValueCard extends StatelessWidget {
  const _TotalValueCard({required this.totalValue, required this.itemCount});
  final double totalValue;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Stock Value',
                      style: AppTextStyles.bodySmall),
                  Text(CurrencyUtils.format(totalValue),
                      style: AppTextStyles.titleLarge
                          .copyWith(color: AppColors.primary)),
                  Text('$itemCount products with stock',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockValueRow extends StatelessWidget {
  const _StockValueRow({required this.row, required this.maxValue});
  final StockValuationRow row;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? (row.value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.name,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  row.qty % 1 == 0
                      ? row.qty.toInt().toString()
                      : row.qty.toStringAsFixed(2),
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  CurrencyUtils.format(row.value),
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primary),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.border,
            color: AppColors.primary.withValues(alpha: 0.5),
            minHeight: 3,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

// ─── Debtor Aging Tab ────────────────────────────────────────────────────────

class _AgingTab extends ConsumerWidget {
  const _AgingTab();

  static const _bucketLabels = ['0-30 days', '31-60 days', '61-90 days', '90+ days'];
  static const _bucketColors = [
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    Color(0xFFB71C1C),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(debtorAgingProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            title: 'All Clear',
            subtitle:
                'No customers have outstanding balances.\nAll receivables are settled.',
          );
        }

        final total = rows.fold<double>(0, (s, r) => s + r.balance);
        final bucketAmounts = List.filled(4, 0.0);
        for (final r in rows) {
          bucketAmounts[r.agingBucket] += r.balance;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        color: AppColors.warning, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Outstanding',
                              style: AppTextStyles.bodySmall),
                          Text(CurrencyUtils.format(total),
                              style: AppTextStyles.titleLarge
                                  .copyWith(color: AppColors.warning)),
                          Text('${rows.length} customers',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pie chart + legend
            Text('Balance by Age', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            _AgingChart(
              bucketAmounts: bucketAmounts,
              total: total,
              labels: _bucketLabels,
              colors: _bucketColors,
            ),
            const SizedBox(height: 8),
            _AgingLegend(
                bucketAmounts: bucketAmounts,
                labels: _bucketLabels,
                colors: _bucketColors),
            const SizedBox(height: 24),

            // Debtor list
            Text('Customers', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            ...rows.map((r) => _DebtorRow(row: r, colors: _bucketColors, labels: _bucketLabels)),
          ],
        );
      },
    );
  }
}

class _AgingChart extends StatelessWidget {
  const _AgingChart({
    required this.bucketAmounts,
    required this.total,
    required this.labels,
    required this.colors,
  });
  final List<double> bucketAmounts;
  final double total;
  final List<String> labels;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final nonZero = bucketAmounts.any((v) => v > 0);
    if (!nonZero) return const SizedBox.shrink();

    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sections: List.generate(4, (i) {
            final value = bucketAmounts[i];
            if (value == 0) return null;
            final pct = total > 0 ? value / total * 100 : 0.0;
            return PieChartSectionData(
              value: value,
              color: colors[i],
              radius: 60,
              title: '${pct.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            );
          }).whereType<PieChartSectionData>().toList(),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}

class _AgingLegend extends StatelessWidget {
  const _AgingLegend({
    required this.bucketAmounts,
    required this.labels,
    required this.colors,
  });
  final List<double> bucketAmounts;
  final List<String> labels;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(4, (i) {
        if (bucketAmounts[i] == 0) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 4),
            Text(
              '${labels[i]}  ${CurrencyUtils.format(bucketAmounts[i])}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );
      }),
    );
  }
}

class _DebtorRow extends StatelessWidget {
  const _DebtorRow(
      {required this.row, required this.colors, required this.labels});
  final DebtorAgingRow row;
  final List<Color> colors;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final bucket = row.agingBucket;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors[bucket].withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labels[bucket],
                      style: AppTextStyles.bodySmall
                          .copyWith(color: colors[bucket]),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyUtils.format(row.balance),
              style: AppTextStyles.titleMedium
                  .copyWith(color: colors[bucket]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.items});
  final List<({String label, String value, Color color, IconData icon})> items;

  @override
  Widget build(BuildContext context) {
    // Build rows of 2 cards — content-driven height, no aspect ratio distortion
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: _SummaryCard(item: items[i])),
          const SizedBox(width: 12),
          if (i + 1 < items.length)
            Expanded(child: _SummaryCard(item: items[i + 1]))
          else
            const Expanded(child: SizedBox()),
        ],
      ));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});
  final ({String label, String value, Color color, IconData icon}) item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: AppTextStyles.titleMedium.copyWith(color: item.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = AppColors.textSecondary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
