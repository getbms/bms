import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/app_database.dart';
import 'database_provider.dart';

part 'dashboard_provider.g.dart';

class DashboardStats {
  const DashboardStats({
    required this.todaySales,
    required this.lowStockCount,
    required this.totalDebtors,
    required this.chequesThisWeek,
    required this.recentInvoices,
  });

  final double todaySales;
  final int lowStockCount;
  final double totalDebtors;
  final int chequesThisWeek;
  final List<Invoice> recentInvoices;
}

@riverpod
Future<DashboardStats> dashboardStats(Ref ref) async {
  final invoicesDao = ref.watch(invoicesDaoProvider);
  final inventoryDao = ref.watch(inventoryDaoProvider);
  final customersDao = ref.watch(customersDaoProvider);
  final chequesDao = ref.watch(chequesDaoProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final results = await Future.wait([
    invoicesDao.getByDateRange(todayStart, todayEnd),
    inventoryDao.watchLowStock().first,
    customersDao.getDebtors(),
    chequesDao.getDueWithinDays(7),
    invoicesDao.getByDateRange(
      now.subtract(const Duration(days: 30)),
      todayEnd,
    ),
  ]);

  final todayInvoices = results[0] as List<Invoice>;
  final lowStock = results[1] as List<StockLevel>;
  final debtors = results[2] as List<Customer>;
  final cheques = results[3] as List<Cheque>;
  final recent = results[4] as List<Invoice>;

  return DashboardStats(
    todaySales: todayInvoices.fold(0, (sum, inv) => sum + inv.total),
    lowStockCount: lowStock.length,
    totalDebtors: debtors.fold(0, (sum, c) => sum + c.balance),
    chequesThisWeek: cheques.length,
    recentInvoices: recent.take(8).toList(),
  );
}

@riverpod
Future<double> todaySalesTotal(Ref ref) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final invoices =
      await ref.watch(invoicesDaoProvider).getByDateRange(start, start.add(const Duration(days: 1)));
  return invoices.fold<double>(0.0, (sum, inv) => sum + inv.total);
}
