import 'package:bms/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() async => db.close());

  Future<String> _supplier({String id = 's1', String name = 'Acme Ltd'}) =>
      db.suppliersDao.insert(SuppliersCompanion.insert(id: id, name: name));

  Future<String> _product(String id) =>
      db.inventoryDao.insertProduct(ProductsCompanion.insert(id: id, name: 'Prod $id'));

  group('SuppliersDao', () {
    group('insert + findById', () {
      test('returns supplier when found', () async {
        await _supplier();
        final s = await db.suppliersDao.findById('s1');
        expect(s?.name, 'Acme Ltd');
      });

      test('returns null when not found', () async {
        expect(await db.suppliersDao.findById('ghost'), isNull);
      });
    });

    group('updateBalance', () {
      test('accumulates balance correctly', () async {
        await _supplier();
        await db.suppliersDao.updateBalance('s1', 300);
        await db.suppliersDao.updateBalance('s1', -100);
        final s = await db.suppliersDao.findById('s1');
        expect(s?.balance, 200);
      });
    });

    group('insertPurchase + getPurchasesBySupplier', () {
      test('returns purchases for specific supplier', () async {
        await _supplier(id: 's1');
        await _supplier(id: 's2', name: 'Beta Ltd');
        await db.suppliersDao.insertPurchase(
          PurchasesCompanion.insert(id: 'pur1', supplierId: 's1', userId: 'u1'),
        );
        await db.suppliersDao.insertPurchase(
          PurchasesCompanion.insert(id: 'pur2', supplierId: 's2', userId: 'u1'),
        );
        final list = await db.suppliersDao.getPurchasesBySupplier('s1');
        expect(list.length, 1);
        expect(list.first.id, 'pur1');
      });
    });

    group('insertPurchaseItems + getItemsForPurchase', () {
      test('returns items for purchase', () async {
        await _supplier();
        await _product('p1');
        await db.suppliersDao.insertPurchase(
          PurchasesCompanion.insert(id: 'pur1', supplierId: 's1', userId: 'u1'),
        );
        await db.suppliersDao.insertPurchaseItems([
          PurchaseItemsCompanion.insert(
              id: 'pi1', purchaseId: 'pur1', productId: 'p1', qty: 10, costPrice: 50),
        ]);
        final items = await db.suppliersDao.getItemsForPurchase('pur1');
        expect(items.length, 1);
        expect(items.first.qty, 10);
      });
    });

    group('nextPoNumber', () {
      test('first PO is PO-00001', () async {
        await _supplier();
        final num = await db.suppliersDao.nextPoNumber();
        expect(num, 'PO-00001');
      });

      test('increments sequentially', () async {
        await _supplier();
        await db.suppliersDao.insertPO(PurchaseOrdersCompanion.insert(
          id: 'po1', supplierId: 's1', poNumber: 'PO-00001', createdBy: 'u1',
        ));
        final num = await db.suppliersDao.nextPoNumber();
        expect(num, 'PO-00002');
      });
    });

    group('nextGrnNumber', () {
      test('first GRN is GRN-00001', () async {
        await _supplier();
        final num = await db.suppliersDao.nextGrnNumber();
        expect(num, 'GRN-00001');
      });

      test('increments sequentially', () async {
        await _supplier();
        await db.suppliersDao.insertPurchase(PurchasesCompanion.insert(
          id: 'pur1', supplierId: 's1', userId: 'u1',
          grnNumber: const Value('GRN-00001'),
        ));
        final num = await db.suppliersDao.nextGrnNumber();
        expect(num, 'GRN-00002');
      });
    });

    group('recordPayment + getPaymentsForSupplier', () {
      test('returns payments for supplier', () async {
        await _supplier();
        await db.suppliersDao.recordPayment(SupplierPaymentsCompanion.insert(
          id: 'sp1', supplierId: 's1', amount: 500, userId: 'u1',
        ));
        final payments = await db.suppliersDao.getPaymentsForSupplier('s1');
        expect(payments.length, 1);
        expect(payments.first.amount, 500);
      });
    });

    group('PO operations', () {
      setUp(() async {
        await _supplier();
        await db.suppliersDao.insertPO(PurchaseOrdersCompanion.insert(
          id: 'po1', supplierId: 's1', poNumber: 'PO-00001', createdBy: 'u1',
        ));
      });

      test('getAllPOs returns all purchase orders', () async {
        final pos = await db.suppliersDao.getAllPOs();
        expect(pos.length, 1);
      });

      test('getPOsBySupplier returns only that suppliers POs', () async {
        await _supplier(id: 's2', name: 'Beta');
        await db.suppliersDao.insertPO(PurchaseOrdersCompanion.insert(
          id: 'po2', supplierId: 's2', poNumber: 'PO-00002', createdBy: 'u1',
        ));
        final pos = await db.suppliersDao.getPOsBySupplier('s1');
        expect(pos.length, 1);
        expect(pos.first.id, 'po1');
      });

      test('updatePOStatus changes status field', () async {
        await db.suppliersDao.updatePOStatus('po1', 'received');
        final pos = await db.suppliersDao.getAllPOs();
        expect(pos.first.status, 'received');
      });

      test('getPOItems returns items for PO', () async {
        await _product('p1');
        await db.suppliersDao.insertPOItems([
          PurchaseOrderItemsCompanion.insert(
            id: 'poi1', poId: 'po1', productId: 'p1', orderedQty: 5, costPrice: 100,
          ),
        ]);
        final items = await db.suppliersDao.getPOItems('po1');
        expect(items.length, 1);
        expect(items.first.orderedQty, 5);
      });
    });
  });
}
