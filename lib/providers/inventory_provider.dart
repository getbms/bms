import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/app_database.dart';
import '../data/database/daos/inventory_dao.dart';
import '../data/repositories/inventory_repository.dart';
import '../features/auth/domain/auth_state.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

// Manual providers - avoids riverpod_generator's Drift type serialization issue.
// inventoryRepository is keepAlive equivalent via Provider (never auto-disposed).

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) =>
    InventoryRepository(
      inventoryDao: ref.watch(inventoryDaoProvider),
      auditLogDao: ref.watch(auditLogDaoProvider),
    ));

final productsStreamProvider = StreamProvider.autoDispose<List<Product>>(
    (ref) => ref.watch(inventoryDaoProvider).watchAllProducts());

final stockStreamProvider = StreamProvider.autoDispose<List<StockLevel>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.stock).watch();
});

final lowStockStreamProvider = StreamProvider.autoDispose<List<StockLevel>>(
    (ref) => ref.watch(inventoryDaoProvider).watchLowStock());

final categoriesFutureProvider = FutureProvider.autoDispose<List<Category>>(
    (ref) => ref.watch(inventoryDaoProvider).getCategories());

class InventoryActions {
  InventoryActions(this._ref);
  final Ref _ref;
  final _uuid = const Uuid();

  InventoryDao get _dao => _ref.read(inventoryDaoProvider);

  String get _userId {
    final s = _ref.read(currentAuthStateProvider);
    return s is Authenticated ? s.user.id : 'system';
  }

  String get _userName {
    final s = _ref.read(currentAuthStateProvider);
    return s is Authenticated ? s.user.name : 'system';
  }

  Future<void> saveProduct({
    String? existingId,
    required String name,
    required String unitType,
    required double costPrice,
    required double sellPrice,
    String? barcode,
    String? categoryId,
    String? brand,
    int reorderLevel = 10,
  }) async {
    final audit = _ref.read(auditLogDaoProvider);
    if (existingId != null) {
      await _dao.updateProduct(ProductsCompanion(
        id: Value(existingId),
        name: Value(name),
        unitType: Value(unitType),
        costPrice: Value(costPrice),
        sellPrice: Value(sellPrice),
        barcode: Value(barcode),
        categoryId: Value(categoryId),
        brand: Value(brand),
        reorderLevel: Value(reorderLevel),
        updatedAt: Value(DateTime.now()),
      ));
      await audit.log(
        id: _uuid.v7(),
        entityType: 'product',
        entityId: existingId,
        action: 'update',
        userId: _userId,
        userName: _userName,
        newValue: {
          'name': name,
          'costPrice': costPrice,
          'sellPrice': sellPrice,
          'unitType': unitType,
        },
      );
    } else {
      final id = _uuid.v7();
      await _dao.insertProduct(ProductsCompanion.insert(
        id: id,
        name: name,
        unitType: Value(unitType),
        costPrice: Value(costPrice),
        sellPrice: Value(sellPrice),
        barcode: Value(barcode),
        categoryId: Value(categoryId),
        brand: Value(brand),
        reorderLevel: Value(reorderLevel),
      ));
      await _dao.upsertStock(
          StockCompanion.insert(productId: id, qty: const Value(0)));
      await audit.log(
        id: _uuid.v7(),
        entityType: 'product',
        entityId: id,
        action: 'create',
        userId: _userId,
        userName: _userName,
        newValue: {'name': name, 'costPrice': costPrice, 'sellPrice': sellPrice},
      );
    }
  }

  Future<void> adjustStock({
    required String productId,
    required double newQty,
    String reason = 'manual adjustment',
  }) async {
    final current = await _dao.getStock(productId);
    final oldQty = current?.qty ?? 0;
    final delta = newQty - oldQty;
    await _dao.upsertStock(StockCompanion(
      productId: Value(productId),
      qty: Value(newQty),
      updatedAt: Value(DateTime.now()),
    ));
    await _dao.recordMovement(StockMovementsCompanion.insert(
      id: _uuid.v7(),
      type: delta >= 0 ? 'in' : 'out',
      productId: productId,
      qty: delta.abs(),
      reason: Value(reason),
      userId: _userId,
    ));
    await _ref.read(auditLogDaoProvider).log(
      id: _uuid.v7(),
      entityType: 'stock',
      entityId: productId,
      action: 'adjust',
      userId: _userId,
      userName: _userName,
      oldValue: {'qty': oldQty},
      newValue: {'qty': newQty, 'reason': reason},
    );
  }
}

final inventoryActionsProvider =
    Provider<InventoryActions>((ref) => InventoryActions(ref));
