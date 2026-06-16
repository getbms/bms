import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/daos/reports_dao.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_provider.g.dart';

class DashboardStats {
  const DashboardStats({
    required this.todaySales,
    required this.lowStockCount,
    required this.totalDebtors,
    required this.chequesThisWeek,
    required this.recentInvoices,
    required this.salesTrend,
    required this.paymentMix,
    required this.mtdSales,
    required this.lastMonthSales,
    required this.mtdInvoiceCount,
    required this.avgOrderValue,
  });

  final double todaySales;
  final int lowStockCount;
  final double totalDebtors;
  final int chequesThisWeek;
  final List<Invoice> recentInvoices;

  // 30-day daily trend (revenue + COGS so grossProfit is available)
  final List<DailySales> salesTrend;

  final Map<String, double> paymentMix;
  final double mtdSales;
  final double lastMonthSales;
  final int mtdInvoiceCount;
  final double avgOrderValue;

  double get mtdGrowthPct {
    if (lastMonthSales == 0) return 0;
    return (mtdSales - lastMonthSales) / lastMonthSales * 100;
  }

  List<DailySales> get last7Days {
    if (salesTrend.length <= 7) return salesTrend;
    return salesTrend.sublist(salesTrend.length - 7);
  }

  double get mtdGrossProfit {
    final now = DateTime.now();
    return salesTrend
        .where((d) => d.date.year == now.year && d.date.month == now.month)
        .fold(0.0, (s, d) => s + d.grossProfit);
  }

  double get mtdGrossMarginPct {
    if (mtdSales == 0) return 0;
    return mtdGrossProfit / mtdSales * 100;
  }
}

@riverpod
Future<DashboardStats> dashboardStats(Ref ref) async {
  final invoicesDao = ref.watch(invoicesDaoProvider);
  final inventoryDao = ref.watch(inventoryDaoProvider);
  final customersDao = ref.watch(customersDaoProvider);
  final chequesDao = ref.watch(chequesDaoProvider);
  final reportsDao = ref.watch(reportsDaoProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final thirtyDaysAgo = todayStart.subtract(const Duration(days: 29));
  final monthStart = DateTime(now.year, now.month, 1);
  final lastMonthStart = DateTime(now.year, now.month - 1, 1);

  final (todayInvs, lowStock, debtors, cheques, recent, trend, thisMonth, lastMonth) =
      await (
    invoicesDao.getByDateRange(todayStart, todayEnd),
    inventoryDao.watchLowStock().first,
    customersDao.getDebtors(),
    chequesDao.getDueWithinDays(7),
    invoicesDao.getByDateRange(now.subtract(const Duration(days: 30)), todayEnd),
    reportsDao.getDailySales(thirtyDaysAgo, todayEnd),
    invoicesDao.getByDateRange(monthStart, todayEnd),
    invoicesDao.getByDateRange(lastMonthStart, monthStart),
  ).wait;

  final paymentMix = <String, double>{};
  int mtdCount = 0;
  double mtdTotal = 0;
  for (final inv in thisMonth.where((i) => i.status != 'void')) {
    paymentMix[inv.paymentType] =
        (paymentMix[inv.paymentType] ?? 0) + inv.total;
    mtdCount++;
    mtdTotal += inv.total;
  }

  return DashboardStats(
    todaySales: todayInvs
        .where((i) => i.status != 'void')
        .fold(0, (s, i) => s + i.total),
    lowStockCount: lowStock.length,
    totalDebtors: debtors.fold(0, (s, c) => s + c.balance),
    chequesThisWeek: cheques.length,
    recentInvoices: recent
        .where((i) => i.status != 'void')
        .take(8)
        .toList(),
    salesTrend: trend,
    paymentMix: paymentMix,
    mtdSales: mtdTotal,
    lastMonthSales: lastMonth
        .where((i) => i.status != 'void')
        .fold(0, (s, i) => s + i.total),
    mtdInvoiceCount: mtdCount,
    avgOrderValue: mtdCount > 0 ? mtdTotal / mtdCount : 0,
  );
}

@riverpod
Future<double> todaySalesTotal(Ref ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final invoices = await ref
      .watch(invoicesDaoProvider)
      .getByDateRange(start, start.add(const Duration(days: 1)));
  return invoices
      .where((i) => i.status != 'void')
      .fold<double>(0.0, (sum, inv) => sum + inv.total);
}
