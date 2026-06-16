import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:bms/core/router/app_router.dart';
import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/core/utils/date_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/daos/reports_dao.dart';
import 'package:bms/providers/dashboard_provider.dart';
import 'package:bms/shared/widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              BmsDateUtils.formatDate(DateTime.now()),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardStatsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── KPI Grid ────────────────────────────────────────────────
              GridView.extent(
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 3,
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
                    label: 'Cheques Due (7d)',
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

              const SizedBox(height: 20),

              // ── MTD Performance ─────────────────────────────────────────
              _MtdPerformanceCard(s: s),

              const SizedBox(height: 28),

              // ── 30-Day Revenue Trend ─────────────────────────────────────
              _SectionHeader(
                title: 'Revenue Trend',
                subtitle: 'Last 30 days - Revenue vs Gross Profit',
              ),
              const SizedBox(height: 12),
              _RevenueTrendChart(trend: s.salesTrend),

              const SizedBox(height: 28),

              // ── Weekly Performance ────────────────────────────────────────
              _SectionHeader(
                title: 'Weekly Performance',
                subtitle: 'Last 7 days',
              ),
              const SizedBox(height: 12),
              _WeeklyGroupedChart(days: s.last7Days),

              // ── Payment Mix ──────────────────────────────────────────────
              if (s.paymentMix.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Payment Mix',
                  subtitle: 'Current month by method',
                ),
                const SizedBox(height: 12),
                _PaymentMixCard(mix: s.paymentMix),
              ],

              // ── Recent Invoices ──────────────────────────────────────────
              if (s.recentInvoices.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Recent Invoices',
                  subtitle: 'Last 30 days',
                  onTap: () => context.go(AppRoutes.invoices),
                ),
                const SizedBox(height: 12),
                _RecentInvoicesList(invoices: s.recentInvoices),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: const Text('View All'),
            ),
        ],
      );
}

// ── MTD Performance Card ─────────────────────────────────────────────────────

class _MtdPerformanceCard extends StatelessWidget {
  const _MtdPerformanceCard({required this.s});
  final DashboardStats s;

  @override
  Widget build(BuildContext context) {
    final isPositive = s.mtdGrowthPct >= 0;
    final growthColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'Month-to-Date Performance',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyUtils.format(s.mtdSales),
                      style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.mtdInvoiceCount} invoices',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              if (s.lastMonthSales > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: growthColor,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.mtdGrowthPct.abs().toStringAsFixed(1)}%',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: growthColor),
                      ),
                      Text(
                        'vs last month',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _MtdMetric(
                label: 'Gross Profit',
                value: CurrencyUtils.format(s.mtdGrossProfit),
                color: const Color(0xFF69F0AE),
              ),
              const SizedBox(width: 24),
              _MtdMetric(
                label: 'Margin',
                value: '${s.mtdGrossMarginPct.toStringAsFixed(1)}%',
                color: Colors.white,
              ),
              const SizedBox(width: 24),
              _MtdMetric(
                label: 'Avg Order',
                value: CurrencyUtils.format(s.avgOrderValue),
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MtdMetric extends StatelessWidget {
  const _MtdMetric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white60)),
          const SizedBox(height: 2),
          Text(value,
              style:
                  AppTextStyles.labelLarge.copyWith(color: color, fontSize: 13)),
        ],
      );
}

// ── 30-Day Revenue Trend Line Chart ──────────────────────────────────────────

class _RevenueTrendChart extends StatelessWidget {
  const _RevenueTrendChart({required this.trend});
  final List<DailySales> trend;

  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final hasSales = trend.any((d) => d.revenue > 0);

