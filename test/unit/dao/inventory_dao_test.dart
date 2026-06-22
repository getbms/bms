import 'package:bms/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_database.dart';

void main() {
  group('InventoryDao', () {
    late AppDatabase db;
    setUp(() { db = openTestDatabase(); });
    tearDown(() async { await db.close(); });

    ProductsCompanion product({
      String id = 'p1',
      String name = 'Widget',
      String? barcode,
      double reorderLevel = 5,
    }) =>
        ProductsCompanion.insert(
          id: id,
          name: name,
          barcode: barcode != null ? Value(barcode) : const Value.absent(),
          reorderLevel: Value(reorderLevel.toInt()),
        );

    test('insertProduct + findById: found returns product', () async {
      await db.inventoryDao.insertProduct(product());
      final result = await db.inventoryDao.findById('p1');
      expect(result, isNotNull);
      expect(result?.id, 'p1');
    });

    test('findById: not found returns null', () async {
      final result = await db.inventoryDao.findById('missing');
      expect(result, isNull);
    });

    test('findByBarcode: returns correct product when barcode matches', () async {
      await db.inventoryDao.insertProduct(product(barcode: 'BAR123'));
      final result = await db.inventoryDao.findByBarcode('BAR123');
      expect(result, isNotNull);
      expect(result?.barcode, 'BAR123');
    });

    test('insertCategory + getCategories: returns categories sorted by name', () async {
      await db.inventoryDao.insertCategory(CategoriesCompanion.insert(id: 'c2', name: 'Zeta'));
      await db.inventoryDao.insertCategory(CategoriesCompanion.insert(id: 'c1', name: 'Alpha'));
      final result = await db.inventoryDao.getCategories();
      expect(result.length, 2);
      expect(result.first.name, 'Alpha');
      expect(result.last.name, 'Zeta');
    });

    test('upsertStock + getStock: sets and retrieves qty', () async {
      await db.inventoryDao.insertProduct(product());
      await db.inventoryDao.upsertStock(
        StockCompanion.insert(productId: 'p1', qty: const Value(10)),
      );
      final result = await db.inventoryDao.getStock('p1');
      expect(result, isNotNull);
      expect(result?.qty, 10.0);
    });

    test('upsertStock twice updates qty', () async {
      await db.inventoryDao.insertProduct(product());
      await db.inventoryDao.upsertStock(
        StockCompanion.insert(productId: 'p1', qty: const Value(10)),
      );
      await db.inventoryDao.upsertStock(
        StockCompanion.insert(productId: 'p1', qty: const Value(25)),
      );
      final result = await db.inventoryDao.getStock('p1');
      expect(result?.qty, 25.0);
    });

    test('recordMovement + getMovementsForProduct: returns in desc order', () async {
      // StockMovements.userId has a FK to Users - seed a user first
      await db.usersDao.insertUser(UsersCompanion.insert(
        id: 'u1', name: 'Test', username: 'testuser', passwordHash: 'x',
      ));
      await db.inventoryDao.insertProduct(product());
      final t1 = DateTime(2024, 1, 1, 9);
      final t2 = DateTime(2024, 1, 1, 10);
      await db.into(db.stockMovements).insert(StockMovementsCompanion(
        id: const Value('m1'),
        type: const Value('in'),
        productId: const Value('p1'),
        qty: const Value(5),
        userId: const Value('u1'),
        createdAt: Value(t1),
      ));
      await db.into(db.stockMovements).insert(StockMovementsCompanion(
        id: const Value('m2'),
        type: const Value('out'),
        productId: const Value('p1'),
        qty: const Value(2),
        userId: const Value('u1'),
        createdAt: Value(t2),
      ));
      final movements = await db.inventoryDao.getMovementsForProduct('p1');
      expect(movements.length, 2);
      expect(movements.first.id, 'm2');
    });

    test('getLowStockProducts: returns product when qty <= reorderLevel', () async {
      await db.inventoryDao.insertProduct(product(reorderLevel: 10));
      await db.inventoryDao.upsertStock(
        StockCompanion.insert(productId: 'p1', qty: const Value(3)),
      );
      final result = await db.inventoryDao.getLowStockProducts();
      expect(result.any((p) => p.id == 'p1'), isTrue);
    });

    test('updateCostPrice: changes cost price', () async {
      await db.inventoryDao.insertProduct(product());
      await db.inventoryDao.updateCostPrice('p1', 99.99);
      final result = await db.inventoryDao.findById('p1');
      expect(result?.costPrice, 99.99);
    });
  });
}
