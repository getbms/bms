import 'package:bms/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() async => db.close());

  Future<Invoice> seedInvoice() => db.invoicesDao.insertInvoice(
        InvoicesCompanion.insert(id: 'inv1', invoiceNo: 'INV-001', userId: 'u1'),
      );

  Future<SalesReturn> seedReturn(String invoiceId, {String id = 'ret1'}) =>
      db.returnsDao.insertReturnWithItems(
        SalesReturnsCompanion.insert(
          id: id,
          invoiceId: invoiceId,
          returnNo: 'placeholder',
          userId: 'u1',
        ),
        [
          ReturnItemsCompanion.insert(
            id: 'ri-$id',
            returnId: id,
            productId: 'p1',
            productName: 'Widget',
            qty: 1,
            unitPrice: 100,
            subtotal: 100,
          ),
        ],
      );

  group('ReturnsDao', () {
    setUp(() async {
      await seedInvoice();
      await db.inventoryDao.insertProduct(
        ProductsCompanion.insert(id: 'p1', name: 'Widget'),
      );
    });

    group('insertReturnWithItems', () {
      test('generates return number in RET-NNNNN format', () async {
        final ret = await seedReturn('inv1');
        expect(ret.returnNo, matches(RegExp(r'^RET-\d{5}$')));
      });

      test('first return number is RET-00001', () async {
        final ret = await seedReturn('inv1');
        expect(ret.returnNo, 'RET-00001');
      });

      test('second return increments to RET-00002', () async {
        await seedReturn('inv1');

        await db.invoicesDao.insertInvoice(InvoicesCompanion.insert(
          id: 'inv2', invoiceNo: 'INV-002', userId: 'u1',
        ));
        final ret2 = await seedReturn('inv2', id: 'ret2');
        expect(ret2.returnNo, 'RET-00002');
      });

      test('return number is overridden by internal counter (not companion)', () async {
        final ret = await db.returnsDao.insertReturnWithItems(
          SalesReturnsCompanion.insert(
            id: 'ret-x',
            invoiceId: 'inv1',
            returnNo: 'SHOULD-BE-REPLACED',
            userId: 'u1',
          ),
          [],
        );
        expect(ret.returnNo, 'RET-00001');
      });
    });

    group('getForInvoice', () {
      test('returns all returns for given invoice', () async {
        await seedReturn('inv1');
        await db.invoicesDao.insertInvoice(InvoicesCompanion.insert(
          id: 'inv2', invoiceNo: 'INV-002', userId: 'u1',
        ));
        await seedReturn('inv2', id: 'ret2');
        final list = await db.returnsDao.getForInvoice('inv1');
        expect(list.length, 1);
        expect(list.first.invoiceId, 'inv1');
      });

      test('returns empty list when invoice has no returns', () async {
        final list = await db.returnsDao.getForInvoice('inv1');
        expect(list, isEmpty);
      });
    });

    group('getItemsForReturn', () {
      test('returns all items for a return', () async {
        await seedReturn('inv1');
        final items = await db.returnsDao.getItemsForReturn('ret1');
        expect(items.length, 1);
        expect(items.first.productName, 'Widget');
      });

      test('returns empty list when return has no items', () async {
        await db.returnsDao.insertReturnWithItems(
          SalesReturnsCompanion.insert(
            id: 'ret-empty',
            invoiceId: 'inv1',
            returnNo: 'placeholder',
            userId: 'u1',
          ),
          [],
        );
        final items = await db.returnsDao.getItemsForReturn('ret-empty');
        expect(items, isEmpty);
      });
    });
  });
}