    if (!hasSales) {
      return _ChartCard(
        height: 240,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart_outlined,
                  size: 40, color: AppColors.border),
              const SizedBox(height: 8),
              Text('No sales data for the last 30 days.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final maxY = trend.map((d) => d.revenue).fold<double>(0, (a, b) => a > b ? a : b);

    final revenueSpots = trend.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.revenue))
        .toList();
    final gpSpots = trend.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.grossProfit.clamp(0, double.infinity)))
        .toList();

    final dateFmt = DateFormat('d MMM');

    return _ChartCard(
      height: 280,
      child: Column(
        children: [
          // Legend
          Row(
            children: [
              _ChartLegendDot(color: AppColors.primary, label: 'Revenue'),
              const SizedBox(width: 16),
              _ChartLegendDot(color: AppColors.success, label: 'Gross Profit'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY > 0 ? maxY * 1.25 : 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 20,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (spots) => spots.map((spot) {
                      final day = trend[spot.x.toInt()];
                      final isRevenue = spot.barIndex == 0;
                      return LineTooltipItem(
                        isRevenue ? dateFmt.format(day.date) : '',
                        AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text: '\n${isRevenue ? "Revenue" : "GP"}  ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white60,
                              fontWeight: FontWeight.w400,
                              fontSize: 11,
                            ),
                          ),
                          TextSpan(
                            text: CurrencyUtils.format(spot.y),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
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
                      interval: maxY > 0 ? maxY / 4 : 25,
                      getTitlesWidget: (v, meta) {
                        if (v == meta.max || v == 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(_compact(v),
                              style: AppTextStyles.bodySmall),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 7,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        if (idx % 7 != 0 && idx != trend.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            dateFmt.format(trend[idx].date),
                            style: AppTextStyles.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: revenueSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: gpSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.success,
                    barWidth: 2,
                    dashArray: [4, 3],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.success.withValues(alpha: 0.10),
                          AppColors.success.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly Grouped Bar Chart ─────────────────────────────────────────────────

class _WeeklyGroupedChart extends StatelessWidget {
  const _WeeklyGroupedChart({required this.days});
  final List<DailySales> days;

  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text('No data.', style: AppTextStyles.bodySmall),
        ),
      );
    }

    final maxY = days.map((d) => d.revenue).fold<double>(0, (a, b) => a > b ? a : b);
    final fmt = DateFormat('EEE');

    final groups = days.asMap().entries.map((e) {
      final d = e.value;
      final gp = d.grossProfit.clamp(0.0, double.infinity);
      return BarChartGroupData(
        x: e.key,
        barsSpace: 3,
        barRods: [
          BarChartRodData(
            toY: d.revenue,
            width: 12,
            color: d.revenue > 0 ? AppColors.primary : AppColors.border,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: gp,
            width: 12,
            color: gp > 0 ? AppColors.success : AppColors.border,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return _ChartCard(
      height: 240,
      child: Column(
        children: [
          Row(
            children: [
              _ChartLegendDot(color: AppColors.primary, label: 'Revenue'),
              const SizedBox(width: 16),
              _ChartLegendDot(color: AppColors.success, label: 'Gross Profit'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY > 0 ? maxY * 1.25 : 100,
                groupsSpace: 16,
                barGroups: groups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.6),
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, rodIndex) {
                      final day = days[group.x];
                      final label = rodIndex == 0 ? 'Revenue' : 'Gross Profit';
                      return BarTooltipItem(
                        '$label\n${CurrencyUtils.format(rod.toY)}',
                        AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        children: rodIndex == 0
                            ? [
                                TextSpan(
                                  text: '\n${fmt.format(day.date)}',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: Colors.white70),
                                ),
                              ]
                            : null,
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
                        if (v == meta.max || v == 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(_compact(v),
                              style: AppTextStyles.bodySmall),
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
                        if (idx < 0 || idx >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            fmt.format(days[idx].date),
                            style: AppTextStyles.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Mix Card ─────────────────────────────────────────────────────────

class _PaymentMixCard extends StatelessWidget {
  const _PaymentMixCard({required this.mix});
  final Map<String, double> mix;

  static const _colorMap = {
    'cash': AppColors.success,
    'card': AppColors.primary,
    'cheque': AppColors.warning,
    'credit': AppColors.error,
    'mixed': Color(0xFF7B1FA2),
  };

  Color _colorFor(String type) =>
      _colorMap[type.toLowerCase()] ?? AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final total = mix.values.fold<double>(0, (s, v) => s + v);
    final entries = mix.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _ChartCard(
      child: Row(
        children: [
          // Donut chart with center label
          SizedBox(
            width: 160,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: entries.map((e) {
                      final pct = total > 0 ? e.value / total * 100 : 0.0;
                      return PieChartSectionData(
                        value: e.value,
                        color: _colorFor(e.key),
                        radius: 54,
                        title: pct >= 10
                            ? '${pct.toStringAsFixed(0)}%'
                            : '',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        showTitle: pct >= 10,
                      );
                    }).toList(),
                    centerSpaceRadius: 38,
                    sectionsSpace: 2,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                    Text(
                      _compactAmount(total),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Legend table
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.map((e) {
                final pct = total > 0 ? e.value / total * 100 : 0.0;
                final color = _colorFor(e.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _methodLabel(e.key),
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: total > 0 ? e.value / total : 0,
                                minHeight: 4,
                                backgroundColor: AppColors.border,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyUtils.format(e.value),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String _compactAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  static String _methodLabel(String type) => switch (type.toLowerCase()) {
        'cash' => 'Cash',
        'card' => 'Card',
        'cheque' => 'Cheque',
        'credit' => 'Credit',
        'mixed' => 'Mixed',
        _ => type,
      };
}

// ── Recent Invoices List ─────────────────────────────────────────────────────

class _RecentInvoicesList extends StatelessWidget {
  const _RecentInvoicesList({required this.invoices});
  final List<Invoice> invoices;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: invoices.asMap().entries.map((e) {
          final inv = e.value;
          final isLast = e.key == invoices.length - 1;
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _statusColor(inv.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_outlined,
                    size: 18,
                    color: _statusColor(inv.status),
                  ),
                ),
                title: Text(inv.invoiceNo, style: AppTextStyles.labelLarge),
                subtitle: Text(
                  BmsDateUtils.formatDateTime(inv.createdAt),
                  style: AppTextStyles.bodySmall,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyUtils.format(inv.total),
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color:
                            _statusColor(inv.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        inv.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(inv.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 52, endIndent: 16),
            ],
          );
        }).toList(),
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
}

// ── Shared Helpers ────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child, this.height});
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _ChartLegendDot extends StatelessWidget {
  const _ChartLegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      );
}
