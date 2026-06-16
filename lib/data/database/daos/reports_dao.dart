import 'package:drift/drift.dart';

import 'package:bms/data/database/app_database.dart';

class DailySales {
  DailySales({required this.date, required this.revenue, required this.cogs});
  final DateTime date;
  final double revenue;
  final double cogs;
  double get grossProfit => revenue - cogs;
}

class StockValuationRow {
  StockValuationRow({
    required this.name,
    required this.qty,
    required this.costPrice,
    required this.value,
  });
  final String name;
  final double qty;
  final double costPrice;
  final double value;
}

class DebtorAgingRow {
  DebtorAgingRow({
    required this.customerId,
    required this.name,
    required this.balance,
    required this.oldestUnpaidDate,
  });
  final String customerId;
  final String name;
  final double balance;
  final DateTime? oldestUnpaidDate;

  int get daysPastDue {
    if (oldestUnpaidDate == null) return 0;
    return DateTime.now().difference(oldestUnpaidDate!).inDays;
  }

  // 0 = 0-30d, 1 = 31-60d, 2 = 61-90d, 3 = 90+d
  int get agingBucket {
    final d = daysPastDue;
    if (d <= 30) return 0;
    if (d <= 60) return 1;
    if (d <= 90) return 2;
    return 3;
  }
}

class ReportsDao {
  ReportsDao(this._db);
  final AppDatabase _db;

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<List<DailySales>> getDailySales(DateTime from, DateTime to) async {
    // Invoice revenue (non-void)
    final invoiceList = await (_db.select(_db.invoices)
          ..where((i) => i.createdAt.isBetweenValues(from, to) & i.status.equals('void').not()))
        .get();

    // Invoice COGS: items × product cost price
    final cogsQuery = _db.select(_db.invoiceItems).join([
      innerJoin(_db.invoices, _db.invoices.id.equalsExp(_db.invoiceItems.invoiceId)),
      innerJoin(_db.products, _db.products.id.equalsExp(_db.invoiceItems.productId)),
    ]);
    cogsQuery.where(
      _db.invoices.createdAt.isBetweenValues(from, to) &
          _db.invoices.status.equals('void').not(),
    );
    final cogsRows = await cogsQuery.get();

    // Quick-sale revenue
    final qsList = await (_db.select(_db.noInvoiceSales)
          ..where((s) => s.createdAt.isBetweenValues(from, to)))
        .get();

    // Quick-sale COGS: qty × product cost price
    final qsCogsQuery = _db.select(_db.noInvoiceSales).join([
      innerJoin(_db.products, _db.products.id.equalsExp(_db.noInvoiceSales.productId)),
    ]);
    qsCogsQuery.where(_db.noInvoiceSales.createdAt.isBetweenValues(from, to));
    final qsCogsRows = await qsCogsQuery.get();

    // Merge into day buckets
    final Map<String, double> revByDay = {};
    final Map<String, double> cogsByDay = {};

    for (final inv in invoiceList) {
      final k = _dateKey(inv.createdAt);
      revByDay[k] = (revByDay[k] ?? 0) + inv.total;
    }
    for (final row in cogsRows) {
      final inv = row.readTable(_db.invoices);
      final item = row.readTable(_db.invoiceItems);
      final product = row.readTable(_db.products);
      final k = _dateKey(inv.createdAt);
      cogsByDay[k] = (cogsByDay[k] ?? 0) + item.qty * product.costPrice;
    }
    for (final qs in qsList) {
      final k = _dateKey(qs.createdAt);
      revByDay[k] = (revByDay[k] ?? 0) + qs.qty * qs.price;
    }
    for (final row in qsCogsRows) {
      final qs = row.readTable(_db.noInvoiceSales);
      final product = row.readTable(_db.products);
      final k = _dateKey(qs.createdAt);
      cogsByDay[k] = (cogsByDay[k] ?? 0) + qs.qty * product.costPrice;
    }

    // Fill every day in range (including days with no sales → 0)
    final result = <DailySales>[];
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!cursor.isAfter(end)) {
      final k = _dateKey(cursor);
      result.add(DailySales(
        date: cursor,
        revenue: revByDay[k] ?? 0,
        cogs: cogsByDay[k] ?? 0,
      ));
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  Future<List<StockValuationRow>> getStockValuation() async {
    final query = _db.select(_db.products).join([
      leftOuterJoin(_db.stock, _db.stock.productId.equalsExp(_db.products.id)),
    ]);
    query.where(_db.products.isActive.equals(true));
    final rows = await query.get();

    return (rows.map((row) {
      final product = row.readTable(_db.products);
      final stockLevel = row.readTableOrNull(_db.stock);
      final qty = stockLevel?.qty ?? 0;
      return StockValuationRow(
        name: product.name,
        qty: qty,
        costPrice: product.costPrice,
        value: product.costPrice * qty,
      );
    }).where((r) => r.qty > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value)));
  }

  Future<List<DebtorAgingRow>> getDebtorAging() async {
    final debtors = await (_db.select(_db.customers)
          ..where((c) => c.balance.isBiggerThanValue(0))
          ..orderBy([(c) => OrderingTerm.desc(c.balance)]))
        .get();

    final result = <DebtorAgingRow>[];
    for (final customer in debtors) {
      final oldest = await (_db.select(_db.invoices)
            ..where((i) =>
                i.customerId.equals(customer.id) &
                i.status.isIn(['open', 'partial']))
            ..orderBy([(i) => OrderingTerm.asc(i.createdAt)])
            ..limit(1))
          .getSingleOrNull();
      result.add(DebtorAgingRow(
        customerId: customer.id,
        name: customer.name,
        balance: customer.balance,
        oldestUnpaidDate: oldest?.createdAt,
      ));
    }
    return result;
  }
}
