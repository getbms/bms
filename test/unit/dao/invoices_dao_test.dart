import 'package:bms/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() async => db.close());

  Future<Invoice> _inv({
    String id = 'inv1',
    String no = 'INV-001',
    String status = 'open',
    double total = 100,
    DateTime? createdAt,
  }) =>
      db.invoicesDao.insertInvoice(InvoicesCompanion.insert(
        id: id,
        invoiceNo: no,
        userId: 'u1',
        total: Value(total),
        status: Value(status),
        createdAt: createdAt != null ? Value(createdAt) : const Value.absent(),
      ));

  Future<void> _item(String invoiceId, {String productId = 'p1'}) =>
      db.invoicesDao.insertItems([
        InvoiceItemsCompanion.insert(
          id: 'ii-${invoiceId}_$productId',
          invoiceId: invoiceId,
          productId: productId,
          productName: 'Widget',
          qty: 1,
          unitPrice: 100,
          subtotal: 100,
        ),
      ]);

  group('InvoicesDao', () {
    group('insertInvoice + findById', () {
      test('returns invoice when found', () async {
        await _inv();
        final inv = await db.invoicesDao.findById('inv1');
        expect(inv?.invoiceNo, 'INV-001');
      });

      test('returns null when not found', () async {
        expect(await db.invoicesDao.findById('ghost'), isNull);
      });
    });

    group('findByInvoiceNo', () {
      test('returns invoice matching invoiceNo', () async {
        await _inv();
        final inv = await db.invoicesDao.findByInvoiceNo('INV-001');
        expect(inv?.id, 'inv1');
      });

      test('returns null when no match', () async {
        expect(await db.invoicesDao.findByInvoiceNo('INV-999'), isNull);
      });
    });

    group('insertItems + getItemsForInvoice', () {
      test('returns all items for invoice', () async {
        await _inv();
        await _item('inv1', productId: 'p1');
        await db.inventoryDao.insertProduct(ProductsCompanion.insert(id: 'p2', name: 'B'));
        await _item('inv1', productId: 'p2');
        final items = await db.invoicesDao.getItemsForInvoice('inv1');
        expect(items.length, 2);
      });
    });

    group('getByDateRange', () {
      test('returns invoices within range', () async {
        final base = DateTime(2024, 6, 15, 10);
        await _inv(id: 'inv1', createdAt: base);
        await _inv(id: 'inv2', no: 'INV-002',
            createdAt: base.add(const Duration(days: 1)));
        await _inv(id: 'inv3', no: 'INV-003',
            createdAt: base.subtract(const Duration(days: 2)));
        final list = await db.invoicesDao.getByDateRange(
          DateTime(2024, 6, 15),
          DateTime(2024, 6, 15, 23, 59, 59),
        );
        expect(list.map((i) => i.id).toSet(), {'inv1'});
      });
    });

    group('voidInvoice', () {
      test('sets status to void', () async {
        await _inv();
        await db.invoicesDao.voidInvoice(
          id: 'inv1', reason: 'mistake', approvedBy: 'manager',
        );
        final inv = await db.invoicesDao.findById('inv1');
        expect(inv?.status, 'void');
        expect(inv?.voidReason, 'mistake');
      });
    });

    group('noInvoiceSales', () {
      test('insertNoInvoiceSale + getNoInvoiceSalesByDate returns entry', () async {
        final now = DateTime.now();
        await db.inventoryDao.insertProduct(ProductsCompanion.insert(id: 'p1', name: 'W'));
        await db.invoicesDao.insertNoInvoiceSale(NoInvoiceSalesCompanion.insert(
          id: 'nis1', productId: 'p1', productName: 'W', qty: 2, price: 50, userId: 'u1',
          createdAt: Value(now),
        ));
        final list = await db.invoicesDao.getNoInvoiceSalesByDate(
          now.subtract(const Duration(hours: 1)),
          now.add(const Duration(hours: 1)),
        );
        expect(list.length, 1);
      });
    });

    group('nextInvoiceNumber', () {
      test('first number has format INV-YYYYMMDD-0001', () async {
        final no = await db.invoicesDao.nextInvoiceNumber();
        expect(no, matches(RegExp(r'^INV-\d{8}-0001$')));
      });

      test('second call increments to 0002', () async {
        final no1 = await db.invoicesDao.nextInvoiceNumber();
        await _inv(no: no1);
        final no2 = await db.invoicesDao.nextInvoiceNumber();
        expect(no2, endsWith('-0002'));
      });
    });
  });
}
