import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/daos/reports_dao.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ReportsDao reports;

  setUp(() {
    db = openTestDatabase();
    reports = ReportsDao(db);
  });
  tearDown(() async => db.close());

  Future<void> seedInvoice({
    required String id,
    required String no,
    required double total,
    required DateTime date,
    String status = 'open',
  }) async {
    await db.invoicesDao.insertInvoice(InvoicesCompanion.insert(
      id: id,
      invoiceNo: no,
      userId: 'u1',
      total: Value(total),
      status: Value(status),
      createdAt: Value(date),
    ));
  }

  Future<void> seedProduct({
    String id = 'p1',
    String name = 'Widget',
    double costPrice = 50,
    bool active = true,
  }) async {
    await db.inventoryDao.insertProduct(ProductsCompanion.insert(
      id: id,
      name: name,
      costPrice: Value(costPrice),
      isActive: Value(active),
    ));
  }

  group('ReportsDao.getDailySales', () {
    test('returns one row per day in range even with no sales', () async {
      final from = DateTime(2024, 6);
      final to = DateTime(2024, 6, 3);
      final rows = await reports.getDailySales(from, to);
      expect(rows.length, 3);
      expect(rows.every((r) => r.revenue == 0), isTrue);
    });

    test('sums revenue from invoices within range', () async {
      final base = DateTime(2024, 6, 1, 12);
      await seedInvoice(id: 'i1', no: 'INV-001', total: 1000, date: base);
      await seedInvoice(id: 'i2', no: 'INV-002', total: 500, date: base);
      final rows = await reports.getDailySales(
        DateTime(2024, 6),
        DateTime(2024, 6, 1, 23, 59, 59),
      );
      expect(rows.length, 1);
      expect(rows.first.revenue, 1500);
    });

    test('excludes voided invoices from revenue', () async {
      final base = DateTime(2024, 6, 1, 10);
      await seedInvoice(id: 'i1', no: 'INV-001', total: 800, date: base);
      await seedInvoice(id: 'i2', no: 'INV-002', total: 200, date: base, status: 'void');
      final rows = await reports.getDailySales(
        DateTime(2024, 6),
        DateTime(2024, 6, 1, 23, 59, 59),
      );
      expect(rows.first.revenue, 800);
    });

    test('excludes invoices outside the date range', () async {
      final outside = DateTime(2024, 5, 31, 12);
      await seedInvoice(id: 'i1', no: 'INV-001', total: 999, date: outside);
      final rows = await reports.getDailySales(
        DateTime(2024, 6),
        DateTime(2024, 6, 1, 23, 59, 59),
      );
      expect(rows.first.revenue, 0);
    });

    test('grossProfit equals revenue minus cogs', () async {
      final base = DateTime(2024, 6, 1, 9);
      await seedProduct(costPrice: 30);
      await seedInvoice(id: 'i1', no: 'INV-001', total: 100, date: base);
      await db.invoicesDao.insertItems([
        InvoiceItemsCompanion.insert(
          id: 'ii1',
          invoiceId: 'i1',
          productId: 'p1',
          productName: 'Widget',
          qty: 1,
          unitPrice: 100,
          subtotal: 100,
        ),
      ]);
      final rows = await reports.getDailySales(
        DateTime(2024, 6),
        DateTime(2024, 6, 1, 23, 59, 59),
      );
      expect(rows.first.revenue, 100);
      expect(rows.first.cogs, 30);
      expect(rows.first.grossProfit, 70);
    });
  });

  group('ReportsDao.getStockValuation', () {
    test('returns empty when no products', () async {
      expect(await reports.getStockValuation(), isEmpty);
    });

    test('excludes products with zero stock', () async {
      await seedProduct();
      expect(await reports.getStockValuation(), isEmpty);
    });

    test('returns product with stock > 0 and correct value', () async {
      await seedProduct(costPrice: 20);
      await db.inventoryDao.upsertStock(StockCompanion.insert(productId: 'p1', qty: const Value(5)));
      final rows = await reports.getStockValuation();
      expect(rows.length, 1);
      expect(rows.first.qty, 5);
      expect(rows.first.costPrice, 20);
      expect(rows.first.value, 100);
    });

    test('excludes inactive products', () async {
      await seedProduct(costPrice: 20, active: false);
      await db.inventoryDao.upsertStock(StockCompanion.insert(productId: 'p1', qty: const Value(5)));
      expect(await reports.getStockValuation(), isEmpty);
    });

    test('sorts by descending value', () async {
      await seedProduct(name: 'Cheap', costPrice: 5);
      await seedProduct(id: 'p2', name: 'Expensive', costPrice: 100);
      await db.inventoryDao.upsertStock(StockCompanion.insert(productId: 'p1', qty: const Value(10)));
      await db.inventoryDao.upsertStock(StockCompanion.insert(productId: 'p2', qty: const Value(3)));
      final rows = await reports.getStockValuation();
      expect(rows.first.name, 'Expensive');
    });
  });

  group('ReportsDao.getDebtorAging', () {
    test('returns empty when no customers with balance > 0', () async {
      await db.customersDao.insert(CustomersCompanion.insert(
        id: 'c1', name: 'Paid', balance: const Value(0),
      ));
      expect(await reports.getDebtorAging(), isEmpty);
    });

    test('includes customer with positive balance', () async {
      await db.customersDao.insert(CustomersCompanion.insert(
        id: 'c1', name: 'Debtor', balance: const Value(500),
      ));
      final rows = await reports.getDebtorAging();
      expect(rows.length, 1);
      expect(rows.first.name, 'Debtor');
      expect(rows.first.balance, 500);
    });

    test('sorts by balance descending', () async {
      await db.customersDao.insert(CustomersCompanion.insert(
        id: 'c1', name: 'Small', balance: const Value(100),
      ));
      await db.customersDao.insert(CustomersCompanion.insert(
        id: 'c2', name: 'Large', balance: const Value(900),
      ));
      final rows = await reports.getDebtorAging();
      expect(rows.first.name, 'Large');
    });

    test('agingBucket is 0 when no unpaid invoices', () async {
      await db.customersDao.insert(CustomersCompanion.insert(
        id: 'c1', name: 'D', balance: const Value(100),
      ));
      final rows = await reports.getDebtorAging();
      expect(rows.first.agingBucket, 0);
      expect(rows.first.daysPastDue, 0);
    });

    test('agingBucket reflects oldest unpaid invoice age', () async {
      await db.customersDao.insert(CustomersCompanion.insert(
        id: 'c1', name: 'D', balance: const Value(200),
      ));
      final old = DateTime.now().subtract(const Duration(days: 45));
      await db.invoicesDao.insertInvoice(InvoicesCompanion.insert(
        id: 'i1',
        invoiceNo: 'INV-001',
        userId: 'u1',
        customerId: const Value('c1'),
        status: const Value('open'),
        createdAt: Value(old),
      ));
      final rows = await reports.getDebtorAging();
      expect(rows.first.agingBucket, 1);
    });
  });
}
