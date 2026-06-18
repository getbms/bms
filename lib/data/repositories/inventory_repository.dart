import 'package:bms/core/errors/app_exception.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/daos/audit_log_dao.dart';
import 'package:bms/data/database/daos/inventory_dao.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class InventoryRepository {
  InventoryRepository({required InventoryDao inventoryDao, required AuditLogDao auditLogDao})
      : _inventory = inventoryDao,
        _audit = auditLogDao;

  final InventoryDao _inventory;
  final AuditLogDao _audit;
  final _uuid = const Uuid();

  Stream<List<Product>> watchProducts() => _inventory.watchAll();

  Stream<List<StockLevel>> watchLowStock() => _inventory.watchLowStock();

  Future<Product?> findByBarcode(String barcode) => _inventory.findByBarcode(barcode);

  Future<String> createProduct({
    required String name,
    required String unitType,
    required double costPrice,
    required double sellPrice,
    String? barcode,
    String? categoryId,
    String? brand,
    int reorderLevel = 10,
    bool trackBatch = false,
    required String userId,
    required String userName,
  }) async {
    final id = _uuid.v7();
    await _inventory.insertProduct(
      ProductsCompanion.insert(
        id: id,
        name: name,
        unitType: Value(unitType),
        costPrice: Value(costPrice),
        sellPrice: Value(sellPrice),
        barcode: Value(barcode),
        categoryId: Value(categoryId),
        brand: Value(brand),
        reorderLevel: Value(reorderLevel),
        trackBatch: Value(trackBatch),
      ),
    );

    // Initialize stock at zero
    await _inventory.upsertStock(StockCompanion.insert(productId: id, qty: const Value(0)));

    await _audit.log(
      id: _uuid.v7(),
      entityType: 'product',
      entityId: id,
      action: 'create',
      userId: userId,
      userName: userName,
      newValue: {'name': name, 'costPrice': costPrice, 'sellPrice': sellPrice},
    );

    return id;
  }

  /// Adjusts stock quantity. Positive delta = stock in, negative = stock out.
  /// Wrapped in a transaction to prevent partial writes.
  Future<void> adjustStock({
    required String productId,
    required double delta,
    required String reason,
    required String userId,
    required String userName,
    String? refId,
    String? refType,
    String? movementType,
  }) async {
    final existing = await _inventory.getStock(productId);
    final currentQty = existing?.qty ?? 0;
    final newQty = currentQty + delta;

    if (newQty < 0) {
      throw BusinessRuleException(
        'Insufficient stock. Available: $currentQty, requested: ${delta.abs()}',
      );
    }

    await _inventory.upsertStock(
      StockCompanion(productId: Value(productId), qty: Value(newQty)),
    );

    await _inventory.recordMovement(
      StockMovementsCompanion.insert(
        id: _uuid.v7(),
        type: movementType ?? (delta >= 0 ? 'in' : 'out'),
        productId: productId,
        qty: delta.abs(),
        reason: Value(reason),
        userId: userId,
        refId: Value(refId),
        refType: Value(refType),
      ),
    );
  }
}
